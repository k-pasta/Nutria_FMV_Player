// Plays the story's videos, with the next ones loaded ahead of time so
// they start without a gap.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// What the video playing does, for the story to react to.
abstract interface class VideoListener {
  /// The playing video's position (and its length, once known).
  void onPosition(Duration position, Duration duration);

  /// The playing video reached its end.
  void onCompleted();
}

/// Plays one video at a time (full window) and keeps others loaded.
abstract interface class VideoEngine {
  set listener(VideoListener? listener);

  /// Starts [path] from the beginning (instantly if it was preloaded).
  Future<void> play(String path);

  /// Loads [paths] so they can start at once; drops other loaded videos.
  Future<void> preload(Set<String> paths);

  void pause();
  void resume();

  /// Stops and unloads everything.
  Future<void> stop();

  /// 0 to 100.
  void setVolume(double volume);

  /// The playing video, filling the area as [fit] says.
  Widget view(BoxFit fit);
}

/// [VideoEngine] with `media_kit`.
class MediaKitVideoEngine implements VideoEngine {
  _Loaded? _current;
  final Map<String, _Loaded> _preloaded = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  VideoListener? _listener;
  double _volume = 100;

  /// Changes when a different video starts, so [view] rebuilds.
  final ValueNotifier<_Loaded?> _shown = ValueNotifier(null);

  @override
  set listener(VideoListener? listener) => _listener = listener;

  Future<_Loaded> _load(String path) async {
    final player = Player();
    final loaded = _Loaded(path, player, VideoController(player));
    await player.open(Media(path), play: false);
    await player.setVolume(_volume);
    return loaded;
  }

  @override
  Future<void> play(String path) async {
    final previous = _current;
    final next = _preloaded.remove(path) ?? await _load(path);
    _current = next;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions
      ..clear()
      ..add(
        next.player.stream.position.listen((p) {
          if (_current == next) {
            _listener?.onPosition(p, next.player.state.duration);
          }
        }),
      )
      ..add(
        // media_kit can report the end more than once; the story must hear
        // it once, and only for the video playing now.
        next.player.stream.completed.listen((done) {
          if (done && _current == next && !next.ended) {
            next.ended = true;
            _listener?.onCompleted();
          }
        }),
      );
    await next.player.setVolume(_volume);
    await next.player.seek(Duration.zero);
    await next.player.play();
    _shown.value = next;
    if (previous != null && previous != next) {
      await previous.player.dispose();
    }
  }

  @override
  Future<void> preload(Set<String> paths) async {
    for (final path in [..._preloaded.keys]) {
      if (!paths.contains(path)) {
        await _preloaded.remove(path)!.player.dispose();
      }
    }
    for (final path in paths) {
      if (!_preloaded.containsKey(path) && path != _current?.path) {
        _preloaded[path] = await _load(path);
      }
    }
  }

  @override
  void pause() => _current?.player.pause();

  @override
  void resume() => _current?.player.play();

  @override
  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _shown.value = null;
    await _current?.player.dispose();
    _current = null;
    for (final loaded in _preloaded.values) {
      await loaded.player.dispose();
    }
    _preloaded.clear();
  }

  @override
  void setVolume(double volume) {
    _volume = volume;
    _current?.player.setVolume(volume);
  }

  @override
  Widget view(BoxFit fit) => ValueListenableBuilder(
    valueListenable: _shown,
    builder: (context, shown, _) => shown == null
        ? const SizedBox.expand()
        : Video(
            key: ValueKey(shown),
            controller: shown.controller,
            controls: NoVideoControls,
            fit: fit,
          ),
  );
}

class _Loaded {
  _Loaded(this.path, this.player, this.controller);

  final String path;
  final Player player;
  final VideoController controller;

  /// Its end was reported (once is enough).
  bool ended = false;
}

/// The app's video engine; tests replace it.
final videoEngineProvider = Provider<VideoEngine>(
  (ref) => MediaKitVideoEngine(),
);
