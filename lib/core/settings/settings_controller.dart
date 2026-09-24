import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'app_settings.dart';
import 'app_settings_repository.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return AppSettingsRepository(appDatabase);
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      final repo = ref.watch(appSettingsRepositoryProvider);
      return SettingsController(repo)..load();
    });

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repository) : super(AppSettings.defaults);

  final AppSettingsRepository _repository;

  Future<void> load() async {
    try {
      final loaded = await _repository.loadSettings();
      state = loaded;
    } catch (_) {
      state = AppSettings.defaults;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = state.copyWith(themeMode: mode);
    state = next;
    try {
      await _repository.saveSettings(next);
    } catch (_) {
      return;
    }
  }

  Future<void> setLocaleCode(String localeCode) async {
    final next = state.copyWith(localeCode: localeCode);
    state = next;
    try {
      await _repository.saveSettings(next);
    } catch (_) {
      return;
    }
  }
}
