import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService.instance;
  Map<String, dynamic>? _user;
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _savingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameC.text = user?['name'] ?? '';
      _emailC.text = user?['email'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    setState(() => _saving = true);

    await _auth.updateProfile(
      userId: _user!['user_id'] ?? _user!['id'].toString(),
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
    );

    await _loadUser();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui ✅')),
      );
    }

    setState(() => _saving = false);
  }

  void _logout() {
    _auth.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _savingPhoto = true;
      });

      final u = _user ?? await _auth.getCurrentUser();

      if (u != null) {
        await _auth.updateProfile(
          userId: u['user_id'] ?? u['id'].toString(),
          name: _nameC.text.trim().isEmpty
              ? (u['name'] ?? '')
              : _nameC.text.trim(),
          email: _emailC.text.trim().isEmpty
              ? (u['email'] ?? '')
              : _emailC.text.trim(),
          photo: picked.path,
        );

        await _loadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil diperbarui 📸')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    } finally {
      setState(() => _savingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "Pilih Foto Profil",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: Text(
                    "Ambil dari Kamera",
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.green),
                  title: Text(
                    "Pilih dari Galeri",
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌼 UI
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final user = _user ?? {};
    final name = user['name'] ?? 'Matcha Lover';
    final email = user['email'] ?? '-';
    final photoPath = user['photo'] ?? "";

    ImageProvider avatarProvider;

    if (_imageFile != null) {
      avatarProvider = FileImage(_imageFile!);
    } else if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      avatarProvider = FileImage(File(photoPath));
    } else {
      avatarProvider = const AssetImage('assets/images/default.jpg');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),

      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Profil",
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(
              Icons.logout,
              color: const Color.fromARGB(255, 253, 253, 253),
            ),
            tooltip: "Keluar",
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // FOTO PROFIL PREMIUM
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200,
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundImage: avatarProvider,
                  ),
                ),

                Positioned(
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _showPhotoPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade900.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _savingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.green.shade900.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 35),

            // CARD PUTIH PRETTY AESTHETIC
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.75,
                ), // putih tulang transparan
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameC,
                    label: "Nama Lengkap",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _emailC,
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 28),
                  _buildSaveButton(),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // CREDIT SECTION
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  Text(
                    "Dibuat oleh:",
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade900.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "• Amanda Neyla Rusy Diyana – 124230044\n"
                    "• Lulu Mustafiyah – 124230040",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ================= TEXTFIELD PREMIUM =================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(
        color: Colors.green.shade900,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.green.shade800),
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade700, width: 1),
        ),
      ),
    );
  }

  // ================= BUTTON SIMPAN =================
  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_alt),
      label: Text(
        _saving ? "Menyimpan..." : "Simpan Perubahan 🍃",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}
