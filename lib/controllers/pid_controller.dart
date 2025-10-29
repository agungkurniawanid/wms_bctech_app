import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/models/request_model.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logger/logger.dart';

class PidViewModel extends GetxController {
  final Config config = Config();
  final tolistforscan = <StockModel>[].obs;
  final tolistpid = <StockModel>[].obs;
  final toliststockhistory = <StockModel>[].obs;
  final stockhistory = <StockModel>[].obs;
  final stocklist = Rx<List<StockModel>>([]);
  final isLoading = true.obs;
  final datetimenow = DateTime.now().obs;
  final firstdate = DateTime.now().obs;
  final choicesr = ''.obs;
  final lastdate = DateTime.now().obs;
  final isLoadingPDF = true.obs;
  final isSearch = true.obs;
  final isIconSearchint = 0.obs;
  final isIconSearch = true.obs;
  final pdfFile = Rx<dynamic>(null);
  final pdfBytes = Rx<dynamic>(null);
  final pdfDir = ''.obs;
  final tutorialRecent = true.obs;
  final countedstring = ''.obs;
  final _stockModelLocal = <StockModel>[];
  final _stockModelLocalOut = <StockModel>[];
  final _stockForHistory = <StockModel>[];

  late String username;

  @override
  void onReady() async {
    username = await DatabaseHelper.db.getUser() ?? '';
    stocklist.bindStream(listPID());
  }

  Stream<List<StockModel>> listPID() {
    try {
      return FirebaseFirestore.instance.collection('PID').snapshots().map((
        QuerySnapshot query,
      ) {
        _clearLocalLists();

        for (final stock in query.docs) {
          final stockModel = StockModel.fromDocumentSnapshot(stock);
          _categorizeStock(stockModel);
        }

        _processAndSortStocks();
        isLoading.value = false;
        return tolistpid;
      });
    } catch (e) {
      Logger().e('Error in listPID: $e');
      return Stream.value([]);
    }
  }

  void _clearLocalLists() {
    _stockModelLocal.clear();
    _stockModelLocalOut.clear();
    _stockForHistory.clear();
    tolistforscan.clear();
    tolistpid.clear();
    toliststockhistory.clear();
  }

  void _categorizeStock(StockModel stockModel) {
    if (stockModel.isApprove == "Counted") {
      _stockModelLocal.add(stockModel);
    } else {
      _stockModelLocalOut.add(stockModel);
    }
  }

  void _processAndSortStocks() {
    _stockModelLocalOut.addAll(_stockModelLocal);
    _stockModelLocalOut.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    tolistpid.assignAll(_stockModelLocalOut);
  }

  Future<void> sendToHistory(
    StockModel stockModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final todayString = DateFormat('yyyy-MM-dd').format(today);
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);

      await FirebaseFirestore.instance
          .collection('HISTORY')
          .doc(username)
          .collection(todayString)
          .doc(stockModel.recordid)
          .set({
            'recordid': stockModel.recordid,
            'color': stockModel.color,
            'created': stockModel.created,
            'createdby': stockModel.createdby,
            'orgid': stockModel.orgid,
            'updated': formattedDate,
            'updatedby': stockModel.updatedby,
            'location': stockModel.location,
            'formatted_updated_at': stockModel.formattedUpdatedAt,
            'isapprove': stockModel.isApprove,
            'location_name': stockModel.locationName,
            'updated_at': stockModel.updatedAt,
            'clientid': stockModel.clientid,
            'sync': stockModel.isSync,
            'doctype': stockModel.doctype,
            'detail': tdata,
          });
    } catch (e) {
      Logger().e('Error in sendToHistory: $e');
    }
  }

  Future<dynamic> refreshStock(StockModel stockModel) async {
    try {
      final data = RequestWorkflow()..documentno = stockModel.location;

      await EasyLoading.showProgress(
        0.3,
        status: 'Call WS',
        maskType: EasyLoadingMaskType.black,
      );

      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      final request = await client
          .postUrl(Uri.parse(await config.url('getrefreshpid')))
          .timeout(const Duration(seconds: 90));

      request.headers.set('content-type', 'application/json');
      request.headers.set('Authorization', config.apiKey);
      request.add(utf8.encode(toJsonRefreshStock(data)));

      final response = await request.close();
      final reply = await response.transform(utf8.decoder).join();

      await EasyLoading.showProgress(
        0.5,
        status: 'Return WS',
        maskType: EasyLoadingMaskType.black,
      );

      switch (response.statusCode) {
        case 200:
          await EasyLoading.dismiss();
          return reply.isNotEmpty;
        case 400:
          return "Approval Gagal Error 400";
        case 401:
          return "Approval Gagal Error 401";
        case 403:
          return "Approval Gagal Error 403";
        case 500:
          return "Approval Gagal Error 500";
        case 504:
          return "Approval Gagal Error 504";
        default:
          return "Approval Gagal";
      }
    } on TimeoutException catch (e) {
      await EasyLoading.dismiss();
      Logger().e('Timeout in refreshStock: $e');
      return "Timeout Error";
    } catch (e) {
      await EasyLoading.dismiss();
      Logger().e('Error in refreshStock: $e');
      return false;
    }
  }

  Future<void> approveAll(
    StockModel stockModel,
    String flag,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('PID')
          .doc(stockModel.recordid)
          .set({
            'recordid': stockModel.recordid,
            'color': stockModel.color,
            'created': stockModel.created,
            'createdby': stockModel.createdby,
            'orgid': stockModel.orgid,
            'updated': today,
            'updatedby': stockModel.updatedby,
            'location': stockModel.location,
            'formatted_updated_at': stockModel.formattedUpdatedAt,
            'isapprove': stockModel.isApprove,
            'location_name': stockModel.locationName,
            'updated_at': stockModel.updatedAt,
            'clientid': stockModel.clientid,
            'sync': stockModel.isSync,
            'doctype': stockModel.doctype,
            'detail': tdata,
          });
    } catch (e) {
      Logger().e('Error in approveAll: $e');
    }
  }

  Future<String> counted() async {
    final year = '${DateFormat('yyyy').format(DateTime.now())}-';

    try {
      final query = await FirebaseFirestore.instance
          .collection('COUNTED')
          .doc(year)
          .get();

      if (query.exists) {
        final data = query.data() as Map<String, dynamic>;
        final documentno = data['documentno'] as String? ?? '';

        if (documentno.isEmpty) {
          countedstring.value = '${year}100000001';
        } else {
          final documentint = int.parse(documentno.substring(5)) + 1;
          countedstring.value = '$year$documentint';
        }
      } else {
        countedstring.value = '${year}100000001';
      }

      return countedstring.value;
    } catch (e) {
      Logger().e('Error in counted: $e');
      countedstring.value = '${year}100000001';
      return countedstring.value;
    }
  }

  Future<void> sendCounted(String documentno) async {
    try {
      final year = '${DateFormat('yyyy').format(DateTime.now())}-';

      await FirebaseFirestore.instance.collection('COUNTED').doc(year).set({
        'documentno': documentno,
      });
    } catch (e) {
      Logger().e('Error in sendCounted: $e');
    }
  }

  Future<void> approveStock(
    StockModel stockModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('PID')
          .doc(stockModel.recordid)
          .set({
            'recordid': stockModel.recordid,
            'color': stockModel.color,
            'created': stockModel.created,
            'createdby': stockModel.createdby,
            'orgid': stockModel.orgid,
            'updated': today,
            'updatedby': stockModel.updatedby,
            'location': stockModel.location,
            'formatted_updated_at': stockModel.formattedUpdatedAt,
            'isapprove': stockModel.isApprove,
            'location_name': stockModel.locationName,
            'updated_at': stockModel.updated,
            'clientid': stockModel.clientid,
            'sync': stockModel.isSync,
            'doctype': stockModel.doctype,
            'detail': tdata,
          });
    } catch (e) {
      Logger().e('Error in approveStock: $e');
    }
  }

  String dateToString(String date) {
    final format = DateFormat('dd-MM-yyyy');
    final dateTime = DateTime.parse(date);
    return format.format(dateTime);
  }
}
