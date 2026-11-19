import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nutria_fmv_player/core/music_director.dart';
import 'package:nutria_fmv_player/core/save_game.dart';
import 'package:nutria_fmv_player/core/story.dart';
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

/// 001 video → 002 add 1 coin → 003 compare coins >= 1: true → 004, false
/// → 005. 004 is branched: two answers, to 005 and the end.
FmvProject _project({
  FmvDefaultSelection selection = FmvDefaultSelection.first,
}) => FmvProject(
  settings: FmvSettings(defaultSelection: selection),
  variables: const {
    'coins': FmvVariable(type: FmvVariableType.integer, initial: 0),
  },
  nodes: const {
    '001': FmvNode(video: 'a.mp4', target: '002'),
    '002': FmvNode(
      type: FmvNodeType.change,
      variable: 'coins',
      operation: FmvChangeOperation.add,
      value: '1',
      target: '003',
    ),
    '003': FmvNode(
      type: FmvNodeType.compare,
      conditions: [
        FmvCondition(
          variable: 'coins',
          comparison: FmvComparison.greaterOrEqual,
          value: '1',
        ),
      ],
      whenTrue: '004',
      whenFalse: '005',
    ),
    '004': FmvNode(
      video: 'b.mp4',
      choices: [
        FmvChoice(text: 'Go', target: '005'),
        FmvChoice(text: 'Stop'),
      ],
    ),
    '005': FmvNode(video: 'c.mp4'),
  },
);

void main() {
  test('logic nodes are followed to the next video', () {
    final story = Story(_project());
    final variables = FmvVariableState(story.project.variables);
    expect(story.startId, '001');
    expect(story.resolve('002', variables), '004');
    expect(variables.values['coins'], 1);
    expect(story.resolve(null, variables), isNull, reason: 'the end');
  });

  test('peeking ahead changes nothing', () {
    final story = Story(_project());
    final variables = FmvVariableState(story.project.variables);
    expect(story.upcoming(story.node('001')!, variables), {'004'});
    expect(variables.values['coins'], 0);
  });

  test('a loop of logic nodes only ends the story', () {
    final story = Story(
      const FmvProject(
        nodes: {
          '001': FmvNode(
            type: FmvNodeType.change,
            variable: 'x',
            operation: FmvChangeOperation.toggle,
            target: '001',
          ),
        },
        variables: {
          'x': FmvVariable(type: FmvVariableType.boolean, initial: false),
        },
      ),
    );
    expect(
      story.resolve('001', FmvVariableState(story.project.variables)),
      isNull,
    );
  });

  test('the default answer follows the selection setting', () {
    final random = math.Random(1);
    int pick(FmvDefaultSelection s, {int last = 0}) {
      final story = Story(_project(selection: s));
      return story.defaultChoice(
        story.node('004')!,
        lastPicked: last,
        random: random,
      );
    }

    expect(pick(FmvDefaultSelection.first), 0);
    expect(pick(FmvDefaultSelection.last), 1);
    expect(pick(FmvDefaultSelection.lastSelected, last: 7), 1);
    expect(pick(FmvDefaultSelection.random), inInclusiveRange(0, 1));
    final story = Story(_project());
    expect(story.nextOf(story.node('004')!, 1), isNull);
    expect(story.nextOf(story.node('001')!, 0), '002');
  });

  group('music', () {
    const withMusic = FmvNode(
      video: 'a.mp4',
      music: FmvMusic(track: 'm.mp3', end: FmvMusicEnd.laterNodeChanges),
    );
    const silent = FmvNode(video: 'b.mp4');

    test('music that goes on until a later node changes it', () {
      final director = MusicDirector();
      expect(
        director.enterVideo(withMusic),
        const PlayMusic('m.mp3', loop: false),
      );
      expect(director.videoEnded(), isNull);
      expect(director.enterVideo(silent), isNull, reason: 'keeps playing');
      expect(director.current?.track, 'm.mp3');
    });

    test('music ending with the video or the choices stops then', () {
      final director = MusicDirector();
      director.enterVideo(
        const FmvNode(
          video: 'a.mp4',
          music: FmvMusic(track: 'm.mp3', fadeOutMs: 500),
        ),
      );
      expect(director.videoEnded(), const StopMusic(500));
      expect(director.enterVideo(silent), isNull);

      director.enterVideo(
        const FmvNode(
          video: 'a.mp4',
          music: FmvMusic(track: 'n.mp3', end: FmvMusicEnd.choicesAppear),
          pauseMusic: FmvLoopMusic(track: 'p.mp3', fadeOutMs: 200),
          choices: [FmvChoice(text: 'x')],
        ),
      );
      final appear = director.choicesAppear(
        const FmvNode(
          video: 'a.mp4',
          pauseMusic: FmvLoopMusic(track: 'p.mp3', fadeOutMs: 200),
        ),
      );
      expect(appear.story, const StopMusic(1000));
      expect(appear.pause, const PlayMusic('p.mp3', loop: true));
      expect(director.choiceMade(), const StopMusic(200));
      expect(director.choiceMade(), isNull);
    });
  });

  test('saved games round-trip; anything else is not one', () {
    final save = SaveGame(
      nodeId: '004',
      values: const {'coins': 2},
      lastPicked: 1,
      savedAt: DateTime(2026, 11, 19, 12),
    );
    final read = SaveGame.decode(save.encode())!;
    expect(read.nodeId, '004');
    expect(read.values, {'coins': 2});
    expect(read.lastPicked, 1);
    expect(read.savedAt, DateTime(2026, 11, 19, 12));
    expect(SaveGame.decode('nope'), isNull);
    expect(SaveGame.decode(null), isNull);
  });
}
