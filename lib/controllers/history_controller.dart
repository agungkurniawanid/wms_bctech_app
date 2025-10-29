// history_view_model.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/history_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';

class HistoryViewModel extends GetxController {
  final Config config = Config();
  final GlobalVM globalViewModel = Get.find();

  final RxList<HistoryModel> historyList = <HistoryModel>[].obs;
  final Rx<List<HistoryModel>> stockList = Rx<List<HistoryModel>>([]);

  final RxBool isLoading = true.obs;
  final RxBool isLoadingPdf = true.obs;
  final RxBool isSearch = true.obs;
  final RxBool isSearchIcon = true.obs;
  final RxBool showTutorialRecent = true.obs;

  final RxInt searchIconState = 0.obs;
  final Rx<DateTime> currentDateTime = DateTime.now().obs;
  final Rx<DateTime> firstDate = DateTime.now().obs;
  final Rx<DateTime> lastDate = DateTime.now().obs;

  final RxString selectedDate = ''.obs;
  final RxString selectedChoice = ''.obs;
  final RxString pdfDirectory = ''.obs;

  final Rx<dynamic> pdfFile = Rx<dynamic>(null);
  final Rx<dynamic> pdfBytes = Rx<dynamic>(null);

  String username = '';
  List<Category> categoryList = [];
  List<Category> inboundCategoryList = [];

  @override
  void onReady() {
    super.onReady();
    stockList.bindStream(historyStream());
  }

  void onReports() {
    stockList.bindStream(reportsStream());
  }

  Future<void> processCombinedStream(
    List<Stream<QuerySnapshot>> streams,
  ) async {
    final combinedStream = StreamZip(streams);

    await for (final snapshots in combinedStream) {
      final List<HistoryModel> result = [];

      for (final query in snapshots) {
        for (final doc in query.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final String docType = data['doctype']?.toString() ?? '';
          final HistoryModel historyModel;

          switch (docType) {
            case 'IN':
              historyModel = HistoryModel.fromDocumentSnapshotInModel(doc);
              _removeDuplicateByPurchaseOrder(historyModel.ebeln ?? '');
              break;
            case 'SR':
              historyModel = HistoryModel.fromDocumentSnapshotOut(doc);
              _removeDuplicateByDocumentNumber(historyModel.documentNo ?? '');
              break;
            default:
              historyModel = HistoryModel.fromDocumentSnapshotStock(doc);
          }
          result.add(historyModel);
        }
      }

      historyList.addAll(result);
      isLoading.value = false;
    }
  }

  void _removeDuplicateByPurchaseOrder(String purchaseOrder) {
    historyList.removeWhere((element) => element.ebeln == purchaseOrder);
  }

  void _removeDuplicateByDocumentNumber(String documentNumber) {
    historyList.removeWhere((element) => element.documentNo == documentNumber);
  }

  Future<void> _initializeCategories() async {
    categoryList = await DatabaseHelper.db.getCategoryWithRole('OUT');
    inboundCategoryList = await DatabaseHelper.db.getCategoryWithRole('IN');

    if (inboundCategoryList.isNotEmpty) {
      _mergeCategoryLists();
    }
  }

  void _mergeCategoryLists() {
    // Remove 'Others' category from inbound list
    inboundCategoryList.removeWhere(
      (element) => element.inventoryGroupName == 'Others',
    );

    for (final inboundCategory in inboundCategoryList) {
      final existingIndex = categoryList.indexWhere(
        (category) =>
            category.inventoryGroupId == inboundCategory.inventoryGroupId,
      );

      if (existingIndex != -1) {
        categoryList[existingIndex] = inboundCategory;
      } else {
        categoryList.add(inboundCategory);
      }
    }
  }

  Stream<List<HistoryModel>> historyStream() async* {
    try {
      await _initializeCategories();

      if (categoryList.isEmpty) {
        isLoading.value = false;
        yield [];
        return;
      }

      final List<HistoryModel> result = [];

      await _processCategoryDocuments(categoryList[0], result);

      if (categoryList.length > 1) {
        await _processCategoryDocuments(categoryList[1], result);
      }

      if (categoryList.length > 2) {
        await _processCategoryDocuments(categoryList[2], result);
      }

      await _processAllCategoryDocuments(result);

      historyList.assignAll(result);
      isLoading.value = false;

      yield result;
    } catch (e) {
      debugPrint('Error in historyStream: $e');
      isLoading.value = false;
      yield [];
    }
  }

  Future<void> _processCategoryDocuments(
    Category category,
    List<HistoryModel> result,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('HISTORY')
          .doc(category.inventoryGroupId)
          .collection(selectedDate.value)
          .get();

      for (final doc in querySnapshot.docs) {
        final historyModel = _createHistoryModelFromDoc(doc);
        if (historyModel.isApprove == 'Y') {
          result.add(historyModel);
        } else {
          result.add(historyModel);
        }
      }
    } catch (e) {
      debugPrint('Error processing category ${category.inventoryGroupId}: $e');
    }
  }

  Future<void> _processAllCategoryDocuments(List<HistoryModel> result) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('HISTORY')
          .doc('ALL')
          .collection(selectedDate.value)
          .get();

      for (final doc in querySnapshot.docs) {
        final historyModel = _createHistoryModelFromDoc(doc);
        _handleAllCategoryDocument(historyModel, result);
      }
    } catch (e) {
      debugPrint('Error processing ALL category: $e');
    }
  }

  HistoryModel _createHistoryModelFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String docType = data['doctype']?.toString() ?? '';

    switch (docType) {
      case 'IN':
        return HistoryModel.fromDocumentSnapshotInModel(doc);
      case 'SR':
        return HistoryModel.fromDocumentSnapshotOut(doc);
      default:
        return HistoryModel.fromDocumentSnapshotStock(doc);
    }
  }

  void _handleAllCategoryDocument(
    HistoryModel historyModel,
    List<HistoryModel> result,
  ) {
    if (historyModel.ebeln != null) {
      if (result.any((element) => element.ebeln == historyModel.ebeln)) {
        result.removeWhere(
          (element) =>
              element.ebeln == historyModel.ebeln && element.mblnr == null,
        );
        result.add(historyModel);
      }
    } else if (historyModel.documentNo != null) {
      _handleStockRequirementDocument(historyModel, result);
    }
  }

  void _handleStockRequirementDocument(
    HistoryModel historyModel,
    List<HistoryModel> result,
  ) {
    if (result.any(
      (element) => element.documentNo == historyModel.documentNo,
    )) {
      result.removeWhere(
        (element) =>
            element.documentNo == historyModel.documentNo &&
            element.mblnr == null,
      );
      result.add(historyModel);
    } else {
      _handleCrossCategoryDocument(historyModel, result);
    }
  }

  void _handleCrossCategoryDocument(
    HistoryModel historyModel,
    List<HistoryModel> result,
  ) {
    for (final category in categoryList) {
      final hasMatchingCategory = historyModel.detail?.any(
        (element) => element.mProductId == category.inventoryGroupId,
      );

      if (hasMatchingCategory == true) {
        result.removeWhere(
          (element) => element.documentNo == historyModel.documentNo,
        );
        result.add(historyModel);
        break;
      }
    }
  }

  Stream<List<HistoryModel>> reportsStream() {
    return FirebaseFirestore.instance
        .collection('HISTORY')
        .doc(globalViewModel.username.value)
        .collection(selectedDate.value)
        .orderBy('updated', descending: true)
        .snapshots()
        .map((QuerySnapshot query) {
          final Set<String> uniqueKeys = <String>{};
          final List<HistoryModel> result = [];

          historyList.value = [];

          for (final doc in query.docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final String? key = data['documentNo']?.toString();

            if (key != null && !uniqueKeys.contains(key)) {
              uniqueKeys.add(key);

              final HistoryModel historyModel = _createHistoryModelFromDoc(doc);

              if (historyModel.isApprove == 'Y') {
                result.add(historyModel);
              } else {
                result.add(historyModel);
              }
            }
          }

          historyList.assignAll(result);
          isLoading.value = false;

          return result;
        });
  }

  String formatDateToString(String date) {
    try {
      final DateFormat format = DateFormat('dd-MM-yyyy');
      final DateTime dateTime = DateTime.parse(date);
      return format.format(dateTime);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return date;
    }
  }
}
