import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';

class DisposableVideoPlayer extends StatelessWidget {
  const DisposableVideoPlayer({
    super.key,
    required this.entry,
    required this.isActive,
  });

  final VideoPlayerEntry entry;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final controller = entry.controller;

    return Positioned.fill(
      // child: IgnorePointer(
        // ignoring: !isActive,
        child: Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Video(controller: controller),
        // ),
      ),
    );
  }
}