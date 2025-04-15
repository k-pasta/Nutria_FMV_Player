import 'enums_data.dart';

class ProjectSettings {
  final bool pauseOnEnd;
  final bool showTimer;
  final int selectionTime;
  final VideoFit videoFit;
  final DefaultSelectionMethod defaultSelection;

  ProjectSettings({
    required this.pauseOnEnd,
    required this.showTimer,
    required this.selectionTime,
    required this.videoFit,
    required this.defaultSelection,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      pauseOnEnd: json['pauseOnEnd'] ?? false,
      showTimer: json['showTimer'] ?? true,
      selectionTime: json['selectionTime'] ?? 8000,
      videoFit: videoFitFromString(json['videoFit']) ?? VideoFit.fit,
      defaultSelection: defaultSelectionFromString(json['defaultSelection']) ?? DefaultSelectionMethod.first,
    );
  }
}