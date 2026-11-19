import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nutria_fmv_player/app/playthrough.dart';
import 'package:nutria_fmv_player/services/audio_engine.dart';
import 'package:nutria_fmv_player/services/story_files.dart';
import 'package:nutria_fmv_player/services/video_engine.dart';
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

class FakeVideo implements VideoEngine {
  VideoListener? _listener;
  final played = <String>[];
  Set<String> preloaded = {};
  bool paused = false;

  @override
  set listener(VideoListener? listener) => _listener = listener;

  /// Pretends the video is at [position] of [length].
  void at(Duration position, Duration length) =>
      _listener!.onPosition(position, length);

  void finish() => _listener!.onCompleted();

  @override
  Future<void> play(String path) async => played.add(path);

  @override
  Future<void> preload(Set<String> paths) async => preloaded = paths;

  @override
  void pause() => paused = true;

  @override
  void resume() => paused = false;

  @override
  Future<void> stop() async {}

  @override
  void setVolume(double volume) {}

  @override
  Widget view(BoxFit fit) => const SizedBox();
}

class FakeAudio implements AudioEngine {
  final log = <String>[];

  @override
  Future<void> play(
    MusicChannel channel,
    String path, {
    required bool loop,
    void Function()? onFinished,
  }) async => log.add('${channel.name} play $path');

  @override
  Future<void> stop(MusicChannel channel, {int fadeOutMs = 0}) async =>
      log.add('${channel.name} stop');

  @override
  void pauseAll() {}

  @override
  void resumeAll() {}

  @override
  void setVolume(double volume) {}
}

class FakeFiles implements StoryFiles {
  final files = <String, String>{};
  final saves = <String, String>{};
  final settings = <String, String>{};

  @override
  Future<String?> pickStory() async => null;

  @override
  Future<String?> readText(String path) async => files[path];

  @override
  String? readSave(String storyPath) => saves[storyPath];

  @override
  Future<void> writeSave(String storyPath, String save) async =>
      saves[storyPath] = save;

  @override
  String? readSetting(String key) => settings[key];

  @override
  Future<void> writeSetting(String key, String value) async =>
      settings[key] = value;
}

/// a.mp4 (with music) → add a coin → b.mp4 asks "Which?": Left → c.mp4,
/// Right → the end. The menu has music.
const _story = FmvProject(
  info: FmvProjectInfo(
    title: 'Story',
    menuMusic: FmvLoopMusic(track: 'menu.mp3'),
    pauseMenuMusic: FmvLoopMusic(track: 'paused.mp3'),
  ),
  settings: FmvSettings(selectionTimeMs: 4000),
  variables: {'coins': FmvVariable(type: FmvVariableType.integer, initial: 0)},
  nodes: {
    '001': FmvNode(
      video: 'a.mp4',
      target: '002',
      music: FmvMusic(track: 'song.mp3', end: FmvMusicEnd.laterNodeChanges),
    ),
    '002': FmvNode(
      type: FmvNodeType.change,
      variable: 'coins',
      operation: FmvChangeOperation.add,
      value: '1',
      target: '003',
    ),
    '003': FmvNode(
      video: 'b.mp4',
      question: 'Which?',
      choices: [
        FmvChoice(text: 'Left', target: '004'),
        FmvChoice(text: 'Right'),
      ],
      pauseMusic: FmvLoopMusic(track: 'think.mp3'),
    ),
    '004': FmvNode(video: 'c.mp4'),
  },
);

const _s = Duration(seconds: 1);

void main() {
  late FakeVideo video;
  late FakeAudio audio;
  late FakeFiles files;
  late ProviderContainer c;

  setUp(() async {
    video = FakeVideo();
    audio = FakeAudio();
    files = FakeFiles()..files['story.fmv'] = _story.encode();
    c = ProviderContainer.test(
      overrides: [
        videoEngineProvider.overrideWithValue(video),
        audioEngineProvider.overrideWithValue(audio),
        storyFilesProvider.overrideWithValue(files),
      ],
    );
    await c.read(playthroughProvider.notifier).loadStory('story.fmv');
  });

  Playthrough state() => c.read(playthroughProvider);
  PlaythroughNotifier player() => c.read(playthroughProvider.notifier);

  test('a story opens at its menu, with its music', () {
    expect(state().phase, Phase.menu);
    expect(audio.log.last, 'story play menu.mp3');
  });

  test(
    'playing through: logic between videos, answers, music, the end',
    () async {
      await player().start();
      expect(video.played, ['a.mp4']);
      expect(video.preloaded, {'b.mp4'}, reason: 'after the logic node');
      expect(audio.log.last, 'story play song.mp3');

      video.finish();
      await pumpEventQueue();
      expect(video.played.last, 'b.mp4');
      expect(state().choicesShown, isFalse);
      expect(audio.log.last, 'story play song.mp3', reason: 'goes on');

      // Answers appear 4 seconds before the end.
      video.at(_s * 5, _s * 10);
      expect(state().choicesShown, isFalse);
      video.at(_s * 6, _s * 10);
      expect(state().choicesShown, isTrue);
      expect(audio.log.last, 'pause play think.mp3');

      player().pick(0);
      expect(state().picked, 0);
      expect(audio.log.last, 'pause stop');
      video.finish();
      await pumpEventQueue();
      expect(video.played.last, 'c.mp4');

      video.finish();
      await pumpEventQueue();
      expect(state().phase, Phase.menu, reason: 'the end');
    },
  );

  test('no answer: the default one is taken; pause stops the video', () async {
    await player().start();
    video.finish();
    await pumpEventQueue();
    player().pause();
    expect(state().paused, isTrue);
    expect(video.paused, isTrue);
    expect(audio.log.last, 'pauseMenu play paused.mp3');
    player().resume();
    expect(video.paused, isFalse);
    expect(audio.log.last, 'pauseMenu stop');

    video.finish();
    await pumpEventQueue();
    expect(video.played.last, 'c.mp4', reason: 'the first answer');
  });

  test('a save plays its video again with the variables it had', () async {
    await player().start();
    video.finish();
    await pumpEventQueue();
    await player().save();
    expect(state().hasSave, isTrue);

    await player().toMenu();
    await player().loadSave();
    expect(video.played.last, 'b.mp4');
    expect(state().nodeId, '003');
  });

  test('the saved games screen opens and closes; a save says when', () async {
    expect(state().savedAt, isNull);
    await player().start();
    await player().save();
    expect(state().savedAt, isNotNull);
    await player().toMenu();
    expect(state().hasSave, isTrue, reason: 'kept on the menu');
    player().openSaves();
    expect(state().savesOpen, isTrue);
    player().closeSaves();
    expect(state().savesOpen, isFalse);
  });

  test('a file that is not a story is reported', () async {
    files.files['bad.fmv'] = 'not json';
    await player().loadStory('bad.fmv');
    expect(state().problem, 'bad.fmv');
    expect(state().phase, Phase.menu, reason: 'the old story stays');
  });
}
