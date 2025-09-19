import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';


class FoodDatabase {
  static final FoodDatabase instance = FoodDatabase._init();
  static Database? _database;

  FoodDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE food_log(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      food TEXT NOT NULL,
      intake REAL NOT NULL,
      calories REAL NOT NULL,
      carbs REAL NOT NULL,
      protein REAL NOT NULL,
      fat REAL NOT NULL
    )
  ''');
  }

  Future<FoodItem> create(FoodItem food) async {
    final db = await instance.database;
    final id = await db.insert('food', food.toMap());
    return food..id = id;
  }

  Future<List<FoodItem>> readAllFoods() async {
    final db = await instance.database;
    final orderBy = 'name ASC';
    final result = await db.query('food', orderBy: orderBy);
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  // ---------- Food Log Functions ----------
  Future<FoodLog> createLog(FoodLog log) async {
    final db = await instance.database;
    final id = await db.insert('food_log', log.toMap());
    return log..id = id;
  }

  Future<List<FoodLog>> readLogsByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'food_log',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((json) => FoodLog.fromMap(json)).toList();
  }

  Future<List<FoodLog>> readLogsByWeek(List<String> dates) async {
    final db = await instance.database;
    final result = await db.query(
      'food_log',
      where: 'date IN (${dates.map((_) => '?').join(',')})',
      whereArgs: dates,
    );
    return result.map((json) => FoodLog.fromMap(json)).toList();
  }


  Future<List<FoodLog>> readLogsByDateRange(String startDate, String endDate) async {
  final db = await instance.database;

  final result = await db.query(
    'food_logs',
    where: 'date BETWEEN ? AND ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date ASC',
  );

  return result.map((e) => FoodLog.fromMap(e)).toList();
}


  Future close() async {
    final db = await instance.database;
    db.close();
  }


}
