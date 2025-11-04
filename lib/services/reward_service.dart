import '../services/db_service.dart';

class RewardService {
  static final DBService _db = DBService.instance;

  static Future<void> onBuyMatcha(double priceIdr) async {
    final user = await _db.getUserStats();
    double balance = (user['balance'] ?? 0).toDouble();
    int points = (user['points'] ?? 0).toInt();

    balance -= priceIdr;
    if (balance < 0) balance = 0;
    points += 5;

    await _db.updateUserStats(balance: balance, points: points);
  }

  static Future<void> onJournalAdded() async {
    final user = await _db.getUserStats();
    int points = (user['points'] ?? 0).toInt();
    points += 10;
    await _db.updateUserStats(points: points);
  }

  static Future<void> exchangePointsDirect() async {
    final user = await _db.getUserStats();
    double balance = (user['balance'] ?? 0).toDouble();
    int points = (user['points'] ?? 0).toInt();

    if (points <= 0) return;

    balance += points * 1000;
    points = 0;

    await _db.updateUserStats(balance: balance, points: points);
  }
}
