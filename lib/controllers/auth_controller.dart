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
import 'package:wms_bctech/pages/login_page.dart';
import 'package:wms_bctech/widgets/awesome_snackbar_widget.dart';
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

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getString('userid') ?? '';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userid');
    userId.value = '';
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

  Future<String> checkLdap(String username) async {
    final uri = Uri.parse(AppConstants.ldapCheckUrl);
    final body = jsonEncode({'username': username, 'password': ''});

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      } else {
        return 'Unexpected response';
      }
    } else {
      debugPrint('LDAP HTTP ${res.statusCode} → ${res.body}');
      return 'HTTP ${res.statusCode}';
    }
  }

  Future<void> loginFunction(String username, String password, context) async {
    if (!await _connectivityController.checkConnection()) {
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Tidak ada koneksi internet!',
        type: ContentType.success,
        top: true,
      );
      return;
    }

    EasyLoading.show(status: 'Authenticating...');
    try {
      final tokenValue = _firebaseController.token ?? '';

      final ldapRes = await http.post(
        Uri.parse('https://srm.cp.co.id/api/ldap/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': ''}),
      );

      final data = jsonDecode(ldapRes.body);
      final message = data['message']?.toString() ?? '';

      _logger.i("LDAP response: $message (status: ${ldapRes.statusCode})");

      if (message == 'LDAP User is not found') {
        AwesomeSnackbarWidget.show(
          context: context,
          msg: 'User belum terdaftar di LDAP.',
          type: ContentType.warning,
          top: true,
        );
        return;
      }

      if (message == 'Wrong password') {
        final roleDoc = await _firestore.collection('role').doc(username).get();
        if (!roleDoc.exists) {
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'User belum terdaftar di Firestore.',
            type: ContentType.warning,
            top: true,
          );
          return;
        }

        final roleData = roleDoc.data() ?? {};
        if (roleData['active']?.toString().toUpperCase() != 'Y') {
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'User belum aktif.',
            type: ContentType.warning,
            top: true,
          );
          return;
        }

        final authDoc = await _firestore.collection('auth').doc('bisi').get();
        if (!authDoc.exists) {
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'Auth document "bisi" not found.',
            type: ContentType.warning,
            top: true,
          );
          return;
        }

        final authData = authDoc.data() ?? {};
        final bypass = authData['bypass'] ?? '';

        if (bypass == password) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userid', username);

          await _firestore.collection('auth').doc('bisi').update({
            'lastLogin': DateTime.now(),
            'lastToken': tokenValue,
          });

          _logger.i('Login sukses untuk $username');
          AwesomeSnackbarWidget.show(
            context: context,
            msg: 'Login sukses.',
            type: ContentType.success,
            top: true,
          );

          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppBottomNavigation()),
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
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Terjadi kesalahan.',
        type: ContentType.failure,
        top: true,
      );
    } catch (e, st) {
      _logger.e('Login error: $e', stackTrace: st);
      AwesomeSnackbarWidget.show(
        context: context,
        msg: 'Terjadi kesalahan.',
        type: ContentType.failure,
        top: true,
      );
    } finally {
      EasyLoading.dismiss();
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
