
import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';

import '../providers/ui_state_provider.dart';
import 'option_button.dart';

class BranchedVideoControls extends StatelessWidget {
  const BranchedVideoControls({
    super.key,

  });

  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoProvider =
        context.read<VideoPlayerStackProvider>();

    return Selector<VideoPlayerStackProvider, VideoPlayerEntry?>(
        selector: (_, provider) => provider.currentEntry,
        builder: (context, shouldStackUpdate, child) {
          VideoPlayerEntry? activeEntry = videoProvider.firstEntry;
          return activeEntry == null
              ? const SizedBox.shrink()
              // Container(
              //     height: 50,
              //     color: Colors.red,
              //   )
              : StreamBuilder<Duration>(
                  stream:
                      activeEntry.positionStream, // Using positionStream here
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final currentNode = nodesProvider.currentNode;
                    final videoDuration = activeEntry.player.state.duration;
                    Duration remainingTime =
                        videoDuration - position;

                    if (currentNode == null ||
                        !nodesProvider.shouldDisplayOptions(remainingTime) ||
                        nodesProvider.haveNextReady || videoDuration == Duration.zero) {
                      print(
                        '[isNotDisplaying] because currentNode = ${currentNode?.id}, remaining time is ${remainingTime.inMilliseconds}, position is ${position.inMilliseconds}, duration is ${videoDuration} shouldDisplayOptions is ${nodesProvider.shouldDisplayOptions(remainingTime)}, haveNextReady is ${nodesProvider.haveNextReady}',
                      );
                      return const SizedBox.shrink();
                    } else {
                      print(
                        '[isDisplaying] because currentNode = ${currentNode.id}, remaining time is ${remainingTime.inMilliseconds}, position is ${position.inMilliseconds}, duration is ${activeEntry.player.state.duration.inMilliseconds} shouldDisplayOptions is ${nodesProvider.shouldDisplayOptions(remainingTime)}, haveNextReady is ${nodesProvider.haveNextReady}',
                      );
                      return Padding(
                        padding: EdgeInsets.all(10),
                        child: BackdropGroup(
                          backdropKey: uiStateProvider.backdropKey,
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: nodesProvider.currentOptionsTop
                                      .asMap()
                                      .entries
                                      .map((entry) => OptionButton(
                                          option: entry.value,
                                          index: entry.key))
                                      .toList(),
                                ),
                              ),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: nodesProvider.currentOptionsBottom
                                      .asMap()
                                      .entries
                                      .map((entry) => OptionButton(
                                          option: entry.value,
                                          index: entry.key +
                                              (nodesProvider.currentOptionsTop
                                                      .length -
                                                  1)))
                                      .toList(),
                                ),
                              ),
                              nodesProvider.currentNode?.isBranched ?? false
                                  ? Container(
                                      height: 10,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(1),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              nodesProvider.remainingTimeFactor(
                                                  remainingTime),
                                          child: Container(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      );
                    }
                  });
        });
  }
}