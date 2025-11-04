import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  var isLoading = false.obs;
  var userId = ''.obs;

  // Reactive variables
  var userData = Rxn<NewUserModel>();
  var userName = RxnString();
  var userEmail = RxnString(); // Tambahan untuk menyimpan email

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getString('userid') ?? '';
    userEmail.value = prefs.getString('useremail') ?? '';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userid');
    await prefs.remove('useremail');
    userId.value = '';
    userEmail.value = null;
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

  Future<bool> checkUserInFirestore(String email) async {
    try {
      // Cari user berdasarkan email di collection role
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

      // Check jika user aktif
      if (roleData['active']?.toString().toUpperCase() != 'Y') {
        return false;
      }

      // Simpan user data untuk penggunaan selanjutnya
      userData.value = NewUserModel.fromMap(roleData);
      userName.value = roleData['username']?.toString() ?? '';
      userEmail.value = email;

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
      final tokenValue = _firebaseController.token ?? '';

      // Authenticate dengan LDAP
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

      // Handle empty response (user tidak ditemukan di LDAP)
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

      // Handle case 1: Login failed di LDAP tapi user ada
      if (status == 1 && message.contains('FAILED')) {
        // Check jika user ada di Firestore berdasarkan email
        final userExists = await checkUserInFirestore(ldapEmail);

        if (!userExists) {
          if (!context.mounted) return;
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'User belum terdaftar di aplikasi.',
            type: ContentType.warning,
            top: true,
          );
          return;
        }

        // Verify bypass password
        final isBypassValid = await verifyBypassPassword(password);

        if (!context.mounted) return;
        if (isBypassValid) {
          await _completeLogin(
            userName.value ?? '',
            ldapEmail,
            tokenValue,
            context,
          );
        } else {
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'Password salah.',
            type: ContentType.failure,
            top: true,
          );
        }
        return;
      }

      // Handle case 2: Login success di LDAP
      if (status == 0 && message.contains('SUCCESS')) {
        // Check jika user ada di Firestore berdasarkan email
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

        await _completeLogin(
          userName.value ?? '',
          ldapEmail,
          tokenValue,
          context,
        );
        return;
      }

      if (!context.mounted) return;

      // Handle other cases
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

  Future<void> _completeLogin(
    String username,
    String email,
    String tokenValue,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userid', username);
      await prefs.setString('useremail', email);

      globalVM.username.value = username;

      await _firestore.collection('auth').doc('bisi').update({
        'lastLogin': FieldValue.serverTimestamp(),
        'lastToken': tokenValue,
      });

      _logger.i('Login sukses untuk $username ($email)');

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

      // SIMPAN ke variabel reactive
      userData.value = model;
      userName.value = roleData['username']?.toString() ?? '';
      userEmail.value = roleData['email']?.toString() ?? '';

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
