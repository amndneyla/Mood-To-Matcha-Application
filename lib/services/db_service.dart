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
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
        date TEXT,
        user_id TEXT,
        image_url TEXT
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
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN user_id TEXT');
      } catch (_) {}

      try {
        await db.execute('ALTER TABLE journals ADD COLUMN user_id TEXT');
      } catch (_) {}

      await db.update('orders', {'user_id': '0000'});
      await db.update('journals', {'user_id': '0000'});
    }
    if (oldV < 12) {
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN image_url TEXT');
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> login(String id, String password) async {
    final db = await database;
    final hash = _hashPassword(password);
    final res = await db.query(
      'users',
      where: 'user_id = ? AND password = ?',
      whereArgs: [id, hash],
    );

    if (res.isEmpty) return null;

    await db.update('users', {'is_logged_in': 0});

    await db.update(
      'users',
      {'is_logged_in': 1},
      where: 'user_id = ?',
      whereArgs: [id],
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
    await db.update('users', {'is_logged_in': 0});
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
    final user = await getLoggedInUser();

    if (user == null) {
      return {
        'name': 'Matcha Lover',
        'points': 0,
        'balance': 0,
        'email': 'default@matcha.com',
      };
    }

    return user;
  }

  Future<void> addPoints(int points) async {
    final db = await database;
    final user = await getLoggedInUser();

    if (user == null) return;

    final userId = user['user_id'];

    await db.update(
      'users',
      {'points': (user['points'] ?? 0) + points},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> addBalance(int amount) async {
    final db = await database;
    final user = await getLoggedInUser();

    if (user == null) return;

    final userId = user['user_id'];

    await db.rawUpdate(
      'UPDATE users SET balance = balance + ? WHERE user_id = ?',
      [amount, userId],
    );
  }

  Future<void> deductBalance(int amount) async {
    final db = await database;
    final user = await getLoggedInUser();

    if (user == null) return;

    final userId = user['user_id'];

    await db.rawUpdate(
      'UPDATE users SET balance = balance - ? WHERE user_id = ?',
      [amount, userId],
    );
  }

  Future<void> resetPoints() async {
    final db = await database;
    final user = await getLoggedInUser();

    if (user == null) return;

    final userId = user['user_id'];

    await db.update(
      'users',
      {'points': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> convertPointsToBalance() async {
    final user = await getLoggedInUser();

    if (user == null) {
      throw Exception('User tidak ditemukan.');
    }

    final points = (user['points'] ?? 0) as int;
    if (points <= 0) throw Exception('Belum ada poin untuk dikonversi.');

    final db = await database;
    final userId = user['user_id'];
    final currentBalance = (user['balance'] ?? 0) as int;

    await db.update(
      'users',
      {'balance': currentBalance + (points * 1000), 'points': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserStats({double? balance, int? points}) async {
    final db = await database;
    final user = await getLoggedInUser();

    if (user == null) return;

    final userId = user['user_id'];
    final currentBalance = balance ?? (user['balance'] ?? 0).toDouble();
    final currentPoints = points ?? (user['points'] ?? 0).toInt();

    await db.update(
      'users',
      {'balance': currentBalance.toInt(), 'points': currentPoints},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> addOrder(
    Drink drink,
    int price,
    String currency, {
    double? lat,
    double? long,
  }) async {
    final db = await database;

    final user = await getLoggedInUser();
    if (user == null) {
      throw Exception('User tidak ditemukan. Silakan login ulang.');
    }

    final userId = user['user_id'];
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
      'user_id': userId,
      'image_url': drink.imageUrl,
    });

    await addPoints(5);
    await deductBalance(price);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;

    final user = await getLoggedInUser();
    if (user == null) return [];

    final userId = user['user_id'];

    return await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> addJournal(JournalEntry j) async {
    final db = await database;

    final user = await getLoggedInUser();
    if (user == null) {
      throw Exception('User tidak ditemukan. Silakan login ulang.');
    }

    final userId = user['user_id'];

    try {
      Future.microtask(() async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS journals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            note TEXT,
            created_at TEXT,
            created_local TEXT,
            zone TEXT,
            user_id TEXT
          )
        ''');
      });
    } catch (_) {}

    int id = await db.insert('journals', {
      'title': j.title,
      'note': j.note,
      'created_at': j.createdAt,
      'created_local': j.createdLocal,
      'zone': j.zone,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await addPoints(10);

    print("✅ Berhasil simpan jurnal dengan ID: $id");
    return id;
  }

  Future<List<JournalEntry>> getAllJournals() async {
    final db = await database;

    final user = await getLoggedInUser();
    if (user == null) return [];

    final userId = user['user_id'];

    final result = await db.query(
      'journals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_local DESC',
    );

    return result.map((e) => JournalEntry.fromMap(e)).toList();
  }

  Future<List<JournalEntry>> getJournalsByDate(DateTime dayLocal) async {
    final db = await database;

    final user = await getLoggedInUser();
    if (user == null) return [];

    final userId = user['user_id'];

    final startLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final endLocal = startLocal.add(const Duration(days: 1));

    final result = await db.query(
      'journals',
      where: 'user_id = ? AND created_local >= ? AND created_local < ?',
      whereArgs: [
        userId,
        startLocal.toIso8601String(),
        endLocal.toIso8601String(),
      ],
      orderBy: 'created_local DESC',
    );

    return result.map((e) => JournalEntry.fromMap(e)).toList();
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
