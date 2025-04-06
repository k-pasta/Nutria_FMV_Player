import 'package:flutter/material.dart';

import '../models/app_theme.dart';

class ThemeProvider extends ChangeNotifier{
  static const AppTheme _appThemeDefault = AppTheme();

  AppTheme get currentTheme => _appThemeDefault;
}