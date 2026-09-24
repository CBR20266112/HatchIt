import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule.dart';

class ScheduleDao {
  ScheduleDao(this._appDatabase);

  final AppDatabase _appDatabase;
  static const _table = 'schedules';
  static final List<Schedule> _memorySchedules = [];
  static int _memoryNextId = 1;

  Future<int> create(Schedule schedule) async {
    if (kIsWeb) {
      final id = schedule.id ?? _memoryNextId++;
      _memorySchedules.add(schedule.copyWith(id: id));
      return id;
    }

    try {
      final db = await _appDatabase.database;
      return db.insert(
        _table,
        schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      final id = schedule.id ?? _memoryNextId++;
      _memorySchedules.add(schedule.copyWith(id: id));
      return id;
    }
  }

  Future<List<Schedule>> getAll() async {
    if (kIsWeb) {
      final schedules = [..._memorySchedules];
      schedules.sort((a, b) {
        final day = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (day != 0) {
          return day;
        }
        return a.startTime.compareTo(b.startTime);
      });
      return schedules;
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        _table,
        orderBy: 'day_of_week ASC, start_time ASC',
      );
      return rows.map(Schedule.fromMap).toList();
    } catch (_) {
      final schedules = [..._memorySchedules];
      schedules.sort((a, b) {
        final day = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (day != 0) {
          return day;
        }
        return a.startTime.compareTo(b.startTime);
      });
      return schedules;
    }
  }

  Future<Schedule?> getById(int id) async {
    if (kIsWeb) {
      for (final schedule in _memorySchedules) {
        if (schedule.id == id) {
          return schedule;
        }
      }
      return null;
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return Schedule.fromMap(rows.first);
    } catch (_) {
      for (final schedule in _memorySchedules) {
        if (schedule.id == id) {
          return schedule;
        }
      }
      return null;
    }
  }

  Future<List<Schedule>> getByDay(int dayOfWeek) async {
    if (kIsWeb) {
      final schedules = _memorySchedules
          .where((schedule) => schedule.dayOfWeek == dayOfWeek)
          .toList();
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        _table,
        where: 'day_of_week = ?',
        whereArgs: [dayOfWeek],
        orderBy: 'start_time ASC',
      );
      return rows.map(Schedule.fromMap).toList();
    } catch (_) {
      final schedules = _memorySchedules
          .where((schedule) => schedule.dayOfWeek == dayOfWeek)
          .toList();
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    }
  }

  Future<void> update(Schedule schedule) async {
    if (schedule.id == null) {
      throw ArgumentError('Schedule id is required for update');
    }

    if (kIsWeb) {
      final index = _memorySchedules.indexWhere(
        (item) => item.id == schedule.id,
      );
      if (index == -1) {
        _memorySchedules.add(schedule);
      } else {
        _memorySchedules[index] = schedule;
      }
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.update(
        _table,
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      final index = _memorySchedules.indexWhere(
        (item) => item.id == schedule.id,
      );
      if (index == -1) {
        _memorySchedules.add(schedule);
      } else {
        _memorySchedules[index] = schedule;
      }
    }
  }

  Future<void> delete(int id) async {
    if (kIsWeb) {
      _memorySchedules.removeWhere((schedule) => schedule.id == id);
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      _memorySchedules.removeWhere((schedule) => schedule.id == id);
    }
  }

  Future<List<Schedule>> batchInsert(List<Schedule> schedules) async {
    if (schedules.isEmpty) {
      return const [];
    }

    if (kIsWeb) {
      final inserted = <Schedule>[];
      for (final schedule in schedules) {
        final id = schedule.id ?? _memoryNextId++;
        final next = schedule.copyWith(id: id);
        _memorySchedules.add(next);
        inserted.add(next);
      }
      return inserted;
    }

    try {
      final db = await _appDatabase.database;
      return db.transaction((txn) async {
        final batch = txn.batch();
        for (final schedule in schedules) {
          batch.insert(
            _table,
            schedule.toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        final results = await batch.commit(noResult: false);
        final inserted = <Schedule>[];
        for (var i = 0; i < schedules.length; i++) {
          final rowId = results[i] as int?;
          inserted.add(schedules[i].copyWith(id: rowId));
        }
        return inserted;
      });
    } catch (_) {
      final inserted = <Schedule>[];
      for (final schedule in schedules) {
        final id = schedule.id ?? _memoryNextId++;
        final next = schedule.copyWith(id: id);
        _memorySchedules.add(next);
        inserted.add(next);
      }
      return inserted;
    }
  }
}
