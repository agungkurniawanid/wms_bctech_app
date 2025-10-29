import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/models/user/account_model.dart';
import 'package:wms_bctech/models/request_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/role_controller.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginAPI {
  final Config config = Config();
  final GlobalVM globalVM = Get.find<GlobalVM>();
  final Rolevm roleVM = Get.find<Rolevm>();

  Future<String> signIn({
    required String email,
    required String password,
    String? token,
  }) async {
    try {
      final RequestWorkflow data = RequestWorkflow(
        email: email,
        password: password,
        token: token,
      );

      Logger().e('Token: $token');

      final HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final HttpClientRequest request = await client
          .postUrl(Uri.parse('https://cpma.cp.co.id:3011/api/login'))
          .timeout(const Duration(seconds: 90));

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', config.apiKey);
      request.add(utf8.encode(toJsonLogin(data)));

      final HttpClientResponse response = await request.close();
      final String reply = await response.transform(utf8.decoder).join();

      switch (response.statusCode) {
        case 200:
          final Account jsonData = Account.fromJson(jsonDecode(reply));

          if (jsonData.status == 1) {
            return 'GAGAL';
          } else {
            await saveUser(jsonData);

            roleVM.listrole().listen((roles) {
              Logger().e("Roles data updated: $roles");
            });
          }
          return 'SUKSES';

        case 400:
        case 403:
        case 500:
          return 'Koneksi error';

        case 401:
          return 'NO USER';

        default:
          return 'Koneksi error';
      }
    } on TimeoutException catch (e) {
      Logger().e('Timeout: $e');
      return 'Koneksi error';
    } catch (e) {
      Logger().e('Error: $e');
      return 'Koneksi error';
    }
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userid', userId);
  }

  Future<void> saveUser(Account data) async {
    try {
      await saveUserId(data.userid ?? '');

      globalVM.username.value = data.userid ?? '';

      await FirebaseFirestore.instance
          .collection('user')
          .doc(data.userid)
          .set({
            'userid': data.userid,
            'email': data.email,
            'name': data.name,
            'status': data.status,
          })
          .then((_) {
            Logger().e("Sukses menyimpan user ke Firestore");
          })
          .catchError((err) {
            Logger().e('Error menyimpan user: $err');
          });
    } catch (e) {
      Logger().e('Error saveUser: $e');
    }
  }
}
