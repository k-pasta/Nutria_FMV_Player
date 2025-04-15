import 'enums_data.dart';

class SupportedOverrides {
  const SupportedOverrides({
    this.selectionTime,
    this.showtimer,
    this.pauseOnEnd,
    this.videoFit,
    this.defaultSelection,
  });

  final Duration? selectionTime;
  final bool? showtimer;
  final bool? pauseOnEnd;
  final VideoFit? videoFit;
  final DefaultSelectionMethod? defaultSelection;
}

