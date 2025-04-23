import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerStackProvider extends ChangeNotifier {
  VideoPlayerEntry? _activeEntry;

  final List<VideoPlayerEntry> _preloadedEntries = [];

  List<VideoPlayerEntry> get allVisibleEntries {
    List<VideoPlayerEntry> entries = <VideoPlayerEntry>[];
    entries = [if (_activeEntry != null) _activeEntry!, ..._preloadedEntries];
    return entries;
  }

  VideoPlayerEntry? get currentEntry => _activeEntry;

  bool get isPlaying => _activeEntry?.player.state.playing ?? false;

  bool _areVideosDirty = false;
  bool get areVideosDirty => _areVideosDirty;
  set areVideosDirty(bool value) {
    if (_areVideosDirty != value) {
      _areVideosDirty = value;
      //notifyListeners only if they are dirty.
      if (value) {
        notifyListeners();
      }
    }
  }

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
    final nextEntry = _preloadedEntries
        .firstWhereOrNull((entry) => entry.videoPath == nextPath);

    if (nextEntry != null) {
      // Step 1: Promote to active immediately
      final oldEntry = _activeEntry;
      _activeEntry = nextEntry;
      _preloadedEntries.remove(nextEntry);

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
      if (_preloadedEntries.every((entry) => entry.videoPath != path)) {
        final entry = await _createEntry(path, autoPlay: false);
        _preloadedEntries.add(entry);
      }
    }
  }

  Future<VideoPlayerEntry> _createEntry(
    String videoPath, {
    bool autoPlay = false,
  }) async {
    final player = Player();
    final controller = VideoController(player);

    await player.open(Media(videoPath), play: autoPlay);

    //TODO potential memory leak because i create listeners for every video loaded
    player.stream.completed.listen((_) {
      areVideosDirty = true;
    });

    return VideoPlayerEntry(
      player: player,
      controller: controller,
      videoPath: videoPath,
    );
  }

  Future<void> _disposeAll() async {
    await _activeEntry?.player.dispose();
    _activeEntry = null;
    await _disposeAllPreloads();
  }

  Future<void> _disposeAllPreloads() async {
    for (final entry in _preloadedEntries) {
      await entry.player.dispose();
    }
    _preloadedEntries.clear();
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
