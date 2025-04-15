import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nodes_provider.dart';
import '../providers/video_player_stack_provider.dart';
import 'disposable_video_player.dart';

class VideoPlaybackManager extends StatelessWidget {
  const VideoPlaybackManager({super.key});

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.read<VideoPlayerStackProvider>();
    final activePlayer = videoProvider.player;

    return StreamBuilder<void>(
      stream: activePlayer?.stream.completed,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData) {
          final nodesProvider = context.read<NodesProvider>();

          final String? nextVideoPath = nodesProvider.currentNode?.videoPath;
          final List<String> preloadPaths = nodesProvider.currentOptions
              .where((option) => option.target != null)
              .map((option) => option.target!)
              .toList();

          if (nextVideoPath != null) {
            print('Transitioning to next video: $nextVideoPath');
            videoProvider.transitionToNextVideo(
              nextPath: nextVideoPath,
              preloadPaths: preloadPaths,
            );
          }
        }

        // Regardless of snapshot, render the full video stack:
        return Stack(
          children: videoProvider.allVisibleEntries.values.map((entry) {
            final isActive = entry.videoPath == videoProvider.currentVideoPath;
            return DisposableVideoPlayer(
              key: ValueKey(entry.videoPath),
              entry: entry,
              isActive: isActive,
            );
          }).toList(),
        );
      },
    );
  }
}