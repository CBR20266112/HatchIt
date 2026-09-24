import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../alarm/alarm_service.dart';
import '../data/schedule_dao.dart';
import '../data/timetable_ocr_service.dart';
import '../domain/schedule.dart';

final scheduleDaoProvider = Provider<ScheduleDao>((ref) {
  return ScheduleDao(ref.watch(appDatabaseProvider));
});

final timetableOcrServiceProvider = Provider<TimetableOcrService>((ref) {
  return TimetableOcrService(ref.watch(scheduleDaoProvider));
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

final scheduleListProvider =
    AsyncNotifierProvider<ScheduleListNotifier, List<Schedule>>(
      ScheduleListNotifier.new,
    );

class ScheduleListNotifier extends AsyncNotifier<List<Schedule>> {
  ScheduleDao get _dao => ref.read(scheduleDaoProvider);
  TimetableOcrService get _ocrService => ref.read(timetableOcrServiceProvider);
  AlarmService get _alarmService => ref.read(alarmServiceProvider);

  @override
  Future<List<Schedule>> build() async {
    try {
      final schedules = await _dao.getAll();
      await _alarmService.scheduleForSchedules(schedules);
      return schedules;
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final schedules = await _dao.getAll();
      await _alarmService.scheduleForSchedules(schedules);
      return schedules;
    });
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _dao.create(schedule);
    await refresh();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _dao.update(schedule);
    await refresh();
  }

  Future<void> removeSchedule(int id) async {
    await _dao.delete(id);
    await refresh();
  }

  Future<List<Schedule>> importFromTimetableImagePath({
    required String imagePath,
    required String apiKey,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('웹 환경에서는 이미지 파일 기반 OCR 가져오기를 지원하지 않습니다.');
    }

    state = const AsyncLoading();

    final next = await AsyncValue.guard(() async {
      await _ocrService.parseTimetableImage(File(imagePath), apiKey);
      final all = await _dao.getAll();
      await _alarmService.scheduleForSchedules(all);
      return all;
    });

    state = next;
    return next.requireValue;
  }

  Future<void> markCompleted(int id, bool completed) async {
    final existing = await _dao.getById(id);
    if (existing == null) {
      return;
    }
    await _dao.update(existing.copyWith(isCompleted: completed));
    await refresh();
  }
}
