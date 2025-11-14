import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ubah Foto Profil',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.camera_alt_rounded,
                    title: 'Ambil Foto dengan Kamera',
                    subtitle: 'Foto selfie atau gambar baru',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildOptionItem(
                    icon: Icons.photo_library_rounded,
                    title: 'Pilih dari Galeri',
                    subtitle: 'Pilih foto dari perangkat Anda',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Hapus foto (jika ada foto profil)
                  if (_authController.userPhotoUrl.value != null &&
                      _authController.userPhotoUrl.value!.isNotEmpty)
                    _buildOptionItem(
                      icon: Icons.delete_rounded,
                      title: 'Hapus Foto Profil',
                      subtitle: 'Kembali ke foto default',
                      color: const Color(0xFFF44336),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showDeleteConfirmation();
                      },
                    ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Text(
                'Pilih salah satu opsi di atas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // 1. Minta Izin
      PermissionStatus status;
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        status = await Permission.photos.request();
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

      // 2. Ambil Gambar
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        // 3. Tampilkan Preview & Edit Options
        await _showImagePreviewAndEdit(File(pickedFile.path));
      }
    } catch (e) {
      Logger().e("Gagal mengambil gambar: $e");
      Get.snackbar(
        'Error',
        'Gagal mengambil gambar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showImagePreviewAndEdit(File imageFile) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview & Edit Foto',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),

            // Edit Options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEditOption(
                    icon: Icons.crop_rotate_rounded,
                    label: 'Crop & Rotate',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _cropImage(imageFile);
                    },
                  ),
                  _buildEditOption(
                    icon: Icons.rotate_right_rounded,
                    label: 'Rotate',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _rotateImage(imageFile);
                    },
                  ),
                  _buildEditOption(
                    icon: Icons.check_rounded,
                    label: 'Gunakan',
                    onTap: () {
                      Navigator.of(context).pop();
                      _uploadImage(imageFile);
                    },
                    isPrimary: true,
                  ),
                ],
              ),
            ),

            // Cancel Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      EasyLoading.show(status: 'Mengupload foto...');

      final result = await _authController.uploadProfilePicture(imageFile);

      EasyLoading.dismiss();

      if (result['success'] == true) {
        Get.snackbar(
          'Sukses',
          result['message'] ?? 'Foto profil berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      EasyLoading.dismiss();
      Logger().e("Gagal upload gambar: $e");
      Get.snackbar(
        'Error',
        'Gagal mengupload gambar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildEditOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPrimary ? hijauGojek : Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: hijauGojek.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              color: isPrimary ? Colors.white : hijauGojek,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 12,
            color: isPrimary ? hijauGojek : Colors.grey.shade700,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _cropImage(File imageFile) async {
    try {
      EasyLoading.show(status: 'Memproses gambar...');

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Foto',
            toolbarColor: hijauGojek,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: hijauGojek,
          ),
          IOSUiSettings(
            title: 'Edit Foto',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetButtonHidden: false,
            rotateButtonsHidden: false,
          ),
        ],
      );

      EasyLoading.dismiss();

      if (croppedFile != null) {
        await _showImagePreviewAndEdit(File(croppedFile.path));
      }
    } catch (e) {
      EasyLoading.dismiss();
      Logger().e("Gagal crop gambar: $e");
      Get.snackbar(
        'Error',
        'Gagal mengedit gambar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rotateImage(File imageFile) async {
    try {
      EasyLoading.show(status: 'Memutar gambar...');

      // Implementasi rotasi gambar sederhana
      // Untuk rotasi yang lebih advanced, Anda bisa menggunakan package image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Rotate Foto',
            toolbarColor: hijauGojek,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        ],
      );

      EasyLoading.dismiss();

      if (croppedFile != null) {
        await _showImagePreviewAndEdit(File(croppedFile.path));
      }
    } catch (e) {
      EasyLoading.dismiss();
      Logger().e("Gagal rotate gambar: $e");
      Get.snackbar(
        'Error',
        'Gagal memutar gambar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Foto Profil?',
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        content: Text(
          'Foto profil akan dihapus dan diganti dengan inisial nama Anda.',
          style: TextStyle(fontFamily: 'MonaSans', color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'MonaSans',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProfilePicture();
            },
            child: Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'MonaSans',
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfilePicture() async {
    try {
      EasyLoading.show(status: 'Menghapus foto...');

      // ⭐️ Panggil controller untuk hapus foto (DI SINI PERBAIKANNYA) ⭐️
      final result = await _authController.deleteProfilePicture();

      // Cek apakah ada error dari controller
      if (result['success'] == false) {
        throw Exception(result['message']);
      }

      EasyLoading.dismiss();
      Get.snackbar(
        'Sukses',
        result['message'] ?? 'Foto profil berhasil dihapus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        'Gagal menghapus foto: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
