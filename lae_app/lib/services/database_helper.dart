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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE status_records(
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
  }

  Future<void> insertStatusRecord(StatusRecord record) async {
    final db = await database;
    await db.insert(
      'status_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
}
