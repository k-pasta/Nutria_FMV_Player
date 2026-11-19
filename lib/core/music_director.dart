// When music starts and stops while a story plays, as decisions the audio
// engine carries out. Pure: no players here.

import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

/// What the music channel should do.
sealed class MusicCommand {
  const MusicCommand();
}

/// Play [track] from the start ([loop]ing or once), replacing what plays.
final class PlayMusic extends MusicCommand {
  const PlayMusic(this.track, {required this.loop});

  final String track;
  final bool loop;

  @override
  bool operator ==(Object other) =>
      other is PlayMusic && other.track == track && other.loop == loop;

  @override
  int get hashCode => Object.hash(track, loop);

  @override
  String toString() => 'PlayMusic($track, loop: $loop)';
}

/// Fade out over [fadeOutMs] and stop.
final class StopMusic extends MusicCommand {
  const StopMusic(this.fadeOutMs);

  final int fadeOutMs;

  @override
  bool operator ==(Object other) =>
      other is StopMusic && other.fadeOutMs == fadeOutMs;

  @override
  int get hashCode => fadeOutMs.hashCode;

  @override
  String toString() => 'StopMusic($fadeOutMs)';
}

/// Decides the story music (one channel) and the pause music (another)
/// from what happens during playback.
///
/// - A video with music starts it. Without music, the music of an earlier
///   video goes on if it ends "when a later node changes it" or "when the
///   track ends" (then it plays out, or loops until other music starts).
/// - Music ending with the choices or the video stops then.
/// - Pause music loops while the viewer chooses and fades out after.
class MusicDirector {
  FmvMusic? _story;
  FmvLoopMusic? _pause;

  /// The story music playing (or `null`).
  FmvMusic? get current => _story;

  /// A video node starts playing. Returns what the story channel should do.
  MusicCommand? enterVideo(FmvNode node) {
    final music = node.music;
    final previous = _story;
    if (music != null) {
      _story = music;
      return PlayMusic(music.track, loop: music.loop);
    }
    if (previous == null ||
        previous.end == FmvMusicEnd.laterNodeChanges ||
        previous.end == FmvMusicEnd.trackEnds) {
      return null;
    }
    // Anything else should have stopped already; make sure it does.
    _story = null;
    return StopMusic(previous.fadeOutMs);
  }

  /// The story track played to its end (it doesn't loop).
  void trackFinished() => _story = null;

  /// The choices of the current video appear. Returns the commands for the
  /// story channel and the pause channel.
  ({MusicCommand? story, MusicCommand? pause}) choicesAppear(FmvNode node) {
    MusicCommand? story;
    final music = _story;
    if (music != null && music.end == FmvMusicEnd.choicesAppear) {
      _story = null;
      story = StopMusic(music.fadeOutMs);
    }
    MusicCommand? pause;
    if (node.pauseMusic case final loop?) {
      _pause = loop;
      pause = PlayMusic(loop.track, loop: true);
    }
    return (story: story, pause: pause);
  }

  /// The viewer picked an answer, or the time ran out: the pause music
  /// stops.
  MusicCommand? choiceMade() {
    final pause = _pause;
    if (pause == null) return null;
    _pause = null;
    return StopMusic(pause.fadeOutMs);
  }

  /// The current video ended.
  MusicCommand? videoEnded() {
    final music = _story;
    if (music == null || music.end != FmvMusicEnd.videoEnds) return null;
    _story = null;
    return StopMusic(music.fadeOutMs);
  }

  /// The story stops (back to the menu): everything fades out.
  ({MusicCommand? story, MusicCommand? pause}) stopAll() {
    final story = _story;
    final pause = _pause;
    _story = null;
    _pause = null;
    return (
      story: story == null ? null : StopMusic(story.fadeOutMs),
      pause: pause == null ? null : StopMusic(pause.fadeOutMs),
    );
  }
}
