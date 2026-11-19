// The viewer's settings: volume and subtitles. Kept between sessions.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutria_fmv_player/services/story_files.dart';

/// Subtitles turned off.
const kSubtitlesOff = 'off';

/// What the viewer chose: [volume] (0 to 100), and [subtitles]: a language
/// code, [kSubtitlesOff], or `null` for the story's main language.
typedef PlayerSettings = ({double volume, String? subtitles});

class SettingsNotifier extends Notifier<PlayerSettings> {
  StoryFiles get _files => ref.read(storyFilesProvider);

  @override
  PlayerSettings build() {
    final files = ref.watch(storyFilesProvider);
    return (
      volume: double.tryParse(files.readSetting('volume') ?? '') ?? 100,
      subtitles: switch (files.readSetting('subtitles')) {
        null || '' => null,
        final code => code,
      },
    );
  }

  void setVolume(double volume) {
    final v = volume.clamp(0, 100).toDouble();
    state = (volume: v, subtitles: state.subtitles);
    _files.writeSetting('volume', '$v');
  }

  /// A language code, [kSubtitlesOff], or `null` (the main language).
  void setSubtitles(String? subtitles) {
    state = (volume: state.volume, subtitles: subtitles);
    _files.writeSetting('subtitles', subtitles ?? '');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, PlayerSettings>(
  SettingsNotifier.new,
);
