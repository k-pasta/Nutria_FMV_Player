import 'package:flutter/material.dart';

class UiStateProvider extends ChangeNotifier {
  final BackdropKey _backdropKey = BackdropKey();
  BackdropKey get backdropKey => _backdropKey;
}
