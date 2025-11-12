import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/role_controller.dart';
import 'package:wms_bctech/models/input_stock_take_model.dart';
import 'package:wms_bctech/models/stock/stock_take_detail_model.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';

class StockTakeController extends GetxController {
  final Config config = Config();
  final GlobalVM globalVM = Get.find();
  final Rolevm roleVM = Get.find();

  // Observables
  final RxString selectedChoice = "UU".obs;
  final RxList<dynamic> stockTickList = <dynamic>[].obs;
  final RxString documentNo = "".obs;
  final RxBool isLoading = false.obs;
  final RxBool isPdfLoading = false.obs;
  final RxString searchValue = ''.obs;

  // Data lists
  final RxList<StockTakeModel> stockList = <StockTakeModel>[].obs;
  final RxList<InputStockTake> inputStockTakeList = <InputStockTake>[].obs;
  final RxList<InputStockTake> countedStockTakeList = <InputStockTake>[].obs;
  final RxList<StockTakeModel> documentList = <StockTakeModel>[].obs;
  final RxList<StockTakeModel> documentListUnique = <StockTakeModel>[].obs;

  // Date observables
  final Rx<DateTime> currentDate = DateTime.now().obs;
  final Rx<DateTime> firstDate = DateTime.now().obs;
  final Rx<DateTime> lastDate = DateTime.now().obs;

  // Stream subscriptions
  StreamSubscription? _documentStreamSubscription;
  StreamSubscription? _detailsStreamSubscription;

  List<String> selectedLocations = [];
  String approvalStatusFilter = "";

  @override
  void onReady() {
    super.onReady();
    bindStockTakeStreams();
  }

  @override
  void onClose() {
    _documentStreamSubscription?.cancel();
    _detailsStreamSubscription?.cancel();
    super.onClose();
  }

  /// Initialize Firestore streams for stocktake documents
  void bindStockTakeStreams() {
    // Cancel existing subscriptions
    _documentStreamSubscription?.cancel();

    // Start listening to document stream
    _documentStreamSubscription = fetchDocumentStream().listen(
      (documents) {
        // Data akan otomatis ter-update melalui observable lists
        Logger().d("Realtime update: ${documents.length} documents received");
      },
      onError: (error) {
        Logger().e("Error in document stream: $error");
        EasyLoading.showError("Error fetching data");
      },
    );
  }

  /// Fetch stocktake document list filtered by month, approval, and location
  Stream<List<StockTakeModel>> fetchDocumentStream() {
    try {
      final String firstDayOfMonth = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(DateTime.now().year, DateTime.now().month, 1));

      // Build base query
      Query query = FirebaseFirestore.instance
          .collection('stock')
          .where('_last_query', isGreaterThanOrEqualTo: firstDayOfMonth);

      return query.snapshots().map((snapshot) {
        final List<StockTakeModel> documents = [];
        final List<StockTakeModel> uniqueDocuments = [];

        for (final doc in snapshot.docs) {
          final stockTake = StockTakeModel.fromDocumentSnapshot(doc);
          documents.add(stockTake);

          // Create unique documents (filter by matnr)
          final uniqueDetails = <StockTakeDetailModel>[];
          final seenMatnr = <String>{};
          for (final detail in stockTake.detail) {
            if (seenMatnr.add(detail.matnr ?? '')) {
              uniqueDetails.add(detail);
            }
          }
          uniqueDocuments.add(stockTake.copyWith(detail: uniqueDetails));
        }

        // Update observable lists - this will trigger UI updates
        documentList.assignAll(documents);
        documentListUnique.assignAll(uniqueDocuments);
        isLoading.value = false;

        Logger().d("Fetched ${uniqueDocuments.length} unique documents");

        return uniqueDocuments;
      });
    } catch (e) {
      Logger().e("Error in fetchDocumentStream: $e");
      return Stream.value([]);
    }
  }

  /// Listen to details for a specific document
  void bindDocumentDetailsStream(String documentNo) {
    _detailsStreamSubscription?.cancel();

    _detailsStreamSubscription = fetchAllDetails(documentNo).listen(
      (details) {
        Logger().d("Realtime details update: ${details.length} items");
      },
      onError: (error) {
        Logger().e("Error in details stream: $error");
      },
    );
  }

  /// Get all stocktake details by document
  Stream<List<InputStockTake>> fetchAllDetails(String docNo) {
    try {
      return FirebaseFirestore.instance
          .collection('stock')
          .doc(docNo)
          .collection('batchid')
          .snapshots()
          .map((snapshot) {
            final localList = snapshot.docs
                .map((doc) => InputStockTake.fromDocumentSnapshot(doc))
                .toList();

            // Update observable list
            inputStockTakeList.assignAll(localList);
            isLoading.value = false;

            Logger().d(
              "Fetched ${localList.length} details for document $docNo",
            );

            return localList;
          });
    } catch (e) {
      Logger().e("Error in fetchAllDetails: $e");
      return Stream.value([]);
    }
  }

  /// Refresh data manually
  Future<void> refreshData() async {
    isLoading.value = true;

    // Re-bind streams to get latest data
    bindStockTakeStreams();

    // If we have a documentNo, also refresh its details
    if (documentNo.value.isNotEmpty) {
      bindDocumentDetailsStream(documentNo.value);
    }

    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }

  /// Update filters and refresh data
  void updateFilters({List<String>? locations, String? approvalStatus}) {
    if (locations != null) {
      selectedLocations = locations;
    }
    if (approvalStatus != null) {
      approvalStatusFilter = approvalStatus;
    }

    // Re-bind streams with new filters
    bindStockTakeStreams();
  }

  // Existing methods remain the same...
  Future<void> createStockTakeDocument(
    List<Map<String, dynamic>> details,
  ) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      final year = DateFormat('yyyy').format(now);

      final existingDocs = await FirebaseFirestore.instance
          .collection('stock')
          .where('validation', isEqualTo: year)
          .get();

      final int newIndex = existingDocs.size + 1;
      final String newDocNo = "ST$year$newIndex";

      await FirebaseFirestore.instance.collection('stock').doc(newDocNo).set({
        'validation': year,
        'documentno': newDocNo,
        'LGORT': "HQ",
        'updated': "",
        'updatedby': "",
        'created': formattedDate,
        'createdby': globalVM.username.value,
        'isapprove': "N",
        'doctype': "stocktake",
        'detail': details,
      });

      Logger().d("Created new stocktake document: $newDocNo");
    } catch (e) {
      Logger().e("Error in createStockTakeDocument: $e");
      rethrow;
    }
  }

  /// Update detail list inside a StockTake document
  Future<void> updateDetailList(
    String documentNo,
    List<StockTakeDetailModel> details,
  ) async {
    try {
      final List<Map<String, dynamic>> mappedDetails = details
          .map((e) => e.toMap())
          .toList();

      await FirebaseFirestore.instance
          .collection('stock')
          .doc(documentNo)
          .update({'detail': mappedDetails});

      Logger().d("Updated details for document: $documentNo");
    } catch (e) {
      Logger().e("Error in updateDetailList: $e");
      rethrow;
    }
  }

  /// Approve a stocktake document
  Future<void> approveStockTake(StockTakeModel model) async {
    try {
      await FirebaseFirestore.instance
          .collection('stock')
          .doc(model.documentid)
          .update({
            "isapprove": "Y",
            "updated": model.updated,
            "updatedby": model.updatedby,
          });

      Logger().d("Approved stocktake: ${model.documentid}");
    } catch (e) {
      Logger().e("Error in approveStockTake: $e");
      rethrow;
    }
  }

  /// Convert date string to formatted date
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  /// Get filtered detail list from document
  List<StockTakeDetailModel> getDetailsFromDocument(String documentNo) {
    if (documentListUnique.isEmpty) return [];

    final doc = documentListUnique.firstWhereOrNull(
      (d) => d.documentid == documentNo,
    );

    if (doc == null) return [];

    if (searchValue.value.trim().isEmpty) return doc.detail;

    return doc.detail
        .where(
          (detail) =>
              detail.mAKTX.toLowerCase().contains(
                searchValue.value.toLowerCase(),
              ) ||
              detail.nORMT.contains(searchValue.value) ||
              detail.mATNR.contains(searchValue.value),
        )
        .toList();
  }

  /// Reset local caches
  void resetLocalData() {
    stockList.clear();
    documentList.clear();
    documentListUnique.clear();
    inputStockTakeList.clear();
    countedStockTakeList.clear();
  }
}
