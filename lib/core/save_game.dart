// A saved place in a story: the video to play again, the variables as they
// were when it started, and the answer picked last.
import 'dart:convert';

/// A saved game. Loading it plays [nodeId] again from the start, with the
/// variables it started with.
class SaveGame {
  const SaveGame({
    required this.nodeId,
    required this.values,
    required this.lastPicked,
    required this.savedAt,
  });

  final String nodeId;
  final Map<String, Object?> values;
  final int lastPicked;
  final DateTime savedAt;

  String encode() => jsonEncode({
    'node': nodeId,
    'values': values,
    'lastPicked': lastPicked,
    'savedAt': savedAt.toIso8601String(),
  });

  /// `null` if [source] isn't a saved game.
  static SaveGame? decode(String? source) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) return null;
      final node = json['node'];
      final values = json['values'];
      if (node is! String || values is! Map) return null;
      return SaveGame(
        nodeId: node,
        values: Map<String, Object?>.from(values),
        lastPicked: switch (json['lastPicked']) {
          final int i => i,
          _ => 0,
        },
        savedAt:
            DateTime.tryParse('${json['savedAt']}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } on FormatException {
      return null;
    }
  }
}
