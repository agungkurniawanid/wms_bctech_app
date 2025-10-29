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

class StockCheckVM extends GetxController {
  Config config = Config();
  var tolistforscan = <StockModel>[].obs;
  var toliststock = <StockModel>[].obs;
  var toliststockhistory = <StockModel>[].obs;
  var stockhistory = <StockModel>[].obs;

  Rx<List<StockModel>> stocklist = Rx<List<StockModel>>([]);
  List<StockModel> stockModellocal = [];
  List<StockModel> stockModellocalout = [];
  List<StockModel> stockforhistory = [];

  var isLoading = true.obs;
  var datetimenow = DateTime.now().obs;
  var firstdate = DateTime.now().obs;
  var choicesr = "".obs;
  var lastdate = DateTime.now().obs;
  var isLoadingPDF = true.obs;
  var isSearch = true.obs;
  var isIconSearchint = 0.obs;
  var isIconSearch = true.obs;
  var pdfFile = Rx<dynamic>(null);
  var pdfBytes = Rx<dynamic>(null);
  var pdfDir = ''.obs;
  var tutorialRecent = true.obs;
  String username = "";

  @override
  void onReady() async {
    stocklist.bindStream(listStock());
  }

  Stream<List<StockModel>> listStock() {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      return FirebaseFirestore.instance
          .collection('STOCK')
          .doc(today)
          .collection('header')
          .snapshots()
          .map((QuerySnapshot query) {
            stockModellocal = [];
            stockModellocalout = [];
            stockforhistory = [];
            tolistforscan.value = [];
            toliststock.value = [];
            toliststockhistory.value = [];

            for (var stock in query.docs) {
              final returnstock = StockModel.fromDocumentSnapshot(stock);

              if (returnstock.isApprove == "N") {
                stockModellocal.add(returnstock);
                stockModellocalout.add(returnstock);
              }
            }

            for (var stock in stockModellocalout) {
              stock.detail?.sort(
                (a, b) => (b.stockTotal ?? 0).compareTo(a.stockTotal ?? 0),
              );
            }

            stockModellocalout.sort(
              (a, b) => (b.updatedAt ?? '').compareTo(a.updatedAt ?? ''),
            );

            tolistforscan.assignAll(stockModellocal);
            toliststock.assignAll(stockModellocalout);
            isLoading.value = false;

            return toliststock;
          });
    } catch (e) {
      Logger().e('Error in listStock: $e');
      isLoading.value = false;
      return Stream.value([]);
    }
  }

  Future<void> sendtohistory(
    StockModel stockModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      var today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      String todayString = DateFormat('yyyy-MM-dd').format(today);
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      var username = await DatabaseHelper.db.getUser();

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
      Logger().e('Error in sendtohistory: $e');
    }
  }

  Future<dynamic> refreshstock(StockModel stockmodel) async {
    try {
      RequestWorkflow data = RequestWorkflow();
      data.documentno = stockmodel.location;

      EasyLoading.showProgress(
        0.3,
        status: 'Call WS',
        maskType: EasyLoadingMaskType.black,
      );

      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

      HttpClientRequest request = await client
          .postUrl(Uri.parse(await config.url('getrefreshstockcheck')))
          .timeout(Duration(seconds: 90));
      request.headers.set('content-type', 'application/json');
      request.headers.set('Authorization', config.apiKey);
      request.add(utf8.encode(toJsonRefreshStock(data)));

      HttpClientResponse response = await request.close();
      var reply = await response.transform(utf8.decoder).join();

      EasyLoading.showProgress(
        0.5,
        status: 'Return WS',
        maskType: EasyLoadingMaskType.black,
      );

      switch (response.statusCode) {
        case 200:
          EasyLoading.dismiss();
          if (reply.isNotEmpty) {
            // Process successful response
            return true;
          } else {
            return false;
          }
        case 400:
          return "Approval Gagal Error 400";
        case 401:
          return "Approval Gagal Error 401";
        case 403:
          return "Approval Gagal Error 403";
        case 504:
          return "Approval Gagal Error 504";
        case 500:
          return "Approval Gagal Error 500";
        default:
          return "Approval Gagal";
      }
    } on TimeoutException catch (e) {
      EasyLoading.dismiss();
      Logger().e('Timeout in refreshstock: $e');
      return "Timeout Error";
    } catch (e) {
      EasyLoading.dismiss();
      Logger().e('Error in refreshstock: $e');
      return false;
    }
  }

  Future<void> approveall(StockModel stockmodel, String flag) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final DocumentReference documentReference = FirebaseFirestore.instance
          .collection('STOCK')
          .doc(today)
          .collection('header')
          .doc(stockmodel.recordid);

      await documentReference.update({
        "isapprove": "Y",
        "updated": stockmodel.updated,
        "updatedby": stockmodel.updatedby,
      });
    } catch (e) {
      Logger().e('Error in approveall: $e');
    }
  }

  Future<void> approvestock(
    StockModel stockModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('STOCK')
          .doc(today)
          .collection('header')
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
      Logger().e('Error in approvestock: $e');
    }
  }

  String dateToString(String date) {
    try {
      final format = DateFormat('dd-MM-yyyy');
      final dateTime = DateTime.parse(date);
      return format.format(dateTime);
    } catch (e) {
      Logger().e('Error in dateToString: $e');
      return date;
    }
  }

  // Helper method untuk konversi ke JSON (asumsi ada di file terpisah)
  String toJsonRefreshStock(RequestWorkflow data) {
    return jsonEncode(data.toJsonRefreshStock());
  }
}
