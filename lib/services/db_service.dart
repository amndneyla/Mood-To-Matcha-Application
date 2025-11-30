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

    final db = await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    final existing = await db.query('users');
    if (existing.isEmpty) {
      await db.insert('users', {
        'user_id': '0000',
        'name': 'Matcha Lover',
        'email': 'default@matcha.com',
        'password': _hashPassword('matcha'),
        'photo': '',
        'points': 0,
        'balance': 100000,
        'is_logged_in': 0,
      });
    }

    // FIX: Jurnal lama yang belum punya user_id → dianggap milik user default
    await db.rawUpdate(
      "UPDATE journals SET user_id = '0000' WHERE user_id IS NULL OR user_id = ''",
    );

    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE,
        name TEXT,
        email TEXT,
        password TEXT,
        photo TEXT,
        points INTEGER DEFAULT 0,
        balance INTEGER DEFAULT 0,
        is_logged_in INTEGER DEFAULT 0
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
        created_at TEXT,
        created_local TEXT,
        zone TEXT,
        user_id TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN photo TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
    }
    if (oldV < 7) {
      try {
        await db.execute('ALTER TABLE journals ADD COLUMN created_local TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE journals ADD COLUMN zone TEXT');
      } catch (_) {}
    }
    if (oldV < 8) {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_user_id ON users(user_id)',
      );
    }
    if (oldV < 9) {
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_logged_in INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldV < 11) {
      await db.execute('ALTER TABLE journals ADD COLUMN user_id TEXT');
    }
  }

  Future<Map<String, dynamic>?> login(String id, String password) async {
    final db = await database;
    final hash = _hashPassword(password.trim());
    final res = await db.query(
      'users',
      where: 'user_id = ? AND password = ?',
      whereArgs: [id.trim(), hash],
    );

    if (res.isEmpty) return null;

    await db.rawUpdate('UPDATE users SET is_logged_in = 0');
    await db.update(
      'users',
      {'is_logged_in': 1},
      where: 'user_id = ?',
      whereArgs: [id.trim()],
    );

    return res.first;
  }

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await database;
    final res = await db.query('users', where: 'is_logged_in = 1');
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> logout() async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET is_logged_in = 0');
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final res = await db.query('users', where: 'user_id = ?', whereArgs: [id]);
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
      whereArgs: [id.trim()],
    );
    if (existing.isNotEmpty) return false;

    final hashedPassword = _hashPassword(password.trim());
    await db.insert('users', {
      'user_id': id.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'password': hashedPassword,
      'photo': '',
      'points': 0,
      'balance': 0,
      'is_logged_in': 0,
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
    final logged = await db.query('users', where: 'is_logged_in = 1');

    if (logged.isNotEmpty) return logged.first;

    final f = await db.query('users', limit: 1);
    return f.first;
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
    if (points <= 0) throw Exception();
    await addBalance(points * 1000);
    await resetPoints();
  }

  Future<void> updateUserStats({double? balance, int? points}) async {
    final db = await database;
    final u = await getUserStats();
    final cb = (u['balance'] ?? 0).toDouble();
    final cp = (u['points'] ?? 0).toInt();
    await db.update('users', {
      'balance': balance ?? cb,
      'points': points ?? cp,
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
    final u = await getUserStats();
    final cb = (u['balance'] ?? 0) as int;
    if (cb < price) throw Exception();
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
    return await db.insert(
      'journals',
      j.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<JournalEntry>> getAllJournals() async {
    final db = await database;
    final r = await db.query('journals', orderBy: 'created_local DESC');
    return r.map((e) => JournalEntry.fromMap(e)).toList();
  }

  Future<List<JournalEntry>> getJournalsByDate(DateTime d) async {
    final db = await database;
    final user = await getLoggedInUser();
    if (user == null) return [];

    final uid = user['user_id'];

    final s = DateTime(d.year, d.month, d.day);
    final e = s.add(const Duration(days: 1));

    final r = await db.query(
      'journals',
      where: 'user_id = ? AND created_local >= ? AND created_local < ?',
      whereArgs: [uid, s.toIso8601String(), e.toIso8601String()],
      orderBy: 'created_local DESC',
    );

    return r.map((e) => JournalEntry.fromMap(e)).toList();
  }

  Future<void> deleteJournal(int id) async {
    final db = await database;
    await db.delete('journals', where: 'id = ?', whereArgs: [id]);
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
