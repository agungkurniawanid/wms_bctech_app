import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/request_model.dart';
import 'package:logger/logger.dart';

class CategoryVM extends GetxController {
  Config config = Config();
  var tolistCategory = <Category>[].obs;
  var isLoading = true.obs;

  Future<dynamic> getcategory(int userid, String role) async {
    try {
      isLoading.value = true;

      final data = RequestWorkflow()
        ..userid = userid
        ..role = role;

      final client = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);

      final String url = await config.url('getinventorygroup');
      final request = await client
          .postUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 90));

      request.headers
        ..set('content-type', 'application/json')
        ..set('Authorization', config.apiKey);

      request.add(utf8.encode(toJsonCategory(data)));

      final response = await request.close();
      final reply = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 && reply.isNotEmpty) {
        final list = json.decode(reply) as List;
        final List<Category> resList = list
            .map((i) => Category.fromJson(i))
            .toList();

        await DatabaseHelper.db.clearCategories();

        for (final category in resList) {
          await DatabaseHelper.db.insertCategory(category.toJson());
        }

        tolistCategory.value = resList;
        return resList;
      } else {
        Logger().w("Server returned ${response.statusCode}");
        return <Category>[];
      }
    } on TimeoutException catch (e) {
      Logger().e('Timeout: $e');
      return 'Koneksi error';
    } on SocketException catch (e) {
      Logger().e('Socket: $e');
      return 'Koneksi error';
    } on HttpException catch (e) {
      Logger().e('HTTP: $e');
      return 'Koneksi error';
    } catch (e) {
      Logger().e('General error: $e');
      return 'Koneksi error';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Method untuk mendapatkan kategori dari database lokal
  Future<void> getCategoriesFromLocal() async {
    try {
      isLoading.value = true;
      List<Category> categories = await DatabaseHelper.db.getCategories();
      tolistCategory.value = categories;
    } catch (e, stackTrace) {
      Logger().e('Error fetching categories: $e');
      Logger().e(stackTrace.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void clearData() {
    tolistCategory.clear();
    isLoading.value = true;
  }
}

String toJsonCategory(RequestWorkflow data) {
  return json.encode({'userid': data.userid, 'role': data.role});
}
