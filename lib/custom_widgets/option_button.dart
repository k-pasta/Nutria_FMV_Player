import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/custom_widgets/nutria_text.dart';
import 'package:nutria_fmv_player/models/app_theme.dart';
import 'package:nutria_fmv_player/models/enums_ui.dart';
import 'package:nutria_fmv_player/models/option.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import '../providers/ui_state_provider.dart';
import '../providers/video_player_stack_provider.dart';

class OptionButton extends StatefulWidget {
  const OptionButton({super.key, required this.option, required this.index});
  final Option option;
  final int index;

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  OptionButtonState buttonState = OptionButtonState.neutral;

  Color _buttonColor(OptionButtonState buttonState, AppTheme theme) {
    switch (buttonState) {
      case OptionButtonState.neutral:
        return theme.cOptionButton;
      case OptionButtonState.inactive:
        return theme.cOptionButton;
      case OptionButtonState.hovered:
        return theme.cOptionButtonPressed;
      case OptionButtonState.pressed:
        return theme.cOptionButtonPressed;
      default:
        return theme.cOptionButton;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoStackProvider =
        context.read<VideoPlayerStackProvider>();

    final AppTheme theme = context.watch<ThemeProvider>().currentAppTheme;

    return Flexible(
      fit: FlexFit.tight,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            buttonState = OptionButtonState.hovered;
          });
        },
        onExit: (_) {
          setState(() {
            buttonState = OptionButtonState.neutral;
          });
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              buttonState = OptionButtonState.pressed;
            });
            nodesProvider.triggerOption(widget.index);

            if (videoStackProvider.activeEntry?.completed ?? false) {
              print('late click');
              videoStackProvider
                  .setVideosDirtyFlag(ShouldStackUpdate.lateOption);
            }
          },
          onTapUp: (_) {
            setState(() {
              buttonState = OptionButtonState.neutral;
            });
          },
          onTapCancel: () {
            setState(() {
              buttonState = OptionButtonState.neutral;
            });
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
                      color: _buttonColor(buttonState, theme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: NutriaText(
                        state: NutriaTextState.accented,
                        text: widget.option.text,
                        textAlign: TextAlign.center,
                        maxLines: 10,
                        invertColor:
                            (buttonState == OptionButtonState.hovered ||
                                buttonState == OptionButtonState.pressed),
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

enum OptionButtonState { neutral, hovered, pressed, inactive }
