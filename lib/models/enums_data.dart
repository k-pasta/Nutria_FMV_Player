enum VideoSettings {
  selectionTime,
  pauseOnEnd,
  showTimer,
  videoFit,
  defaultSelection,
  pauseMusicPath,
}

VideoSettings? videoSettingFromString(String value) {
  switch (value) {
    case 'selectionTime':
      return VideoSettings.selectionTime;
    case 'pauseOnEnd':
      return VideoSettings.pauseOnEnd;
    case 'showTimer':
      return VideoSettings.showTimer;
    case 'videoFit':
      return VideoSettings.videoFit;
    case 'defaultSelection':
      return VideoSettings.defaultSelection;
    case 'pauseMusicPath':
      return VideoSettings.pauseMusicPath;
    default:
      return null;
  }
}

enum VideoFit {
  fit,
  fitWidth,
  fitHeight,
  fill,
  fillWidth,
  fillHeight,
  stretch,
}

VideoFit? videoFitFromString(String value) {
  switch (value.toLowerCase()) {
    case 'fit':
      return VideoFit.fit;
    case 'fit width':
      return VideoFit.fitWidth;
    case 'fit height':
      return VideoFit.fitHeight;
    case 'fill':
      return VideoFit.fill;
    case 'fill width':
      return VideoFit.fillWidth;
    case 'fill height':
      return VideoFit.fillHeight;
    case 'stretch':
      return VideoFit.stretch;
    default:
      return null;
  }
}

enum DefaultSelectionMethod {
  first,
  last,
  lastSelected,
  random,
  specified,
}

DefaultSelectionMethod? defaultSelectionFromString(String value) {
  switch (value.toLowerCase()) {
    case 'first':
      return DefaultSelectionMethod.first;
    case 'last':
      return DefaultSelectionMethod.last;
    case 'lastselected':
      return DefaultSelectionMethod.lastSelected;
    case 'random':
      return DefaultSelectionMethod.random;
    case 'specified':
      return DefaultSelectionMethod.specified;
    default:
      return null;
  }
}
