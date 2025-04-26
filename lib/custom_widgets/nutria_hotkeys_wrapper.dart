import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutria_fmv_player/app_state/app_static_data.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/ui_state_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:nutria_fmv_player/static_data/data_static_properties.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  runApp(const MyApp());
}

/// Example showing multiple hotkeys connected to multiple actions.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NutriaHotkeysWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Hotkeys Example')),
          body: const Center(child: Text('Press keys!')),
        ),
      ),
    );
  }
}

/// Wrap your whole app/screen inside this widget to handle hotkeys globally inside the app.
class NutriaHotkeysWrapper extends StatelessWidget {
  final Widget child;

  const NutriaHotkeysWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.read<VideoPlayerStackProvider>();
    final nodesProvider = context.read<NodesProvider>();
    final UiStateProvider uiStateProvider = context.read<UiStateProvider>();

    return Shortcuts(
      // 1. Map key combinations to "Intents"
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.keyF): const ToggleFullScreenIntent(),
        LogicalKeySet(LogicalKeyboardKey.f11): const ToggleFullScreenIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const PauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape):
            const PauseIntent(), // Press "Escape"
        LogicalKeySet(
          LogicalKeyboardKey.arrowUp,
        ): const IncrementAudioUp(), // Press Ctrl+S
        LogicalKeySet(
          LogicalKeyboardKey.arrowDown,
        ): const IncrementAudioDown(), // Press Ctrl+S
      },
      child: Actions(
        // 2. Map Intents to code (CallbackAction)
        actions: <Type, Action<Intent>>{
          PauseIntent: CallbackAction<Intent>(
            onInvoke: (intent) {
              debugPrint('pause toggle');
              videoProvider.activeEntry?.player.playOrPause();
              return null;
            },
          ),
          ToggleFullScreenIntent: CallbackAction<Intent>(
            onInvoke: (intent) async {
              debugPrint('fullscreen toggle');
              bool fs = await windowManager.isFullScreen();
              await windowManager.setFullScreen(!fs);
              return null;
            },
          ),
          IncrementAudioUp: CallbackAction<Intent>(
            onInvoke: (intent) {
              double currentVolume = AppStaticData.volume;
              double newVolume = (currentVolume +
                      DataStaticProperties.audioIncrementPercentage)
                  .clamp(0.0, 100.0);
              videoProvider.currentEntry?.player.setVolume(newVolume);
              AppStaticData.volume = newVolume;
              return null;
            },
          ),
          IncrementAudioDown: CallbackAction<Intent>(
            onInvoke: (intent) async {
              double currentVolume = AppStaticData.volume;
              double newVolume = (currentVolume -
                      DataStaticProperties.audioIncrementPercentage)
                  .clamp(0.0, 100.0);
              videoProvider.currentEntry?.player.setVolume(newVolume);
              AppStaticData.volume = newVolume;
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true, // 3. Automatically grab focus when built
          child: child, // 4. Everything inside keeps hotkeys active
        ),
      ),
    );
  }
}

// You can define custom Intents if needed (here IntentB and SaveIntent are custom).
class PauseIntent extends Intent {
  const PauseIntent();
}

class ToggleFullScreenIntent extends Intent {
  const ToggleFullScreenIntent();
}

class IncrementAudioUp extends Intent {
  const IncrementAudioUp();
}

class IncrementAudioDown extends Intent {
  const IncrementAudioDown();
}
