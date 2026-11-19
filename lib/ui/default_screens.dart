// The screens used when a story doesn't design its own (stories made
// before the Maker designed them): the Maker's default layouts in its
// default styles.
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

const _heading = FmvScreenStyle(
  fontSize: 0.09,
  bold: true,
  fontFamily: 'manrope',
);
const _text = FmvScreenStyle(fontSize: 0.035, fontFamily: 'inter');
const _button = FmvScreenStyle(
  fontSize: 0.045,
  fontFamily: 'inter',
  backgroundOpacity: 0.55,
  radius: 0.015,
  padding: 0.015,
);

/// A column of [kinds] from [top] down, styled as buttons.
List<FmvScreenElement> _column(
  List<String> kinds, {
  required double top,
  double step = 0.1,
  double width = 0.28,
}) => [
  for (final (i, kind) in kinds.indexed)
    FmvScreenElement(
      kind: kind,
      x: 0.5,
      y: top + i * step,
      width: width,
      style: _button,
    ),
];

const _title = FmvScreenElement(
  kind: 'title',
  x: 0.5,
  y: 0.2,
  width: 0.7,
  style: _heading,
);

/// Title, description and Start/Load/Settings/Quit.
final kDefaultMenuScreen = FmvMenuScreen(
  elements: [
    const FmvScreenElement(
      kind: 'title',
      x: 0.5,
      y: 0.22,
      width: 0.7,
      style: _heading,
    ),
    const FmvScreenElement(
      kind: 'description',
      x: 0.5,
      y: 0.34,
      width: 0.6,
      style: _text,
    ),
    ..._column(const ['start', 'load', 'settings', 'quit'], top: 0.55),
  ],
);

/// The question above the answers, and the timer, low on the screen.
const kDefaultChoiceScreen = FmvMenuScreen(
  elements: [
    FmvScreenElement(
      kind: 'question',
      x: 0.5,
      y: 0.42,
      width: 0.8,
      style: _text,
    ),
    FmvScreenElement(
      kind: 'choices',
      x: 0.5,
      y: 0.68,
      width: 0.5,
      gap: 0.015,
      style: _button,
    ),
    FmvScreenElement(
      kind: 'timer',
      x: 0.5,
      y: 0.94,
      width: 0.6,
      thickness: 0.012,
      style: _button,
    ),
  ],
);

/// Title and Resume/Save/Load/Settings/Main Menu/Quit.
final kDefaultPauseScreen = FmvMenuScreen(
  elements: [
    _title,
    ..._column(
      const ['resume', 'save', 'load', 'settings', 'mainMenu', 'quit'],
      top: 0.38,
      step: 0.09,
    ),
  ],
);

/// Title, volume, subtitles, full screen and Back.
final kDefaultSettingsScreen = FmvMenuScreen(
  elements: [
    const FmvScreenElement(
      kind: 'title',
      x: 0.5,
      y: 0.18,
      width: 0.7,
      style: _heading,
    ),
    ..._column(
      const ['volume', 'subtitles', 'fullScreen'],
      top: 0.4,
      step: 0.13,
      width: 0.4,
    ),
    const FmvScreenElement(
      kind: 'back',
      x: 0.5,
      y: 0.85,
      width: 0.22,
      style: _button,
    ),
  ],
);

/// Title, the saved games and Back.
const kDefaultSavesScreen = FmvMenuScreen(
  elements: [
    FmvScreenElement(
      kind: 'title',
      x: 0.5,
      y: 0.18,
      width: 0.7,
      style: _heading,
    ),
    FmvScreenElement(
      kind: 'saves',
      x: 0.5,
      y: 0.5,
      width: 0.45,
      style: _button,
    ),
    FmvScreenElement(
      kind: 'back',
      x: 0.5,
      y: 0.85,
      width: 0.22,
      style: _button,
    ),
  ],
);

/// [design], or [fallback] if the story didn't design it (keeping the
/// story's background).
FmvMenuScreen designedOr(FmvMenuScreen design, FmvMenuScreen fallback) =>
    design.elements.isEmpty
    ? FmvMenuScreen(background: design.background, elements: fallback.elements)
    : design;
