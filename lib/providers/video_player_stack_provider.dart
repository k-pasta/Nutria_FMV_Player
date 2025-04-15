import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerStackProvider extends ChangeNotifier {
  VideoPlayerEntry? _activeEntry;
  final Map<String, VideoPlayerEntry> _preloadedEntries = {}; // path -> entry
Map<String, VideoPlayerEntry> get allVisibleEntries {
    final entries = <String, VideoPlayerEntry>{};
    if (_activeEntry != null) {
      entries[_activeEntry!.videoPath] = _activeEntry!;
    }
    entries.addAll(_preloadedEntries);
    return entries;
  }

  Player? get player => _activeEntry?.player;
  VideoController? get controller => _activeEntry?.controller;
  String? get currentVideoPath => _activeEntry?.videoPath;

  bool get isPlaying => player?.state.playing ?? false;

  /// Load the very first video and preload future options
  Future<void> loadInitialVideo({
    required String videoPath,
    required List<String> preloadPaths,
  }) async {
    await _disposeAll();

    _activeEntry = await _createEntry(videoPath, autoPlay: true);
    notifyListeners();

    await _preloadVideos(preloadPaths);
  }

  /// Transition to one of the preloaded videos
  Future<void> transitionToNextVideo({
  required String nextPath,
  required List<String> preloadPaths,
}) async {
  final nextEntry = _preloadedEntries[nextPath];

  if (nextEntry != null) {
    // Step 1: Promote to active immediately
    final oldEntry = _activeEntry;
    _activeEntry = nextEntry;
    _preloadedEntries.remove(nextPath);
    notifyListeners(); // This triggers a widget update (like switching opacity)

    // Step 2: Play the new one immediately
    unawaited(_activeEntry!.player.play());

    // Step 3: Dispose of old active player in background
    if (oldEntry != null) {
      unawaited(oldEntry.player.dispose());
    }

    // Step 4: Clean and preload others in background
    unawaited(_disposeAllPreloads());
    unawaited(_preloadVideos(preloadPaths));
  } else {
    // Fallback: load from scratch (still with unawaited transitions)
    await loadInitialVideo(
      videoPath: nextPath,
      preloadPaths: preloadPaths,
    );
  }
}

  Future<void> _preloadVideos(List<String> paths) async {
    for (var path in paths) {
      if (!_preloadedEntries.containsKey(path)) {
        final entry = await _createEntry(path, autoPlay: false);
        _preloadedEntries[path] = entry;
      }
    }
  }

  Future<VideoPlayerEntry> _createEntry(
    String videoPath, {
    bool autoPlay = false,
  }) async {
    final player = Player();
    final controller = VideoController(player);

    await player.setVolume(100);
    await player.open(Media(videoPath), play: autoPlay);

    return VideoPlayerEntry(
      player: player,
      controller: controller,
      videoPath: videoPath,
    );
  }

  Future<void> _disposeAllPreloads() async {
    for (final entry in _preloadedEntries.values) {
      await entry.player.dispose();
    }
    _preloadedEntries.clear();
  }

  Future<void> _disposeAll() async {
    await _activeEntry?.player.dispose();
    _activeEntry = null;
    await _disposeAllPreloads();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }
}

class VideoPlayerEntry {
  final Player player;
  final VideoController controller;
  final String videoPath;

  VideoPlayerEntry({
    required this.player,
    required this.controller,
    required this.videoPath,
  });
}