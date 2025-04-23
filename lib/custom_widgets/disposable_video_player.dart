import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !widget.isActive,
        child: Opacity(
          opacity: widget.isActive ? 1.0 : 0.0,
          child: Video(controller: controller),
        ),
      ),
    );
  }
}
