import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import 'app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._appDatabase);

  static const _table = 'app_settings';
  static AppSettings _memoryFallback = AppSettings.defaults;
  final AppDatabase _appDatabase;

  Future<AppSettings> loadSettings() async {
    if (kIsWeb) {
      return _memoryFallback;
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (rows.isEmpty) {
        await saveSettings(AppSettings.defaults);
        return AppSettings.defaults;
      }

      final row = rows.first;
      final localeCode =
          (row['locale_code'] as String?) ?? AppSettings.defaults.localeCode;
      final themeModeRaw = (row['theme_mode'] as String?) ?? 'system';

      final loaded = AppSettings(
        localeCode: localeCode,
        themeMode: AppSettings.themeModeFromDb(themeModeRaw),
        geminiApiKey: (row['gemini_api_key'] as String?) ?? '',
      );
      _memoryFallback = loaded;
      return loaded;
    } catch (_) {
      return _memoryFallback;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    _memoryFallback = settings;
    if (kIsWeb) {
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.insert(_table, {
        'id': 1,
        'locale_code': settings.localeCode,
        'theme_mode': AppSettings.themeModeToDb(settings.themeMode),
        'gemini_api_key': settings.geminiApiKey,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      return;
    }
  }
}
