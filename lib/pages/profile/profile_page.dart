import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/pages/auth/login_page.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final NewAuthController _authController = Get.find<NewAuthController>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  // --- TAMBAHAN: Untuk Image Picker ---
  final ImagePicker _picker = ImagePicker();
  // --- BATAS TAMBAHAN ---

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _authController.getUserData();
    } catch (e) {
      debugPrint("Failed to load user data: $e");
    }
  }

  Future<void> _refreshData() async {
    try {
      debugPrint("Refreshing profile data...");
      await _loadUserData();
      await Future.delayed(const Duration(seconds: 1));
      debugPrint("Profile data refreshed successfully");
    } catch (e) {
      debugPrint("Error refreshing profile data: $e");
      Get.snackbar(
        'Error',
        'Gagal memuat ulang data',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  // [FILE: profile_page.dart]
  // GANTI SELURUH fungsi _buildProfileHeader dengan kode ini

  Widget _buildProfileHeader(double fem, double ffem) {
    return Obx(() {
      final username =
          _authController.userName.value ?? _authController.userId.value;
      final email = _authController.userEmail.value ?? '';
      final isActive = _authController.userData.value?.active == 'Y';
      final photoUrl = _authController.userPhotoUrl.value; // URL foto profil

      final String firstLetter = username.isNotEmpty
          ? username[0].toUpperCase()
          : 'U';

      // Tentukan isi avatar (foto atau inisial)
      Widget profileContent;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        // Jika ada URL foto, tampilkan foto profil
        profileContent = CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator(color: Colors.white)),
          errorWidget: (context, url, error) =>
              Center(child: Icon(Icons.error, color: Colors.white)),
        );
      } else {
        // Jika tidak ada foto, tampilkan huruf inisial
        profileContent = Center(
          child: Text(
            firstLetter,
            style: TextStyle(
              fontFamily: 'MonaSans',
              fontSize: 42 * ffem,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        height: 280 * fem,
        padding: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [hijauGojek, hijauGojek.withValues(alpha: 0.9)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40 * fem),
            bottomRight: Radius.circular(40 * fem),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50 * fem,
              top: -50 * fem,
              child: Container(
                width: 200 * fem,
                height: 200 * fem,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- ⭐️ AVATAR (foto atau inisial) ---
                  Stack(
                    children: [
                      Container(
                        width: 120 * fem,
                        height: 120 * fem,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hijauGojek,
                          border: Border.all(
                            color: Colors.white,
                            width: 3 * fem,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8 * fem,
                              offset: Offset(0, 4 * fem),
                            ),
                          ],
                        ),
                        child: ClipOval(child: profileContent),
                      ),
                      // Tombol Edit (ikon pensil)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: Container(
                            width: 36 * fem,
                            height: 36 * fem,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: hijauGojek, width: 2),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: hijauGojek,
                              size: 20 * fem,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // --- ⭐️ BLOK DUPLIKAT SUDAH DIHAPUS ---
                  SizedBox(height: 16 * fem),
                  Text(
                    TextHelper.formatUserName(username),
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 24 * ffem,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4 * fem),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 14 * ffem,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.only(top: 8 * fem),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * fem,
                      vertical: 4 * fem,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12 * fem),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 12 * ffem,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUserInfoSection(double fem, double ffem) {
    return Obx(() {
      final username =
          _authController.userName.value ?? _authController.userId.value;
      final email = _authController.userEmail.value ?? '';
      final userData = _authController.userData.value;
      final isActive = userData?.active == 'Y';

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16 * fem),
        padding: EdgeInsets.all(16 * fem),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * fem),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8 * fem,
              offset: Offset(0, 2 * fem),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Informasi Pengguna',
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontSize: 18 * ffem,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: _triggerRefresh,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: hijauGojek,
                    size: 20 * ffem,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 40 * fem,
                    minHeight: 40 * fem,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * fem),
            _buildInfoItem(
              fem,
              ffem,
              Icons.person_outline,
              'Username',
              username,
            ),
            if (email.isNotEmpty)
              _buildInfoItem(fem, ffem, Icons.email_outlined, 'Email', email),
            _buildInfoItem(
              fem,
              ffem,
              Icons.verified_user_outlined,
              'Status',
              isActive ? 'Aktif' : 'Tidak Aktif',
            ),
            if (userData?.updatedby != null && userData!.updatedby.isNotEmpty)
              _buildInfoItem(
                fem,
                ffem,
                Icons.update_outlined,
                'Terakhir Diupdate Oleh',
                userData.updatedby,
              ),
            if (userData?.updated != null && userData!.updated.isNotEmpty)
              _buildInfoItem(
                fem,
                ffem,
                Icons.calendar_today_outlined,
                'Terakhir Diupdate',
                userData.updated,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAccessListSection(double fem, double ffem) {
    return Obx(() {
      final accessList = _authController.userData.value?.inList ?? [];

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16 * fem),
        padding: EdgeInsets.all(16 * fem),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * fem),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8 * fem,
              offset: Offset(0, 2 * fem),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: hijauGojek,
                  size: 20 * ffem,
                ),
                SizedBox(width: 8 * fem),
                Text(
                  'Lokasi Perusahaan',
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontSize: 18 * ffem,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12 * fem),
            if (accessList.isEmpty)
              Container(
                padding: EdgeInsets.all(16 * fem),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8 * fem),
                ),
                child: Center(
                  child: Text(
                    'Tidak ada akses aplikasi',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 14 * ffem,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ...accessList.map(
                (access) => _buildAccessItem(fem, ffem, access),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAccessItem(double fem, double ffem, String access) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8 * fem),
      padding: EdgeInsets.all(12 * fem),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8 * fem),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4 * fem,
            height: 24 * fem,
            decoration: BoxDecoration(
              color: hijauGojek,
              borderRadius: BorderRadius.circular(2 * fem),
            ),
          ),

          SizedBox(width: 12 * fem),
          Expanded(
            child: Text(
              access,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 12 * ffem,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.verified_outlined, color: Colors.green, size: 16 * ffem),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    double fem,
    double ffem,
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8 * fem),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: hijauGojek, size: 20 * ffem),
          SizedBox(width: 12 * fem),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontSize: 12 * ffem,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 2 * fem),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontSize: 14 * ffem,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(20 * fem, 0, 20 * fem, 16 * fem),
      child: Material(
        borderRadius: BorderRadius.circular(16 * fem),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * fem),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xfff44236).withValues(alpha: 0.1),
                const Color(0xfff44236).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xfff44236).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(16 * fem),
            splashColor: const Color(0xfff44236).withValues(alpha: 0.2),
            highlightColor: const Color(0xfff44236).withValues(alpha: 0.1),
            child: Container(
              padding: EdgeInsets.all(10 * fem),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44 * fem,
                        height: 44 * fem,
                        decoration: BoxDecoration(
                          color: const Color(0xfff44236).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xfff44236,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: const Color(0xfff44236),
                          size: 20 * ffem,
                        ),
                      ),

                      SizedBox(width: 16 * fem),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keluar Akun',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 16 * ffem,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xfff44236),
                              letterSpacing: -0.5,
                            ),
                          ),

                          SizedBox(height: 2 * fem),
                          Text(
                            'Keluar dari aplikasi',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12 * ffem,
                              fontWeight: FontWeight.w400,
                              color: const Color(
                                0xfff44236,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Container(
                    width: 32 * fem,
                    height: 32 * fem,
                    decoration: BoxDecoration(
                      color: const Color(0xfff44236).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xfff44236),
                      size: 14 * ffem,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualRefreshButton(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(20 * fem, 0, 20 * fem, 16 * fem),
      child: Material(
        borderRadius: BorderRadius.circular(16 * fem),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * fem),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                hijauGojek.withValues(alpha: 0.1),
                hijauGojek.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: hijauGojek.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: _triggerRefresh,
            borderRadius: BorderRadius.circular(16 * fem),
            splashColor: hijauGojek.withValues(alpha: 0.2),
            highlightColor: hijauGojek.withValues(alpha: 0.1),
            child: Container(
              padding: EdgeInsets.all(10 * fem),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44 * fem,
                        height: 44 * fem,
                        decoration: BoxDecoration(
                          color: hijauGojek.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hijauGojek.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: hijauGojek,
                          size: 20 * ffem,
                        ),
                      ),

                      SizedBox(width: 16 * fem),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refresh Data',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 16 * ffem,
                              fontWeight: FontWeight.w600,
                              color: hijauGojek,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2 * fem),
                          Text(
                            'Muat ulang data profil',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12 * ffem,
                              fontWeight: FontWeight.w400,
                              color: hijauGojek.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Container(
                    width: 32 * fem,
                    height: 32 * fem,
                    decoration: BoxDecoration(
                      color: hijauGojek.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: hijauGojek,
                      size: 14 * ffem,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xfff44236).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 40,
                      color: Color(0xfff44236),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Keluar Aplikasi?',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Apakah Anda yakin ingin keluar dari aplikasi? '
                    'Anda perlu login kembali untuk menggunakan aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.grey[50],
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // 1. Tutup dialog dulu
                            Navigator.of(context).pop();

                            // 2. Tampilkan loading
                            EasyLoading.show(status: 'Logging out...');

                            // 3. Panggil fungsi logout dari controller
                            // (Ini akan menghapus sesi di Firestore & SharedPreferences)
                            await _authController.logout();

                            // 4. Tutup loading
                            EasyLoading.dismiss();

                            // 5. Navigasi ke halaman Login
                            // Gunakan Get.offAll agar stack navigasi bersih
                            Get.offAll(() => const LoginPage());
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xfff44236),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  fontFamily: 'MonaSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        color: hijauGojek,
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        displacement: 40.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(fem, ffem),
                const SizedBox(height: 24),
                _buildUserInfoSection(fem, ffem),
                const SizedBox(height: 16),
                _buildAccessListSection(fem, ffem),
                const SizedBox(height: 24),
                _buildLogoutButton(fem, ffem),
                _buildManualRefreshButton(fem, ffem),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: hijauGojek,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: hijauGojek),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ⭐️ FUNGSI BARU: Mengambil dan Meng-upload gambar ⭐️ ---
  Future<void> _pickImage(ImageSource source) async {
    // 1. Minta Izin
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      Get.snackbar(
        'Izin Ditolak',
        'Izin ${source == ImageSource.camera ? "kamera" : "galeri"} diperlukan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // 2. Ambil Gambar
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Kompresi gambar
        maxWidth: 800, // Resize gambar
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // 3. Tampilkan Loading
        EasyLoading.show(status: 'Mengupload foto...');

        // 4. Panggil Controller untuk Upload
        final result = await _authController.uploadProfilePicture(imageFile);

        EasyLoading.dismiss();

        if (result['success'] == true) {
          Get.snackbar(
            'Sukses',
            result['message'] ?? 'Foto profil berhasil diperbarui',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      Logger().e("Gagal mengambil gambar: $e");
      Get.snackbar(
        'Error',
        'Gagal memproses gambar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
