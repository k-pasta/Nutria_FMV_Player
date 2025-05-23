import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:nutria_fmv_player/models/enums_data.dart';
import 'package:nutria_fmv_player/models/option.dart';
import 'package:nutria_fmv_player/models/project_info.dart';
import 'package:nutria_fmv_player/utilities/split_list.dart';
import '../models/enums_data.dart';

import '../models/project_settings.dart';
import '../models/video_node.dart';

class NodesProvider extends ChangeNotifier {
  final List<Node> _nodes = [];
  List<Node> get nodes => _nodes;
  set nodes(List<Node> newNodes) {
    _nodes.clear();
    _nodes.addAll(newNodes);
    currentNode = firstVideoNode;
  }

  VideoNode get firstVideoNode => _nodes.firstWhere((node) => node is VideoNode,
      orElse: () => throw Exception('No VideoNodes available')) as VideoNode;

  VideoNode? _currentNode;
  VideoNode? get currentNode => _currentNode;
  set currentNode(VideoNode? newNode) {
    if (newNode == null) {
      _currentNode = null;
      return;
    }
    if (newNode.isBranched) {
      currentOptions = newNode.options;
    } else if (!newNode.isBranched) {
      currentOptions = []; //empty options list if is not branched
    }
    _currentNode = newNode;
    log('current node has this path: ${_currentNode?.videoPath}');
  }

  ProjectInfo _projectInfo = ProjectInfo(title: '', description: '');
  ProjectInfo get projectInfo => _projectInfo;

  ProjectSettings _projectSettings = ProjectSettings(
      pauseOnEnd: false,
      showTimer: true,
      selectionTime: 8000,
      videoFit: VideoFit.fit,
      defaultSelection: DefaultSelectionMethod.first);

  ProjectSettings get projectSettings => _projectSettings;

  //Load project function
  //TODO try catch
  void parseProjectJson(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    final parsedProjectInfo =
        ProjectInfo.fromJson(jsonMap['ProjectInfo'] as Map<String, dynamic>);
    final parsedProjectSettings = ProjectSettings.fromJson(
        jsonMap['ProjectSettings'] as Map<String, dynamic>);

    final nodesMap = jsonMap['Nodes'] as Map<String, dynamic>;
    final List<VideoNode> parsedNodes = nodesMap.entries
        .map((entry) => VideoNode.fromJson(entry.key, entry.value))
        .toList();

    // You now have projectInfo, projectSettings, and nodes ready to use.

    // Print everything: ProjectInfo, ProjectSettings, and all VideoNodes.
    print('--- Project Information ---');
    print('Title: ${parsedProjectInfo.title}');
    print('Description: ${parsedProjectInfo.description}');
    print('');

    print('--- Project Settings ---');
    print('Pause On End: ${parsedProjectSettings.pauseOnEnd}');
    print('Show Timer: ${parsedProjectSettings.showTimer}');
    print('Selection Time: ${parsedProjectSettings.selectionTime}');
    print('Video Fit: ${parsedProjectSettings.videoFit}');
    print('Default Selection: ${parsedProjectSettings.defaultSelection}');
    print('');

    print('--- Nodes (${parsedNodes.length} total) ---');
    for (final node in parsedNodes) {
      print('Node ID: ${node.id}');
      print('  Video Path: ${node.videoPath}');
      print('  Is Branched: ${node.isBranched}');

      // If branched, print each option; otherwise, print the target option.
      if (node.isBranched) {
        print('  Options:');
        for (final option in node.options) {
          print('    Option: ${option.text}, Target: ${option.target}');
        }
      } else {
        // For non-branched nodes, we expect a single target in options.
        print('  Target: ${node.options.first.target}');
      }

      // Check and print any overrides if they exist.
      if (node.overrides != null && node.overrides!.isNotEmpty) {
        print('  Overrides:');
        node.overrides!.forEach((setting, value) {
          // For enums, this prints only the enum value name.
          final settingName = setting.toString().split('.').last;
          print('    $settingName: $value');
        });
      }

      print(''); // Blank line between nodes.
    }
    nodes = parsedNodes;
    _projectInfo = parsedProjectInfo;
    _projectSettings = parsedProjectSettings;
    notifyListeners();
  }

  final List<List<Option>> _currentOptions = [[], []];
  List<Option> get currentOptionsTop => _currentOptions[0];
  List<Option> get currentOptionsBottom => _currentOptions[1];
  List<Option> get currentOptions => _currentOptions[0] + _currentOptions[1];

  set currentOptions(List<Option> newOptions) {
    List<Option> optionsTop = splitList(newOptions)[0];
    List<Option> optionsBottom = splitList(newOptions)[1];
    _currentOptions.clear();
    _currentOptions.addAll([optionsTop, optionsBottom]);
    // notifyListeners();
  }

//used for the nextVideoNode function, when selection method is lastSelected
  int _lastSelectedIndex = 0;

  T getNodeSetting<T>(VideoNode videoNode, VideoSettings setting) {
    final value = videoNode.overrides?[setting] ?? _projectSettings.getSetting(setting);
    if (value is T) {
      return value;
    } else {
      throw Exception("Expected setting of type $T but got ${value.runtimeType}");
    }
  }

  VideoNode? nextVideoNode(
      {required VideoNode currentVideoNode, int? selectedIndex}) {
    Node? nextNode;
    DefaultSelectionMethod currentNodeSelectionMethod =
        getNodeSetting<DefaultSelectionMethod>(currentVideoNode, VideoSettings.defaultSelection);
    // currentVideoNode.overrides?[VideoSettings.defaultSelection] ??
    //     _projectSettings.defaultSelection; //TODO move to static data

    if (currentVideoNode.isBranched) {
      if (selectedIndex != null) {
        _lastSelectedIndex = selectedIndex;
        nextNode = _nodes.firstWhereOrNull(
          (n) => n.id == currentVideoNode.options[selectedIndex].target,
        );
      } else {
        switch (currentNodeSelectionMethod) {
          case DefaultSelectionMethod.first:
            _lastSelectedIndex = 0;
            nextNode = _nodes.firstWhereOrNull(
              (n) =>
                  n.id ==
                  currentVideoNode
                      .options.first.target, //todo handle crash if no options
            );
            break;
          case DefaultSelectionMethod.last:
            _lastSelectedIndex = currentVideoNode.options.length - 1;
            nextNode = _nodes.firstWhereOrNull(
              (n) => n.id == currentVideoNode.options.last.target,
            );
            break;
          case DefaultSelectionMethod.random:
            _lastSelectedIndex = (currentVideoNode.options.isNotEmpty)
                ? (currentVideoNode.options.length *
                        (math.Random().nextDouble()))
                    .toInt()
                : 0;
            nextNode = _nodes.firstWhereOrNull(
              (n) =>
                  n.id == currentVideoNode.options[_lastSelectedIndex].target,
            );
            break;
          case DefaultSelectionMethod.lastSelected:
            final clampedIndex = _lastSelectedIndex.clamp(
                0, currentVideoNode.options.length - 1);
            _lastSelectedIndex = clampedIndex;
            nextNode = _nodes.firstWhereOrNull(
              (n) => n.id == currentVideoNode.options[clampedIndex].target,
            );
            break;
          case DefaultSelectionMethod.specified:
            // TODO implement specified selection method
            // This is a placeholder for the specified selection method.
            _lastSelectedIndex = 0;
            nextNode = _nodes.firstWhereOrNull(
              (n) => n.id == currentVideoNode.options.first.target,
            );
            break;
          // default:
        }
      }
    } else {
      _lastSelectedIndex = 0;
      nextNode = _nodes.firstWhereOrNull(
        (n) => n.id == currentVideoNode.options.first.target,
      );
    }

    if (nextNode is VideoNode) {
      return nextNode;
    } else {
      log('no next node available');
      // Placeholder for future behavior when nextNode is not a VideoNode
      return null;
    }
  }

  bool _haveNextReady = false;
  set haveNextReady(bool haveNextReady) {
    _haveNextReady = haveNextReady;
  }

  bool get haveNextReady => _haveNextReady;

  bool shouldDisplayOptions(Duration remainingTime) {
    final timeFromEnd = _currentNode?.overrides?[VideoSettings.selectionTime] !=
            null
        ? Duration(
            milliseconds: _currentNode!.overrides![VideoSettings.selectionTime])
        : Duration(milliseconds: projectSettings.selectionTime);
    if (_currentNode == null) {
      return false;
    }
    return remainingTime <= timeFromEnd;
  }

  double remainingTimeFactor(Duration remainingTime) {
    final timeFromEnd = _currentNode?.overrides?[VideoSettings.selectionTime] !=
            null
        ? Duration(
            milliseconds: _currentNode!.overrides![VideoSettings.selectionTime])
        : Duration(milliseconds: projectSettings.selectionTime);
    if (_currentNode == null || timeFromEnd.inMilliseconds <= 0) {
      return 0.0;
    }
    final factor = remainingTime.inMilliseconds / timeFromEnd.inMilliseconds;
    return factor.clamp(0.0, 1.0);
  }

  void triggerOption(int? optionIndex) {
    if (!_haveNextReady) {
      currentNode = nextVideoNode(
        currentVideoNode: currentNode!,
        selectedIndex: optionIndex,
      );
    }
    log('selected $optionIndex and havenextready was $_haveNextReady');
    _haveNextReady = true;
  }

  Node? getNodeById(String id) {
    return _nodes.firstWhereOrNull((node) => node.id == id);
  }

  String? getPathById(String id) {
    return (getNodeById(id) is VideoNode)
        ? (getNodeById(id) as VideoNode).videoPath
        : null;
  }

  List<VideoNode> getNextNodes({required VideoNode currentVideoNode}) {
    //return all options's target nodes
    List<VideoNode> nextNodes = [];

    for (var option in currentVideoNode.options) {
      var nextNode =
          _nodes.firstWhereOrNull((node) => node.id == option.target);
      if (nextNode != null) {
        if (nextNode is VideoNode) {
          nextNodes.add(nextNode);
        }
      } else {
        // placeholder for future behavior when nextNode is not a VideoNode
      }
    }

    return nextNodes;
  }

  void log(String message) {
    debugPrint("[NodesProvider] $message");
  }
}
