import '../services/db_service.dart';

class RewardService {
  static final DBService _db = DBService.instance;

  /// ✅ Saat beli matcha → saldo berkurang, poin bertambah
  static Future<void> onBuyMatcha(double priceIdr) async {
    final user = await _db.getUserStats();
    double balance = (user['balance'] ?? 0).toDouble();
    int points = (user['points'] ?? 0).toInt();

    // Kurangi saldo & tambah poin
    balance -= priceIdr;
    if (balance < 0) balance = 0; // biar gak minus
    points += 5;

    await _db.updateUserStats(balance: balance, points: points);
  }

  /// ✅ Saat isi jurnal → poin +10
  static Future<void> onJournalAdded() async {
    final user = await _db.getUserStats();
    int points = (user['points'] ?? 0).toInt();
    points += 10;
    await _db.updateUserStats(points: points);
  }

  /// ✅ Tukar poin langsung ke saldo tanpa popup
  /// 1 poin = Rp1.000
  static Future<void> exchangePointsDirect() async {
    final user = await _db.getUserStats();
    double balance = (user['balance'] ?? 0).toDouble();
    int points = (user['points'] ?? 0).toInt();

    if (points <= 0) return; // gak bisa kalau belum ada poin

    balance += points * 1000;
    points = 0;

    await _db.updateUserStats(balance: balance, points: points);
  }
}
