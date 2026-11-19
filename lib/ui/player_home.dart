// What the Player shows: the button to open a story, the story's main menu,
// or the video with its answers, subtitles and the pause menu; settings,
// saved games and credits over them. Screens are drawn by the shared
// nutria_fmv_screens package, as the Maker's designer shows them.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nutria_fmv_player/app/playthrough.dart';
import 'package:nutria_fmv_player/app/settings.dart';
import 'package:nutria_fmv_player/services/story_files.dart';
import 'package:nutria_fmv_player/services/video_engine.dart';
import 'package:nutria_fmv_player/ui/default_screens.dart';
import 'package:nutria_fmv_player/ui/screen_parts.dart';
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';
import 'package:nutria_fmv_screens/nutria_fmv_screens.dart';
import 'package:window_manager/window_manager.dart';

/// How a video fills the window.
BoxFit boxFitOf(FmvVideoFit fit) => switch (fit) {
  FmvVideoFit.fit => BoxFit.contain,
  FmvVideoFit.fitWidth || FmvVideoFit.fillWidth => BoxFit.fitWidth,
  FmvVideoFit.fitHeight || FmvVideoFit.fillHeight => BoxFit.fitHeight,
  FmvVideoFit.fill => BoxFit.cover,
  FmvVideoFit.stretch => BoxFit.fill,
};

/// The subtitle cues of the file at [path], or `null` if it can't be read.
final subtitleCuesProvider =
    FutureProvider.family<List<FmvSubtitleCue>?, String>((ref, path) async {
      final text = await ref.read(storyFilesProvider).readText(path);
      return text == null ? null : parseSrt(text);
    });

/// Whether the window fills the screen.
class FullScreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> toggle() async {
    final next = !await windowManager.isFullScreen();
    await windowManager.setFullScreen(next);
    state = next;
  }
}

final fullScreenProvider = NotifierProvider<FullScreenNotifier, bool>(
  FullScreenNotifier.new,
);

/// Leaves the app (the window closes).
Future<void> quitApp() async {
  await windowManager.destroy();
  exit(0);
}

/// "Saved 19 Nov, 21:14": when a saved game was made.
String saveLabel(DateTime at) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Saved ${at.day} ${months[at.month - 1]}, '
      '${two(at.hour)}:${two(at.minute)}';
}

/// [screen] with the Player's additions: its background, and its font
/// files once loaded.
class _Screen extends ConsumerWidget {
  const _Screen({required this.screen, required this.content});

  final FmvMenuScreen screen;
  final ScreenContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = loadedFonts(ref, screen);
    return ScreenView(
      screen: screen,
      content: content,
      background: backgroundOf(screen),
      fontFamilyOf: (path) => fonts[path],
    );
  }
}

/// The whole Player window.
class PlayerHome extends ConsumerWidget {
  const PlayerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(playthroughProvider.select((p) => p.phase));
    final settingsOpen = ref.watch(
      playthroughProvider.select((p) => p.settingsOpen),
    );
    final savesOpen = ref.watch(playthroughProvider.select((p) => p.savesOpen));
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: switch (phase) {
              Phase.noStory => const _NoStory(),
              Phase.menu => const _Menu(),
              Phase.playing => const _Playing(),
            },
          ),
          if (savesOpen) const Positioned.fill(child: _SavesScreen()),
          if (settingsOpen) const Positioned.fill(child: _SettingsScreen()),
        ],
      ),
    );
  }
}

class _NoStory extends ConsumerWidget {
  const _NoStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(playthroughProvider.select((p) => p.problem));
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: ref.read(playthroughProvider.notifier).openStory,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Open a Story…', style: TextStyle(fontSize: 18)),
            ),
          ),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Couldn\'t open $problem: it isn\'t a story made with '
                'Nutria FMV Maker, or it can\'t be read.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// What Load does: the saved games screen when the story designed one,
/// else loading the saved game straight away.
void _load(PlaythroughNotifier notifier) {
  final project = notifier.story?.project;
  if (project != null && !project.savesScreen.isEmpty) {
    notifier.openSaves();
  } else {
    notifier.loadSave();
  }
}

/// The story's main menu, designed or the default one.
class _Menu extends ConsumerWidget {
  const _Menu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playthroughProvider.notifier);
    final hasSave = ref.watch(playthroughProvider.select((p) => p.hasSave));
    final project = notifier.story!.project;
    return _Screen(
      screen: designedOr(project.menuScreen, kDefaultMenuScreen),
      content: ScreenContent(
        title: project.info.title,
        description: project.info.description,
        disabled: {if (!hasSave) 'load'},
        onButton: (kind) => switch (kind) {
          'start' => notifier.start(),
          'load' => _load(notifier),
          'settings' => notifier.openSettings(),
          'credits' => _showCredits(context, project.info),
          'quit' => quitApp(),
          _ => null,
        },
      ),
    );
  }
}

void _showCredits(BuildContext context, FmvProjectInfo info) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info.title ?? ''),
        content: Text(
          [
            if (info.description case final d?) plainTextOf(d),
            'Made with Nutria FMV.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );

/// A video playing, with what goes over it.
class _Playing extends ConsumerWidget {
  const _Playing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playthroughProvider.notifier);
    final nodeId = ref.watch(playthroughProvider.select((p) => p.nodeId));
    final paused = ref.watch(playthroughProvider.select((p) => p.paused));
    final waiting = ref.watch(
      playthroughProvider.select((p) => p.waitingAtEnd),
    );
    final story = notifier.story;
    final node = story?.node(nodeId);
    if (story == null || node == null) return const SizedBox.expand();
    final settings = story.settingsOf(node);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            // A click goes on after a video that waits at its end.
            onTap: notifier.continueAtEnd,
            onDoubleTap: ref.read(fullScreenProvider.notifier).toggle,
            child: ref
                .read(videoEngineProvider)
                .view(boxFitOf(settings.videoFit)),
          ),
        ),
        Positioned.fill(child: _Subtitles(node: node)),
        if (node.isBranched) const Positioned.fill(child: _Choices()),
        if (waiting && !node.isBranched)
          const Positioned(
            right: 24,
            bottom: 24,
            child: Text(
              'Click to go on',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        if (paused) const Positioned.fill(child: _PauseMenu()),
      ],
    );
  }
}

/// The answers over the video, once it's time to choose, on the node's
/// answer screen.
class _Choices extends ConsumerWidget {
  const _Choices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playthroughProvider);
    final notifier = ref.read(playthroughProvider.notifier);
    final story = notifier.story!;
    final node = notifier.currentNode;
    if (node == null || !p.choicesShown) return const SizedBox.shrink();
    final settings = story.settingsOf(node);
    final remaining = p.duration - p.position;
    final timeLeft = settings.showTimer && !p.waitingAtEnd && p.picked == null
        ? (remaining.inMilliseconds / settings.selectionTimeMs).clamp(0.0, 1.0)
        : null;
    final design = story.project.choiceScreenOf(node);
    return _Screen(
      // Over the video: the screen's own background isn't drawn.
      screen: FmvMenuScreen(
        elements: designedOr(design, kDefaultChoiceScreen).elements,
      ),
      content: ScreenContent(
        question: node.question,
        answers: [for (final c in node.choices!) c.text],
        picked: p.picked,
        timeLeft: timeLeft,
        onAnswer: notifier.pick,
      ),
    );
  }
}

/// The subtitles of the playing video, in the viewer's language.
class _Subtitles extends ConsumerWidget {
  const _Subtitles({required this.node});

  final FmvNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(settingsProvider.select((s) => s.subtitles));
    if (choice == kSubtitlesOff) return const SizedBox.shrink();
    final path =
        (choice == null ? null : node.subtitleTracks[choice]) ?? node.subtitles;
    if (path == null) return const SizedBox.shrink();
    final cues = ref.watch(subtitleCuesProvider(path)).value;
    if (cues == null) return const SizedBox.shrink();
    final position = ref.watch(playthroughProvider.select((p) => p.position));
    final cue = cues
        .where((c) => c.start <= position && position < c.end)
        .firstOrNull;
    if (cue == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: const Alignment(0, 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text.rich(
            markdownSpan(
              cue.text,
              TextStyle(
                color: Colors.white,
                fontSize: constraints.maxHeight * 0.04,
                height: 1.25,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// The pause menu over the stopped video, designed or the default one.
class _PauseMenu extends ConsumerWidget {
  const _PauseMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playthroughProvider.notifier);
    final hasSave = ref.watch(playthroughProvider.select((p) => p.hasSave));
    final project = notifier.story!.project;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: _Screen(
        screen: designedOr(project.pauseScreen, kDefaultPauseScreen),
        content: ScreenContent(
          title: project.info.title,
          description: project.info.description,
          disabled: {if (!hasSave) 'load'},
          onButton: (kind) => switch (kind) {
            'resume' => notifier.resume(),
            'save' => notifier.save(),
            'load' => _load(notifier),
            'settings' => notifier.openSettings(),
            'mainMenu' => notifier.toMenu(),
            'quit' => quitApp(),
            _ => null,
          },
        ),
      ),
    );
  }
}

/// Volume, subtitles and full screen, on the story's settings screen (or
/// the default one).
class _SettingsScreen extends ConsumerWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final playthrough = ref.read(playthroughProvider.notifier);
    final project = playthrough.story?.project;
    final languages = project?.info.languages ?? const <String>[];
    // The choices, in order: off, then the story's languages (or just "on"
    // without any).
    final options = <(String?, String)>[
      (kSubtitlesOff, 'Off'),
      if (languages.length < 2)
        (null, 'On')
      else
        for (final (i, code) in languages.indexed)
          (i == 0 ? null : code, fmvLanguageLabel(code)),
    ];
    final current = options.indexWhere((o) => o.$1 == settings.subtitles);
    return ColoredBox(
      // A screen of its own: what's behind doesn't show through.
      color: Colors.black,
      child: _Screen(
        screen: designedOr(
          project?.settingsScreen ?? const FmvMenuScreen(),
          kDefaultSettingsScreen,
        ),
        content: ScreenContent(
          title: project?.info.title,
          volume: settings.volume,
          onVolume: notifier.setVolume,
          subtitles: options[current < 0 ? 0 : current].$2,
          onSubtitles: (direction) {
            final next = (current + direction) % options.length;
            notifier.setSubtitles(options[next].$1);
          },
          fullScreen: ref.watch(fullScreenProvider),
          onFullScreen: ref.read(fullScreenProvider.notifier).toggle,
          onButton: (kind) {
            if (kind == 'back') playthrough.closeSettings();
          },
        ),
      ),
    );
  }
}

/// The saved games, to load one.
class _SavesScreen extends ConsumerWidget {
  const _SavesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playthroughProvider.notifier);
    final savedAt = ref.watch(playthroughProvider.select((p) => p.savedAt));
    final project = notifier.story?.project;
    return ColoredBox(
      // A screen of its own: what's behind doesn't show through.
      color: Colors.black,
      child: _Screen(
        screen: designedOr(
          project?.savesScreen ?? const FmvMenuScreen(),
          kDefaultSavesScreen,
        ),
        content: ScreenContent(
          title: project?.info.title,
          saves: [if (savedAt != null) saveLabel(savedAt)],
          onSaveSlot: (_) {
            notifier.closeSaves();
            notifier.loadSave();
          },
          onButton: (kind) {
            if (kind == 'back') notifier.closeSaves();
          },
        ),
      ),
    );
  }
}
