import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'app_settings.dart';
import 'app_settings_repository.dart';
import '../../features/mascot/data/mascot_asset_manager.dart';
import '../../features/mascot/presentation/mascot_controller.dart';
import '../../features/schedules/presentation/schedule_controller.dart';
import '../../features/daily_records/presentation/daily_record_controller.dart';
import '../../features/events/presentation/cat_ambush_controller.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return AppSettingsRepository(appDatabase);
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      final repo = ref.watch(appSettingsRepositoryProvider);
      return SettingsController(repo)..load();
    });

final developerModeProvider = StateProvider<bool>((ref) => false);

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

  Future<void> setGeminiApiKey(String geminiApiKey) async {
    final next = state.copyWith(geminiApiKey: geminiApiKey.trim());
    state = next;
    try {
      await _repository.saveSettings(next);
    } catch (_) {
      return;
    }
  }
}

/// 앱 데이터 전체 초기화 실질적 실행
/// 1. SQLite 데이터베이스 파일 완전 삭제
/// 2. 로컬에 다운로드된 마스코트 zip/폴더 삭제
/// 3. 모든 Riverpod Provider 상태 무효화
/// 4. "앱 데이터가 초기화되었습니다. 앱을 재시작합니다." 다이얼로그 표시
/// 5. 초기 알 화면으로 강제 이동
Future<void> executeFullAppReset(BuildContext context, WidgetRef ref) async {
  try {
    // 1. SQLite 데이터베이스 파일 완전 삭제
    await AppDatabase.instance.resetDatabase();

    // 2. 다운로드된 마스코트 zip 및 폴더 삭제
    await MascotAssetManager().clearAll();

    // 3. 모든 Riverpod Provider 상태 무효화
    ref.invalidate(settingsControllerProvider);
    ref.invalidate(mascotProfileProvider);
    ref.invalidate(scheduleListProvider);
    ref.invalidate(dailyRecordControllerProvider);
    ref.invalidate(catAmbushControllerProvider);

    if (!context.mounted) return;

    // 4. "앱 데이터가 초기화되었습니다. 앱을 재시작합니다." 안내 다이얼로그
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('초기화 완료'),
          content: const Text('앱 데이터가 초기화되었습니다. 앱을 재시작합니다.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    // 5. 초기 알 화면으로 강제 이동 (최상위 화면으로 이동)
    Navigator.of(context).popUntil((route) => route.isFirst);
  } catch (e) {
    debugPrint('[executeFullAppReset] error: $e');
  }
}

