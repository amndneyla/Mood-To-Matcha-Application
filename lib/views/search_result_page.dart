import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drink_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'detail_page.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;
  const SearchResultPage({super.key, required this.keyword});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final ApiService api = ApiService();
  List<Drink> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final all = await api.fetchDrinks();
    final q = widget.keyword.toLowerCase();
    setState(() {
      _results = all
          .where(
            (d) =>
                d.category.toLowerCase().contains(q) ||
                d.name.toLowerCase().contains(q),
          )
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Hasil: ${widget.keyword}",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? Center(
              child: Text(
                "Tidak ada hasil ditemukan.",
                style: GoogleFonts.poppins(color: kSubtitleColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final d = _results[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailPage(drink: d)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        d.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        d.restaurant,
                        style: GoogleFonts.poppins(
                          color: kSubtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
