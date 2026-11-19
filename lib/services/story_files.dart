// Files: picking and reading a story, reading subtitles, and keeping saved
// games and settings on this computer.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// File access for the Player. Never throws: unreadable files are `null`.
abstract interface class StoryFiles {
  /// Asks for a `.fmv` file; `null` if cancelled.
  Future<String?> pickStory();

  /// The text of the file at [path].
  Future<String?> readText(String path);

  /// The saved game of the story at [storyPath], as saved text.
  String? readSave(String storyPath);
  Future<void> writeSave(String storyPath, String save);

  /// A stored setting.
  String? readSetting(String key);
  Future<void> writeSetting(String key, String value);
}

/// [StoryFiles] on the local disk, with saves and settings in the
/// platform's preferences store.
class LocalStoryFiles implements StoryFiles {
  LocalStoryFiles(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> pickStory() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['fmv'],
    );
    return file?.path;
  }

  @override
  Future<String?> readText(String path) async {
    try {
      return await File(path).readAsString();
    } on FileSystemException {
      return null;
    } on FormatException {
      // Not UTF-8: read it byte by byte rather than not at all.
      try {
        return String.fromCharCodes(await File(path).readAsBytes());
      } on FileSystemException {
        return null;
      }
    }
  }

  @override
  String? readSave(String storyPath) =>
      _preferences.getString('save:$storyPath');

  @override
  Future<void> writeSave(String storyPath, String save) =>
      _preferences.setString('save:$storyPath', save);

  @override
  String? readSetting(String key) => _preferences.getString('setting:$key');

  @override
  Future<void> writeSetting(String key, String value) =>
      _preferences.setString('setting:$key', value);
}

/// Overridden in `main` with the loaded preferences, and in tests.
final storyFilesProvider = Provider<StoryFiles>(
  (ref) => throw UnimplementedError('storyFilesProvider is set in main()'),
);
