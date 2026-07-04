import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/record.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'insulin_rates.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER,
        pumpPosition TEXT,
        planName TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE rate_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordId INTEGER,
        startTime TEXT,
        endTime TEXT,
        oldValue REAL,
        newValue REAL,
        FOREIGN KEY(recordId) REFERENCES records(id) ON DELETE CASCADE
      )
    ''');
  }

  // 插入记录
  Future<int> insertRecord(RateRecord record, List<RateEntry> rates) async {
    final database = await db;
    int recordId = 0;
    await database.transaction((txn) async {
      recordId = await txn.insert('records', record.toMap());
      for (var rate in rates) {
        await txn.insert('rate_entries', {
          'recordId': recordId,
          'startTime': rate.startTime,
          'endTime': rate.endTime,
          'oldValue': rate.oldValue,
          'newValue': rate.newValue,
        });
      }
    });
    return recordId;
  }

  // 获取所有记录（不含明细）
  Future<List<RateRecord>> getAllRecords() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'records',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => RateRecord.fromMap(maps[i]));
  }

  // 获取单条记录及明细
  Future<RateRecord?> getRecordWithRates(int recordId) async {
    final database = await db;
    final recordMaps = await database.query(
      'records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
    if (recordMaps.isEmpty) return null;
    final record = RateRecord.fromMap(recordMaps.first);
    final rateMaps = await database.query(
      'rate_entries',
      where: 'recordId = ?',
      whereArgs: [recordId],
      orderBy: 'startTime',
    );
    record.rates.addAll(rateMaps.map((m) => RateEntry.fromMap(m)));
    return record;
  }

  // 删除记录
  Future<int> deleteRecord(int id) async {
    final database = await db;
    await database.delete('rate_entries', where: 'recordId = ?', whereArgs: [id]);
    return await database.delete('records', where: 'id = ?', whereArgs: [id]);
  }
}
