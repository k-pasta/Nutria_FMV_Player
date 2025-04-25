import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nutria_fmv_player/models/enums_data.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';

import '../providers/video_manager_provider.dart';

class DisposableVideoPlayer extends StatefulWidget {
  const DisposableVideoPlayer({
    super.key,
    required this.entry,
    required this.isActive,
  });

  final VideoPlayerEntry entry;
  final bool isActive;

  @override
  State<DisposableVideoPlayer> createState() => _DisposableVideoPlayerState();
}

class _DisposableVideoPlayerState extends State<DisposableVideoPlayer> {
  late final VideoController controller;
  late BoxFit boxFit;

  @override
  void initState() {
    super.initState();
    controller = widget.entry.controller;
  }

  @override
  void didUpdateWidget(covariant DisposableVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      setState(() {
        // Trigger a rebuild if isActive changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<NodesProvider, VideoNode?>(
      selector: (_, provider) => provider.currentNode,
      builder: (context, currentNode, child) {
        VideoFit videoFit = currentNode != null
            ? context
                .read<NodesProvider>()
                .getNodeSetting(currentNode, VideoSettings.videoFit)
            : VideoFit.fit;
        boxFit = videoFit.boxFit;

        return Video(
          controller: controller,
          controls: NoVideoControls,
          fit: boxFit,
        );
      },
    );
  }
}
