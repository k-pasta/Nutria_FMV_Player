// What the Player adds to the shared screen drawing (nutria_fmv_screens):
// loading a story's font files, and image or video backgrounds.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

/// The font family a font file is loaded under, or `null` if it can't be.
final fontFamilyProvider = FutureProvider.family<String?, String>((
  ref,
  path,
) async {
  try {
    final bytes = await File(path).readAsBytes();
    final family = 'story-font-${path.hashCode}';
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    return family;
  } on Object {
    return null;
  }
});

/// The families the font files of [screen]'s styles are loaded under (a
/// font still loading is left out: its text uses the built-in font).
Map<String, String> loadedFonts(WidgetRef ref, FmvMenuScreen screen) {
  final fonts = <String, String>{};
  for (final element in screen.elements) {
    final path = element.style.font;
    if (path == null || fonts.containsKey(path)) continue;
    final family = ref.watch(fontFamilyProvider(path)).value;
    if (family != null) fonts[path] = family;
  }
  return fonts;
}

/// The background of [screen], or `null` without one.
Widget? backgroundOf(FmvMenuScreen screen) => switch (screen.background) {
  final path? => StoryBackground(key: ValueKey(path), path: path),
  null => null,
};

/// An image, or a video looping without sound.
class StoryBackground extends StatefulWidget {
  const StoryBackground({super.key, required this.path});

  final String path;

  @override
  State<StoryBackground> createState() => _StoryBackgroundState();
}

class _StoryBackgroundState extends State<StoryBackground> {
  Player? _player;
  VideoController? _controller;

  static const _images = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'};

  bool get _isImage =>
      _images.contains(widget.path.split('.').last.toLowerCase());

  @override
  void initState() {
    super.initState();
    if (!_isImage) {
      final player = Player();
      _player = player;
      _controller = VideoController(player);
      player
        ..setVolume(0)
        ..setPlaylistMode(PlaylistMode.single)
        ..open(Media(widget.path));
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Image.file(
        File(widget.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    return Video(
      controller: controller,
      controls: NoVideoControls,
      fit: BoxFit.cover,
    );
  }
}
