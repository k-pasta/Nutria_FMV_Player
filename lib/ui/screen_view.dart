// Draws a designed screen (main menu, answers, pause menu) as the Maker's
// screen designer shows it: elements at fractions of the window, sized by
// its height, in their styles.
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

/// [text] with `**bold**` and `*italic*` shown as such.
TextSpan markdownSpan(String text, TextStyle style) => TextSpan(
  style: style,
  children: [
    for (final run in parseInlineMarkdown(text))
      if (!run.isMarker)
        TextSpan(
          text: run.text,
          style: TextStyle(
            fontWeight: run.bold ? FontWeight.bold : null,
            fontStyle: run.italic ? FontStyle.italic : null,
          ),
        ),
  ],
);

/// What the elements of a screen show and do.
class ScreenContent {
  const ScreenContent({
    this.title,
    this.description,
    this.question,
    this.answers = const [],
    this.picked,
    this.timeLeft,
    this.onButton,
    this.onAnswer,
    this.disabled = const {},
  });

  final String? title;
  final String? description;
  final String? question;
  final List<String> answers;

  /// The answer picked, drawn highlighted.
  final int? picked;

  /// For the timer: how much of the choosing time is left (1 to 0), or
  /// `null` to hide it.
  final double? timeLeft;

  /// A button element ("start", "quit", …) was clicked.
  final void Function(String kind)? onButton;

  /// Answer [index] was clicked.
  final void Function(int index)? onAnswer;

  /// Button kinds shown dimmed and not clickable (e.g. "load" without a
  /// saved game).
  final Set<String> disabled;
}

/// Texts of buttons that have none of their own.
const kButtonTexts = {
  'start': 'Start',
  'load': 'Load',
  'save': 'Save',
  'settings': 'Settings',
  'credits': 'Credits',
  'quit': 'Quit',
  'resume': 'Resume',
  'mainMenu': 'Main Menu',
};

/// [screen] filling the space it's given.
class ScreenView extends StatelessWidget {
  const ScreenView({
    super.key,
    required this.screen,
    required this.content,
    this.showBackground = true,
  });

  final FmvMenuScreen screen;
  final ScreenContent content;

  /// Draws the screen's background (the answers screen goes over a video).
  final bool showBackground;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      return Stack(
        children: [
          if (showBackground)
            if (screen.background case final path?)
              Positioned.fill(child: _Background(path: path)),
          for (final element in screen.elements)
            if (_shows(element))
              Positioned(
                left: element.x * size.width,
                top: element.y * size.height,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _ElementView(
                    element: element,
                    screen: size,
                    content: content,
                  ),
                ),
              ),
        ],
      );
    },
  );

  bool _shows(FmvScreenElement element) => switch (element.kind) {
    'question' => content.question?.trim().isNotEmpty ?? false,
    'choices' => content.answers.isNotEmpty,
    'timer' => content.timeLeft != null,
    'title' => content.title?.trim().isNotEmpty ?? false,
    'description' => content.description?.trim().isNotEmpty ?? false,
    final kind => kButtonTexts.containsKey(kind),
  };
}

class _Background extends StatefulWidget {
  const _Background({required this.path});

  final String path;

  @override
  State<_Background> createState() => _BackgroundState();
}

/// An image, or a video looping without sound.
class _BackgroundState extends State<_Background> {
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

/// One element in its style.
class _ElementView extends ConsumerWidget {
  const _ElementView({
    required this.element,
    required this.screen,
    required this.content,
  });

  final FmvScreenElement element;
  final Size screen;
  final ScreenContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = element.style;
    final h = screen.height;
    final family = switch (style.font) {
      final path? => ref.watch(fontFamilyProvider(path)).value,
      null => null,
    };
    final textStyle = TextStyle(
      fontSize: style.fontSize * h,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontFamily: family,
      color: Color(style.textColor),
      height: 1.2,
    );
    final width = element.width * screen.width;

    Widget text(String value) =>
        Text.rich(markdownSpan(value, textStyle), textAlign: TextAlign.center);

    switch (element.kind) {
      case 'choices':
        return SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Every answer as wide as the element, like in the Maker.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, answer) in content.answers.indexed) ...[
                if (i > 0) SizedBox(height: (element.gap ?? 0.015) * h),
                _Box(
                  style: style,
                  screenHeight: h,
                  highlighted: content.picked == i,
                  dimmed: content.picked != null && content.picked != i,
                  onTap: content.onAnswer == null
                      ? null
                      : () => content.onAnswer!(i),
                  child: text(answer),
                ),
              ],
            ],
          ),
        );
      case 'timer':
        return SizedBox(
          width: width,
          child: _Box(
            style: style,
            screenHeight: h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: content.timeLeft ?? 0,
                child: Container(
                  height: style.fontSize * h * 0.4,
                  decoration: BoxDecoration(
                    color: Color(style.textColor),
                    borderRadius: BorderRadius.circular(style.radius * h),
                  ),
                ),
              ),
            ),
          ),
        );
      case 'title' || 'description' || 'question':
        final value =
            element.text ??
            switch (element.kind) {
              'title' => content.title,
              'description' => content.description,
              _ => content.question,
            } ??
            '';
        return SizedBox(
          width: width,
          child: _Box(style: style, screenHeight: h, child: text(value)),
        );
      default:
        final kind = element.kind;
        final disabled = content.disabled.contains(kind);
        return SizedBox(
          width: width,
          child: _Box(
            style: style,
            screenHeight: h,
            dimmed: disabled,
            onTap: disabled || content.onButton == null
                ? null
                : () => content.onButton!(kind),
            child: text(element.text ?? kButtonTexts[kind] ?? kind),
          ),
        );
    }
  }
}

/// A box in [style]; clickable ones brighten under the mouse.
class _Box extends StatefulWidget {
  const _Box({
    required this.style,
    required this.screenHeight,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
  });

  final FmvScreenStyle style;
  final double screenHeight;
  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool dimmed;

  @override
  State<_Box> createState() => _BoxState();
}

class _BoxState extends State<_Box> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final h = widget.screenHeight;
    final lit = widget.highlighted || (_hovered && widget.onTap != null);
    final opacity = (style.backgroundOpacity + (lit ? 0.25 : 0)).clamp(
      0.0,
      1.0,
    );
    final box = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.dimmed ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(style.padding * h),
        decoration: BoxDecoration(
          color: Color(style.backgroundColor).withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(style.radius * h),
          border: widget.highlighted
              ? Border.all(color: Color(style.textColor), width: 2)
              : null,
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return box;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: box),
    );
  }
}
