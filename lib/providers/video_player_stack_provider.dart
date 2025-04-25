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

  VideoPlayerEntry? get currentEntry =>
      allVisibleEntries.firstWhereOrNull((entry) => entry.player.state.playing);

  VideoPlayerEntry? get firstEntry =>
      allVisibleEntries.isNotEmpty ? allVisibleEntries.first : null;

  bool get isPlaying => _activeEntry?.player.state.playing ?? false;

  ShouldStackUpdate _shouldStackUpdate = ShouldStackUpdate.no;

  get shouldStackUpdate {
    return _shouldStackUpdate;
  }

  void setVideosDirtyFlag(ShouldStackUpdate reason) {
    _shouldStackUpdate = reason;
    notifyListeners();
  }

  void clearVideosDirtyFlag() {
    _shouldStackUpdate = ShouldStackUpdate.no;
    notifyListeners();
  }

  /// Load the very first video and preload future options
  Future<void> loadInitialVideo({
    required String videoPath,
    required List<String> preloadPaths,
  }) async {
    await _disposeAll();
    await _preloadVideos(preloadPaths);
    _activeEntry = await _createEntry(videoPath, autoPlay: true);

    setVideosDirtyFlag(ShouldStackUpdate.initial);
    print('completed loading initial video');
  }

  /// Transition to one of the preloaded videos
  void transitionToNextVideo({
    required String nextPath,
    required List<String> preloadPaths,
  }) {
    final nextEntry = _preloadedEntries
        .firstWhereOrNull((entry) => entry.videoPath == nextPath);

//print _preloadedEntries paths and nextPath
    print(
        'TR-Preloaded entries paths: ${_preloadedEntries.map((entry) => entry.videoPath).toList()}');
    print('TR-Next path: $nextPath');

    if (nextEntry != null) {
      print('TR-there is a preloaded entry with that path');
      // Step 1: Promote to active immediately
      final oldEntry = _activeEntry;
      _activeEntry = nextEntry;
      _preloadedEntries.remove(nextEntry);

      // Step 2: Play the new one immediately
      _activeEntry!.player.play();

      // Step 3: Dispose of old active player in background
      if (oldEntry != null) {
        oldEntry.player.dispose();
      }

      // Step 4: Clean and preload others in background
      _disposeAllPreloads().then((_) => _preloadVideos(preloadPaths));

    } else {
      throw Exception('The requested video path was not preloaded: $nextPath');
    }
  }

  // void callNotify() {
  //   notifyListeners();
  // }

  /// Preloads a list of video paths into memory for faster transitions.
  ///
  /// This method ensures that videos are preloaded only if they are not
  /// already in the `_preloadedEntries` list. It creates a `VideoPlayerEntry`
  /// for each path and adds it to the preloaded entries.
  Future<void> _preloadVideos(List<String> paths) async {
    for (var path in paths) {
      // Check if the video is already preloaded
      if (_preloadedEntries.every((entry) => entry.videoPath != path)) {
        // Create a new VideoPlayerEntry for the video path
        final entry = await _createEntry(path, autoPlay: false);
        // Add the entry to the preloaded entries list
        _preloadedEntries.add(entry);
      }
    }
    print(
        'TR-Preloaded videos paths: ${_preloadedEntries.map((entry) => entry.videoPath).toList()}');
  }

  Future<void> _disposeAll() async {
    await _activeEntry?.player.dispose();
    _activeEntry = null;
    await _disposeAllPreloads();
  }

  Future<void> _disposeAllPreloads() async {
    final entriesToDispose = List<VideoPlayerEntry>.from(_preloadedEntries);
    for (final entry in entriesToDispose) {
      await entry.player.dispose();
    }
    _preloadedEntries.clear();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  /// Internal utility to create and optionally warm-up a video entry.
  Future<VideoPlayerEntry> _createEntry(
    String path, {
    bool autoPlay = false,
  }) async {
    final player = Player();
    final controller = VideoController(player);
    final subs = <StreamSubscription>[];
    // Open media
    await player.open(Media(path), play: autoPlay);
    await player.setVolume(100);

    // Optional quick warm-up cycle
    // if (autoWarmUp && !autoPlay) {
    //   await player.setVolume(0);
    //   await player.play();
    //   await Future.delayed(const Duration(milliseconds: 50));
    //   await player.pause();
    //   await player.seek(const Duration(milliseconds: 0));
    //   await player.setVolume(100);
    // }

    // Listen for playback completion
    subs.add(player.stream.completed.listen((completed) {
      if (completed) {
        setVideosDirtyFlag(ShouldStackUpdate.option);
        log('Completed playing `$path`');
      }
    }));

    return VideoPlayerEntry._(
      player: player,
      controller: controller,
      videoPath: path,
      subscriptions: subs,
    );
  }

  void log(String message) => debugPrint('[VPStack] $message');
}

/// Internal video entry with disposal logic.
class VideoPlayerEntry {
  VideoPlayerEntry._({
    required this.player,
    required this.controller,
    required this.videoPath,
    required this.subscriptions,
  });

  final Player player;
  final VideoController controller;
  final String videoPath;
  final List<StreamSubscription> subscriptions;

  // Getter for position stream
  Stream<Duration> get positionStream => player.stream.position;
  bool get completed => player.state.completed;
  /// Dispose this entry's resources.
  Future<void> dispose() async {
    for (var sub in subscriptions) {
      await sub.cancel();
    }
    await player.dispose();
    log('Disposed entry `$videoPath`');
  }

  void log(String message) => debugPrint('[VPStack] $message');
}

enum ShouldStackUpdate { no, initial, option, end }
