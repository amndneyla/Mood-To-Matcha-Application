import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/drink_model.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/reward_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/global_currency.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService api = ApiService();
  final DBService db = DBService.instance;

  List<Drink> _all = [];
  List<Drink> _filtered = [];
  bool _loading = true;

  String _userName = "Matcha Lover";
  int _points = 0;
  double _balance = 0;
  String _currentCity = "";
  String _selectedCurrency = "IDR";
  String _selectedMood = "All Mood";

  final MapController _mapController = MapController();
  LatLng? _current;
  LatLng? _saved;
  final TextEditingController _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([_loadUser(), _loadLocation(), _loadDrinks()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    // ambil user login aktif dari AuthService
    final user = await AuthService.instance.getCurrentUser();
    final u = await db.getUserStats();

    if (!mounted) return;
    setState(() {
      _userName = user?['name'] ?? "Matcha Lover";
      _points = (u['points'] ?? 0) as int;
      _balance = (u['balance'] ?? 0).toDouble();
    });
  }

  Future<void> _refreshUser() async {
    final u = await db.getUserStats();
    if (!mounted) return;
    setState(() {
      _points = (u['points'] ?? 0) as int;
      _balance = (u['balance'] ?? 0).toDouble();
    });
  }

  Future<void> _loadDrinks() async {
    try {
      final list = await api.fetchDrinks();
      _all = list;
      _filtered = list;
    } catch (e) {
      debugPrint("Fetch drinks error: $e");
    }
  }

  Future<void> _loadLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied)
        return;

      final pos = await Geolocator.getCurrentPosition();
      _current = LatLng(pos.latitude, pos.longitude);

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _currentCity =
            p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _applyFilter() {
    String q = _searchC.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((d) {
        final matchText =
            d.name.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q) ||
            d.mood.toLowerCase().contains(q);

        final moodMatch =
            _selectedMood == "All Mood" ||
            d.mood.toLowerCase() == _selectedMood.toLowerCase();

        return matchText && moodMatch;
      }).toList();
    });
  }

  Future<void> _exchangePoints() async {
    await RewardService.exchangePointsDirect();
    await _refreshUser();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Poin berhasil ditukar jadi saldo 💸")),
    );
  }

  Future<void> _saveLocation() async {
    if (_current == null) return;
    setState(() => _saved = _current);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lokasi berhasil disimpan 📍")),
    );
  }

  /// ✅ Pindah ke lokasi GPS & update kota
  Future<void> _goToMyLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aktifkan GPS dulu ya 📍")),
        );
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak 🚫")));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newPoint = LatLng(pos.latitude, pos.longitude);
      _mapController.move(newPoint, 13);

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      String city = "";
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city =
            p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? "";
      }

      setState(() {
        _current = newPoint;
        _currentCity = city.isNotEmpty ? city : "Lokasi tidak diketahui";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📍 Lokasi diperbarui: $_currentCity")),
      );
    } catch (e) {
      debugPrint("Error saat goToMyLocation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui lokasi 😞")),
      );
    }
  }

  // HEADER ===========================================================
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF7CA779),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Mood To Matcha 🍵",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Halo, $_userName! 👋",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_currentCity.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                "📍 Kamu lagi di $_currentCity",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),

          // KARTU INFORMASI
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4E0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "Poin",
                      style: GoogleFonts.poppins(
                        color: kSubtitleColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "$_points pts",
                      style: GoogleFonts.poppins(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _exchangePoints,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        color: kAccentColor,
                        size: 24,
                      ),
                      Text(
                        "Tukar",
                        style: GoogleFonts.poppins(
                          color: kAccentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    DropdownButton<String>(
                      value: _selectedCurrency,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: "USD", child: Text("USD")),
                        DropdownMenuItem(value: "IDR", child: Text("IDR")),
                        DropdownMenuItem(value: "JPY", child: Text("JPY")),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCurrency = v);
                      },
                    ),
                    Text(
                      "${CurrencyUtils.symbol(_selectedCurrency)}${CurrencyUtils.format(CurrencyUtils.convertFromIdr(_balance, _selectedCurrency), _selectedCurrency)}",
                      style: GoogleFonts.poppins(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PENCARIAN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchC,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: "Cari matcha, kategori, atau mood...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MAP ===============================================================
  Widget _mapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _current ?? LatLng(-6.2, 106.8),
                  initialZoom: 13,
                  onTap: (tapPos, latlng) async {
                    setState(() => _current = latlng);
                    final placemarks = await placemarkFromCoordinates(
                      latlng.latitude,
                      latlng.longitude,
                    );
                    if (placemarks.isNotEmpty) {
                      final p = placemarks.first;
                      setState(() {
                        _currentCity =
                            p.locality ??
                            p.subAdministrativeArea ??
                            p.administrativeArea ??
                            "Lokasi tidak diketahui";
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'mood_to_matcha',
                  ),
                  if (_current != null || _saved != null)
                    MarkerLayer(
                      markers: [
                        if (_current != null)
                          Marker(
                            width: 50,
                            height: 50,
                            point: _current!,
                            child: const Icon(
                              Icons.location_pin,
                              color: kPrimaryColor,
                              size: 40,
                            ),
                          ),
                        if (_saved != null)
                          Marker(
                            width: 40,
                            height: 40,
                            point: _saved!,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveLocation,
                    icon: const Icon(Icons.save, color: Colors.white, size: 18),
                    label: const Text("Simpan Lokasi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _goToMyLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text("My Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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

  // FILTER MOOD =======================================================
  Widget _moodFilter() {
    final moods = ["All Mood", "Ceria", "Tenang", "Fokus", "Dingin", "Hangat"];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = moods[i];
          final selected = _selectedMood == m;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMood = m);
              _applyFilter();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor),
              ),
              child: Text(
                m,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // GRID ==============================================================
  Widget _gridDrinks() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            "Tidak ada matcha ditemukan 🍵",
            style: GoogleFonts.poppins(color: kSubtitleColor),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid.builder(
        itemCount: _filtered.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (_, i) {
          final d = _filtered[i];
          final price = CurrencyUtils.convertFromIdr(
            d.priceUsd * 16000,
            _selectedCurrency,
          );

          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(drink: d)),
              );
              if (result == true) await _refreshUser();
            },
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: d.imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.green.shade50,
                        child: const Center(
                          child: Icon(Icons.local_cafe, color: Colors.grey),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          d.restaurant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: kSubtitleColor,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          "${CurrencyUtils.symbol(_selectedCurrency)}${CurrencyUtils.format(price, _selectedCurrency)}",
                          style: GoogleFonts.poppins(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // BUILD =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _mapSection()),
            SliverToBoxAdapter(child: _moodFilter()),
            _gridDrinks(),
          ],
        ),
      ),
    );
  }
}
