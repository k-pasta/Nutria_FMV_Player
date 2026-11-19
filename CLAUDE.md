# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Nutria FMV Player is a GPLv3 Flutter **desktop** app (Windows is the main target) that plays interactive movies (`.fmv` files) made with Nutria FMV Maker (separate repo, `k-pasta/Nutria_FMV_Maker`). It shows the story's main menu, plays its videos, shows the answers over them, runs its logic (variables), plays music and subtitles, and has a pause menu with saving and loading.

The `.fmv` format is the pure-Dart package `nutria_fmv_protocol`, which lives in the Maker repo (`packages/nutria_fmv_protocol`):
- `pubspec.yaml` takes it from GitHub (`git:` with `path:`), pinned to a commit by `pubspec.lock`, so this repo builds on its own. After a protocol change is pushed to the Maker's `main`, run `flutter pub upgrade nutria_fmv_protocol`.
- To work on both at once, create a `pubspec_overrides.yaml` (git-ignored) with `dependency_overrides: nutria_fmv_protocol: path: ../../Nutria_FMV_Maker/packages/nutria_fmv_protocol`; delete it again before committing, or the lock file records the local path.
- A change to the package is a protocol change for both apps.

## Commands

```sh
flutter pub get
flutter run -d windows                # or: flutter run -d windows -a "C:\path\story.fmv"
flutter analyze
flutter test
```

## Architecture

```
lib/
  core/      pure Dart: Story (following logic nodes to the next video, default answers),
             MusicDirector (when music starts and stops), SaveGame
  services/  IO behind interfaces, each a Riverpod Provider that tests override:
             VideoEngine and AudioEngine (media_kit), StoryFiles (files, saves, settings)
  app/       PlaythroughNotifier (the whole run: menu, playing, choices, pause, save/load)
             and SettingsNotifier (volume, subtitle language)
  ui/        ScreenView (draws a designed screen like the Maker's designer does),
             default_screens.dart (used when a story doesn't design a screen), PlayerHome
```

- **Playback:** `PlaythroughNotifier` is the `VideoListener` of the video engine. Positions decide when the answers appear (`selectionTime` before the end); the end of a video takes the picked answer (or the default one, or waits with "pause on end") and `Story.resolve` follows change/compare nodes to the next video. The engine reports a video's end once, and only for the video playing.
- **Ahead of time:** after a video starts, the videos that can come next (`Story.upcoming`, which looks through logic nodes on a copy of the variables) are loaded so they start without a gap.
- **Saves** store the video node playing and the variables as they were when it started; loading plays that video again.
- **Screens:** elements are placed at fractions of the window and sized by its height; `kButtonTexts` are the default button texts.
- No codegen: providers are plain `Provider`/`NotifierProvider`.

## Conventions

The same as the Maker's: `package:material_ui/material_ui.dart` instead of material.dart, package imports only, a one-line `//` header per file, `///` docs on public types, comment the *why*, keep `flutter analyze` clean (`analysis_options.yaml` has the lints).
