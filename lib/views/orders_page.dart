import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../utils/constants.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DBService.instance.getOrders();
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        title: Text(
          'Riwayat Pembelian',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _orders.isEmpty
          ? Center(
              child: Text(
                'Belum ada pembelian.',
                style: GoogleFonts.poppins(color: kSubtitleColor),
              ),
            )
          : ListView.separated(
              itemCount: _orders.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = _orders[i];
                final date = DateTime.tryParse(o['date'] ?? '')?.toLocal();
                final when = date == null
                    ? '-'
                    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}  •  ${date.day}/${date.month}/${date.year}';
                final price = o['price'] ?? 0;
                final currency = (o['currency'] ?? 'IDR')
                    .toString()
                    .toUpperCase();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: kPrimaryColor,
                      child: Icon(Icons.local_cafe, color: Colors.white),
                    ),
                    title: Text(
                      o['drink_name'] ?? '-',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      when,
                      style: GoogleFonts.poppins(
                        color: kSubtitleColor,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      currency == 'IDR' ? 'Rp$price' : '$price $currency',
                      style: GoogleFonts.poppins(
                        color: kAccentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
