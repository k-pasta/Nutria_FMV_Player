import 'package:flutter/material.dart';
import 'package:nutria_fmv_player/models/enums_data.dart';

class UiStateProvider extends ChangeNotifier {
  final BackdropKey _backdropKey = BackdropKey();
  BackdropKey get backdropKey => _backdropKey;

  AppState _appState = AppState.noProject;
  AppState get appState => _appState;
  set appState(AppState newState) {
    _appState = newState;
    notifyListeners();
  }
}
