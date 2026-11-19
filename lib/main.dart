// Entry point: initializes video and the window, then opens the Player
// (with a story given on the command line, if any).
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nutria_fmv_player/app/playthrough.dart';
import 'package:nutria_fmv_player/app/settings.dart';
import 'package:nutria_fmv_player/services/story_files.dart';
import 'package:nutria_fmv_player/ui/player_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      storyFilesProvider.overrideWithValue(LocalStoryFiles(preferences)),
    ],
  );
  // Opening a .fmv with the Player passes it as the first argument.
  if (args.isNotEmpty && args.first.toLowerCase().endsWith('.fmv')) {
    await container.read(playthroughProvider.notifier).loadStory(args.first);
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const PlayerApp()),
  );
}

/// The Player app: the home screen with the Player's keys.
class PlayerApp extends StatelessWidget {
  const PlayerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Nutria FMV Player',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF4E6A),
        brightness: Brightness.dark,
      ),
    ),
    home: const Scaffold(body: PlayerKeys(child: PlayerHome())),
  );
}

/// The Player's keys:
/// - Escape or Space: pause menu (and back);
/// - 1 to 9: pick that answer; Enter: go on after a video that waits;
/// - F or F11: full screen;
/// - Up and Down: volume.
class PlayerKeys extends ConsumerWidget {
  const PlayerKeys({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playthrough = ref.read(playthroughProvider.notifier);
    final settings = ref.read(settingsProvider.notifier);
    void volume(double by) =>
        settings.setVolume(ref.read(settingsProvider).volume + by);
    Future<void> fullScreen() async =>
        windowManager.setFullScreen(!await windowManager.isFullScreen());
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (ref.read(playthroughProvider).settingsOpen) {
            playthrough.closeSettings();
          } else {
            playthrough.togglePause();
          }
        },
        const SingleActivator(LogicalKeyboardKey.space):
            playthrough.togglePause,
        const SingleActivator(LogicalKeyboardKey.enter):
            playthrough.continueAtEnd,
        const SingleActivator(LogicalKeyboardKey.keyF): fullScreen,
        const SingleActivator(LogicalKeyboardKey.f11): fullScreen,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => volume(10),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => volume(-10),
        for (var i = 1; i <= 9; i++)
          SingleActivator(LogicalKeyboardKey(0x30 + i)): () =>
              playthrough.pick(i - 1),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
