// Walking through a story: which video comes next, after logic nodes, and
// which answer is taken when the viewer doesn't pick one.
import 'dart:math' as math;

import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

/// Most logic nodes followed in a row before giving up (a loop made of
/// logic nodes only would never reach a video).
const kMaxLogicSteps = 10000;

/// A loaded `.fmv` story.
class Story {
  Story(this.project);

  final FmvProject project;

  FmvNode? node(String? id) => id == null ? null : project.nodes[id];

  /// The first node; `null` for an empty story.
  String? get startId => project.startNodeId;

  /// Follows logic nodes from [id], changing and testing [variables] as
  /// they say, to the first video node. `null` when the story ends there
  /// (no node, or logic nodes going round forever).
  String? resolve(String? id, FmvVariableState variables) {
    var current = id;
    for (var steps = 0; current != null && steps < kMaxLogicSteps; steps++) {
      final node = project.nodes[current];
      if (node == null) return null;
      switch (node.type) {
        case FmvNodeType.video:
          return current;
        case FmvNodeType.change:
          if (node.variable case final variable?) {
            if (node.operation case final operation?) {
              variables.change(variable, operation, node.value);
            }
          }
          current = node.target;
        case FmvNodeType.compare:
          final holds = variables.test(
            conditions: node.conditions,
            matchAny: node.matchAny,
            expression: node.expression,
          );
          current = holds ? node.whenTrue : node.whenFalse;
      }
    }
    return null;
  }

  /// The video node [resolve] would reach from [id], without changing
  /// [variables] (for loading the next videos ahead of time).
  String? peek(String? id, FmvVariableState variables) =>
      resolve(id, variables.copy());

  /// The settings for [node]: the project's, with the node's overrides.
  FmvSettings settingsOf(FmvNode node) =>
      project.settings.withOverrides(node.overrides);

  /// The answer taken when the time runs out without a pick, by the node's
  /// default selection. [lastPicked] is the answer index picked last time
  /// anywhere; [random] picks for "random".
  int defaultChoice(
    FmvNode node, {
    required int lastPicked,
    required math.Random random,
  }) {
    final count = node.choices?.length ?? 0;
    if (count <= 1) return 0;
    return switch (settingsOf(node).defaultSelection) {
      FmvDefaultSelection.first || FmvDefaultSelection.specified => 0,
      FmvDefaultSelection.last => count - 1,
      FmvDefaultSelection.lastSelected => lastPicked.clamp(0, count - 1),
      FmvDefaultSelection.random => random.nextInt(count),
    };
  }

  /// Where [node] goes on to: its target, or the target of answer [choice]
  /// of a branched node.
  String? nextOf(FmvNode node, int choice) {
    final choices = node.choices;
    if (choices == null || choices.isEmpty) return node.target;
    return choices[choice.clamp(0, choices.length - 1)].target;
  }

  /// The video nodes a viewer could see right after [node] (to load them
  /// ahead of time).
  Set<String> upcoming(FmvNode node, FmvVariableState variables) => {
    for (var i = 0; i < (node.choices?.length ?? 1); i++)
      ?peek(nextOf(node, i), variables),
  };
}
