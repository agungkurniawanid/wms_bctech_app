import 'dart:async';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/controllers/delivery_order/delivery_order_sequence_controller.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:logger/web.dart';
import 'package:wms_bctech/models/delivery_order/delivery_order_detail_model.dart';
import 'package:wms_bctech/models/delivery_order/delivery_order_model.dart';

class DeliveryOrderController extends GetxController {
  final Logger _logger = Logger();
  final RxList<DeliveryOrderModel> deliveryOrderList =
      <DeliveryOrderModel>[].obs;
  final RxList<DeliveryOrderModel> deliveryOrderListBackup =
      <DeliveryOrderModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'Created Date'.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeliveryOrderSequenceController _sequenceService =
      DeliveryOrderSequenceController();
  final Rx<String> _currentSearchQuery = ''.obs;
  Timer? _searchDebounceTimer;
  bool _isSearchOperationRunning = false;
  String _lastCompletedSearchQuery = '';
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalLoaded = 0.obs;
  final RxBool isLoadingMore = false.obs;

  @override
  void onReady() {
    _logger.d('🎯 DeliveryOrderController onReady dipanggil');
    super.onReady();
    loadInitialDeliveryOrderData();
  }

  @override
  void onInit() {
    super.onInit();
    _logger.d('🎯 DeliveryOrderController onInit');
    ever(searchQuery, (String query) {
      _handleSearchQueryChange(query);
    });
  }

  Future<void> loadInitialDeliveryOrderData() async {
    _logger.d('📥 loadInitialDeliveryOrderData dipanggil');
    try {
      isLoading.value = true;
      _hasMoreData.value = true;
      _lastDocument = null;
      _totalLoaded.value = 0;
      deliveryOrderList.clear();
      deliveryOrderListBackup.clear();

      await _loadMoreDeliveryOrderData(isInitial: true);

      _logger.d(
        '✅ Data Delivery Order awal berhasil diload: ${deliveryOrderList.length} items',
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading initial DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreDeliveryOrderData() async {
    if (isLoadingMore.value || !_hasMoreData.value || isSearching.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      await _loadMoreDeliveryOrderData(isInitial: false);
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading more DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _loadMoreDeliveryOrderData({required bool isInitial}) async {
    _logger.d(
      '📥 _loadMoreDeliveryOrderData - isInitial: $isInitial, lastDocument: $_lastDocument',
    );

    try {
      Query query = _firestore
          .collection('delivery_order')
          .orderBy('createdat', descending: true)
          .limit(_pageSize);

      if (!isInitial && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMoreData.value = false;
        _logger.d('🏁 Tidak ada data lagi untuk diload');
        return;
      }

      final List<DeliveryOrderModel> newDeliveryOrderList = [];
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

      for (final doc in snapshot.docs) {
        try {
          final grModel = DeliveryOrderModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );

          // --- INI LOGIKA FILTER ANDA ---
          if (grModel.status != 'completed') {
            // 1. Jika status BUKAN completed, selalu tambahkan
            newDeliveryOrderList.add(grModel);
          } else {
            // 2. Jika status COMPLETED, cek updatedAt
            if (grModel.updatedAt != null &&
                grModel.updatedAt!.isAfter(oneDayAgo)) {
              // 2a. Jika updatedAt ada dan dalam 24 jam terakhir, tambahkan
              newDeliveryOrderList.add(grModel);
            } else {
              // 2b. Jika completed dan sudah lama (atau updatedAt null), jangan tambahkan
              _logger.d(
                '🚫 Menyembunyikan GR (completed & > 24 jam): ${grModel.doId}',
              );
            }
          }
          // --- BATAS LOGIKA FILTER ---
        } catch (e) {
          _logger.e('❌ Error parsing GR document ${doc.id}: $e');
        }
      }
      _lastDocument = snapshot.docs.last;

      if (isInitial) {
        deliveryOrderList.assignAll(newDeliveryOrderList);
        deliveryOrderListBackup.assignAll(newDeliveryOrderList);
      } else {
        deliveryOrderList.addAll(newDeliveryOrderList);
        deliveryOrderListBackup.addAll(newDeliveryOrderList);
      }

      _totalLoaded.value = deliveryOrderList.length;
      _hasMoreData.value = snapshot.docs.length == _pageSize;

      _logger.d(
        '✅ Loaded ${newDeliveryOrderList.length} DO documents, total: ${deliveryOrderList.length}',
      );
      _logger.d('📊 Has more data: ${_hasMoreData.value}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error in _loadMoreDeliveryOrderData: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> refreshData() async {
    _logger.d('🔄 refreshData dipanggil');
    try {
      if (isSearching.value) {
        clearSearch();
      }
      await loadInitialDeliveryOrderData();
    } catch (e, stackTrace) {
      _logger.e('❌ Error refreshing data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    }
  }

  void _handleSearchQueryChange(String query) {
    _logger.d('🔄 Search query changed: "$query"');
    _searchDebounceTimer?.cancel();
    if (query.isEmpty) {
      _logger.d('🧹 Query kosong, clear search immediately');
      _clearSearchImmediately();
      return;
    }
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _executeSearch(query);
    });
  }

  void _clearSearchImmediately() {
    _logger.d('🧹 Immediate clear search');
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;
    isSearching.value = false;
    searchQuery.value = '';
    if (deliveryOrderListBackup.isNotEmpty) {
      deliveryOrderList.assignAll(deliveryOrderListBackup);
      _logger.d('✅ Data restored: ${deliveryOrderList.length} items');
    }
  }

  Future<void> _executeSearch(String query) async {
    if (_isSearchOperationRunning) {
      _logger.d('⏸️ Search operation already running, skipping');
      return;
    }
    if (query == _lastCompletedSearchQuery) {
      _logger.d('⏭️ Same query as last completed, skipping');
      return;
    }

    _logger.d('🚀 Executing search for: "$query"');
    try {
      _isSearchOperationRunning = true;
      _currentSearchQuery.value = query;
      await _performSearchOperation(query);
      _lastCompletedSearchQuery = query;
      _logger.d('✅ Search completed successfully for: "$query"');
    } catch (e, stackTrace) {
      _logger.e('❌ Search operation failed: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      if (deliveryOrderListBackup.isNotEmpty) {
        deliveryOrderList.assignAll(deliveryOrderListBackup);
      }
    } finally {
      _isSearchOperationRunning = false;
    }
  }

  Future<void> _performSearchOperation(String query) async {
    _logger.d(
      '📊 Starting search operation, backup data: ${deliveryOrderListBackup.length} items',
    );
    if (deliveryOrderListBackup.isEmpty) {
      _logger.w('⚠️ No backup data available for search');
      return;
    }

    final listToFilter = List<DeliveryOrderModel>.from(deliveryOrderListBackup);
    final searchKey = query.toLowerCase().trim();
    _logger.d('🔍 Filtering ${listToFilter.length} items for: "$searchKey"');

    try {
      final filteredList = await Isolate.run(() {
        try {
          return listToFilter.where((deliverOrder) {
            try {
              final doId = deliverOrder.doId.toLowerCase();
              final soNumber = deliverOrder.soNumber.toLowerCase();
              final createdBy = TextHelper.formatUserName(
                deliverOrder.createdBy ?? 'Unknown',
              ).toLowerCase();

              final hasMatchingDetail = deliverOrder.details.any((detail) {
                final sn = detail.sn?.toLowerCase() ?? '';
                return sn.contains(searchKey);
              });

              return doId.contains(searchKey) ||
                  soNumber.contains(searchKey) ||
                  createdBy.contains(searchKey) ||
                  hasMatchingDetail;
            } catch (e) {
              return false;
            }
          }).toList();
        } catch (e) {
          return <DeliveryOrderModel>[];
        }
      });

      _logger.d('🏁 Isolate completed, found: ${filteredList.length} items');

      if (_currentSearchQuery.value == query) {
        deliveryOrderList.assignAll(filteredList);
        _logger.d('✅ Search results updated with ${filteredList.length} items');
      } else {
        _logger.d('⏭️ Query changed during search, ignoring results');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Isolate error: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  void setSearchMode(bool searching) {
    _logger.d('🔄 setSearchMode: $searching, current: ${isSearching.value}');
    if (isSearching.value == searching) {
      _logger.d('⏭️ Same search mode, skipping');
      return;
    }
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;
    isSearching.value = searching;
    if (!searching) {
      _clearSearchImmediately();
    } else {
      _logger.d('🔍 Entering search mode');
    }
  }

  void updateSearchQuery(String newQuery) {
    _logger.d('📝 updateSearchQuery: "$newQuery"');
    searchQuery.value = newQuery;
  }

  void clearSearch() {
    _logger.d('🧹 clearSearch called');
    setSearchMode(false);
  }

  void updateSearchQueryDeliveryOrderPage(String newQuery) {
    _logger.d('🔄 updateSearchQueryDeliveryOrderPage: "$newQuery"');
    if (newQuery.isEmpty) {
      setSearchMode(false);
    } else {
      setSearchMode(true);
      searchDeliveryOrder(newQuery);
    }
  }

  void searchDeliveryOrder(String query) async {
    _logger.d('🔍 searchDeliveryOrder dipanggil dengan query: "$query"');
    try {
      await _updateSearchState(query, true);
      _logger.d(
        '📊 Data sebelum search: ${deliveryOrderListBackup.length} items',
      );

      if (query.isEmpty) {
        _logger.d('🔄 Query kosong, restore data dari backup');
        if (deliveryOrderListBackup.isNotEmpty) {
          deliveryOrderList.assignAll(deliveryOrderListBackup);
          _logger.d('✅ Data restored: ${deliveryOrderList.length} items');
        } else {
          _logger.w('⚠️ Backup data kosong, tidak ada data untuk direstore');
        }
        await _updateSearchState(query, false);
        return;
      }

      final listToFilter = List<DeliveryOrderModel>.from(
        deliveryOrderListBackup,
      );
      final searchKey = query.toLowerCase().trim();
      _logger.d('🚀 Memulai filter di Isolate untuk keyword: "$searchKey"');

      final filteredList = await Isolate.run(() {
        return listToFilter.where((gr) {
          final doId = gr.doId.toLowerCase();
          final soNumber = gr.soNumber.toLowerCase();
          final createdBy = TextHelper.formatUserName(
            gr.createdBy ?? 'Unknown',
          ).toLowerCase();

          final hasMatchingDetail = gr.details.any((detail) {
            final sn = detail.sn?.toLowerCase() ?? '';
            return sn.contains(searchKey);
          });

          return doId.contains(searchKey) ||
              soNumber.contains(searchKey) ||
              createdBy.contains(searchKey) ||
              hasMatchingDetail;
        }).toList();
      });

      _logger.d('🏁 Isolate selesai, hasil: ${filteredList.length} items');

      if (searchQuery.value == query) {
        deliveryOrderList.assignAll(filteredList);
        await _updateSearchState(query, false);
        _logger.d(
          '✅ Search completed, data diupdate dengan ${filteredList.length} items',
        );
      } else {
        _logger.d('⏭️ Query berubah, abaikan hasil Isolate lama');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error di searchDeliveryOrder: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      await _updateSearchState('', false);
    }
  }

  Future<void> _updateSearchState(String query, bool searching) async {
    await Future.microtask(() {
      searchQuery.value = query;
      isSearching.value = searching;
    });
  }

  Future<void> loadDeliveryOrderData() async {
    _logger.d('📥 loadDeliveryOrderData dipanggil');
    try {
      isLoading.value = true;
      await getDeliveryOrderStream().first;
      _logger.d('✅ Data DO berhasil diload');
      isLoading.value = false;
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      isLoading.value = false;
    }
  }

  Stream<List<DeliveryOrderModel>> getDeliveryOrderStream() {
    _logger.d('📡 getDeliveryOrderStream dipanggil');
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final startOfDay = DateTime(
      oneMonthAgo.year,
      oneMonthAgo.month,
      oneMonthAgo.day,
    );

    return _firestore
        .collection('delivery_order')
        .where(
          'createdat',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('createdat', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          _logger.d(
            '📊 Mendapatkan ${snapshot.docs.length} documents dari Firestore',
          );
          final List<DeliveryOrderModel> grList = [];
          for (final doc in snapshot.docs) {
            try {
              final deliveryOrderModel = DeliveryOrderModel.fromFirestore(
                doc,
                null,
              );
              grList.add(deliveryOrderModel);
            } catch (e) {
              _logger.e('❌ Error parsing DO document ${doc.id}: $e');
            }
          }

          grList.sort((a, b) {
            final dateA = a.createdAt;
            final dateB = b.createdAt;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          deliveryOrderListBackup.value = List.from(grList);
          deliveryOrderList.value = List.from(grList);
          _logger.d('✅ Backup data diupdate: ${grList.length} items');
          _logger.d('✅ Loaded ${grList.length} DO documents dari last 30 days');
          return grList;
        })
        .handleError((error) {
          _logger.e('❌ Stream error in getDeliveryOrderStream: $error');
          return <DeliveryOrderModel>[];
        });
  }

  Future<bool> isSerialNumberUniqueGlobal(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim().toLowerCase();
      if (trimmedSerial.isEmpty) {
        return true;
      }
      _logger.d('🔍 Validasi serial number global: $trimmedSerial');
      final querySnapshot = await _firestore.collection('delivery_order').get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final details = data['details'] as List<dynamic>?;
        if (details != null) {
          for (final detail in details) {
            final detailSn = detail['SN'] as String?;
            if (detailSn != null && detailSn.trim().isNotEmpty) {
              final existingSn = detailSn.trim().toLowerCase();
              if (existingSn == trimmedSerial) {
                _logger.w('❌ Serial number duplikat ditemukan:');
                _logger.w('  Serial: $trimmedSerial');
                _logger.w('  DO ID: ${doc.id}');
                _logger.w('  Product: ${detail['productid']}');
                return false;
              }
            }
          }
        }
      }
      _logger.d('✅ Serial number unik secara global: $trimmedSerial');
      return true;
    } catch (e) {
      _logger.e('❌ Error validasi serial number global: $e');
      return false;
    }
  }

  void sortGroupedDeliveryOrder(String sortBy) {
    selectedSort.value = sortBy;
    final List<DeliveryOrderModel> sortedList = List.from(deliveryOrderList);

    switch (sortBy) {
      case 'DO ID':
        sortedList.sort((a, b) => a.doId.compareTo(b.doId));
        break;
      case 'SO Number':
        sortedList.sort((a, b) => a.soNumber.compareTo(b.soNumber));
        break;
      case 'Created Date':
      default:
        sortedList.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
    }
    deliveryOrderList.assignAll(sortedList);
  }

  Future<bool> isSerialNumberUniqueOptimized(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return true;

      final querySnapshot = await _firestore
          .collection('delivery_order')
          .where(
            'details',
            arrayContainsAny: [
              {'SN': trimmedSerial},
              {'SN': serialNumber},
            ],
          )
          .limit(1)
          .get();

      final isUnique = querySnapshot.docs.isEmpty;

      if (!isUnique) {
        _logger.w('❌ Serial number sudah digunakan: $trimmedSerial');
      } else {
        _logger.d('✅ Serial number unik: $trimmedSerial');
      }
      return isUnique;
    } catch (e) {
      _logger.e('❌ Error optimized serial number check: $e');
      return await isSerialNumberUniqueGlobal(serialNumber);
    }
  }

  Future<Set<String>> getAllExistingSerialNumbers() async {
    try {
      final Set<String> existingSerials = {};
      final querySnapshot = await _firestore.collection('delivery_order').get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final details = data['details'] as List<dynamic>?;
        if (details != null) {
          for (final detail in details) {
            final sn = detail['SN'] as String?;
            if (sn != null && sn.trim().isNotEmpty) {
              existingSerials.add(sn.trim().toLowerCase());
            }
          }
        }
      }
      _logger.d('📊 Total serial number yang ada: ${existingSerials.length}');
      return existingSerials;
    } catch (e) {
      _logger.e('❌ Error mendapatkan existing serial numbers: $e');
      return {};
    }
  }

  Future<bool> isSerialNumberUnique(String serialNumber) async {
    try {
      // 1. Simpan SN asli (jangan .toLowerCase())
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return true; // Anggap valid jika kosong

      _logger.d('🔍 Validasi SN global (query): $trimmedSerial');

      // 2. Query ke field 'sn' untuk mengecek duplikat
      //    Ini adalah cara yang benar: cepat, efisien, dan hanya membaca 1 data.
      final querySnapshot = await _firestore
          .collection('serial_numbers')
          .where('sn', isEqualTo: trimmedSerial) // <-- Mencari field 'sn'
          .limit(1)
          .get();

      // 3. Jika query tidak menemukan dokumen, berarti unik
      final isUnique = querySnapshot.docs.isEmpty;

      if (!isUnique) {
        _logger.w(
          '❌ SN $trimmedSerial sudah ada di GR: ${querySnapshot.docs.first.data()['gr_id']}',
        );
      } else {
        _logger.d('✅ SN $trimmedSerial unik secara global');
      }

      return isUnique;
    } catch (e) {
      _logger.e('❌ Error cek SN global: $e');
      return false; // Anggap tidak unik jika terjadi error
    }
  }

  Future<Map<String, bool>> validateBatchSerialNumbers(
    List<String> serialNumbers,
  ) async {
    try {
      final existingSerials = await getAllExistingSerialNumbers();
      final Map<String, bool> results = {};
      for (final serial in serialNumbers) {
        final trimmedSerial = serial.trim().toLowerCase();
        if (trimmedSerial.isEmpty) {
          results[serial] = true;
          continue;
        }
        results[serial] = !existingSerials.contains(trimmedSerial);
      }
      return results;
    } catch (e) {
      _logger.e('❌ Error validasi batch serial numbers: $e');
      final Map<String, bool> results = {};
      for (final serial in serialNumbers) {
        results[serial] = await isSerialNumberUniqueOptimized(serial);
      }
      return results;
    }
  }

  Future<Map<String, dynamic>> validateAndAddGrDetails({
    required String doId,
    required List<DeliveryOrderDetailModel> newDetails,
  }) async {
    try {
      final List<String> serialNumbers = [];
      for (final detail in newDetails) {
        if (detail.sn != null && detail.sn!.isNotEmpty) {
          serialNumbers.add(detail.sn!);
        }
      }

      final uniqueSerialNumbers = serialNumbers.toSet();
      if (uniqueSerialNumbers.length != serialNumbers.length) {
        return {
          'success': false,
          'error':
              'Terdapat duplikat serial number dalam data yang akan disimpan',
        };
      }
      for (final serialNumber in serialNumbers) {
        final isUnique = await isSerialNumberUnique(serialNumber);
        if (!isUnique) {
          return {
            'success': false,
            'error': 'Serial number "$serialNumber" sudah digunakan di sistem',
          };
        }
      }

      return await updateGrDetails(doId: doId, details: newDetails);
    } catch (e) {
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetailsWithValidation({
    required String doId,
    required List<DeliveryOrderDetailModel> newDetails,
  }) async {
    try {
      final serialNumbersToValidate = newDetails
          .where((detail) => detail.sn != null && detail.sn!.trim().isNotEmpty)
          .map((detail) => detail.sn!)
          .toList();

      _logger.d('🔍 Validasi ${serialNumbersToValidate.length} serial numbers');

      for (final serial in serialNumbersToValidate) {
        final isUnique = await isSerialNumberUniqueOptimized(serial);
        if (!isUnique) {
          return {
            'success': false,
            'error':
                'Serial number "$serial" sudah digunakan di sistem. Serial number harus unik secara global.',
          };
        }
      }

      _logger.d('✅ Semua serial numbers valid, melanjutkan penyimpanan...');
      return await updateGrDetails(doId: doId, details: newDetails);
    } catch (e) {
      _logger.e('❌ Error update DO details dengan validasi: $e');
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetails({
    required String doId,
    required List<DeliveryOrderDetailModel> details,
  }) async {
    try {
      final docRef = _firestore.collection('delivery_order').doc(doId);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('DO document dengan ID $doId tidak ditemukan');
        }

        transaction.update(docRef, {
          'details': details.map((detail) => detail.toMap()).toList(),
          'updatedat': Timestamp.fromDate(DateTime.now()), // Sesuai struktur
        });
      });

      _logger.d('✅ DO details updated: $doId dengan ${details.length} items');
      return {
        'success': true,
        'message': 'Details berhasil diupdate dengan ${details.length} items',
      };
    } catch (e) {
      _logger.e('❌ Error updating DO details: $e');
      return {'success': false, 'error': 'Gagal update details: $e'};
    }
  }

  Future<String> generatedoId() async {
    final currentYear = DateTime.now().year.toString();

    try {
      final sequenceToUse = await _sequenceService.getNextAvailableSequence();
      final sequenceString = sequenceToUse.toString().padLeft(7, '0');
      final generateddoId = 'DO$currentYear$sequenceString';

      _logger.d(
        '🎯 Generated DO ID: $generateddoId (sequence: $sequenceToUse)',
      );

      return generateddoId;
    } catch (e) {
      _logger.e('❌ CRITICAL: Failed to generate DO ID after retries: $e');

      Get.snackbar(
        'Error',
        'Gagal generate DO ID. Silakan coba lagi.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }

  Future<void> cancelGrCreation(String doId) async {
    try {
      final sequenceMatch = RegExp(r'DO\d{4}(\d{7})$').firstMatch(doId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.cancelReservation(sequence);
          await _markGrAsCancelled(doId);

          _logger.d('✅ DO creation CANCELLED: $doId (sequence: $sequence)');
        }
      }
    } catch (e) {
      _logger.e('Error cancelling DO creation: $e');
    }
  }

  Future<void> _markGrAsCancelled(String doId) async {
    try {
      final docRef = _firestore.collection('delivery_order').doc(doId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'status': 'cancelled',
          'cancelledat': Timestamp.fromDate(DateTime.now()),
        });
        _logger.d('✅ Marked DO as cancelled: $doId');
      }
    } catch (e) {
      _logger.e('Error marking DO as cancelled: $e');
    }
  }

  Future<void> saveSerialNumberGlobal({
    required String serialNumber,
    required String doId,
    required String productId,
  }) async {
    try {
      // 1. JANGAN .toLowerCase(), simpan data asli
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return;

      // 2. Gunakan .add() untuk membuat ID dokumen otomatis
      // Ini mengizinkan SN berisi '/' atau karakter spesial lainnya
      await FirebaseFirestore.instance.collection('serial_numbers').add({
        // <-- Menggunakan .add()
        'sn': trimmedSerial, // <-- Menyimpan SN asli di field 'sn'
        'do_id': doId,
        'productid': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.d(
        '✅ Serial number $trimmedSerial disimpan ke koleksi global serial_numbers',
      );
    } catch (e) {
      _logger.e('❌ Gagal simpan serial number global: $e');
    }
  }

  void sortDeliveryOrder(String sortBy) {
    selectedSort.value = sortBy;
    final List<DeliveryOrderModel> sortedList = List.from(deliveryOrderList);

    switch (sortBy) {
      case 'DO ID':
        sortedList.sort((a, b) => a.doId.compareTo(b.doId));
        break;
      case 'SO Number':
        sortedList.sort((a, b) => a.soNumber.compareTo(b.soNumber));
        break;
      case 'Created Date':
      default:
        sortedList.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
    }
    deliveryOrderList.assignAll(sortedList);
  }

  Future<bool> addNewDeliveryOrder({
    required String doId,
    required String soNumber,
    required List<DeliveryOrderDetailModel> details,
  }) async {
    try {
      final now = DateTime.now();
      final username = 'current_user';

      final grinData = {
        'doid': doId,
        'soid': soNumber,
        'createdby': username,
        'createdat': Timestamp.fromDate(now),
        'status': 'pending',
        'details': details.map((d) => d.toMap()).toList(),
      };

      await _firestore.collection('delivery_order').doc(doId).set(grinData);
      _logger.i('✅ DO $doId berhasil ditambahkan');
      return true;
    } catch (e) {
      _logger.e('Error adding new DO: $e');
      return false;
    }
  }

  Future<DeliveryOrderModel?> getDeliveryOrderById(String doId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('delivery_order')
          .doc(doId)
          .get();

      if (doc.exists) {
        return DeliveryOrderModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting DO by ID: $e');
      return null;
    }
  }

  Future<void> confirmGrCreation(String doId) async {
    try {
      final sequenceMatch = RegExp(r'DO\d{4}(\d{7})$').firstMatch(doId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.completeReservation(sequence);
          await _markGrAsCompleted(doId);
          _logger.d('✅ DO creation CONFIRMED: $doId');
        }
      }
    } catch (e) {
      _logger.e('Error confirming DO creation: $e');
    }
  }

  Future<void> _markGrAsCompleted(String doId) async {
    try {
      await _firestore.collection('delivery_order').doc(doId).update({
        'status': 'completed',
        'completedat': Timestamp.fromDate(DateTime.now()),
      });
      _logger.d('✅ Marked DO as completed: $doId');
    } catch (e) {
      _logger.e('Error marking DO as completed: $e');
    }
  }

  Future<String> generatedoIdAtSave() async {
    final currentYear = DateTime.now().year.toString();
    try {
      final generateddoId = await FirebaseFirestore.instance
          .runTransaction<String>((transaction) async {
            final lastGrQuery = await _firestore
                .collection('delivery_order')
                .where('doid', isGreaterThanOrEqualTo: 'DO$currentYear')
                .where('doid', isLessThan: 'DO${int.parse(currentYear) + 1}')
                .orderBy('doid', descending: true)
                .limit(1)
                .get();

            int nextSequence = 1;

            if (lastGrQuery.docs.isNotEmpty) {
              final lastdoId = lastGrQuery.docs.first.id;
              final sequenceMatch = RegExp(
                r'DO\d{4}(\d{7})$',
              ).firstMatch(lastdoId);
              if (sequenceMatch != null) {
                final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
                nextSequence = lastSequence + 1;
              }
            }
            final sequenceString = nextSequence.toString().padLeft(7, '0');
            final newdoId = 'DO$currentYear$sequenceString';
            final existingDoc = await _firestore
                .collection('delivery_order')
                .doc(newdoId)
                .get();
            if (existingDoc.exists) {
              nextSequence++;
              final retrySequenceString = nextSequence.toString().padLeft(
                7,
                '0',
              );
              final retrydoId = 'DO$currentYear$retrySequenceString';
              final retryExistingDoc = await _firestore
                  .collection('delivery_order')
                  .doc(retrydoId)
                  .get();
              if (retryExistingDoc.exists) {
                throw Exception('DO ID sudah digunakan, silakan coba lagi');
              }
              return retrydoId;
            }

            return newdoId;
          }, timeout: const Duration(seconds: 10));

      _logger.d('✅ Generated DO ID: $generateddoId');
      return generateddoId;
    } catch (e) {
      _logger.e('❌ Error generating DO ID: $e');
      throw Exception('Gagal generate DO ID: $e');
    }
  }

  Future<Map<String, dynamic>> saveGrWithGeneratedId({
    required String soNumber,
    required List<DeliveryOrderDetailModel> details,
    required String currentUser,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final doId = await generatedoIdAtSave();

        if (doId.isEmpty) {
          throw Exception('Gagal generate DO ID');
        }
        final newGr = DeliveryOrderModel(
          doId: doId,
          soNumber: soNumber,
          createdBy: currentUser,
          createdAt: DateTime.now(),
          status: 'drafted',
          details: details,
        );

        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore.collection('delivery_order').doc(doId);
          final docSnapshot = await transaction.get(docRef);

          if (docSnapshot.exists) {
            throw Exception('DO ID $doId sudah digunakan oleh pengguna lain');
          }
          transaction.set(docRef, newGr.toFirestore());
        });

        _logger.d('✅ DO berhasil disimpan dengan ID: $doId');

        return {
          'success': true,
          'doId': doId,
          'message': 'DO berhasil disimpan',
        };
      } catch (e) {
        retryCount++;
        _logger.e('❌ Attempt $retryCount failed: $e');

        if (retryCount >= maxRetries) {
          return {
            'success': false,
            'error': 'Gagal menyimpan DO setelah $maxRetries percobaan: $e',
          };
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return {'success': false, 'error': 'Gagal menyimpan DO'};
  }

  Future<void> handleRefreshDeliveryOrderPage() async {
    await refreshData();
  }

  bool get hasMoreData => _hasMoreData.value;
  bool get isLoadingMoreData => isLoadingMore.value;
  int get totalLoaded => _totalLoaded.value;

  @override
  void onClose() {
    _logger.d('🧹 DeliveryOrderController onClose');
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;
    super.onClose();
  }
}
