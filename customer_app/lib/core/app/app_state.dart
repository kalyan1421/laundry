import 'package:flutter/material.dart';

class AppState {
  final ThemeMode themeMode;

  AppState({this.themeMode = ThemeMode.system});

  AppState copyWith({
    ThemeMode? themeMode,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
} 