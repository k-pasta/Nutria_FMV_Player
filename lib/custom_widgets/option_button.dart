import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/custom_widgets/nutria_text.dart';
import 'package:nutria_fmv_player/models/enums_ui.dart';
import 'package:nutria_fmv_player/models/option.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:provider/provider.dart';

import '../providers/ui_state_provider.dart';
import '../providers/video_player_stack_provider.dart';

class OptionButton extends StatelessWidget {
  const OptionButton({super.key, required this.option, required this.index});
  final Option option;
  final int index;
  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoStackProvider =
        context.read<VideoPlayerStackProvider>();

    return Flexible(
      fit: FlexFit.tight,
      // flex: (option.text.length / 80).ceil(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
