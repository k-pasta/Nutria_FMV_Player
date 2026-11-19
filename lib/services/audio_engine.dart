// Music: three channels (the story's music, the music while choosing, and
// the pause menu's), each fading out when stopped.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// The music channels.
enum MusicChannel {
  /// Music with the videos (and the main menu's).
  story,

  /// Music while the viewer chooses.
  pause,

  /// Music in the pause menu. [AudioEngine.pauseAll] leaves it alone: it
  /// plays while the rest is paused.
  pauseMenu,
}

/// Plays music on [MusicChannel]s.
abstract interface class AudioEngine {
  /// Plays [path] on [channel] from the start, replacing what played there.
  /// [onFinished] is called when a track that doesn't loop ends.
  Future<void> play(
    MusicChannel channel,
    String path, {
    required bool loop,
    void Function()? onFinished,
  });

  /// Fades [channel] out over [fadeOutMs] and stops it.
  Future<void> stop(MusicChannel channel, {int fadeOutMs = 0});

  /// Pauses and resumes every channel but [MusicChannel.pauseMenu].
  void pauseAll();
  void resumeAll();

  /// 0 to 100.
  void setVolume(double volume);
}

/// [AudioEngine] with `media_kit` players (no video output).
class MediaKitAudioEngine implements AudioEngine {
  final Map<MusicChannel, Player> _players = {};
  final Map<MusicChannel, StreamSubscription<bool>> _finished = {};
  double _volume = 100;

  @override
  Future<void> play(
    MusicChannel channel,
    String path, {
    required bool loop,
    void Function()? onFinished,
  }) async {
    await _dispose(channel);
    final player = Player();
    _players[channel] = player;
    await player.setPlaylistMode(
      loop ? PlaylistMode.single : PlaylistMode.none,
    );
    await player.setVolume(_volume);
    await player.open(Media(path));
    if (!loop && onFinished != null) {
      _finished[channel] = player.stream.completed.listen((done) {
        if (done) onFinished();
      });
    }
  }

  @override
  Future<void> stop(MusicChannel channel, {int fadeOutMs = 0}) async {
    final player = _players[channel];
    if (player == null) return;
    // Fade in about 20 steps, then let go of the player.
    const steps = 20;
    if (fadeOutMs > 0) {
      for (var i = steps - 1; i >= 0; i--) {
        if (_players[channel] != player) return;
        await player.setVolume(_volume * i / steps);
        await Future<void>.delayed(Duration(milliseconds: fadeOutMs ~/ steps));
      }
    }
    if (_players[channel] == player) await _dispose(channel);
  }

  Future<void> _dispose(MusicChannel channel) async {
    await _finished.remove(channel)?.cancel();
    await _players.remove(channel)?.dispose();
  }

  @override
  void pauseAll() {
    for (final MapEntry(key: channel, value: p) in _players.entries) {
      if (channel != MusicChannel.pauseMenu) p.pause();
    }
  }

  @override
  void resumeAll() {
    for (final MapEntry(key: channel, value: p) in _players.entries) {
      if (channel != MusicChannel.pauseMenu) p.play();
    }
  }

  @override
  void setVolume(double volume) {
    _volume = volume;
    for (final p in _players.values) {
      p.setVolume(volume);
    }
  }
}

/// The app's audio engine; tests replace it.
final audioEngineProvider = Provider<AudioEngine>(
  (ref) => MediaKitAudioEngine(),
);
