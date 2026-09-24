import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/mascot_profile.dart';

class MascotProfileDao {
  MascotProfileDao(this._appDatabase);

  final AppDatabase _appDatabase;
  static const _table = 'mascot_profile';
  static MascotProfile _memoryProfile = const MascotProfile(
    id: 1,
    currentStage: MascotStage.egg,
    eggCrackDay: 0,
    speciesId: 1,
    equippedTool: null,
    equippedHat: null,
    expPlumBlossom: 120,
    curFurBalls: 50,
    curKeycaps: 3,
    furGrowthGauge: 0,
    lastPetTime: null,
    lastFeedTime: null,
  );

  Future<MascotProfile> getProfile() async {
    if (kIsWeb) {
      return _memoryProfile;
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
        await saveProfile(MascotProfile.defaults);
        return MascotProfile.defaults;
      }

      final loaded = MascotProfile.fromMap(rows.first);
      _memoryProfile = loaded;
      return loaded;
    } catch (_) {
      return _memoryProfile;
    }
  }

  Future<void> saveProfile(MascotProfile profile) async {
    _memoryProfile = profile;
    if (kIsWeb) {
      return;
    }

    try {
      final db = await _appDatabase.database;
      await db.insert(
        _table,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      return;
    }
  }
}
