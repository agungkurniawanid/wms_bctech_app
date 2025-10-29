import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:intl/intl.dart';

enum RefreshTypeSO { listRecentData, listPOData }

class OutController extends GetxController {
  final GlobalVM globalvm = Get.find();
  static final HttpClient client = HttpClient();
  final Config config = Config();

  final RxList<OutModel> tolistSO = <OutModel>[].obs;
  final RxList<OutModel> tolistSOapprove = <OutModel>[].obs;
  final RxList<OutModel> tolistSObackup = <OutModel>[].obs;

  final Rx<List<OutModel>> srlist = Rx<List<OutModel>>([]);
  final Rx<List<OutModel>> srlisthistory = Rx<List<OutModel>>([]);

  final List<OutModel> outmodellocal = [];
  final List<OutModel> outmodellocalbackup = [];
  final List<OutModel> outmodelhistory = [];

  final RxBool isLoading = true.obs;
  final RxBool isLoadingPDF = true.obs;
  final RxBool isSearch = true.obs;
  final RxBool isapprove = false.obs;
  final RxBool isIconSearch = true.obs;
  final RxBool isDark = true.obs;
  final RxBool tutorialRecent = true.obs;

  final RxInt isIconSearchint = 0.obs;
  final Rx<DateTime> datetimenow = DateTime.now().obs;
  final Rx<DateTime> firstdate = DateTime.now().obs;
  final Rx<DateTime> lastdate = DateTime.now().obs;
  final RxString sortVal = 'SO Date'.obs;
  final RxString choicein = ''.obs;
  final RxString pdfDir = ''.obs;

  final Rx<dynamic> pdfFile = Rx<dynamic>(null);
  final Rx<dynamic> pdfBytes = Rx<dynamic>(null);

  String username = '';

  @override
  void onReady() {
    srlist.bindStream(listSO());
  }

  void onRecent() {
    isLoading.value = true;
    srlist.bindStream(listforRecentALL());
  }

  Future<void> getname() async {
    username = (await DatabaseHelper.db.getUser()) ?? '';
  }

  String? dateToString(String? date, String test) {
    if (date == null) return '';
    try {
      final format = DateFormat('dd-MM-yyyy');
      final dateTime = DateTime.parse(date);
      return format.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Future<bool> approveOut(
    OutModel outmodel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      final username = await DatabaseHelper.db.getUser();

      await FirebaseFirestore.instance
          .collection('out')
          .doc(outmodel.documentno)
          .set({
            'dateordered': outmodel.dateordered,
            'documentno': outmodel.documentno,
            'docstatus': outmodel.docstatus,
            'ad_client_id': outmodel.adClientId,
            'ad_org_id': outmodel.adOrgId,
            'c_bpartner_id': outmodel.cBpartnerId,
            'c_currency_id': outmodel.cCurrencyId,
            'c_doctype_id': outmodel.cDoctypeId,
            'c_doctypetarget_id': outmodel.cDoctypetargetId,
            'deliveryviarule': outmodel.deliveryviarule,
            'details': tdata,
            'freightcostrule': outmodel.freightcostrule,
            'm_pricelist_id': outmodel.mPricelistId,
            'm_product_category_id': outmodel.mProductCategoryId,
            'm_warehouse_id': outmodel.mWarehouseId,
            'priorityrule': outmodel.priorityrule,
            'totallines': outmodel.totallines,
            'user1_id': outmodel.user1Id,
            'clientid': outmodel.clientid,
            'created': outmodel.created,
            'createdby': outmodel.createdby,
            'updated': formattedDate,
            'updatedby': username,
            'sync': outmodel.issync,
            'orgid': outmodel.orgid,
            'TRUCK': outmodel.truck,
            'INVOICENO': outmodel.invoiceno,
            'VENDORPO': outmodel.vendorpo,
          });

      return true;
    } catch (e) {
      debugPrint('Error in approveOut: $e');
      return false;
    }
  }

  Future<String> getSoWithDoc(String documentNumber) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('out')
          .where('documentno', isEqualTo: documentNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docData = query.docs.first.data();
        return docData['ad_client_id']?.toString() ?? '0';
      }
      return "0";
    } catch (e) {
      debugPrint('Error in getSoWithDoc: $e');
      return "0";
    }
  }

  Future<void> sendHistory(
    OutModel outmodel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final now = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(now);
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      final username = await DatabaseHelper.db.getUser();

      final historyCollection = FirebaseFirestore.instance
          .collection('HISTORY_OUT')
          .doc(GlobalVar.choicecategory)
          .collection(todayString);

      final historyData = {
        'dateordered': outmodel.dateordered,
        'documentno': outmodel.documentno,
        'docstatus': outmodel.docstatus,
        'ad_client_id': outmodel.adClientId,
        'ad_org_id': outmodel.adOrgId,
        'c_bpartner_id': outmodel.cBpartnerId,
        'c_currency_id': outmodel.cCurrencyId,
        'c_doctype_id': outmodel.cDoctypeId,
        'c_doctypetarget_id': outmodel.cDoctypetargetId,
        'deliveryviarule': outmodel.deliveryviarule,
        'details': tdata,
        'freightcostrule': outmodel.freightcostrule,
        'm_pricelist_id': outmodel.mPricelistId,
        'm_product_category_id': outmodel.mProductCategoryId,
        'm_warehouse_id': outmodel.mWarehouseId,
        'priorityrule': outmodel.priorityrule,
        'totallines': outmodel.totallines,
        'user1_id': outmodel.user1Id,
        'clientid': outmodel.clientid,
        'created': outmodel.created,
        'createdby': outmodel.createdby,
        'updated': formattedDate,
        'updatedby': username,
        'sync': outmodel.issync,
        'orgid': outmodel.orgid,
        'TRUCK': outmodel.truck,
      };

      await historyCollection.add(historyData);
    } catch (e) {
      debugPrint('Error in sendHistory: $e');
    }
  }

  Future<List<OutModel>> getData(String documentno, String category) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('out')
          .where('documentno', isEqualTo: documentno)
          .get();

      if (query.docs.isEmpty) return [];

      final List<OutModel> result = [];
      for (final sr in query.docs) {
        final returnso = OutModel.fromDocumentSnapshot(sr);
        final returnsobackup = OutModel.fromDocumentSnapshot(sr);

        if (returnso.docstatus == 'CO') {
          result.add(returnso);
          outmodellocalbackup.add(returnsobackup);
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching data: $e');
      rethrow;
    }
  }

  Stream<List<OutModel>> listSO() {
    try {
      return FirebaseFirestore.instance
          .collection('out')
          .snapshots()
          .map((query) {
            final outmodellocal = <OutModel>[];

            for (final sr in query.docs) {
              try {
                final returnpo = OutModel.fromDocumentSnapshot(sr);
                if (returnpo.docstatus == 'CO') {
                  outmodellocal.add(returnpo);
                }
              } catch (e) {
                debugPrint('Error parsing document: $e');
              }
            }

            tolistSO.assignAll(outmodellocal);
            debugPrint(
              'Loaded ${outmodellocal.length} documents from Firebase',
            );
            return outmodellocal;
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (event) {
              debugPrint('Stream timeout');
              event.add([]);
            },
          );
    } catch (e) {
      debugPrint('Error in listPO: $e');
      return Stream.value(<OutModel>[]);
    }
  }

  Stream<List<OutModel>> listforRecentALL() {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final oneMonthString = DateFormat('yyyy-MM-dd').format(oneMonthAgo);
      debugPrint('Filtering from date: $oneMonthString');

      return FirebaseFirestore.instance
          .collection('out')
          .where('dateordered', isGreaterThanOrEqualTo: oneMonthString)
          .orderBy('dateordered', descending: true)
          .limit(10)
          .snapshots()
          .map<List<OutModel>>((query) {
            final outmodellocal = <OutModel>[];

            for (final doc in query.docs) {
              try {
                final returnso = OutModel.fromDocumentSnapshot(doc);
                if (returnso.docstatus == 'CO') {
                  outmodellocal.add(returnso);
                  debugPrint('Added SO: ${returnso.documentno}');
                } else {
                  debugPrint(
                    'Skipped SO (status ${returnso.docstatus}): ${returnso.documentno}',
                  );
                }
              } catch (e) {
                debugPrint('Error parsing document: $e');
              }
            }

            debugPrint('Total filtered SOs: ${outmodellocal.length}');

            tolistSO.assignAll(outmodellocal);
            tolistSObackup.assignAll(outmodellocal);
            isLoading.value = false;

            return outmodellocal;
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: (sink) {
              debugPrint('Stream timeout');
              isLoading.value = false;
              sink.add([]);
            },
          );
    } catch (e) {
      debugPrint('Error creating stream: $e');
      isLoading.value = false;
      return Stream.value([]);
    }
  }

  Stream<List<OutModel>> getFilteredSO({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return listSO().map((list) {
      var filteredList = list;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredList = filteredList
            .where(
              (so) =>
                  (so.documentno?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (so.cBpartnerId?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }

      if (startDate != null && endDate != null) {
        filteredList = filteredList.where((so) {
          if (so.dateordered == null) return false;
          try {
            final soDate = DateTime.parse(so.dateordered!);
            return soDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                soDate.isBefore(endDate.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      }

      return filteredList;
    });
  }

  Future<void> refreshDataSO({
    RefreshTypeSO type = RefreshTypeSO.listPOData,
  }) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });

    try {
      switch (type) {
        case RefreshTypeSO.listRecentData:
          srlist.bindStream(listforRecentALL());
          break;
        case RefreshTypeSO.listPOData:
          srlist.bindStream(listSO());
          break;
      }
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Error refreshing data for $type: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }

  void clearFilters() {
    tolistSO.assignAll(tolistSObackup);
    isSearch.value = true;
    isIconSearch.value = true;
  }

  @override
  void onClose() {
    srlist.close();
    super.onClose();
  }
}
