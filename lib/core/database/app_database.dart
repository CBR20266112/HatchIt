import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'hatchit.db';
  static const _databaseVersion = 3;

  Database? _database;

  Future<void> initializeForPlatform() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return database.then((_) {});
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is bypassed on web runtime.');
    }

    if (_database != null) {
      return _database!;
    }

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, _databaseName);
      _database = await _openAndPrepareDatabase(path);
      return _database!;
    } catch (error, stackTrace) {
      debugPrint(
        'AppDatabase primary open failed, fallback to in-memory DB: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      _database = await _openAndPrepareDatabase(inMemoryDatabasePath);
      return _database!;
    }
  }

  Future<Database> _openAndPrepareDatabase(String path) {
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        locale_code TEXT NOT NULL,
        theme_mode TEXT NOT NULL,
        gemini_api_key TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _ensureColumnExists(
      db,
      table: 'app_settings',
      column: 'gemini_api_key',
      definition: "TEXT NOT NULL DEFAULT ''",
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('CLASS', 'EVENT')),
        day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)),
        alarm_offset_minutes INTEGER NOT NULL DEFAULT 30 CHECK (alarm_offset_minutes IN (30, 60, 90, 120))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_date TEXT NOT NULL,
        slot_type TEXT NOT NULL CHECK (slot_type IN ('MORNING', 'EVENING')),
        mood_level INTEGER NOT NULL CHECK (mood_level BETWEEN 1 AND 5),
        question_text TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mascot_profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_stage TEXT NOT NULL CHECK (current_stage IN ('EGG', 'HATCHED', 'MASCOT')),
        egg_crack_day INTEGER NOT NULL DEFAULT 0 CHECK (egg_crack_day BETWEEN 0 AND 7),
        species_id INTEGER,
        equipped_tool TEXT,
        equipped_hat TEXT,
        exp_plum_blossom INTEGER NOT NULL DEFAULT 0,
        cur_fur_balls INTEGER NOT NULL DEFAULT 0,
        cur_keycaps INTEGER NOT NULL DEFAULT 0,
        fur_growth_gauge INTEGER NOT NULL DEFAULT 0,
        rhythm_score INTEGER NOT NULL DEFAULT 0,
        execution_score INTEGER NOT NULL DEFAULT 0,
        cognition_score INTEGER NOT NULL DEFAULT 0,
        energy_score INTEGER NOT NULL DEFAULT 0,
        nature_score INTEGER NOT NULL DEFAULT 0,
        humanities_score INTEGER NOT NULL DEFAULT 0,
        art_physical_score INTEGER NOT NULL DEFAULT 0,
        service_score INTEGER NOT NULL DEFAULT 0,
        education_score INTEGER NOT NULL DEFAULT 0,
        bohemian_score INTEGER NOT NULL DEFAULT 0,
        burst_pace_score INTEGER NOT NULL DEFAULT 0,
        deep_focus_score INTEGER NOT NULL DEFAULT 0,
        last_pet_time TEXT,
        last_feed_time TEXT
      )
    ''');

    await db.insert('app_settings', {
      'id': 1,
      'locale_code': 'ko',
      'theme_mode': 'system',
      'gemini_api_key': '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'rhythm_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'execution_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'cognition_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'energy_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'nature_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'humanities_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'art_physical_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'service_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'education_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'bohemian_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'burst_pace_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumnExists(
      db,
      table: 'mascot_profile',
      column: 'deep_focus_score',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );

    await db.insert('mascot_profile', {
      'id': 1,
      'current_stage': 'EGG',
      'egg_crack_day': 0,
      'species_id': null,
      'equipped_tool': null,
      'equipped_hat': null,
      'exp_plum_blossom': 0,
      'cur_fur_balls': 0,
      'cur_keycaps': 0,
      'fur_growth_gauge': 0,
      'rhythm_score': 0,
      'execution_score': 0,
      'cognition_score': 0,
      'energy_score': 0,
      'nature_score': 0,
      'humanities_score': 0,
      'art_physical_score': 0,
      'service_score': 0,
      'education_score': 0,
      'bohemian_score': 0,
      'burst_pace_score': 0,
      'deep_focus_score': 0,
      'last_pet_time': null,
      'last_feed_time': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureColumnExists(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
    final hasColumn = tableInfo.any((row) => row['name'] == column);
    if (hasColumn) {
      return;
    }
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
