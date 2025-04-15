import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nutria_fmv_player/custom_widgets/nutria_text.dart';
import 'package:nutria_fmv_player/models/enums_ui.dart';
import 'package:nutria_fmv_player/models/option.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';

import '../providers/ui_state_provider.dart';
import 'video_players_manager.dart';

class WindowsAppLayout extends StatelessWidget {
  const WindowsAppLayout({super.key, required this.videoNode});
  final VideoNode videoNode;

  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoPlayerStackProvider =
        context.watch<VideoPlayerStackProvider>();

    final controller = videoPlayerStackProvider.controller;
    final entries = videoPlayerStackProvider
        .allVisibleEntries; // includes active + preloaded
    final activePath = videoPlayerStackProvider.currentVideoPath;

    return Stack(
      children: [
        controller == null
            ? const Center(child: CircularProgressIndicator())
            : const VideoPlaybackManager(),
        Column(
          children: [
            Expanded(
              child: Center(
                  child: ElevatedButton(
                onPressed: () async {
                  // Use the FilePicker provided by the package
                  final result = await FilePicker.platform.pickFiles();

                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    final jsonString = await file.readAsString();
                    nodesProvider.parseProjectJson(jsonString);
                    String? firstPath = nodesProvider.currentNode?.videoPath;
                    List<String> preloadPaths = nodesProvider.currentOptions
                        .map((option) => option.target)
                        .whereType<String>()
                        .toList();
                    if (firstPath != null) {
                      videoPlayerStackProvider.loadInitialVideo(
                          videoPath: firstPath, preloadPaths: preloadPaths);
                    }
                  }
                },
                child: Text('Load Project'),
              )),
            ),
            Selector<NodesProvider, VideoNode?>(
              selector: (_, provider) => provider.currentNode,
              builder: (context, currentNode, child) {
                return Padding(
                  padding: EdgeInsets.all(10),
                  child: BackdropGroup(
                    backdropKey: uiStateProvider.backdropKey,
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: nodesProvider.currentOptionsTop
                                .asMap()
                                .entries
                                .map((entry) => OptionButton(
                                    option: entry.value, index: entry.key))
                                .toList(),
                          ),
                        ),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: nodesProvider.currentOptionsBottom
                                .asMap()
                                .entries
                                .map((entry) => OptionButton(
                                    option: entry.value,
                                    index: entry.key +
                                        (nodesProvider
                                                .currentOptionsTop.length -
                                            1)))
                                .toList(),
                          ),
                        ),
                        Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: .5,
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class OptionButton extends StatelessWidget {
  const OptionButton({super.key, required this.option, required this.index});
  final Option option;
  final int index;
  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    void closeCurrentOptions() {}

    return Flexible(
      fit: FlexFit.tight,
      // flex: (option.text.length / 80).ceil(),
      child: MouseRegion(
        child: GestureDetector(
          onTapDown: (_) {
            nodesProvider.triggerOption(index);
          },
          child: Padding(
            padding: EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                backdropGroupKey: uiStateProvider.backdropKey,
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: NutriaText(
                        state: NutriaTextState.accented,
                        text: option.text,
                        textAlign: TextAlign.center,
                        maxLines: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
