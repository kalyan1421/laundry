import 'package:flutter/material.dart';
import 'app_state.dart';

class AppStateManager extends ValueNotifier<AppState> {
  AppStateManager() : super(AppState());

  void updateThemeMode(ThemeMode themeMode) {
    value = value.copyWith(themeMode: themeMode);
  }
} 