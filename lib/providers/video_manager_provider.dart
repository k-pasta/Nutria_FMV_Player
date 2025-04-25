// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';

// /// A simple provider managing a stack of video players for seamless transitions.
// class VideoManagerProvider extends ChangeNotifier {
//   VideoManagerProvider({this.autoWarmUp = true});

//   /// Whether to perform a quick warm-up play/pause cycle on preloads.
//   final bool autoWarmUp;

//   /// Active video index in the pool.
//   int _activeIndex = 0;

//   /// Pool of video entries: first is active, others are preloaded.
//   final List<VideoEntry> _pool = [];

//   /// Unmodifiable view of current entries (active + preloads).
//   List<VideoEntry> get entries => List.unmodifiable(_pool);

//   /// The currently active entry.
//   VideoEntry? get activeEntry => (_pool.isNotEmpty) ? _pool[_activeIndex] : null;

//   /// Indicates if the active video is playing.
//   bool get isPlaying => activeEntry?.player.state.playing ?? false;

//   /// Load the initial video and optional preload list.
//   Future<void> load({
//     required String initialPath,
//     List<String>? preloadPaths,
//   }) async {
//     await _disposeAll();
//     _activeIndex = 0;

//     // Create active entry and autoplay
//     final active = await _createEntry(initialPath, autoPlay: true);
//     _pool.add(active);

//     // Preload others
//     if (preloadPaths != null) {
//       for (var path in preloadPaths) {
//         final entry = await _createEntry(path, autoPlay: false);
//         _pool.add(entry);
//       }
//     }

//     notifyListeners();
//     debugPrint('[VideoManager] Loaded initial video `$initialPath`');
//   }

//   /// Transition to a new video, disposing old preloads and setting up new ones.
//   Future<void> transitionTo({
//     required String path,
//     List<String>? preloadPaths,
//   }) async {
//     // Find or create the target entry
//     int index = _pool.indexWhere((e) => e.path == path);
//     VideoEntry entry;
//     if (index != -1) {
//       entry = _pool[index];
//     } else {
//       entry = await _createEntry(path, autoPlay: false);
//     }

//     // Stop and pause current active
//     activeEntry?.player.pause();

//     // Dispose all others except our target
//     for (var e in List<VideoEntry>.from(_pool)) {
//       if (e.path != entry.path) {
//         await e.dispose();
//         _pool.remove(e);
//       }
//     }

//     // Ensure target is first in pool
//     _activeIndex = 0;
//     _pool.remove(entry);
//     _pool.insert(0, entry);

//     // Start playback
//     await entry.player.play();
//     debugPrint('[VideoManager] Transitioned to `$path`');

//     // Preload fresh list
//     if (preloadPaths != null) {
//       for (var p in preloadPaths) {
//         // skip already loaded
//         if (_pool.any((e) => e.path == p)) continue;
//         final preloadEntry = await _createEntry(p, autoPlay: false);
//         _pool.add(preloadEntry);
//       }
//     }

//     notifyListeners();
//   }

//   /// Dispose of all players and subscriptions.
//   Future<void> _disposeAll() async {
//     for (var entry in _pool) {
//       await entry.dispose();
//     }
//     _pool.clear();
//     debugPrint('[VideoManager] Disposed all entries');
//   }

//   /// Internal utility to create and optionally warm-up a video entry.
//   Future<VideoEntry> _createEntry(
//     String path, {
//     bool autoPlay = false,
//   }) async {
//     final player = Player();
//     final controller = VideoController(player);
//     final subs = <StreamSubscription>[];

//     // Open media
//     await player.open(Media(path), play: autoPlay);
//     await player.setVolume(100);

//     // Optional quick warm-up cycle
//     if (autoWarmUp && !autoPlay) {
//       await player.setVolume(0);
//       await player.play();
//       await Future.delayed(const Duration(milliseconds: 50));
//       await player.pause();
//       await player.seek(const Duration(milliseconds: 0));
//       await player.setVolume(100);
//     }

//     // Listen for playback completion
//     subs.add(player.stream.completed.listen((completed) {
//       if (completed) {
//         debugPrint('[VideoManager] Completed playing `$path`');
//       }
//     }));

//     return VideoEntry._(
//       player: player,
//       controller: controller,
//       path: path,
//       subscriptions: subs,
//     );
//   }

//   @override
//   void dispose() {
//     _disposeAll();
//     super.dispose();
//   }
// }

// /// Internal video entry with disposal logic.
// class VideoEntry {
//   VideoEntry._({
//     required this.player,
//     required this.controller,
//     required this.path,
//     required this.subscriptions,
//   });

//   final Player player;
//   final VideoController controller;
//   final String path;
//   final List<StreamSubscription> subscriptions;

//   /// Dispose this entry's resources.
//   Future<void> dispose() async {
//     for (var sub in subscriptions) {
//       await sub.cancel();
//     }
//     await player.dispose();
//     debugPrint('[VideoManager] Disposed entry `$path`');
//   }
// }
