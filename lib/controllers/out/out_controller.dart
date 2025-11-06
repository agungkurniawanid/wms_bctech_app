import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/models/out/out_detail_model.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'package:wms_bctech/pages/good_receipt/good_receipt_page.dart';
import 'package:intl/intl.dart';
import 'package:logger/web.dart';
import 'package:http/http.dart' as http;

enum RefreshTypeSalesOrder { listRecentData, listSalesOrderData }

class OutController extends GetxController {
  final GlobalVM globalvm = Get.find();
  static final HttpClient client = HttpClient();
  final Config config = Config();

  final RxList<OutModel> tolistSalesOrder = <OutModel>[].obs;
  final RxList<OutModel> tolistSalesOrderapprove = <OutModel>[].obs;
  final RxList<OutModel> tolistSalesOrderbackup = <OutModel>[].obs;
  final RxList<OutModel> tolistSalesOrderRecent = <OutModel>[].obs;

  final Rx<List<OutModel>> salesOrderList = Rx<List<OutModel>>([]);
  final Rx<List<OutModel>> salesOrderListhistory = Rx<List<OutModel>>([]);

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
  final RxList<OutModel> filteredPOList = <OutModel>[].obs;

  final Rx<dynamic> pdfFile = Rx<dynamic>(null);
  final Rx<dynamic> pdfBytes = Rx<dynamic>(null);

  final Logger _logger = Logger();

  final RxList<OutDetailModel> detailsList = <OutDetailModel>[].obs;
  final RxBool isDetailsLoading = false.obs;
  final RxString detailsError = ''.obs;
  String username = '';

  @override
  void onReady() {
    salesOrderList.bindStream(listSalesOrder());
  }

  void onRecent() {
    isLoading.value = true;
    salesOrderList.bindStream(listforRecentALL());
  }

  Future<void> getname() async {
    username = (await DatabaseHelper.db.getUser()) ?? '';
  }

  void searchSOData(String query) {
    if (query.isEmpty) {
      clearFilters();
      return;
    }

    final searchQuery = query.toLowerCase().trim();
    final sourceList = tolistSalesOrderbackup.isNotEmpty
        ? tolistSalesOrderbackup
        : tolistSalesOrder;

    final filteredList = sourceList.where((po) {
      final documentNo = po.documentno?.toLowerCase() ?? '';
      final customer = po.cBpartnerId?.toLowerCase() ?? '';
      final customerPO = po.vendorpo?.toLowerCase() ?? '';

      return documentNo.contains(searchQuery) ||
          customer.contains(searchQuery) ||
          customerPO.contains(searchQuery);
    }).toList();

    filteredPOList.assignAll(filteredList);
  }

  void sortSOData(String sortBy) {
    List<OutModel> listToSort = List.from(
      filteredPOList.isNotEmpty ? filteredPOList : tolistSalesOrder,
    );

    switch (sortBy) {
      case 'SO Date':
        listToSort.sort((a, b) {
          final aDate = a.dateordered ?? '';
          final bDate = b.dateordered ?? '';
          return bDate.compareTo(aDate);
        });
        break;
      case 'Customer':
        listToSort.sort((a, b) {
          final acustomer = a.cBpartnerId ?? '';
          final bcustomer = b.cBpartnerId ?? '';
          return acustomer.compareTo(bcustomer);
        });
        break;
      case 'All':
      default:
        // Tidak melakukan sorting, tampilkan data asli
        listToSort = List.from(tolistSalesOrder);
        break;
    }

    filteredPOList.assignAll(listToSort);
  }

  /// Update clearFilters method
  void clearFilters() {
    // Kembalikan ke data asli
    filteredPOList.assignAll(tolistSalesOrder);
    isSearch.value = false;
    isIconSearch.value = true;
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

  Future<void> refreshDetailsData(String documentNo) async {
    try {
      isDetailsLoading.value = true;
      detailsError.value = '';

      final List<OutDetailModel> refreshedDetails =
          await getDetailsByDocumentNo(documentNo);
      detailsList.assignAll(refreshedDetails);
    } catch (e) {
      detailsError.value = 'Error refreshing details: $e';
      _logger.e('Error refreshing details: $e');
    } finally {
      isDetailsLoading.value = false;
    }
  }

  Future<bool> approveIn(
    OutModel outModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      final username = await DatabaseHelper.db.getUser();

      await FirebaseFirestore.instance
          .collection('out')
          .doc(outModel.documentno)
          .set({
            'dateordered': outModel.dateordered,
            'documentno': outModel.documentno,
            'docstatus': outModel.docstatus,
            'ad_client_id': outModel.adClientId,
            'ad_org_id': outModel.adOrgId,
            'c_bpartner_id': outModel.cBpartnerId,
            'c_currency_id': outModel.cCurrencyId,
            'c_doctype_id': outModel.cDoctypeId,
            'c_doctypetarget_id': outModel.cDoctypetargetId,
            'deliveryviarule': outModel.deliveryviarule,
            'details': tdata,
            'freightcostrule': outModel.freightcostrule,
            'm_pricelist_id': outModel.mPricelistId,
            'm_product_category_id': outModel.mProductCategoryId,
            'm_warehouse_id': outModel.mWarehouseId,
            'priorityrule': outModel.priorityrule,
            'totallines': outModel.totallines,
            'user1_id': outModel.user1Id,
            'clientid': outModel.clientid,
            'created': outModel.created,
            'createdby': outModel.createdby,
            'updated': formattedDate,
            'updatedby': username,
            'sync': outModel.issync,
            'orgid': outModel.orgid,
            'TRUCK': outModel.truck,
            'INVOICENO': outModel.invoiceno,
            'VENDORPO': outModel.vendorpo,
          });

      return true;
    } catch (e) {
      _logger.e('Error in approveIn: $e');
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
      _logger.e('Error in getPoWithDoc: $e');
      return "0";
    }
  }

  Future<void> sendHistory(
    OutModel outModel,
    List<Map<String, dynamic>> tdata,
  ) async {
    try {
      final now = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(now);
      final formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
      final username = await DatabaseHelper.db.getUser();

      final historyCollection = FirebaseFirestore.instance
          .collection('HISTORY')
          .doc(GlobalVar.choicecategory)
          .collection(todayString);

      final historyData = {
        'dateordered': outModel.dateordered,
        'documentno': outModel.documentno,
        'docstatus': outModel.docstatus,
        'ad_client_id': outModel.adClientId,
        'ad_org_id': outModel.adOrgId,
        'c_bpartner_id': outModel.cBpartnerId,
        'c_currency_id': outModel.cCurrencyId,
        'c_doctype_id': outModel.cDoctypeId,
        'c_doctypetarget_id': outModel.cDoctypetargetId,
        'deliveryviarule': outModel.deliveryviarule,
        'details': tdata,
        'freightcostrule': outModel.freightcostrule,
        'm_pricelist_id': outModel.mPricelistId,
        'm_product_category_id': outModel.mProductCategoryId,
        'm_warehouse_id': outModel.mWarehouseId,
        'priorityrule': outModel.priorityrule,
        'totallines': outModel.totallines,
        'user1_id': outModel.user1Id,
        'clientid': outModel.clientid,
        'created': outModel.created,
        'createdby': outModel.createdby,
        'updated': formattedDate,
        'updatedby': username,
        'sync': outModel.issync,
        'orgid': outModel.orgid,
        'TRUCK': outModel.truck,
      };

      await historyCollection.add(historyData);
    } catch (e) {
      _logger.e('Error in sendHistory: $e');
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
        final returnpo = OutModel.fromDocumentSnapshot(sr);
        final returnpobackup = OutModel.fromDocumentSnapshot(sr);

        // Filter berdasarkan docstatus - hanya mengambil yang completed (CO)
        if (returnpo.docstatus == 'CO') {
          result.add(returnpo);
          outmodellocalbackup.add(returnpobackup);
        }
      }

      return result;
    } catch (e) {
      _logger.e('Error fetching data: $e');
      rethrow;
    }
  }

  Stream<List<OutModel>> listSalesOrder() {
    try {
      return FirebaseFirestore.instance
          .collection('out')
          .where('is_fully_delivered', isEqualTo: 'N')
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
                _logger.e('Error parsing document: $e');
              }
            }

            tolistSalesOrder.assignAll(outmodellocal);
            filteredPOList.assignAll(outmodellocal); // Sync filtered list
            _logger.e('Loaded ${outmodellocal.length} documents from Firebase');
            return outmodellocal;
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (event) {
              _logger.e('Stream timeout');
              event.add([]);
            },
          );
    } catch (e) {
      _logger.e('Error in listSalesOrder: $e');
      return Stream.value(<OutModel>[]);
    }
  }

  Stream<List<OutModel>> listforRecentALL() {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final oneMonthString = DateFormat('yyyy-MM-dd').format(oneMonthAgo);
      _logger.e('Filtering from date: $oneMonthString');

      return FirebaseFirestore.instance
          .collection('out')
          .where('dateordered', isGreaterThanOrEqualTo: oneMonthString)
          .where(
            'is_fully_delivered',
            isEqualTo: 'N',
          ) // ← tetap underscore untuk Firestore
          .orderBy('dateordered', descending: true)
          .limit(10)
          .snapshots()
          .map<List<OutModel>>((query) {
            final outmodellocal = <OutModel>[];

            for (final doc in query.docs) {
              try {
                final returnpo = OutModel.fromDocumentSnapshot(doc);
                // Hanya tambahkan jika docstatus CO (sudah ada di query Firestore)
                if (returnpo.docstatus == 'CO') {
                  outmodellocal.add(returnpo);
                  _logger.e(
                    'Added PO: ${returnpo.documentno}, FullyDelivered: ${returnpo.isFullyDelivered}',
                  );
                } else {
                  _logger.e(
                    'Skipped PO (status ${returnpo.docstatus}): ${returnpo.documentno}',
                  );
                }
              } catch (e) {
                _logger.e('Error parsing document: $e');
              }
            }

            _logger.e('Total filtered POs: ${outmodellocal.length}');
            tolistSalesOrderRecent.assignAll(outmodellocal);
            isLoading.value = false;

            return outmodellocal;
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: (sink) {
              _logger.e('Stream timeout');
              isLoading.value = false;
              sink.add([]);
            },
          );
    } catch (e) {
      _logger.e('Error creating stream: $e');
      isLoading.value = false;
      return Stream.value([]);
    }
  }

  Stream<List<OutModel>> getFilteredPO({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return listSalesOrder().map((list) {
      var filteredList = list;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredList = filteredList
            .where(
              (po) =>
                  (po.documentno?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (po.cBpartnerId?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }

      if (startDate != null && endDate != null) {
        filteredList = filteredList.where((po) {
          if (po.dateordered == null) return false;
          try {
            final poDate = DateTime.parse(po.dateordered!);
            return poDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                poDate.isBefore(endDate.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      }

      return filteredList;
    });
  }

  Future<void> refreshDataSO({
    RefreshTypeSalesOrder type = RefreshTypeSalesOrder.listSalesOrderData,
  }) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });

    try {
      switch (type) {
        case RefreshTypeSalesOrder.listRecentData:
          salesOrderList.bindStream(listforRecentALL());
          break;
        case RefreshTypeSalesOrder.listSalesOrderData:
          salesOrderList.bindStream(listSalesOrder());
          break;
      }
      await Future.delayed(const Duration(seconds: 2));

      // Inisialisasi filtered list dengan semua data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        filteredPOList.assignAll(tolistSalesOrder);
      });
    } catch (e) {
      _logger.e('Error refreshing data for $type: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }

  @override
  void onClose() {
    salesOrderList.close();
    super.onClose();
  }

  Future<List<OutDetailModel>> getDetailsByDocumentNo(String documentNo) async {
    try {
      _logger.i('Mencari details untuk documentno: $documentNo');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('out')
          .where('documentno', isEqualTo: documentNo)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.w('Tidak ditemukan data dengan documentno: $documentNo');
        return [];
      }

      final doc = querySnapshot.docs.first;
      final outModel = OutModel.fromDocumentSnapshot(doc);

      _logger.i('Berhasil mengambil data outModel: ${outModel.documentno}');

      if (outModel.details == null || outModel.details!.isEmpty) {
        _logger.w('Details kosong untuk documentno: $documentNo');
        return [];
      }

      _logger.i('Jumlah details ditemukan: ${outModel.details!.length}');

      return outModel.details!;
    } catch (e) {
      _logger.e('Error dalam getDetailsByDocumentNo: $e');
      rethrow;
    }
  }

  Stream<List<OutDetailModel>> getDetailsByDocumentNoWithFilter(
    String documentNo,
  ) {
    try {
      _logger.i(
        'Membuat stream details realtime untuk documentno: $documentNo',
      );

      return FirebaseFirestore.instance
          .collection('out')
          .where('documentno', isEqualTo: documentNo)
          .where('is_fully_delivered', isEqualTo: 'N')
          .snapshots()
          .asyncMap((querySnapshot) async {
            if (querySnapshot.docs.isEmpty) {
              _logger.w('Tidak ditemukan data dengan documentno: $documentNo');
              return <OutDetailModel>[];
            }

            final doc = querySnapshot.docs.first;
            final outModel = OutModel.fromDocumentSnapshot(doc);

            _logger.i(
              'Berhasil mengambil data OutModel: ${outModel.documentno}',
            );

            if (outModel.details == null || outModel.details!.isEmpty) {
              _logger.w('Details kosong untuk documentno: $documentNo');
              return <OutDetailModel>[];
            }

            final filteredDetails = outModel.details!.where((
              OutDetailModel detail,
            ) {
              final qtyEntered = detail.qtyEntered ?? 0.0;
              final qtydelivered = detail.qtydelivered ?? 0.0;
              return qtyEntered < qtydelivered;
            }).toList();

            _logger.i(
              'Jumlah details setelah filter: ${filteredDetails.length}',
            );

            return filteredDetails;
          })
          .handleError((error) {
            _logger.e('Error dalam stream details: $error');
            return <OutDetailModel>[];
          });
    } catch (e) {
      _logger.e('Error creating details stream: $e');
      return Stream.value(<OutDetailModel>[]);
    }
  }

  Stream<OutModel?> getPODataStream(String documentNo) {
    try {
      _logger.i('Membuat stream PO data realtime untuk: $documentNo');

      return FirebaseFirestore.instance
          .collection('out')
          .where('documentno', isEqualTo: documentNo)
          .snapshots()
          .map((querySnapshot) {
            if (querySnapshot.docs.isEmpty) {
              _logger.w('Tidak ditemukan PO dengan documentno: $documentNo');
              return null;
            }

            final doc = querySnapshot.docs.first;
            final outModel = OutModel.fromDocumentSnapshot(doc);

            _logger.i('Berhasil update PO data: ${outModel.documentno}');
            return outModel;
          })
          .handleError((error) {
            _logger.e('Error dalam stream PO data: $error');
            return null;
          });
    } catch (e) {
      _logger.e('Error creating PO data stream: $e');
      return Stream.value(null);
    }
  }

  Future<void> sendToKafkaForGR(String grId) async {
    try {
      Get.showOverlay(
        loadingWidget: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(strokeWidth: 3, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Mengirim data ke CPERP...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        asyncFunction: () async {
          try {
            final snapshotKafkaConfig = FirebaseFirestore.instance.collection(
              'z_function_config',
            );

            // 1️⃣ Get Kafka URL
            final getUrlKafka = await snapshotKafkaConfig
                .doc('httpSendDocumentToKafka_url')
                .get(GetOptions(source: Source.server));

            if (!getUrlKafka.exists) {
              Get.showSnackbar(
                const GetSnackBar(
                  backgroundColor: Colors.red,
                  title: 'Error',
                  message: 'Kafka URL not found',
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final kafkaUrl = getUrlKafka.data()?['value'];

            // 2️⃣ Get Topic MR
            final getTopicKafkaMR = await snapshotKafkaConfig
                .doc('kafka_producer_topic_mr')
                .get(GetOptions(source: Source.server));

            if (!getTopicKafkaMR.exists) {
              Get.showSnackbar(
                const GetSnackBar(
                  backgroundColor: Colors.red,
                  title: 'Error',
                  message: 'Kafka topic MR not found',
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final kafkaTopic = getTopicKafkaMR.data()?['value'];

            // 3️⃣ Get Token
            final getTokenKafka = await snapshotKafkaConfig
                .doc('httpSendDocumentToKafka_token')
                .get(GetOptions(source: Source.server));

            if (!getTokenKafka.exists) {
              Get.showSnackbar(
                const GetSnackBar(
                  backgroundColor: Colors.red,
                  title: 'Error',
                  message: 'Kafka token not found',
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final kafkaToken = getTokenKafka.data()?['value'];

            // 4️⃣ Get dokumen GR
            final grDocRef = FirebaseFirestore.instance
                .collection('good_receipt')
                .doc(grId);
            final grDoc = await grDocRef.get();

            if (!grDoc.exists) {
              Get.showSnackbar(
                GetSnackBar(
                  backgroundColor: Colors.red,
                  title: 'Error',
                  message: 'GR document not found: $grId',
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }

            final grData = grDoc.data();
            final kafkaStatus = grData?['lastSeenToKafkaLogStatus'];
            if (kafkaStatus == "success") {
              Get.showSnackbar(
                const GetSnackBar(
                  backgroundColor: Colors.blue,
                  title: 'Info',
                  message: 'Data sudah pernah dikirim ke Kafka sebelumnya',
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // 5️⃣ Kirim ke Kafka
            final docPath = '/good_receipt/$grId';
            final url = Uri.parse(kafkaUrl);
            final headers = {
              'Content-type': 'application/json',
              'Authorization': 'Bearer $kafkaToken',
            };
            final body = jsonEncode({
              "list_document_path": [docPath],
              'topic': kafkaTopic,
              'force_send': true,
            });

            final response = await http.post(url, headers: headers, body: body);

            if (response.statusCode == 200) {
              _logger.i('✅ Success: ${response.body}');
              Get.showSnackbar(
                const GetSnackBar(
                  backgroundColor: Colors.green,
                  title: 'Success',
                  message: 'Data berhasil dikirim ke CPERP',
                  duration: Duration(seconds: 2),
                ),
              );

              // ✅ Setelah sukses kirim → langsung ke grin_page
              Future.delayed(const Duration(seconds: 1), () {
                Get.to(GoodReceiptPage());
              });
            } else {
              _logger.i('❌ Failed: ${response.statusCode}\n${response.body}');
              Get.showSnackbar(
                GetSnackBar(
                  backgroundColor: Colors.red,
                  title: 'Error',
                  message:
                      'Gagal kirim ke Kafka: ${response.statusCode}\nResponse: ${response.body}',
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            _logger.i('Error send to Kafka: $e');
            Get.showSnackbar(
              GetSnackBar(
                backgroundColor: Colors.red,
                title: 'Error',
                message: 'Error: $e',
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } catch (e, st) {
      _logger.i('Error in sendToKafkaForGR: $e | $st');
    }
  }
}
