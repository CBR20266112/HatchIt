import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.localeCode,
    required this.themeMode,
    required this.geminiApiKey,
  });

  final String localeCode;
  final ThemeMode themeMode;
  final String geminiApiKey;

  static const AppSettings defaults = AppSettings(
    localeCode: 'ko',
    themeMode: ThemeMode.system,
    geminiApiKey: '',
  );

  AppSettings copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    String? geminiApiKey,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }

  static ThemeMode themeModeFromDb(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToDb(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
