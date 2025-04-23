import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import '../providers/nodes_provider.dart';
import '../providers/video_player_stack_provider.dart';
import 'disposable_video_player.dart';

class VideoPlaybackManager extends StatefulWidget {
  const VideoPlaybackManager({super.key});

  @override
  State<VideoPlaybackManager> createState() => _VideoPlaybackManagerState();
}

class _VideoPlaybackManagerState extends State<VideoPlaybackManager> {
  late List<DisposableVideoPlayer> videoPlayers;

  @override
  void initState() {
    VideoPlayerEntry? firstentry =
        context.read<VideoPlayerStackProvider>().currentEntry;
    videoPlayers = [
      if (firstentry != null)
        DisposableVideoPlayer(
          entry: firstentry,
          isActive: true,
          key: ValueKey(firstentry.videoPath),
        ),
    ];
    super.initState();
  }

  // void _updateVideoPlayers(List<VideoPlayerEntry> entries) {
  //   // Build a lookup of existing video players by their videoPath
  //   final Map<String, DisposableVideoPlayer> playerLookup = {
  //     for (final player in videoPlayers) player.entry.videoPath: player,
  //   };

  //   final List<DisposableVideoPlayer> updatedPlayers = [];

  //   for (final entry in entries) {
  //     if (playerLookup.containsKey(entry.videoPath)) {
  //       // Reuse the video player and remove it from the lookup to flag it as processed
  //       updatedPlayers.add(playerLookup[entry.videoPath]!);
  //       playerLookup.remove(entry.videoPath);
  //     } else {
  //       // Create a new video player if it doesn't exist
  //       updatedPlayers.add(DisposableVideoPlayer(
  //         entry: entry,
  //         isActive: false,
  //         key: ValueKey(entry.videoPath),
  //       ));
  //     }
  //   }
  //   // Assign the reordered list back to videoPlayers
  //   videoPlayers = updatedPlayers;

  //   print(
  //       'Updated video players: ${videoPlayers.map((player) => (player.key! as ValueKey).value).toList()}');
  // }

  void _updateVideoPlayers(
    List<VideoPlayerEntry> entries,
    VideoPlayerEntry? activeEntry,
  ) {
    // we don’t need the lookup of widgets—just rebuild them,
    // using the same entry.controller inside each.
    videoPlayers = entries.map((entry) {
      return DisposableVideoPlayer(
        key: ValueKey(entry.videoPath),
        entry: entry,
        // mark active if this entry matches the provider’s currentEntry
        isActive: entry == activeEntry,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.read<VideoPlayerStackProvider>();
    final Player? activePlayer = videoProvider.currentEntry?.player;

    return Selector<VideoPlayerStackProvider, Player?>(
      selector: (_, prov) => prov.currentEntry?.player,
      builder: (context, activePlayer, _) {
        return StreamBuilder<void>(
          stream: activePlayer?.stream.completed,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active &&
                snapshot.hasData) {
              final nodesProvider = context.read<NodesProvider>();
              final String? nextVideoPath =
                  nodesProvider.currentNode?.videoPath;
              //noo
              final List<String> preloadPaths = nodesProvider.currentOptions
                  .where((option) => option.target != null)
                  .map((option) =>
                      nodesProvider.getPathById(option.target!) as String)
                  .toList();

              if (nextVideoPath != null) {
                // print('Transitioning to next video: $nextVideoPath');
                videoProvider.transitionToNextVideo(
                  nextPath: nextVideoPath,
                  preloadPaths: preloadPaths,
                );
              }
            }

            // Trigger rebuild when provider changes
            return Selector<VideoPlayerStackProvider, List<VideoPlayerEntry>>(
              selector: (_, provider) => provider.allVisibleEntries,
              builder: (context, entries, _) {
                final active =
                    context.read<VideoPlayerStackProvider>().currentEntry;
                _updateVideoPlayers(entries, active);
                return Stack(children: videoPlayers);
              },
            );
          },
        );
      },
    );
  }
}
