import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/db_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  String? _currentUserId;

  AuthService._init();

  Future<bool> login(String id, String password) async {
    final db = DBService.instance;
    final user = await db.login(id, password);
    if (user != null) {
      _currentUserId = user['user_id'].toString();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = DBService.instance;
    final user = await db.getLoggedInUser();
    if (user != null) {
      _currentUserId = user['user_id'];
      return user;
    }
    return null;
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? photo,
  }) async {
    final db = DBService.instance;
    await db.updateUserProfile(userId, name, email, photo);
  }

  Future<bool> tryAutoLogin() async {
    final db = DBService.instance;
    final user = await db.getLoggedInUser();
    if (user != null) {
      _currentUserId = user['user_id'];
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final db = DBService.instance;
    await db.logout();
    _currentUserId = null;
  }

  bool isLoggedIn() => _currentUserId != null;
}
