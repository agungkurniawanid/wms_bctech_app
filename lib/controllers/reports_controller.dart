import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/reports_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:intl/intl.dart';

class ReportsVM extends GetxController {
  final Config config = Config();
  final GlobalVM globalvm = Get.find<GlobalVM>();
  final tolisthistory = <ReportsModel>[].obs;
  final tolisthistoryin = <ReportsModel>[].obs;
  final tolisthistoryout = <ReportsModel>[].obs;
  final tolisthistorysc = <ReportsModel>[].obs;
  final tolisthistoryfortotal = <ReportsModel>[].obs;
  final stocklist = Rx<List<ReportsModel>>(<ReportsModel>[]);
  final isLoading = true.obs;
  final isLoadingPDF = true.obs;
  final isSearch = true.obs;
  final isIconSearch = true.obs;
  final isIconSearchint = 0.obs;
  final tutorialRecent = true.obs;
  final datetimenow = DateTime.now().obs;
  final firstdate = DateTime.now().obs;
  final lastdate = DateTime.now().obs;
  final choicedate = ''.obs;
  final choice = ''.obs;
  final choicechip = ''.obs;
  final pdfFile = Rx<dynamic>(null);
  final pdfBytes = Rx<dynamic>(null);
  final pdfDir = ''.obs;

  String? username;
  final listcategory = <Category>[];

  @override
  void onReady() {
    stocklist.bindStream(reports());
    super.onReady();
  }

  Stream<List<ReportsModel>> reports() {
    if (choice.value.isEmpty || choicedate.value.isEmpty) {
      return Stream.value(<ReportsModel>[]);
    }

    switch (choice.value) {
      case 'OT':
        return _getOutTransferReports();
      case 'ALL':
        return _getAllReports();
      default:
        return _getSpecificLocationReports();
    }
  }

  Stream<List<ReportsModel>> _getOutTransferReports() {
    return FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('AB')
        .collection(choicedate.value)
        .snapshots()
        .asyncMap(_processOutTransferData);
  }

  Future<List<ReportsModel>> _processOutTransferData(
    QuerySnapshot query,
  ) async {
    final result = <ReportsModel>[];
    await _processCollection(query, result, filterPallet: true);

    final query2 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('CH')
        .collection(choicedate.value)
        .get();
    await _processCollection(query2, result, filterPallet: true);

    final query3 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('FZ')
        .collection(choicedate.value)
        .get();
    await _processCollection(query3, result, filterPallet: true);

    final query4 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('ALL')
        .collection(choicedate.value)
        .get();
    await _processAllCollectionForUpdates(query4, result);

    _updateUI(result);
    return result;
  }

  Stream<List<ReportsModel>> _getAllReports() {
    return FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('AB')
        .collection(choicedate.value)
        .snapshots()
        .asyncMap(_processAllData);
  }

  Future<List<ReportsModel>> _processAllData(QuerySnapshot query) async {
    final result = <ReportsModel>[];

    await _processCollection(query, result);

    final query2 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('CH')
        .collection(choicedate.value)
        .get();
    await _processCollection(query2, result);

    final query3 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('FZ')
        .collection(choicedate.value)
        .get();
    await _processCollection(query3, result);

    final query4 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('ALL')
        .collection(choicedate.value)
        .get();
    await _processAllCollectionForUpdates(query4, result);

    _updateUI(result);
    return result;
  }

  Stream<List<ReportsModel>> _getSpecificLocationReports() {
    return FirebaseFirestore.instance
        .collection('HISTORY')
        .doc(choice.value)
        .collection(choicedate.value)
        .snapshots()
        .asyncMap(_processSpecificLocationData);
  }

  Future<List<ReportsModel>> _processSpecificLocationData(
    QuerySnapshot query,
  ) async {
    final result = <ReportsModel>[];
    final result2 = <ReportsModel>[];

    if (query.docs.isNotEmpty) {
      await _processCollection(query, result);
    }

    final query2 = await FirebaseFirestore.instance
        .collection('HISTORY')
        .doc('ALL')
        .collection(choicedate.value)
        .get();
    await _processSpecificAllCollection(query2, result);

    final query3 = await FirebaseFirestore.instance
        .collection('SR')
        .where('createdat', isGreaterThanOrEqualTo: choicedate.value)
        .get();

    if (query3.docs.isNotEmpty) {
      for (final doc in query3.docs) {
        final reportsModel = ReportsModel.fromDocumentSnapshotOut(
          documentSnapshot: doc,
        );
        reportsModel.flag = 'Y';
        result2.add(reportsModel);
      }
    }

    tolisthistoryout.assignAll(result2);
    _updateUI(result);
    return result;
  }

  Future<void> _processCollection(
    QuerySnapshot query,
    List<ReportsModel> result, {
    bool filterPallet = false,
  }) async {
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final doctype = data['doctype'] as String? ?? '';

      final ReportsModel reportsModel;

      switch (doctype) {
        case 'IN':
          reportsModel = ReportsModel.fromDocumentSnapshotInModel(
            documentSnapshot: doc,
          );
          if (!filterPallet || _containsPallet(reportsModel)) {
            _addReportModel(result, reportsModel);
          }
          break;
        case 'SR':
          reportsModel = ReportsModel.fromDocumentSnapshotOut(
            documentSnapshot: doc,
          );
          _addReportModel(result, reportsModel);
          break;
        default:
          reportsModel = ReportsModel.fromDocumentSnapshotStock(
            documentSnapshot: doc,
          );
          _addReportModel(result, reportsModel);
          break;
      }
    }
  }

  Future<void> _processAllCollectionForUpdates(
    QuerySnapshot query,
    List<ReportsModel> result,
  ) async {
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final doctype = data['doctype'] as String? ?? '';

      if (doctype == 'IN') {
        final reportsModel = ReportsModel.fromDocumentSnapshotInModel(
          documentSnapshot: doc,
        );
        _updateExistingInModel(result, reportsModel);
      }
    }
  }

  Future<void> _processSpecificAllCollection(
    QuerySnapshot query,
    List<ReportsModel> result,
  ) async {
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final doctype = data['doctype'] as String? ?? '';

      switch (doctype) {
        case 'IN':
          final reportsModel = ReportsModel.fromDocumentSnapshotInModel(
            documentSnapshot: doc,
          );
          _updateExistingInModel(result, reportsModel);
          break;
        case 'SR':
          final reportsModel = ReportsModel.fromDocumentSnapshotOut(
            documentSnapshot: doc,
          );
          _updateExistingOutModel(result, reportsModel);
          break;
        default:
          final reportsModel = ReportsModel.fromDocumentSnapshotStock(
            documentSnapshot: doc,
          );
          _updateExistingStockModel(result, reportsModel);
          break;
      }
    }
  }

  bool _containsPallet(ReportsModel model) {
    return model.tData?.any(
          (element) => element.maktx?.contains('Pallet') ?? false,
        ) ??
        false;
  }

  void _addReportModel(List<ReportsModel> result, ReportsModel model) {
    if (model.isApprove == 'Y') {
      result.add(model);
    } else {
      result.add(model);
    }
  }

  void _updateExistingInModel(
    List<ReportsModel> result,
    ReportsModel newModel,
  ) {
    final existingIndex = result.indexWhere(
      (element) => element.ebeln == newModel.ebeln,
    );

    if (existingIndex != -1) {
      result.removeAt(existingIndex);
      newModel.flag = 'Y';
    }

    result.add(newModel);
  }

  void _updateExistingOutModel(
    List<ReportsModel> result,
    ReportsModel newModel,
  ) {
    final existingIndex = result.indexWhere(
      (element) => element.documentNo == newModel.documentNo,
    );

    if (existingIndex != -1) {
      final existing = result[existingIndex];
      if (existing.mblnr == null) {
        result.removeAt(existingIndex);
      }
      newModel.flag = 'Y';
      result.add(newModel);
    } else if (newModel.detail?.any(
          (element) => element.mProductId == choice.value,
        ) ??
        false) {}
    {
      result.removeWhere(
        (element) => element.documentNo == newModel.documentNo,
      );
      newModel.flag = 'Y';
      result.add(newModel);
    }
  }

  void _updateExistingStockModel(
    List<ReportsModel> result,
    ReportsModel newModel,
  ) {
    final existingIndex = result.indexWhere(
      (element) => element.documentNo == newModel.documentNo,
    );

    if (existingIndex != -1) {
      result.removeAt(existingIndex);
      newModel.flag = 'Y';
      result.add(newModel);
    }
  }

  void _updateUI(List<ReportsModel> result) {
    tolisthistory.assignAll(result);
    isLoading.value = false;
  }

  String dateToString(String date) {
    try {
      final dateTime = DateTime.parse(date);
      final format = DateFormat('dd-MM-yyyy');
      return format.format(dateTime);
    } catch (e) {
      return date;
    }
  }
}
