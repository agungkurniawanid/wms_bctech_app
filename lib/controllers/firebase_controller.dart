// [FILE LENGKAP: firebase_controller.dart]

import 'dart:async';

import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/pages/auth/login_page.dart';

class FirebaseController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  String? token;
  StreamSubscription? _sessionListener; // Untuk mendengarkan status sesi

  // --- FUNGSI BARU UNTUK MEMASTIKAN TOKEN ADA ---
  /// Fungsi ini akan mengambil token jika belum ada, atau mengembalikan yang sudah ada.
  Future<String?> getValidToken() async {
    // 1. Jika token sudah ada, langsung kembalikan
    if (token != null && token!.isNotEmpty) {
      _logger.i('Menggunakan token yang sudah ada.');
      return token;
    }

    // 2. Jika token belum ada, panggil inisialisasi dan tunggu
    _logger.w('Token belum ada. Menjalankan inisialisasi/pengambilan token...');
    await initializeFirebaseMessaging();

    // 3. Kembalikan token (bisa jadi masih null jika gagal)
    return token;
  }
  // --- BATAS FUNGSI BARU ---

  Future<void> initializeFirebaseMessaging() async {
    // Jika sudah inisialisasi, tidak perlu diulang
    if (_isInitialized) return;

    try {
      await _firebaseMessaging.requestPermission();
      await _getFirebaseToken(); // Panggil fungsi internal untuk mengisi token
      _isInitialized = true;
      _logger.i("Firebase Messaging initialized successfully");

      // Listener untuk notifikasi saat aplikasi di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.d('Pesan diterima di foreground: ${message.data}');
        // Jika Anda mengimplementasikan push notif untuk "kick"
        if (message.data['type'] == 'SESSION_KICK') {
          _logger.w('Menerima notifikasi SESSION_KICK!');
          _handleSessionKick();
        }
      });
    } catch (e) {
      _logger.e("Error initializing Firebase Messaging: $e");
      _isInitialized = false;
    }
  }

  Future<void> _getFirebaseToken() async {
    try {
      token = await _firebaseMessaging.getToken();
      _logger.i("Firebase Token: $token");
    } catch (e) {
      _logger.e("Error getting Firebase token: $e");
      token = null; // Pastikan null jika gagal
    }
  }

  // --- FUNGSI HELPER UNTUK DEVICE ID ---
  Future<String?> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // ID unik dan konsisten di Android
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // Unik per aplikasi per vendor
      }
      _logger.w('Platform tidak diketahui, tidak bisa dapat Device ID');
      return null;
    } catch (e) {
      _logger.e('Error getting device ID: $e');
      return null;
    }
  }

  // --- FUNGSI BARU UNTUK MENDENGARKAN SESI ---
  Future<void> startSessionListener() async {
    final deviceId = await _getDeviceId();
    if (deviceId == null) {
      _logger.e('Tidak bisa memulai session listener: Device ID null');
      return;
    }

    _logger.d('Memulai session listener untuk device: $deviceId');

    // Batalkan listener lama jika ada
    await _sessionListener?.cancel();

    // Buat listener baru ke dokumen sesi perangkat ini
    _sessionListener = _firestore
        .collection('auth')
        .doc('bisi')
        .collection('active_sessions')
        .doc(deviceId) // Dengarkan hanya dokumen device ini
        .snapshots()
        .listen(
          (snapshot) {
            // Jika dokumen tidak ada (dihapus oleh login baru), berarti kita sudah di-kick
            if (!snapshot.exists) {
              _logger.w(
                'Sesi untuk device $deviceId tidak ditemukan (dihapus). Sesi dihentikan.',
              );
              _handleSessionKick();
            }
          },
          onError: (error) {
            _logger.e('Error pada session listener: $error');
          },
        );
  }

  // --- FUNGSI BARU UNTUK STOP LISTENER ---
  Future<void> stopSessionListener() async {
    await _sessionListener?.cancel();
    _sessionListener = null;
    _logger.d('Session listener dihentikan.');
  }

  // --- FUNGSI BARU UNTUK MENANGANI KICK ---
  void _handleSessionKick() {
    // Hentikan listener agar tidak memicu ulang
    stopSessionListener();

    // Panggil fungsi logout dari AuthController (pastikan sudah di-Get.find)
    if (Get.isRegistered<NewAuthController>()) {
      final NewAuthController authController = Get.find<NewAuthController>();
      // Panggil logout HANYA jika pengguna masih login
      if (authController.userId.value.isNotEmpty) {
        authController.logout(); // Hapus data login lokal
        _logger.i('Logout lokal dipicu oleh session kick.');
      }
    }

    // Tampilkan dialog dan paksa ke halaman login
    // Pastikan Get.context tidak null
    if (Get.context != null) {
      // Tutup semua dialog/snackbar yang mungkin terbuka
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text('Sesi Berakhir'),
            ],
          ),
          content: const Text(
            'Akun Anda telah login di perangkat lain. Sesi di perangkat ini telah dihentikan.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Gunakan Get.offAll untuk membersihkan stack navigasi
                Get.offAll(() => const LoginPage());
              },
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }
}
