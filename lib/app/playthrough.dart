// The Player's state: which story is loaded, where the viewer is in it,
// and everything that happens while it plays (choices, music, pausing,
// saving).
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutria_fmv_player/app/settings.dart';
import 'package:nutria_fmv_player/core/music_director.dart';
import 'package:nutria_fmv_player/core/save_game.dart';
import 'package:nutria_fmv_player/core/story.dart';
import 'package:nutria_fmv_player/services/audio_engine.dart';
import 'package:nutria_fmv_player/services/story_files.dart';
import 'package:nutria_fmv_player/services/video_engine.dart';
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

/// Where the Player is.
enum Phase {
  /// Nothing loaded: the button to open a story.
  noStory,

  /// The story's main menu.
  menu,

  /// A video plays (possibly paused, with the pause menu).
  playing,
}

/// The Player's state, for the screens to show.
class Playthrough {
  const Playthrough({
    this.phase = Phase.noStory,
    this.storyPath,
    this.problem,
    this.nodeId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.choicesShown = false,
    this.picked,
    this.waitingAtEnd = false,
    this.paused = false,
    this.settingsOpen = false,
    this.hasSave = false,
  });

  final Phase phase;
  final String? storyPath;

  /// Why the last story couldn't be opened (the file's path), or `null`.
  final String? problem;

  /// The video node playing.
  final String? nodeId;
  final Duration position;
  final Duration duration;

  /// Whether the answers are on screen.
  final bool choicesShown;

  /// The answer the viewer picked, once they have.
  final int? picked;

  /// The video ended and waits: for an answer, or (without answers) for a
  /// click to go on ("pause on end").
  final bool waitingAtEnd;

  /// The pause menu is open.
  final bool paused;

  /// The settings are open (over the menu or the pause menu).
  final bool settingsOpen;

  /// The story has a saved game to load.
  final bool hasSave;

  Playthrough copyWith({
    Phase? phase,
    String? storyPath,
    String? Function()? problem,
    String? Function()? nodeId,
    Duration? position,
    Duration? duration,
    bool? choicesShown,
    int? Function()? picked,
    bool? waitingAtEnd,
    bool? paused,
    bool? settingsOpen,
    bool? hasSave,
  }) => Playthrough(
    phase: phase ?? this.phase,
    storyPath: storyPath ?? this.storyPath,
    problem: problem == null ? this.problem : problem(),
    nodeId: nodeId == null ? this.nodeId : nodeId(),
    position: position ?? this.position,
    duration: duration ?? this.duration,
    choicesShown: choicesShown ?? this.choicesShown,
    picked: picked == null ? this.picked : picked(),
    waitingAtEnd: waitingAtEnd ?? this.waitingAtEnd,
    paused: paused ?? this.paused,
    settingsOpen: settingsOpen ?? this.settingsOpen,
    hasSave: hasSave ?? this.hasSave,
  );
}

/// Runs the story: one method per thing the viewer does, and the video
/// engine's events.
class PlaythroughNotifier extends Notifier<Playthrough>
    implements VideoListener {
  Story? _story;
  FmvVariableState? _variables;

  /// The variables as they were when the current video started (what a
  /// save stores, so loading plays that video again from the same state).
  Map<String, Object> _variablesAtNode = const {};
  MusicDirector _music = MusicDirector();
  int _lastPicked = 0;
  final _random = math.Random();

  VideoEngine get _video => ref.read(videoEngineProvider);
  AudioEngine get _audio => ref.read(audioEngineProvider);
  StoryFiles get _files => ref.read(storyFilesProvider);

  /// The loaded story.
  Story? get story => _story;

  /// The video node playing.
  FmvNode? get currentNode => _story?.node(state.nodeId);

  @override
  Playthrough build() {
    ref.read(videoEngineProvider).listener = this;
    // Keep both engines at the viewer's volume.
    ref.listen(
      settingsProvider,
      (_, settings) => applyVolume(settings),
      fireImmediately: true,
    );
    return const Playthrough();
  }

  // ---------------------------------------------------------------- story

  /// Asks for a story file and opens it.
  Future<void> openStory() async {
    final path = await _files.pickStory();
    if (path != null) await loadStory(path);
  }

  /// Opens the story at [path] and shows its main menu.
  Future<void> loadStory(String path) async {
    final text = await _files.readText(path);
    FmvProject? project;
    if (text != null) {
      try {
        project = FmvProject.decode(text);
      } on FmvFormatException {
        project = null;
      } on FormatException {
        project = null;
      }
    }
    if (project == null) {
      state = state.copyWith(problem: () => path);
      return;
    }
    await _stopPlaying();
    _story = Story(project);
    state = Playthrough(
      phase: Phase.menu,
      storyPath: path,
      hasSave: SaveGame.decode(_files.readSave(path)) != null,
    );
    await _playMenuMusic();
  }

  Future<void> _playMenuMusic() async {
    if (_story?.project.info.menuMusic case final music?) {
      await _audio.play(MusicChannel.story, music.track, loop: true);
    }
  }

  /// Starts the story from the beginning, or from [save].
  Future<void> start({SaveGame? save}) async {
    final story = _story;
    if (story == null) return;
    final variables = FmvVariableState(story.project.variables);
    if (save != null) variables.restore(save.values);
    _variables = variables;
    _lastPicked = save?.lastPicked ?? 0;
    _music = MusicDirector();
    final menuMusic = story.project.info.menuMusic;
    await _audio.stop(MusicChannel.story, fadeOutMs: menuMusic?.fadeOutMs ?? 0);
    final first = save != null && story.node(save.nodeId) != null
        ? save.nodeId
        : story.resolve(story.startId, variables);
    await _enter(first);
  }

  /// Loads the story's saved game.
  Future<void> loadSave() async {
    final path = state.storyPath;
    if (path == null) return;
    final save = SaveGame.decode(_files.readSave(path));
    if (save != null) await start(save: save);
  }

  /// Saves the current place (the video playing restarts when loaded).
  Future<void> save() async {
    final path = state.storyPath;
    final nodeId = state.nodeId;
    if (path == null || nodeId == null) return;
    await _files.writeSave(
      path,
      SaveGame(
        nodeId: nodeId,
        values: _variablesAtNode,
        lastPicked: _lastPicked,
        savedAt: DateTime.now(),
      ).encode(),
    );
    state = state.copyWith(hasSave: true);
  }

  /// Back to the main menu.
  Future<void> toMenu() async {
    await _stopPlaying();
    state = Playthrough(
      phase: _story == null ? Phase.noStory : Phase.menu,
      storyPath: state.storyPath,
      hasSave: state.hasSave,
    );
    await _playMenuMusic();
  }

  Future<void> _stopPlaying() async {
    await _video.stop();
    final stops = _music.stopAll();
    await _run(MusicChannel.story, stops.story);
    await _run(MusicChannel.pause, stops.pause);
    // The menu's music, if it was playing.
    await _audio.stop(MusicChannel.story);
  }

  // -------------------------------------------------------------- playing

  Future<void> _enter(String? nodeId) async {
    final story = _story!;
    final node = story.node(nodeId);
    if (node == null) {
      await toMenu();
      return;
    }
    final variables = _variables!;
    _variablesAtNode = Map.of(variables.values);
    state = state.copyWith(
      phase: Phase.playing,
      nodeId: () => nodeId,
      position: Duration.zero,
      duration: Duration.zero,
      choicesShown: false,
      picked: () => null,
      waitingAtEnd: false,
      paused: false,
      settingsOpen: false,
    );
    await _run(MusicChannel.story, _music.enterVideo(node));
    final video = node.video;
    if (video == null) {
      // Nothing to show: go on as if it had played.
      onCompleted();
      return;
    }
    await _video.play(video);
    await _video.preload({
      for (final id in story.upcoming(node, variables)) ?story.node(id)?.video,
    });
  }

  @override
  void onPosition(Duration position, Duration duration) {
    final node = currentNode;
    if (node == null || state.phase != Phase.playing) return;
    state = state.copyWith(position: position, duration: duration);
    final remaining = duration - position;
    if (node.isBranched &&
        !state.choicesShown &&
        duration > Duration.zero &&
        remaining.inMilliseconds <= _story!.settingsOf(node).selectionTimeMs) {
      _showChoices(node);
    }
  }

  void _showChoices(FmvNode node) {
    state = state.copyWith(choicesShown: true);
    final commands = _music.choicesAppear(node);
    _run(MusicChannel.story, commands.story);
    _run(MusicChannel.pause, commands.pause);
  }

  /// The viewer picks answer [index].
  void pick(int index) {
    final node = currentNode;
    final count = node?.choices?.length ?? 0;
    if (node == null ||
        !state.choicesShown ||
        state.picked != null ||
        index < 0 ||
        index >= count) {
      return;
    }
    _lastPicked = index;
    state = state.copyWith(picked: () => index);
    _run(MusicChannel.pause, _music.choiceMade());
    if (state.waitingAtEnd) _advance();
  }

  /// Goes on after a video that waits at its end (no answers).
  void continueAtEnd() {
    final node = currentNode;
    if (node == null || !state.waitingAtEnd || node.isBranched) return;
    _advance();
  }

  @override
  void onCompleted() {
    final node = currentNode;
    if (node == null || state.phase != Phase.playing) return;
    _run(MusicChannel.story, _music.videoEnded());
    final waits = _story!.settingsOf(node).pauseOnEnd;
    if (node.isBranched) {
      // A video shorter than the choosing time shows its answers now.
      if (!state.choicesShown) _showChoices(node);
      if (state.picked == null) {
        if (waits) {
          state = state.copyWith(waitingAtEnd: true);
          return;
        }
        final choice = _story!.defaultChoice(
          node,
          lastPicked: _lastPicked,
          random: _random,
        );
        _lastPicked = choice;
        state = state.copyWith(picked: () => choice);
        _run(MusicChannel.pause, _music.choiceMade());
      }
    } else if (waits) {
      state = state.copyWith(waitingAtEnd: true);
      return;
    }
    _advance();
  }

  void _advance() {
    final node = currentNode!;
    final next = _story!.resolve(
      _story!.nextOf(node, state.picked ?? 0),
      _variables!,
    );
    _enter(next);
  }

  /// Opens the pause menu (stopping the video and music).
  void pause() {
    if (state.phase != Phase.playing || state.paused) return;
    _video.pause();
    _audio.pauseAll();
    state = state.copyWith(paused: true);
  }

  /// Closes the pause menu and plays on.
  void resume() {
    if (!state.paused) return;
    state = state.copyWith(paused: false, settingsOpen: false);
    _video.resume();
    _audio.resumeAll();
  }

  void togglePause() => state.paused ? resume() : pause();

  void openSettings() => state = state.copyWith(settingsOpen: true);

  void closeSettings() => state = state.copyWith(settingsOpen: false);

  /// Applies the viewer's volume to both engines.
  void applyVolume(PlayerSettings settings) {
    _video.setVolume(settings.volume);
    _audio.setVolume(settings.volume);
  }

  Future<void> _run(MusicChannel channel, MusicCommand? command) async {
    switch (command) {
      case PlayMusic(:final track, :final loop):
        await _audio.play(
          channel,
          track,
          loop: loop,
          onFinished: channel == MusicChannel.story
              ? _music.trackFinished
              : null,
        );
      case StopMusic(:final fadeOutMs):
        await _audio.stop(channel, fadeOutMs: fadeOutMs);
      case null:
        break;
    }
  }
}

final playthroughProvider = NotifierProvider<PlaythroughNotifier, Playthrough>(
  PlaythroughNotifier.new,
);
