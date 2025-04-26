import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_theme.dart';
import '../models/enums_ui.dart';
import '../providers/theme_provider.dart';

class NutriaText extends StatelessWidget {
  final String text;
  final NutriaTextState state;
  final NutriaTextStyle textStyle;
  final int maxLines;
  final TextAlign textAlign;
  final bool selectable;
  final double sizeMultiplier;
  final bool invertColor;
  const NutriaText(
      {required this.text,
      this.state = NutriaTextState.normal,
      this.textStyle = NutriaTextStyle.normal,
      this.maxLines = 1,
      this.textAlign = TextAlign.left,
      this.selectable = false,
      this.sizeMultiplier = 1.0,
      this.invertColor = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    Color _invertColor(Color color) {
      return Color.from(
        red: 1.0 - color.r,
        green: 1.0 - color.g,
        blue: 1.0 - color.b,
        alpha: color.a, // Preserve the original alpha
      );
    }

    final AppTheme theme = context.watch<ThemeProvider>().currentAppTheme;
    return Text(
      text,
      textAlign: textAlign,
      softWrap: false,
      style: TextStyle(
        height: 1.0,
        color: invertColor
            ? (state == NutriaTextState.accented
                ? _invertColor(theme.cTextActive)
                : state == NutriaTextState.inactive
                    ? _invertColor(theme.cTextInactive)
                    : _invertColor(theme.cText))
            : (state == NutriaTextState.accented
                ? theme.cTextActive
                : state == NutriaTextState.inactive
                    ? theme.cTextInactive
                    : theme.cText),
        fontSize: theme.dTextHeight * sizeMultiplier,
        fontFamily: 'SourceSans', // Ensure the correct family is used
        fontVariations: textStyle == NutriaTextStyle.boldItalic
            ? [FontVariation('wght', 700)]
            : textStyle == NutriaTextStyle.bold
                ? [FontVariation('wght', 700)]
                : [FontVariation('wght', 100)],
        fontStyle: textStyle == NutriaTextStyle.italic ||
                textStyle == NutriaTextStyle.boldItalic
            ? FontStyle.italic
            : FontStyle.normal,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }
}
