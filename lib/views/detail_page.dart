import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drink_model.dart';
import '../services/reward_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../utils/global_currency.dart';
import '../utils/constants.dart';

class DetailPage extends StatefulWidget {
  final Drink drink;
  const DetailPage({super.key, required this.drink});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  double _balance = 0;
  int _points = 0;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DBService.instance.getUserStats();
    if (!mounted) return;
    setState(() {
      _balance = (user['balance'] ?? 0).toDouble();
      _points = (user['points'] ?? 0).toInt();
    });
  }

  Future<void> _buyMatcha() async {
    final priceIdr = CurrencyUtils.usdToIdr(widget.drink.priceUsd);

    if (_balance < priceIdr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saldo kamu tidak cukup 🥺"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isBuying = true);

    await RewardService.onBuyMatcha(priceIdr);
    await _loadUser();

    if (!mounted) return;
    setState(() => _isBuying = false);

    await NotificationService().showMatchaNotification(widget.drink.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pesanan kamu sedang disiapkan 🍵 (+5 poin)",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drink;
    final price = CurrencyUtils.formatIdr(CurrencyUtils.usdToIdr(d.priceUsd));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: Text(
          d.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Gambar minuman
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                d.imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 240,
                  color: Colors.green.shade50,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🍵 Nama dan harga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    d.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🌿 Detail singkat
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip(Icons.category, d.category),
                _infoChip(Icons.mood, d.mood),
                _infoChip(Icons.health_and_safety, d.health),
              ],
            ),

            const SizedBox(height: 20),

            // 📖 Deskripsi
            Text(
              "Deskripsi",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d.description.isEmpty
                  ? "Matcha spesial ini dibuat dengan daun teh pilihan yang lembut dan menenangkan."
                  : d.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kSubtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            // 🛒 Tombol beli
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBuying ? null : _buyMatcha,
                icon: _isBuying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.local_cafe, color: Colors.white),
                label: Text(
                  _isBuying ? "Memproses..." : "Pesan Sekarang",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 💰 Info user
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Saldo kamu: ${CurrencyUtils.formatIdr(_balance)}",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  Text(
                    "Poin kamu: $_points",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryColor, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
