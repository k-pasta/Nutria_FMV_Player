import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nutria_fmv_player/models/enums_data.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/ui_state_provider.dart';
import 'package:provider/provider.dart';

import '../providers/nodes_provider.dart';
import '../providers/video_manager_provider.dart';
import '../providers/video_player_stack_provider.dart';
import 'disposable_video_player.dart';

class VideoPlaybackManager extends StatefulWidget {
  const VideoPlaybackManager({super.key});

  @override
  State<VideoPlaybackManager> createState() => _VideoPlaybackManagerState();
}

class _VideoPlaybackManagerState extends State<VideoPlaybackManager> {
  // late List<DisposableVideoPlayer> videoPlayers;

  // @override
  // void initState() {
  //   VideoPlayerEntry? firstentry =
  //       context.read<VideoPlayerStackProvider>().currentEntry;
  //   videoPlayers = [
  //     if (firstentry != null)
  //       DisposableVideoPlayer(
  //         entry: firstentry,
  //         isActive: true,
  //         key: ValueKey(firstentry.videoPath),
  //       ),
  //   ];
  //   super.initState();
  // }

  // void _updateVideoPlayers(
  //   List<VideoPlayerEntry> entries,
  //   VideoPlayerEntry? activeEntry,
  // ) {
  //   videoPlayers = entries.map((entry) {
  //     return DisposableVideoPlayer(
  //       key: ValueKey(entry.videoPath),
  //       entry: entry,
  //       // mark active if this entry matches the provider’s currentEntry
  //       isActive: entry == activeEntry,
  //     );
  //   }).toList();
  //   print('updated video players');
  // }

  VideoPlayerEntry? activeEntry;
  List<VideoPlayerEntry> entries = [];

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.read<VideoPlayerStackProvider>();
    final nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    return Selector<VideoPlayerStackProvider, ShouldStackUpdate>(
      selector: (_, provider) => provider.shouldStackUpdate,
      builder: (context, shouldStackUpdate, _) {
        print('rebuilding, areVideosDirty is $shouldStackUpdate');

        if (shouldStackUpdate == ShouldStackUpdate.option) {
          final currentNode = nodesProvider.currentNode;
          if (currentNode != null) {
            bool shouldMoveForward = !nodesProvider.getNodeSetting<bool>(
                currentNode, VideoSettings.pauseOnEnd);

            if (shouldMoveForward) {
              //trigger selection in case it wasn't triggered
              //this is also performed when the node is not branching as all it does is fetch the next video
              nodesProvider.triggerOption(null);
              //storing currentNode
              final activeNode = nodesProvider.currentNode;

              //if it exists, that means the player can move on
              if (activeNode != null) {
                final preloadPaths = activeNode.options
                    .where((option) => option.target != null)
                    .map((option) =>
                        nodesProvider.getPathById(option.target!) as String)
                    .toList();

                //transitioning to next video
                videoProvider.transitionToNextVideo(
                  nextPath: activeNode.videoPath,
                  preloadPaths: preloadPaths,
                );
              } else {
                
              }
            }

            //if it doesn't exits, that means there is no other video in the list, so we go back to main menu
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              uiStateProvider.appState = AppState.mainMenu;
            });
          }

          // _updateVideoPlayers(entries, activeEntry);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            videoProvider.clearVideosDirtyFlag();
            nodesProvider.haveNextReady = false;
            // safe here
          });
        } else if (shouldStackUpdate == ShouldStackUpdate.initial) {
          // _updateVideoPlayers(entries, activeEntry);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            videoProvider.clearVideosDirtyFlag(); // safe here
          });
        }

        //fetching the entries from the video provider to render, once they have been set.
        activeEntry = videoProvider.currentEntry;
        entries = videoProvider.allVisibleEntries;

        return IndexedStack(
          index: 0,
          children: entries.map((entry) {
            return DisposableVideoPlayer(
              key: ValueKey(entry.videoPath),
              entry: entry,
              isActive: entry == activeEntry,
            );
          }).toList(),
        );
      },
    );
  }
}
