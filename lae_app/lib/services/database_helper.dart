/// database_helper.dart
///
/// [文件说明]
/// 数据库辅助类，用于管理本地SQLite数据库。
/// 采用单例模式，确保应用中只有一个数据库连接实例。
///
/// [主要功能]
/// - 初始化数据库和数据表。
/// - 提供对 `status_records` 表的增删改查（CRUD）方法。
///
/// [未来展望]
/// - 当有新的数据模型和数据表时，可在此文件中添加新的 `_create...Table` 和 CRUD 方法。
/// - 可以增加数据库升级（migration）的逻辑。
///
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:lae_app/models/status_record.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // The init() method for main.dart to call.
  // It simply ensures the database is created.
  Future<void> init() async {
    await database;
    print("Database initialized.");
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lae_database.db');
    return await openDatabase(
      path,
      version: 3, // <-- 1. Bump the version number from 2 to 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // This function creates all tables from scratch.
    await _createTables(db);
  }

  // 3. Create a new _onUpgrade function
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // This logic handles migrating the database when the version number changes.
    if (oldVersion < 2) {
      // If coming from v1, we need to add Reminders and Schedules
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          trigger_rule TEXT NOT NULL,
          repeat_rule TEXT NOT NULL,
          properties TEXT,
          linked_routine_id INTEGER,
          linked_schedule_id INTEGER,
          is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT '计划中',
          linked_quest_id INTEGER,
          linked_objective_internal_id TEXT,
          start_time TEXT,
          end_time TEXT,
          attribute TEXT,
          recurring_rule TEXT,
          notes TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    // 2. Add new logic for upgrading from version 2 to 3
    if (oldVersion < 3) {
      // If coming from v2, we only need to add the new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Quests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          display_id TEXT,
          name TEXT NOT NULL,
          parent_id INTEGER,
          status TEXT NOT NULL DEFAULT '进行中',
          objectives TEXT,
          target_rules TEXT,
          description TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          LAE_id INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Routine_Plan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_name TEXT NOT NULL,
          time_block TEXT NOT NULL,
          linked_quest_id INTEGER,
          start_time TEXT NOT NULL,
          repeat_time TEXT NOT NULL,
          attribute TEXT,
          notes TEXT
        )
      ''');
    }
  }

  // 4. Centralize table creation logic to avoid duplication
  Future<void> _createTables(Database db, {bool ifNotExists = false}) async {
    final ifNotExistsClause = ifNotExists ? 'IF NOT EXISTS' : '';

    await db.execute('''
      CREATE TABLE $ifNotExistsClause status_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordTime TEXT NOT NULL,
        sleepTime TEXT,
        wakeUpTime TEXT,
        sleepQuality REAL,
        laeState REAL,
        exerciseState REAL,
        researchState REAL,
        dietInfo TEXT,
        anxietyLevel REAL,
        overallState REAL,
        remarks TEXT,
        timeToFallAsleep TEXT,
        timeToGetUp TEXT,
        sleepAbnormalities TEXT
      )
    ''');

    // Using the exact schema from your schema.sql file
    await db.execute('''
      CREATE TABLE $ifNotExistsClause Reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        trigger_rule TEXT NOT NULL,
        repeat_rule TEXT NOT NULL,
        properties TEXT,
        linked_routine_id INTEGER,
        linked_schedule_id INTEGER,
        is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $ifNotExistsClause Schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT '计划中',
        linked_quest_id INTEGER,
        linked_objective_internal_id TEXT,
        start_time TEXT,
        end_time TEXT,
        attribute TEXT,
        recurring_rule TEXT,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $ifNotExistsClause Quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        display_id TEXT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        status TEXT NOT NULL DEFAULT '进行中',
        objectives TEXT,
        target_rules TEXT,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        LAE_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $ifNotExistsClause Routine_Plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_name TEXT NOT NULL,
        time_block TEXT NOT NULL,
        linked_quest_id INTEGER,
        start_time TEXT NOT NULL,
        repeat_time TEXT NOT NULL,
        attribute TEXT,
        notes TEXT
      )
    ''');
  }

  Future<void> insertStatusRecord(StatusRecord record) async {
    final db = await database;
    await db.insert(
      'status_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteStatusRecord(int id) async {
    final db = await database;
    return await db.delete(
      'status_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 新增：获取所有状态记录的方法
  // 这个方法应该在这里，作为 DatabaseHelper 类的一部分
  Future<List<StatusRecord>> getAllStatusRecords() async {
    final db = await database;
    // 按记录时间降序排序，最新的记录在最前面
    final List<Map<String, dynamic>> maps = await db.query(
      'status_records',
      orderBy: 'recordTime DESC',
    );

    return List.generate(maps.length, (i) {
      return StatusRecord.fromMap(maps[i]);
    });
  }

  // New generic method to get all records from a table
  Future<List<Map<String, dynamic>>> getRecords(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Add a generic method to replace data in a table, useful for syncing.
  Future<void> replaceAll(String table, List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table); // Clear the table
      for (final record in data) {
        await txn.insert(table, record); // Insert new data
      }
    });
  }
}
