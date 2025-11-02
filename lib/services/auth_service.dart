import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  static Database? _db;
  String? _currentUserId;

  AuthService._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'matchapay.db');
    _db = await openDatabase(path, version: 6);
    return _db!;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// REGISTER USER BARU
  Future<void> register({
    required String id,
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [id],
    );

    if (existing.isNotEmpty) {
      throw Exception('ID sudah digunakan.');
    }

    final hashed = _hashPassword(password);

    await db.insert('users', {
      'user_id': id,
      'name': name,
      'email': email,
      'password': hashed,
      'photo': '',
      'points': 0,
      'balance': 100000,
    });
  }

  /// LOGIN USER
  Future<bool> login(String id, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return false;

    final user = result.first;
    final hashed = _hashPassword(password);

    if (user['password'] == hashed) {
      _currentUserId = user['user_id']?.toString();
      return true;
    }

    return false;
  }

  /// MENDAPATKAN DATA USER SAAT INI
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserId == null) return null;
    final db = await database;

    final result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// UPDATE PROFIL (nama, email, foto)
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? photo,
  }) async {
    final db = await database;

    await db.update(
      'users',
      {'name': name, 'email': email, 'photo': photo ?? ''},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// LOGOUT USER
  void logout() {
    _currentUserId = null;
  }

  /// CEK LOGIN
  bool isLoggedIn() => _currentUserId != null;
}
