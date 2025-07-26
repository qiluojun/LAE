///
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

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/status_record.dart';

class DatabaseHelper {
  // 单例模式，确保全局只有一个实例
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static const String _dbName = 'lae_database.db';
  static const String _statusRecordTable = 'status_records';

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 创建数据表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_statusRecordTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordTime TEXT NOT NULL,
        sleepTime TEXT NOT NULL,
        wakeUpTime TEXT NOT NULL,
        sleepQuality INTEGER NOT NULL,
        laeState INTEGER NOT NULL,
        exerciseState INTEGER NOT NULL,
        researchState INTEGER NOT NULL,
        dietInfo TEXT NOT NULL,
        anxietyLevel REAL NOT NULL,
        overallState REAL NOT NULL,
        remarks TEXT
      )
    ''');
  }

  /// 插入一条状态记录
  /// 返回插入行的ID
  Future<int> insertStatusRecord(StatusRecord record) async {
    Database db = await instance.database;
    return await db.insert(_statusRecordTable, record.toMap());
  }

  // 未来可以添加更多方法，例如：
  // Future<List<StatusRecord>> getAllStatusRecords() async { ... }
  // Future<int> updateStatusRecord(StatusRecord record) async { ... }
  // Future<int> deleteStatusRecord(int id) async { ... }
}
