import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/custom_widgets/nutria_text.dart';
import 'package:nutria_fmv_player/models/app_theme.dart';
import 'package:nutria_fmv_player/models/enums_ui.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/theme_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';

import '../models/enums_data.dart';
import '../providers/ui_state_provider.dart';
import 'branched_video_controls.dart';
import 'video_players_manager.dart';

class WindowsAppLayout extends StatelessWidget {
  const WindowsAppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoStackProvider =
        context.read<VideoPlayerStackProvider>();

    return Selector<UiStateProvider, AppState>(
      selector: (_, uiStateProvider) => uiStateProvider.appState,
      builder: (context, appState, child) {
        switch (appState) {
          case AppState.noProject:
            return const Stack(
              children: [
                Center(child: LoadProjectButton()),
              ],
            );
          case AppState.mainMenu:
            print('in main menu');
            return Stack(
              children: [
                Center(
                  child: Column(
                    spacing: 100,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        spacing: 10,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NutriaText(
                            text: nodesProvider.projectInfo.title,
                            state: NutriaTextState.accented,
                            sizeMultiplier: 3,
                            // style: Theme.of(context).textTheme.headline5,
                          ),
                          NutriaText(
                            text: nodesProvider.projectInfo.description,
                            // style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ],
                      ),
                      // Spacer(),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  nodesProvider.currentNode = nodesProvider.firstVideoNode; //re-initializes the list to load for playback
                                  uiStateProvider.appState = AppState.loading;
                                  
                                  String? firstPath =
                                      nodesProvider.currentNode?.videoPath;

                                  final List<String> preloadPaths =
                                      nodesProvider.currentOptions
                                          .where(
                                              (option) => option.target != null)
                                          .map((option) => nodesProvider
                                                  .getPathById(option.target!)
                                              as String)
                                          .toList();

                                  if (firstPath != null) {
                                    await videoStackProvider.loadInitialVideo(
                                        videoPath: firstPath,
                                        preloadPaths: preloadPaths);
                                    uiStateProvider.appState = AppState.videos;
                                  } else {
                                    uiStateProvider.appState = AppState.mainMenu; //if no initial video exists, go back to main menu
                                  }
                                },
                                child: Text('Start film'),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  exit(0); //Should be SystemNavigator.pop(); on android
                                },
                                child: Text('Exit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

          case AppState.videos:
            return const Stack(
              children: [
                VideoPlaybackManager(),
                Column(
                  children: [
                    Expanded(
                      child: SizedBox(),
                    ),
                    BranchedVideoControls(),
                  ],
                ),
              ],
            );
          case AppState.loading:
            return Center(
              child: CircularProgressIndicator(),
            );
          default:
            return const Placeholder();
        }
      },
    );
  }
}

class LoadProjectButton extends StatelessWidget {
  const LoadProjectButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final NodesProvider nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();
    final VideoPlayerStackProvider videoManagerProvider =
        context.read<VideoPlayerStackProvider>();
    final AppTheme theme = context.watch<ThemeProvider>().currentAppTheme;

    void _loadProject() async {
      // Use the FilePicker provided by the package
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        uiStateProvider.appState = AppState.loading;
        final file = File(result.files.single.path!);

        final jsonString = await file.readAsString();

        nodesProvider.parseProjectJson(jsonString);

        String? firstPath = nodesProvider.currentNode?.videoPath;

        final List<String> preloadPaths = nodesProvider.currentOptions
            .where((option) => option.target != null)
            .map(
                (option) => nodesProvider.getPathById(option.target!) as String)
            .toList();

        // // Print preload paths
        // for (var path in preloadPaths) {
        //   debugPrint('Preloading video path: $path');
        // }

        if (firstPath != null) {
          // print('loading initial video ${firstPath}');
          uiStateProvider.appState = AppState.mainMenu;
          // await videoManagerProvider.loadInitialVideo(
          //     videoPath: firstPath, preloadPaths: preloadPaths);

          // uiStateProvider.appState = AppState.videos;
        }
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _loadProject,
        child: Container(
            constraints: BoxConstraints(maxWidth: 200, maxHeight: 150),
            decoration: BoxDecoration(
                color: theme.cMenuButtons,
                borderRadius:
                    BorderRadius.circular(theme.dMenuButtonsBorderRadius)),
            child: Center(child: NutriaText(text: 'Load Project'))),
      ),
    );
  }
}
