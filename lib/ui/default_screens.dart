// The screens used when a story doesn't design its own: the Maker's
// classic layouts in its default styles.
import 'package:nutria_fmv_protocol/nutria_fmv_protocol.dart';

const _heading = FmvScreenStyle(fontSize: 0.09, bold: true);
const _text = FmvScreenStyle(fontSize: 0.035);
const _button = FmvScreenStyle(
  fontSize: 0.045,
  backgroundOpacity: 0.55,
  radius: 0.015,
  padding: 0.015,
);

/// A column of buttons of [kinds] from [top] down.
List<FmvScreenElement> _buttons(
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
    ..._buttons(const ['start', 'load', 'settings', 'quit'], top: 0.55),
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
      style: _button,
    ),
  ],
);

/// Title and Resume/Save/Load/Settings/Main Menu/Quit.
final kDefaultPauseScreen = FmvMenuScreen(
  elements: [
    const FmvScreenElement(
      kind: 'title',
      x: 0.5,
      y: 0.2,
      width: 0.7,
      style: _heading,
    ),
    ..._buttons(
      const ['resume', 'save', 'load', 'settings', 'mainMenu', 'quit'],
      top: 0.38,
      step: 0.09,
    ),
  ],
);
