import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/daily_record.dart';

class DailyRecordDao {
  DailyRecordDao(this._appDatabase);

  final AppDatabase _appDatabase;
  static const _table = 'daily_records';
  static final List<DailyRecord> _memoryRecords = [];
  static int _memoryNextId = 1;

  Future<int> create(DailyRecord record) async {
    if (kIsWeb) {
      final id = record.id ?? _memoryNextId++;
      _memoryRecords.add(record.copyWith(id: id));
      return id;
    }

    try {
      final db = await _appDatabase.database;
      return db.insert(
        _table,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      final id = record.id ?? _memoryNextId++;
      _memoryRecords.add(record.copyWith(id: id));
      return id;
    }
  }

  Future<List<DailyRecord>> getAll() async {
    if (kIsWeb) {
      final records = [..._memoryRecords];
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.query(_table, orderBy: 'created_at DESC');
      return rows.map(DailyRecord.fromMap).toList();
    } catch (_) {
      final records = [..._memoryRecords];
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    }
  }

  Future<DailyRecord?> getById(int id) async {
    if (kIsWeb) {
      for (final record in _memoryRecords) {
        if (record.id == id) {
          return record;
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
      return DailyRecord.fromMap(rows.first);
    } catch (_) {
      for (final record in _memoryRecords) {
        if (record.id == id) {
          return record;
        }
      }
      return null;
    }
  }

  Future<void> update(DailyRecord record) async {
    if (record.id == null) {
      throw ArgumentError('DailyRecord id is required for update');
    }

    if (kIsWeb) {
      final index = _memoryRecords.indexWhere((item) => item.id == record.id);
      if (index == -1) {
        _memoryRecords.add(record);
      } else {
        _memoryRecords[index] = record;
      }
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.update(
        _table,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      final index = _memoryRecords.indexWhere((item) => item.id == record.id);
      if (index == -1) {
        _memoryRecords.add(record);
      } else {
        _memoryRecords[index] = record;
      }
    }
  }

  Future<DailyRecord?> getByDateAndSlot({
    required String recordDate,
    required DailySlotType slotType,
  }) async {
    if (kIsWeb) {
      for (final record in _memoryRecords) {
        if (record.recordDate == recordDate && record.slotType == slotType) {
          return record;
        }
      }
      return null;
    }

    try {
      final db = await _appDatabase.database;
      final slot = slotType == DailySlotType.morning ? 'MORNING' : 'EVENING';
      final rows = await db.query(
        _table,
        where: 'record_date = ? AND slot_type = ?',
        whereArgs: [recordDate, slot],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }
      return DailyRecord.fromMap(rows.first);
    } catch (_) {
      for (final record in _memoryRecords) {
        if (record.recordDate == recordDate && record.slotType == slotType) {
          return record;
        }
      }
      return null;
    }
  }

  Future<void> clearAll() async {
    _memoryRecords.clear();
    _memoryNextId = 1;
    if (kIsWeb) {
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.delete(_table);
    } catch (_) {
      return;
    }
  }

  Future<void> delete(int id) async {
    if (kIsWeb) {
      _memoryRecords.removeWhere((record) => record.id == id);
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      _memoryRecords.removeWhere((record) => record.id == id);
    }
  }
}
