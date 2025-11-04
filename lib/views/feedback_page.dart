import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Kesan & Pesan 💚',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🌿 Ilustrasi atas
            Container(
              height: 160,
              width: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDFF4E0),
              ),
              child: const Icon(
                Icons.emoji_emotions_rounded,
                size: 80,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Terima Kasih 💚",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Sedikit cerita tentang pengalaman belajar Flutter dan membangun Mood To Matcha 🍵",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: kSubtitleColor),
            ),

            const SizedBox(height: 24),

            // 📝 Kartu kesan dan pesan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "✨ Mata kuliah *Pemrograman Aplikasi Mobile* memberikan pengalaman luar biasa dalam membangun aplikasi lintas platform menggunakan Flutter.\n\n"
                "Saya belajar banyak tentang pengelolaan state, integrasi API, database lokal (SQLite), penggunaan LBS, hingga implementasi notifikasi yang membuat aplikasi terasa lebih hidup.\n\n"
                "Mood To Matcha 🍵 bukan sekadar tugas — tapi juga refleksi perjalanan belajar saya, di mana kode dan kreativitas bertemu jadi satu harmoni yang hijau dan menenangkan.",
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.6,
                  color: kTextColor,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "“Setiap baris kode adalah secangkir matcha — tenang, fokus, dan penuh makna.” 🍵",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kPrimaryColor,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
