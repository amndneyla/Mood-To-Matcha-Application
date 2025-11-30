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

  // --- Tambahan untuk foto profil ---
  final ImagePicker _picker = ImagePicker();
  File? _imageFile; // preview lokal setelah pilih foto
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

  // ==== FOTO PROFIL ====

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

      // Simpan ke DB via AuthService (path lokal)
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
          photo: picked.path, // << simpan path foto
        );
        await _loadUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil diperbarui 📸')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Pilih Foto Profil",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
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
                  leading: const Icon(Icons.photo, color: kPrimaryColor),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final user = _user ?? {};
    final name = user['name'] ?? 'Matcha Lover';
    final email = user['email'] ?? '-';
    final photoPath = (user['photo'] ?? '') as String;

    ImageProvider avatarProvider;
    if (_imageFile != null) {
      avatarProvider = FileImage(_imageFile!);
    } else if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      avatarProvider = FileImage(File(photoPath));
    } else {
      avatarProvider = const AssetImage('assets/images/nelaprofile.png');
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 4, 230),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profil 🍃",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ==== FOTO PROFIL INTERAKTIF ====
            Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: avatarProvider,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _showPhotoPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 240, 0, 0),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _savingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),
            _buildTextField(
              controller: _nameC,
              label: "Nama Lengkap",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailC,
              label: "Email",
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 30),
            _buildSaveButton(),
            const SizedBox(height: 14),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: kTextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 0, 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: Colors.green.shade200,
        elevation: 3,
      ),
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.save_alt, color: Colors.white),
      label: Text(
        _saving ? "Menyimpan..." : "Simpan Perubahan 🍵",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.white),
      label: Text(
        "Keluar",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
