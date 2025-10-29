import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart' as db;
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/request_model.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'package:logger/logger.dart';

class WeborderVM extends GetxController {
  final Config config = Config();

  final tolistWO = <OutModel>[].obs;
  final tolistwoout = <OutModel>[].obs;
  final wolist = Rx<List<OutModel>>([]);

  List<OutModel> outmodellocal = [];
  List<OutModel> outmodellocalout = [];

  final isLoading = true.obs;
  final datetimenow = DateTime.now().obs;
  final firstdate = DateTime.now().obs;
  final lastdate = DateTime.now().obs;
  final isLoadingPDF = true.obs;
  final sortVal = "Location".obs;
  final sortValSR = "Request Date".obs;
  final isSearch = true.obs;
  final intlistwo = 0.obs;
  final isIconSearch = true.obs;
  final pdfFile = Rx<dynamic>(null);
  final pdfBytes = Rx<dynamic>(null);
  final pdfDir = ''.obs;
  final tutorialRecent = true.obs;
  final choiceWO = "".obs;
  final choiceout = "".obs;

  @override
  void onReady() {
    super.onReady();
    wolist.bindStream(listWO());
  }

  Stream<List<OutModel>> listWO() {
    try {
      tolistWO.clear();
      tolistwoout.clear();

      final h1 = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day - 1,
      );
      final h1string = DateFormat('yyyy-MM-dd').format(h1);

      return FirebaseFirestore.instance
          .collection('WO')
          .doc(GlobalVar.choicecategory)
          .collection('headerdetail')
          .where('delivery_date', isGreaterThanOrEqualTo: h1string)
          .snapshots()
          .map((QuerySnapshot query) {
            outmodellocal = [];
            outmodellocalout = [];

            for (var doc in query.docs) {
              final outModel = OutModel.fromDocumentSnapshot(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              );

              if (outmodellocal.length < 10) {
                outmodellocal.add(outModel);
              }
              outmodellocalout.add(outModel);
            }

            tolistwoout.value = outmodellocalout;
            tolistWO.value = outmodellocal;
            intlistwo.value = tolistwoout.length;
            isLoading.value = false;

            return tolistwoout;
          });
    } catch (e) {
      Logger().e(e);
      return Stream.value([]);
    }
  }

  Future<dynamic> getlistwo(int userid) async {
    try {
      final data = RequestWorkflow(userid: userid);
      final client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

      final request = await client
          .postUrl(Uri.parse(await config.url('getweborderheader')))
          .timeout(const Duration(seconds: 90));

      request.headers.set('content-type', 'application/json');
      request.headers.set('Authorization', config.apiKey());
      request.add(utf8.encode(toJsonCategory(data)));

      final response = await request.close();
      final reply = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 && reply.isNotEmpty) {
        final list = json.decode(reply) as List;
        final resList = list.map((i) => OutModel.fromJson(i)).toList();

        for (final outModel in resList) {
          await db.DatabaseHelper.db.insertOut(outModel);
        }
      }

      return <Category>[];
    } on TimeoutException catch (e) {
      Logger().e(e);
      return 'Koneksi error';
    } catch (e) {
      Logger().e(e);
      return 'Koneksi error';
    }
  }
}
