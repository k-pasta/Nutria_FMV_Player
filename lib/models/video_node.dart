import 'option.dart';
import 'enums_data.dart';

abstract class Node {
  const Node({required this.id});
  final String id;
}

class VideoNode extends Node {
  const VideoNode({
    required super.id,
    required this.isBranched,
    required this.options,
    required this.videoPath,
    this.overrides,
  });

  const VideoNode.branched({
    required super.id,
    required this.options,
    required this.videoPath,
    this.overrides,
  }) : isBranched = true;

  const VideoNode.simple({
    required super.id,
    required this.options,
    required this.videoPath,
    this.overrides,
  }) : isBranched = false;

  final bool isBranched;
  final List<Option> options;
  final String videoPath;
  final Map<VideoSettings, dynamic>? overrides;

  factory VideoNode.fromJson(String id, Map<String, dynamic> json) {
    final isBranched = json.containsKey('choices');
    final options = isBranched
        ? (json['choices'] as List).map((opt) => Option.fromJson(opt)).toList()
        : [Option(text: '', target: json['target'])];

    Map<VideoSettings, dynamic>? overrides;
    if (json.containsKey('overrides')) {
      overrides = {};
      json['overrides'].forEach((key, value) {
        final setting = videoSettingFromString(key);
        if (setting == VideoSettings.videoFit) {
          if (setting != null) {
            overrides![setting] = videoFitFromString(value);
          }
        } else if (setting == VideoSettings.defaultSelection) {
          if (setting != null) {
            overrides![setting] = defaultSelectionFromString(value);
          }
        } else {
          if (setting != null) {
            overrides![setting] = value;
          }
        }
      });
    }

    return VideoNode(
      id: id,
      isBranched: isBranched,
      options: options,
      videoPath: json['video'],
      overrides: overrides,
    );
  }
}
