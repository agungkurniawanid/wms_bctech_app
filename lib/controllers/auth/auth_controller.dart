// [FILE LENGKAP: auth_controller.dart]

import 'dart:convert';
import 'dart:io' show File, Platform; // <-- PASTIKAN IMPORT INI ADA
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart'; // <-- PASTIKAN IMPORT INI ADA
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wms_bctech/constants/app_constant.dart';
import 'package:wms_bctech/controllers/connectivity_controller.dart';
import 'package:wms_bctech/controllers/firebase_controller.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/models/user/user_model.dart';
import 'package:wms_bctech/pages/app_bottom_navigation_page.dart';
import 'package:wms_bctech/pages/auth/login_page.dart';
import 'package:wms_bctech/components/awesome_snackbar_widget.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewAuthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final ConnectivityController _connectivityController =
      ConnectivityController();
  final FirebaseController _firebaseController = FirebaseController();
  final globalVM = Get.find<GlobalVM>();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- TAMBAHAN UNTUK DEVICE ID ---
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  // --- BATAS TAMBAHAN ---

  var isLoggingOut = false.obs;

  var isLoading = false.obs;
  var userId = ''.obs;
  var userData = Rxn<NewUserModel>();
  var userName = RxnString();
  var userEmail = RxnString();
  var userPhotoUrl = RxnString();

  // --- FUNGSI BARU UNTUK MENDAPATKAN DEVICE ID ---
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // ID unik dan konsisten di Android
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ??
            'ios_device_error'; // Unik per aplikasi per vendor
      }
      return 'unknown_platform';
    } catch (e) {
      _logger.e('Error getting device ID: $e');
      return 'device_error';
    }
  }
  // --- BATAS FUNGSI BARU ---

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getString('userid') ?? '';
    userEmail.value = prefs.getString('useremail') ?? '';
    userPhotoUrl.value = prefs.getString('photo_url');
  }

  Future<void> logout() async {
    isLoggingOut.value = true;
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getDeviceId();
    if (deviceId != 'device_error' && deviceId != 'unknown_platform') {
      try {
        await _firebaseController.stopSessionListener();
        await _firestore
            .collection('auth')
            .doc('bisi')
            .collection('active_sessions')
            .doc(deviceId)
            .delete();
        _logger.i('Sesi untuk device $deviceId telah dihapus.');
      } catch (e) {
        _logger.e('Gagal menghapus sesi saat logout: $e');
      }
    }
    await prefs.remove('userid');
    await prefs.remove('useremail');
    await prefs.remove('photo_url');
    userId.value = '';
    userEmail.value = null;
  }

  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      // 1. Dapatkan username (yang kita gunakan sebagai ID unik)
      String? username = await getUserId();
      if (username == null || username.isEmpty) {
        throw Exception('Pengguna tidak login');
      }

      _logger.i('Memulai upload foto untuk $username...');

      // 2. Tentukan path di Firebase Storage
      // Ini akan otomatis mereplace file lama jika ada
      final storagePath = 'profile_pictures/$username/profile.jpg';
      final storageRef = _storage.ref().child(storagePath);

      // 3. Upload file
      final uploadTask = await storageRef.putFile(imageFile);
      final newUrl = await uploadTask.ref.getDownloadURL();
      _logger.d('Foto berhasil diupload: $newUrl');

      // 4. Cari Dokumen ID di 'role' berdasarkan username
      final query = await _firestore
          .collection('role')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Dokumen role pengguna tidak ditemukan di Firestore');
      }
      final docId = query.docs.first.id;

      // 5. Update field 'photo_url' di Firestore
      await _firestore.collection('role').doc(docId).update({
        'photo_url': newUrl,
      });
      _logger.d('URL Foto berhasil disimpan ke Firestore');

      // 6. Update state lokal dan SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photo_url', newUrl);
      userPhotoUrl.value = newUrl;
      userData.value?.photoUrl = newUrl; // Update model lokal juga

      return {'success': true, 'message': 'Foto profil berhasil diperbarui'};
    } catch (e) {
      _logger.e('Gagal upload foto profil: $e');
      return {'success': false, 'message': 'Gagal upload foto: $e'};
    }
  }

  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userid');
    } catch (e) {
      _logger.e('Error getting user ID: $e');
      return null;
    }
  }

  Future<void> generateAuthCollectionIfNotExists() async {
    final authDocRef = _firestore.collection('auth').doc('bisi');
    final authDoc = await authDocRef.get();

    if (!authDoc.exists) {
      await authDocRef.set({
        'bypass': AppConstants.defaultBypass,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Auth document "bisi" created');
    } else {
      debugPrint('Auth document "bisi" already exists');
    }
  }

  Future<Map<String, dynamic>?> authenticateWithLdap(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse(AppConstants.ldapCheckUrl);
      final body = jsonEncode({'username': email, 'password': password});

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        if (res.body.isEmpty) {
          return {'status': -1, 'message': 'Empty response'};
        }

        final data = jsonDecode(res.body);
        return data;
      } else {
        debugPrint('LDAP HTTP ${res.statusCode} → ${res.body}');
        return {'status': -1, 'message': 'HTTP ${res.statusCode}'};
      }
    } catch (e) {
      _logger.e('LDAP authentication error: $e');
      return {'status': -1, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      // 1. Dapatkan username
      String? username = await getUserId();
      if (username == null || username.isEmpty) {
        throw Exception('Pengguna tidak login');
      }
      _logger.i('Menghapus foto profil untuk $username...');

      // 2. Hapus file dari Firebase Storage
      final storagePath = 'profile_pictures/$username/profile.jpg';
      final storageRef = _storage.ref().child(storagePath);

      try {
        await storageRef.delete();
        _logger.d('Foto di Storage $storagePath berhasil dihapus.');
      } catch (e) {
        // Jika file tidak ada di storage, jangan setop proses.
        // Tetap lanjutkan untuk menghapus URL dari Firestore.
        _logger.w('Gagal hapus foto di Storage (mungkin sudah tidak ada): $e');
      }

      // 3. Hapus URL dari Firestore (set ke null)
      final query = await _firestore
          .collection('role')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Dokumen role pengguna tidak ditemukan');
      }
      final docId = query.docs.first.id;

      await _firestore.collection('role').doc(docId).update({
        'photo_url': null, // Set ke null akan menghapus field/mengosongkannya
      });
      _logger.d('URL Foto berhasil dihapus dari Firestore');

      // 4. Hapus dari SharedPreferences dan state lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('photo_url');
      userPhotoUrl.value = null; // Set RxnString ke null
      userData.value?.photoUrl = null; // Update model lokal

      return {'success': true, 'message': 'Foto profil berhasil dihapus'};
    } catch (e) {
      _logger.e('Gagal hapus foto profil: $e');
      return {'success': false, 'message': 'Gagal menghapus foto: $e'};
    }
  }

  Future<bool> checkUserInFirestore(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('role')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      final roleDoc = querySnapshot.docs.first;
      final roleData = roleDoc.data();

      if (roleData['active']?.toString().toUpperCase() != 'Y') {
        return false;
      }

      userData.value = NewUserModel.fromMap(roleData);
      userName.value = roleData['username']?.toString() ?? '';
      userEmail.value = email;

      userPhotoUrl.value = roleData['photo_url']?.toString();

      return true;
    } catch (e) {
      _logger.e('Error checking user in Firestore: $e');
      return false;
    }
  }

  Future<bool> verifyBypassPassword(String password) async {
    try {
      final authDoc = await _firestore.collection('auth').doc('bisi').get();
      if (!authDoc.exists) {
        return false;
      }

      final authData = authDoc.data() ?? {};
      final bypass = authData['bypass']?.toString() ?? '';

      return bypass == password;
    } catch (e) {
      _logger.e('Error verifying bypass password: $e');
      return false;
    }
  }

  // --- FUNGSI LOGIN LENGKAP YANG SUDAH DIPERBAIKI ---
  Future<void> loginFunction(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (!await _connectivityController.checkConnection()) {
      if (!context.mounted) return;
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Tidak ada koneksi internet!',
        type: ContentType.failure,
        top: true,
      );
      return;
    }

    EasyLoading.show(status: 'Authenticating...');
    try {
      // 1. Dapatkan info perangkat ini (Perangkat Baru)
      _logger.d('Mencoba mendapatkan FCM token...');
      final String? newToken = await _firebaseController.getValidToken();

      if (newToken == null || newToken.isEmpty) {
        EasyLoading.dismiss();
        if (!context.mounted) return;
        AwesomeSnackbarWidget.show(
          context: context,
          msg: 'Gagal mendapatkan token perangkat. Coba lagi.',
          type: ContentType.failure,
          top: true,
        );
        return;
      }
      _logger.d('FCM Token didapatkan.');
      final String newDeviceId = await _getDeviceId();
      // --- BATAS PERBAIKAN ---

      // 2. Otentikasi LDAP
      final ldapResult = await authenticateWithLdap(email, password);

      if (ldapResult == null) {
        if (!context.mounted) return;
        AwesomeSnackbarWidget.show(
          context: context,
          msg: 'Gagal terhubung ke server.',
          type: ContentType.failure,
          top: true,
        );
        return;
      }

      final status = ldapResult['status'] as int?;
      final message = ldapResult['message']?.toString() ?? '';
      final ldapEmail = ldapResult['email']?.toString() ?? '';

      _logger.i(
        "LDAP response - Status: $status, Message: $message, Email: $ldapEmail",
      );

      if (status == -1 && message == 'Empty response') {
        if (!context.mounted) return;
        AwesomeSnackbarWidget.show(
          context: context,
          msg: 'User tidak ditemukan di sistem.',
          type: ContentType.warning,
          top: true,
        );
        return;
      }

      // 3. Cek apakah login valid (LDAP sukses ATAU Bypass sukses)
      bool isLoginValid = false;
      if (status == 0 && message.contains('SUCCESS')) {
        isLoginValid = true;
      } else if (status == 1 && message.contains('FAILED')) {
        final isBypassValid = await verifyBypassPassword(password);
        if (isBypassValid) {
          isLoginValid = true;
        } else {
          if (!context.mounted) return;
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'Password salah.',
            type: ContentType.failure,
            top: true,
          );
          return;
        }
      }

      // 4. JIKA LOGIN VALID (BAIK LDAP ATAU BYPASS)
      if (isLoginValid) {
        // Cek apakah user terdaftar di 'role' dan 'active'
        final userExists = await checkUserInFirestore(ldapEmail);
        if (!context.mounted) return;

        if (!userExists) {
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'User belum terdaftar di aplikasi.',
            type: ContentType.warning,
            top: true,
          );
          return;
        }

        // --- LOGIKA SINGLE DEVICE LOGIN (PINDAH KE SINI) ---
        _logger.d('Memulai validasi single device...');
        final sessionRef = _firestore
            .collection('auth')
            .doc('bisi')
            .collection('active_sessions');

        // Cek apakah email ini sudah tercatat di sesi lain
        final existingSessionQuery = await sessionRef
            .where('email', isEqualTo: ldapEmail)
            .limit(1)
            .get();

        if (existingSessionQuery.docs.isNotEmpty) {
          // Email ini sudah login di perangkat lain
          final oldSessionDoc = existingSessionQuery.docs.first;
          final oldDeviceId = oldSessionDoc.id;
          final oldFcmToken = oldSessionDoc.data()['fcm_token'] as String?;

          if (oldDeviceId != newDeviceId) {
            // Ini adalah perangkat BARU. Kita harus "menendang" perangkat lama.
            _logger.w(
              'Sesi $ldapEmail ditemukan di device $oldDeviceId. Menendang sesi lama.',
            );

            if (oldFcmToken != null && oldFcmToken.isNotEmpty) {
              // _firebaseController.sendKickNotification(oldFcmToken);
              _logger.d('Mengirim kick-notification ke token: $oldFcmToken');
            }

            // Hapus dokumen sesi lama
            await oldSessionDoc.reference.delete();
            _logger.d('Dokumen sesi lama $oldDeviceId dihapus.');
          } else {
            _logger.d(
              'Device ID sama ($newDeviceId), mengizinkan login ulang.',
            );
          }
        }

        if (!context.mounted) return;

        await _completeLogin(
          userName.value ?? '',
          ldapEmail,
          newToken,
          newDeviceId,
          context,
        );
        return;
      }

      // Jika status tidak diketahui
      if (!context.mounted) return;
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Terjadi kesalahan: $message',
        type: ContentType.failure,
        top: true,
      );
    } catch (e, st) {
      _logger.e('Login error: $e', stackTrace: st);

      if (!context.mounted) return;
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Terjadi kesalahan sistem.',
        type: ContentType.failure,
        top: true,
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  // --- FUNGSI _completeLogin LENGKAP YANG SUDAH DIPERBAIKI ---
  Future<void> _completeLogin(
    String username,
    String email,
    String tokenValue,
    String deviceId, // <-- Terima Device ID
    BuildContext context,
  ) async {
    try {
      isLoggingOut.value = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userid', username);
      await prefs.setString('useremail', email);
      await prefs.setString('photo_url', userPhotoUrl.value ?? '');

      globalVM.username.value = username;

      // --- PERBAIKAN: Simpan sesi ke subkoleksi 'active_sessions' ---
      final sessionDocRef = _firestore
          .collection('auth')
          .doc('bisi')
          .collection('active_sessions')
          .doc(deviceId); // Gunakan deviceId sebagai ID dokumen

      await sessionDocRef.set({
        'email': email,
        'username': username,
        'fcm_token': tokenValue,
        'last_login': FieldValue.serverTimestamp(),
      });

      // Hapus update pada 'auth/bisi' yang lama (jika masih ada)
      // await _firestore.collection('auth').doc('bisi').update({ ... });
      // --- BATAS PERBAIKAN ---

      // --- TAMBAHKAN INI: Mulai mendengarkan sesi ---
      await _firebaseController.startSessionListener();
      // --- BATAS TAMBAHAN ---

      _logger.i('Login sukses untuk $username ($email) di device $deviceId');

      if (!context.mounted) return;
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Login sukses.',
        type: ContentType.success,
        top: true,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppBottomNavigation()),
        );
      }
    } catch (e) {
      _logger.e('Error completing login: $e');
      rethrow;
    }
  }

  Future<NewUserModel?> getUserData() async {
    try {
      await loadUserId();
      final String currentUserId = userId.value;
      if (currentUserId.isEmpty) return null;

      final qs = await _firestore
          .collection('role')
          .where('username', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) return null;

      final roleData = qs.docs.first.data();
      final model = NewUserModel.fromMap(roleData);

      userData.value = model;
      userName.value = roleData['username']?.toString() ?? '';
      userEmail.value = roleData['email']?.toString() ?? '';

      // --- TAMBAHAN: Ambil photo_url ---
      userPhotoUrl.value = roleData['photo_url']?.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photo_url', userPhotoUrl.value ?? '');
      // --- BATAS TAMBAHAN ---

      return model;
    } catch (e) {
      _logger.e('Error getUserData: $e');
      return null;
    }
  }

  void toLogin(BuildContext context) async {
    try {
      var userid = await getUserId();
      if (context.mounted) {
        if (userid == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          globalVM.username.value = userid;
          isLoggingOut.value = false;

          // --- TAMBAHKAN INI: Mulai listener saat auto-login ---
          _firebaseController.startSessionListener();
          // --- BATAS TAMBAHAN ---

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppBottomNavigation()),
          );
        }
      }
    } catch (e) {
      _logger.e('Error in toLogin: $e');
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }
}
