import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/drink_model.dart';
import '../models/journal_model.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('matchapay.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        name TEXT,
        email TEXT,
        password TEXT,
        photo TEXT,
        points INTEGER DEFAULT 0,
        balance INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drink_name TEXT,
        price INTEGER,
        currency TEXT,
        lat REAL,
        long REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE journals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        note TEXT,
        created_at TEXT
      )
    ''');

    await db.insert('users', {
      'user_id': '0000',
      'name': 'Matcha Lover',
      'email': 'default@matcha.com',
      'password': _hashPassword('matcha'),
      'photo': '',
      'points': 0,
      'balance': 100000,
    });
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN photo TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
    }
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final res = await db.query('users', where: 'user_id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> login(String id, String password) async {
    final db = await database;
    final hash = _hashPassword(password);
    final res = await db.query(
      'users',
      where: 'user_id = ? AND password = ?',
      whereArgs: [id, hash],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<bool> registerUser(
    String id,
    String name,
    String email,
    String password,
  ) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty) return false;
    await db.insert('users', {
      'user_id': id,
      'name': name,
      'email': email,
      'password': _hashPassword(password),
      'photo': '',
      'points': 0,
      'balance': 100000,
    });
    return true;
  }

  Future<void> updateUserProfile(
    String id,
    String name,
    String email,
    String? photo,
  ) async {
    final db = await database;
    await db.update(
      'users',
      {'name': name, 'email': email, 'photo': photo ?? ''},
      where: 'user_id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    if (result.isEmpty) {
      await db.insert('users', {
        'user_id': '0000',
        'name': 'Matcha Lover',
        'email': 'default@matcha.com',
        'password': _hashPassword('matcha'),
        'photo': '',
        'points': 0,
        'balance': 100000,
      });
      return {
        'name': 'Matcha Lover',
        'points': 0,
        'balance': 100000,
        'email': 'default@matcha.com',
      };
    }
    return result.first;
  }

  Future<void> addPoints(int points) async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET points = points + ?', [points]);
  }

  Future<void> addBalance(int amount) async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET balance = balance + ?', [amount]);
  }

  Future<void> deductBalance(int amount) async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET balance = balance - ?', [amount]);
  }

  Future<void> resetPoints() async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET points = 0');
  }

  Future<void> convertPointsToBalance() async {
    final u = await getUserStats();
    final points = (u['points'] ?? 0) as int;
    if (points <= 0) throw Exception('Belum ada poin untuk dikonversi.');
    await addBalance(points * 1000);
    await resetPoints();
  }

  Future<void> updateUserStats({double? balance, int? points}) async {
    final db = await database;
    final user = await getUserStats();
    final currentBalance = (user['balance'] ?? 0).toDouble();
    final currentPoints = (user['points'] ?? 0).toInt();
    await db.update('users', {
      'balance': balance ?? currentBalance,
      'points': points ?? currentPoints,
    });
  }

  Future<void> addOrder(
    Drink drink,
    int price,
    String currency, {
    double? lat,
    double? long,
  }) async {
    final db = await database;
    final user = await getUserStats();
    final currentBalance = (user['balance'] ?? 0) as int;
    if (currentBalance < price) {
      throw Exception('Saldo tidak cukup untuk membeli matcha ini.');
    }
    await db.insert('orders', {
      'drink_name': drink.name,
      'price': price,
      'currency': currency,
      'lat': lat,
      'long': long,
      'date': DateTime.now().toUtc().toIso8601String(),
    });
    await addPoints(5);
    await deductBalance(price);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'date DESC');
  }

  Future<int> addJournal(JournalEntry j) async {
    final db = await database;
    final id = await db.insert('journals', j.toMap());
    await addPoints(10);
    return id;
  }

  Future<List<JournalEntry>> getAllJournals() async {
    final db = await database;
    final result = await db.query('journals', orderBy: 'created_at DESC');
    return result.map((e) => JournalEntry.fromMap(e)).toList();
  }

  Future<List<JournalEntry>> getJournalsByDate(DateTime dayLocal) async {
    final db = await database;
    final startLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final startUtc = startLocal.toUtc().toIso8601String();
    final endUtc = endLocal.toUtc().toIso8601String();
    final result = await db.query(
      'journals',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startUtc, endUtc],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => JournalEntry.fromMap(e)).toList();
  }

  Future<void> resetDatabase() async {
    final path = join(await getDatabasesPath(), 'matchapay.db');
    await deleteDatabase(path);
    _database = null;
    await database;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
