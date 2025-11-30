import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/db_service.dart';
import '../models/order_history_model.dart';
import '../utils/constants.dart';
import '../utils/global_currency.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<OrderHistory> _orders = [];
  bool _loading = true;
  String _selectedFilter = "Semua";

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final data = await DBService.instance.getOrders();
    final orderList = data.map((e) => OrderHistory.fromMap(e)).toList();

    setState(() {
      _orders = _filterOrders(orderList);
      _loading = false;
    });
  }

  List<OrderHistory> _filterOrders(List<OrderHistory> orders) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case "Hari Ini":
        return orders.where((o) {
          return o.date.year == now.year &&
              o.date.month == now.month &&
              o.date.day == now.day;
        }).toList();

      case "Minggu Ini":
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return orders.where((o) => o.date.isAfter(startOfWeek)).toList();

      case "Bulan Ini":
        return orders.where((o) {
          return o.date.year == now.year && o.date.month == now.month;
        }).toList();

      default:
        return orders;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Hari ini, ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays == 1) {
      return "Kemarin, ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} hari lalu";
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  int _getTotalSpent() {
    return _orders.fold(0, (sum, order) => sum + order.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Riwayat Pesanan",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : _orders.isEmpty
                ? _buildEmptyView()
                : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text(
            "Total Pesanan",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "${_orders.length} Pesanan",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Total Belanja: ${CurrencyUtils.formatIdr(_getTotalSpent().toDouble())}",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["Semua", "Hari Ini", "Minggu Ini", "Bulan Ini"];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = filters[i];
          final selected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () async {
              setState(() => _selectedFilter = filter);
              await _loadOrders();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kPrimaryColor : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : kTextColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final order = _orders[i];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderHistory order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ FOTO PRODUK
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: order.imageUrl != null && order.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: order.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.green.shade50,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: kPrimaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_cafe,
                        color: kPrimaryColor,
                        size: 30,
                      ),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_cafe,
                      color: kPrimaryColor,
                      size: 30,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.drinkName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(order.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kSubtitleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "+5 Poin",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (order.lat != null && order.long != null) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: kSubtitleColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatIdr(order.price.toDouble()),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada pesanan",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kSubtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Yuk pesan matcha favoritmu!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
