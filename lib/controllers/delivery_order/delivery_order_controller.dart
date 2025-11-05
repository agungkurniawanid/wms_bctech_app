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
  // Variabel GetX (State) - Nama variabel sisi Klien (seperti grinList) tetap
  final RxList<DeliveryOrderModel> grinList = <DeliveryOrderModel>[].obs;
  final RxList<DeliveryOrderModel> grinListBackup = <DeliveryOrderModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'Created Date'.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeliveryOrderSequenceController _sequenceService =
      DeliveryOrderSequenceController();

  // Debouncer untuk Search
  final Rx<String> _currentSearchQuery = ''.obs;
  Timer? _searchDebounceTimer;
  bool _isSearchOperationRunning = false;
  String _lastCompletedSearchQuery = '';

  // Variabel Pagination
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalLoaded = 0.obs;
  final RxBool isLoadingMore = false.obs;

  @override
  void onReady() {
    _logger.d('🎯 DeliveryOrderController onReady dipanggil');
    super.onReady();
    loadInitialGrinData();
  }

  @override
  void onInit() {
    super.onInit();
    _logger.d('🎯 DeliveryOrderController onInit');
    ever(searchQuery, (String query) {
      _handleSearchQueryChange(query);
    });
  }

  // Method untuk load data awal
  Future<void> loadInitialGrinData() async {
    _logger.d('📥 loadInitialGrinData dipanggil');
    try {
      isLoading.value = true;
      _hasMoreData.value = true;
      _lastDocument = null;
      _totalLoaded.value = 0;
      grinList.clear();
      grinListBackup.clear();

      await _loadMoreGrinData(isInitial: true);

      _logger.d(
        '✅ Data Delivery Order awal berhasil diload: ${grinList.length} items',
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading initial DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  // Method untuk load lebih banyak data (pagination)
  Future<void> loadMoreGrinData() async {
    if (isLoadingMore.value || !_hasMoreData.value || isSearching.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      await _loadMoreGrinData(isInitial: false);
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading more DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Core method untuk load data dengan pagination
  Future<void> _loadMoreGrinData({required bool isInitial}) async {
    _logger.d(
      '📥 _loadMoreGrinData - isInitial: $isInitial, lastDocument: $_lastDocument',
    );

    try {
      Query query = _firestore
          .collection('delivery_order')
          .orderBy(
            'createdat',
            descending: true,
          ) // Sesuai struktur: 'createdat'
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

      final List<DeliveryOrderModel> newGrList = [];

      for (final doc in snapshot.docs) {
        try {
          // Model 'DeliveryOrderModel' diasumsikan menangani mapping
          // (misal: fromFirestore mengambil 'doid' dan 'soid')
          final grModel = DeliveryOrderModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );
          newGrList.add(grModel);
        } catch (e) {
          _logger.e('❌ Error parsing DO document ${doc.id}: $e');
        }
      }

      _lastDocument = snapshot.docs.last;

      if (isInitial) {
        grinList.assignAll(newGrList);
        grinListBackup.assignAll(newGrList);
      } else {
        grinList.addAll(newGrList);
        grinListBackup.addAll(newGrList);
      }

      _totalLoaded.value = grinList.length;
      _hasMoreData.value = snapshot.docs.length == _pageSize;

      _logger.d(
        '✅ Loaded ${newGrList.length} DO documents, total: ${grinList.length}',
      );
      _logger.d('📊 Has more data: ${_hasMoreData.value}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error in _loadMoreGrinData: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Refresh data (pull to refresh)
  Future<void> refreshData() async {
    _logger.d('🔄 refreshData dipanggil');
    try {
      if (isSearching.value) {
        clearSearch();
      }
      await loadInitialGrinData();
    } catch (e, stackTrace) {
      _logger.e('❌ Error refreshing data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    }
  }

  // --- Logika Search (Sistem A) ---
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
    if (grinListBackup.isNotEmpty) {
      grinList.assignAll(grinListBackup);
      _logger.d('✅ Data restored: ${grinList.length} items');
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
      if (grinListBackup.isNotEmpty) {
        grinList.assignAll(grinListBackup);
      }
    } finally {
      _isSearchOperationRunning = false;
    }
  }

  Future<void> _performSearchOperation(String query) async {
    _logger.d(
      '📊 Starting search operation, backup data: ${grinListBackup.length} items',
    );
    if (grinListBackup.isEmpty) {
      _logger.w('⚠️ No backup data available for search');
      return;
    }

    final listToFilter = List<DeliveryOrderModel>.from(grinListBackup);
    final searchKey = query.toLowerCase().trim();
    _logger.d('🔍 Filtering ${listToFilter.length} items for: "$searchKey"');

    try {
      final filteredList = await Isolate.run(() {
        try {
          return listToFilter.where((gr) {
            try {
              // Asumsi model.grId memegang 'doid' dan model.poNumber memegang 'soid'
              final grId = gr.grId.toLowerCase();
              final poNumber = gr.poNumber.toLowerCase(); // Ini adalah 'soid'
              final createdBy = TextHelper.formatUserName(
                // Asumsi model.createdBy memegang 'createdby'
                gr.createdBy ?? 'Unknown',
              ).toLowerCase();

              final hasMatchingDetail = gr.details.any((detail) {
                final sn = detail.sn?.toLowerCase() ?? ''; // Asumsi model.sn
                return sn.contains(searchKey);
              });

              return grId.contains(searchKey) || // Search by DO ID
                  poNumber.contains(searchKey) || // Search by SO ID
                  createdBy.contains(searchKey) || // Search by User
                  hasMatchingDetail; // Search by SN
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
        grinList.assignAll(filteredList);
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

  // --- Logika Search (Sistem B) ---
  void updateSearchQueryGrinPage(String newQuery) {
    _logger.d('🔄 updateSearchQueryGrinPage: "$newQuery"');
    if (newQuery.isEmpty) {
      setSearchMode(false);
    } else {
      setSearchMode(true);
      searchGrin(newQuery);
    }
  }

  void searchGrin(String query) async {
    _logger.d('🔍 searchGrin dipanggil dengan query: "$query"');
    try {
      await _updateSearchState(query, true);
      _logger.d('📊 Data sebelum search: ${grinListBackup.length} items');

      if (query.isEmpty) {
        _logger.d('🔄 Query kosong, restore data dari backup');
        if (grinListBackup.isNotEmpty) {
          grinList.assignAll(grinListBackup);
          _logger.d('✅ Data restored: ${grinList.length} items');
        } else {
          _logger.w('⚠️ Backup data kosong, tidak ada data untuk direstore');
        }
        await _updateSearchState(query, false);
        return;
      }

      final listToFilter = List<DeliveryOrderModel>.from(grinListBackup);
      final searchKey = query.toLowerCase().trim();
      _logger.d('🚀 Memulai filter di Isolate untuk keyword: "$searchKey"');

      final filteredList = await Isolate.run(() {
        return listToFilter.where((gr) {
          // Asumsi model.grId memegang 'doid' dan model.poNumber memegang 'soid'
          final grId = gr.grId.toLowerCase();
          final poNumber = gr.poNumber.toLowerCase(); // Ini adalah 'soid'
          final createdBy = TextHelper.formatUserName(
            gr.createdBy ?? 'Unknown',
          ).toLowerCase();

          final hasMatchingDetail = gr.details.any((detail) {
            final sn = detail.sn?.toLowerCase() ?? '';
            return sn.contains(searchKey);
          });

          return grId.contains(searchKey) || // Search by DO ID
              poNumber.contains(searchKey) || // Search by SO ID
              createdBy.contains(searchKey) || // Search by User
              hasMatchingDetail;
        }).toList();
      });

      _logger.d('🏁 Isolate selesai, hasil: ${filteredList.length} items');

      if (searchQuery.value == query) {
        grinList.assignAll(filteredList);
        await _updateSearchState(query, false);
        _logger.d(
          '✅ Search completed, data diupdate dengan ${filteredList.length} items',
        );
      } else {
        _logger.d('⏭️ Query berubah, abaikan hasil Isolate lama');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error di searchGrin: $e');
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

  // --- Logika Loading (Sistem B) ---
  Future<void> loadGrinData() async {
    _logger.d('📥 loadGrinData dipanggil');
    try {
      isLoading.value = true;
      await getGrinStream().first;
      _logger.d('✅ Data DO berhasil diload');
      isLoading.value = false;
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading DO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      isLoading.value = false;
    }
  }

  Stream<List<DeliveryOrderModel>> getGrinStream() {
    _logger.d('📡 getGrinStream dipanggil');
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final startOfDay = DateTime(
      oneMonthAgo.year,
      oneMonthAgo.month,
      oneMonthAgo.day,
    );

    return _firestore
        .collection('delivery_order')
        .where(
          'createdat', // Sesuai struktur: 'createdat'
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('createdat', descending: true) // Sesuai struktur: 'createdat'
        .snapshots()
        .asyncMap((snapshot) async {
          _logger.d(
            '📊 Mendapatkan ${snapshot.docs.length} documents dari Firestore',
          );
          final List<DeliveryOrderModel> grList = [];
          for (final doc in snapshot.docs) {
            try {
              // Asumsi Model menangani mapping
              final grModel = DeliveryOrderModel.fromFirestore(doc, null);
              grList.add(grModel);
            } catch (e) {
              _logger.e('❌ Error parsing DO document ${doc.id}: $e');
            }
          }

          grList.sort((a, b) {
            // Asumsi Model.createdAt adalah DateTime
            final dateA = a.createdAt;
            final dateB = b.createdAt;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          grinListBackup.value = List.from(grList);
          grinList.value = List.from(grList);
          _logger.d('✅ Backup data diupdate: ${grList.length} items');
          _logger.d('✅ Loaded ${grList.length} DO documents dari last 30 days');
          return grList;
        })
        .handleError((error) {
          _logger.e('❌ Stream error in getGrinStream: $error');
          return <DeliveryOrderModel>[];
        });
  }

  // --- Logika Validasi SN ---
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
            // Asumsi field SN di 'details' adalah 'SN' (uppercase)
            final detailSn = detail['SN'] as String?;
            if (detailSn != null && detailSn.trim().isNotEmpty) {
              final existingSn = detailSn.trim().toLowerCase();
              if (existingSn == trimmedSerial) {
                _logger.w('❌ Serial number duplikat ditemukan:');
                _logger.w('  Serial: $trimmedSerial');
                _logger.w('  DO ID: ${doc.id}'); // doc.id adalah 'doid'
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

  void sortGroupedGrin(String sortBy) {
    selectedSort.value = sortBy;
    final List<DeliveryOrderModel> sortedList = List.from(grinList);

    switch (sortBy) {
      case 'GR ID': // Teks UI, bisa tetap 'GR ID'
        // Asumsi model.grId memegang 'doid'
        sortedList.sort((a, b) => a.grId.compareTo(b.grId));
        break;
      case 'PO Number': // Teks UI, bisa tetap 'PO Number'
        // Asumsi model.poNumber memegang 'soid'
        sortedList.sort((a, b) => a.poNumber.compareTo(b.poNumber));
        break;
      case 'Created Date':
      default:
        sortedList.sort((a, b) {
          // Asumsi model.createdAt adalah DateTime
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
    }
    grinList.assignAll(sortedList);
  }

  Future<bool> isSerialNumberUniqueOptimized(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return true;

      // Query ini mungkin tidak berfungsi seperti yang diharapkan di Firestore
      // jika 'details' berisi map yang kompleks.
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
      // Fallback ke metode global yang lebih lambat
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
            final sn = detail['SN'] as String?; // Asumsi field 'SN'
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

  // Ini adalah metode validasi yang paling direkomendasikan
  Future<bool> isSerialNumberUnique(String serialNumber) async {
    try {
      final trimmed = serialNumber.trim().toLowerCase();
      if (trimmed.isEmpty) return true;

      final doc = await FirebaseFirestore.instance
          .collection('serial_numbers')
          .doc(trimmed)
          .get();

      if (doc.exists) {
        // PERBAIKAN: Logika Anda sudah benar menggunakan 'do_id'
        _logger.w('❌ SN $trimmed sudah ada di DO: ${doc['do_id']}');
        return false;
      }

      _logger.d('✅ SN $trimmed unik secara global');
      return true;
    } catch (e) {
      _logger.e('❌ Error cek SN global: $e');
      return false;
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
    required String grId, // Ini adalah 'doid'
    required List<DeliveryOrderDetailModel> newDetails,
  }) async {
    try {
      final List<String> serialNumbers = [];
      for (final detail in newDetails) {
        // Asumsi model.sn
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

      // Menggunakan metode validasi terbaik
      for (final serialNumber in serialNumbers) {
        final isUnique = await isSerialNumberUnique(serialNumber);
        if (!isUnique) {
          return {
            'success': false,
            'error': 'Serial number "$serialNumber" sudah digunakan di sistem',
          };
        }
      }

      return await updateGrDetails(grId: grId, details: newDetails);
    } catch (e) {
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetailsWithValidation({
    required String grId, // Ini adalah 'doid'
    required List<DeliveryOrderDetailModel> newDetails,
  }) async {
    try {
      final serialNumbersToValidate = newDetails
          .where((detail) => detail.sn != null && detail.sn!.trim().isNotEmpty)
          .map((detail) => detail.sn!)
          .toList();

      _logger.d('🔍 Validasi ${serialNumbersToValidate.length} serial numbers');

      for (final serial in serialNumbersToValidate) {
        // Menggunakan metode validasi yang lebih lambat
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
      return await updateGrDetails(grId: grId, details: newDetails);
    } catch (e) {
      _logger.e('❌ Error update DO details dengan validasi: $e');
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetails({
    required String grId, // Ini adalah 'doid'
    required List<DeliveryOrderDetailModel> details,
  }) async {
    try {
      final docRef = _firestore.collection('delivery_order').doc(grId);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('DO document dengan ID $grId tidak ditemukan');
        }

        transaction.update(docRef, {
          'details': details.map((detail) => detail.toMap()).toList(),
          'updatedat': Timestamp.fromDate(DateTime.now()), // Sesuai struktur
        });
      });

      _logger.d('✅ DO details updated: $grId dengan ${details.length} items');
      return {
        'success': true,
        'message': 'Details berhasil diupdate dengan ${details.length} items',
      };
    } catch (e) {
      _logger.e('❌ Error updating DO details: $e');
      return {'success': false, 'error': 'Gagal update details: $e'};
    }
  }

  Future<String> generateGrId() async {
    final currentYear = DateTime.now().year.toString();

    try {
      final sequenceToUse = await _sequenceService.getNextAvailableSequence();
      final sequenceString = sequenceToUse.toString().padLeft(7, '0');
      // PENYESUAIAN: 'GR' menjadi 'DO'
      final generatedGrId = 'DO$currentYear$sequenceString';

      _logger.d(
        '🎯 Generated DO ID: $generatedGrId (sequence: $sequenceToUse)',
      );

      return generatedGrId;
    } catch (e) {
      _logger.e('❌ CRITICAL: Failed to generate DO ID after retries: $e');

      Get.snackbar(
        'Error',
        'Gagal generate DO ID. Silakan coba lagi.', // 'GR' -> 'DO'
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }

  Future<void> cancelGrCreation(String grId) async {
    try {
      // PENYESUAIAN: 'GR' menjadi 'DO'
      final sequenceMatch = RegExp(r'DO\d{4}(\d{7})$').firstMatch(grId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.cancelReservation(sequence);
          await _markGrAsCancelled(grId);

          _logger.d('✅ DO creation CANCELLED: $grId (sequence: $sequence)');
        }
      }
    } catch (e) {
      _logger.e('Error cancelling DO creation: $e');
    }
  }

  Future<void> _markGrAsCancelled(String grId) async {
    try {
      final docRef = _firestore.collection('delivery_order').doc(grId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'status': 'cancelled',
          'cancelledat': Timestamp.fromDate(DateTime.now()), // Sesuai struktur
        });
        _logger.d('✅ Marked DO as cancelled: $grId');
      }
    } catch (e) {
      _logger.e('Error marking DO as cancelled: $e');
    }
  }

  Future<void> saveSerialNumberGlobal({
    required String serialNumber,
    required String grId, // Ini adalah 'doid'
    required String productId,
  }) async {
    try {
      final trimmed = serialNumber.trim().toLowerCase();
      if (trimmed.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('serial_numbers')
          .doc(trimmed)
          .set({
            'do_id': grId, // Nama field 'do_id' sudah benar
            'productid': productId,
            'createdat': FieldValue.serverTimestamp(), // Sesuai struktur
          });

      _logger.d(
        '✅ Serial number $trimmed disimpan ke koleksi global serial_numbers',
      );
    } catch (e) {
      _logger.e('❌ Gagal simpan serial number global: $e');
    }
  }

  // Ini duplikat dari `sortGroupedGrin`
  void sortGrin(String sortBy) {
    selectedSort.value = sortBy;
    final List<DeliveryOrderModel> sortedList = List.from(grinList);

    switch (sortBy) {
      case 'GR ID':
        // Asumsi model.grId memegang 'doid'
        sortedList.sort((a, b) => a.grId.compareTo(b.grId));
        break;
      case 'PO Number':
        // Asumsi model.poNumber memegang 'soid'
        sortedList.sort((a, b) => a.poNumber.compareTo(b.poNumber));
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
    grinList.assignAll(sortedList);
  }

  Future<bool> addNewGrin({
    required String grId, // Ini adalah 'doid'
    required String poNumber, // Ini adalah 'soid'
    required List<DeliveryOrderDetailModel> details,
  }) async {
    try {
      final now = DateTime.now();
      final username = 'current_user'; // Placeholder

      final grinData = {
        'doid': grId, // Sesuai struktur
        'soid': poNumber, // Sesuai struktur
        'createdby': username, // Sesuai struktur
        'createdat': Timestamp.fromDate(now), // Sesuai struktur
        'status': 'pending', // Asumsi field ini ada
        'details': details.map((d) => d.toMap()).toList(),
      };

      await _firestore.collection('delivery_order').doc(grId).set(grinData);
      _logger.i('✅ DO $grId berhasil ditambahkan');
      return true;
    } catch (e) {
      _logger.e('Error adding new DO: $e');
      return false;
    }
  }

  Future<DeliveryOrderModel?> getGrinById(String grId) async {
    // Ini adalah 'doid'
    try {
      final doc = await FirebaseFirestore.instance
          .collection('delivery_order')
          .doc(grId)
          .get();

      if (doc.exists) {
        // Asumsi Model.fromFirestore menangani mapping
        return DeliveryOrderModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting DO by ID: $e');
      return null;
    }
  }

  Future<void> confirmGrCreation(String grId) async {
    try {
      // PENYESUAIAN: 'GR' menjadi 'DO'
      final sequenceMatch = RegExp(r'DO\d{4}(\d{7})$').firstMatch(grId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.completeReservation(sequence);
          await _markGrAsCompleted(grId);
          _logger.d('✅ DO creation CONFIRMED: $grId');
        }
      }
    } catch (e) {
      _logger.e('Error confirming DO creation: $e');
    }
  }

  Future<void> _markGrAsCompleted(String grId) async {
    try {
      await _firestore.collection('delivery_order').doc(grId).update({
        'status': 'completed',
        'completedat': Timestamp.fromDate(DateTime.now()), // Sesuai struktur
      });
      _logger.d('✅ Marked DO as completed: $grId');
    } catch (e) {
      _logger.e('Error marking DO as completed: $e');
    }
  }

  Future<String> generateGrIdAtSave() async {
    final currentYear = DateTime.now().year.toString();
    try {
      final generatedGrId = await FirebaseFirestore.instance
          .runTransaction<String>((transaction) async {
            // PENYESUAIAN: Kueri ke field 'doid' dan prefix 'DO'
            final lastGrQuery = await _firestore
                .collection('delivery_order')
                .where('doid', isGreaterThanOrEqualTo: 'DO$currentYear')
                .where('doid', isLessThan: 'DO${int.parse(currentYear) + 1}')
                .orderBy('doid', descending: true)
                .limit(1)
                .get();

            int nextSequence = 1;

            if (lastGrQuery.docs.isNotEmpty) {
              final lastGrId = lastGrQuery.docs.first.id;
              // PENYESUAIAN: 'GR' menjadi 'DO'
              final sequenceMatch = RegExp(
                r'DO\d{4}(\d{7})$',
              ).firstMatch(lastGrId);
              if (sequenceMatch != null) {
                final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
                nextSequence = lastSequence + 1;
              }
            }
            final sequenceString = nextSequence.toString().padLeft(7, '0');
            // PENYESUAIAN: 'GR' menjadi 'DO'
            final newGrId = 'DO$currentYear$sequenceString';
            final existingDoc = await _firestore
                .collection('delivery_order')
                .doc(newGrId)
                .get();
            if (existingDoc.exists) {
              nextSequence++;
              final retrySequenceString = nextSequence.toString().padLeft(
                7,
                '0',
              );
              // PENYESUAIAN: 'GR' menjadi 'DO'
              final retryGrId = 'DO$currentYear$retrySequenceString';
              final retryExistingDoc = await _firestore
                  .collection('delivery_order')
                  .doc(retryGrId)
                  .get();
              if (retryExistingDoc.exists) {
                throw Exception('DO ID sudah digunakan, silakan coba lagi');
              }
              return retryGrId;
            }

            return newGrId;
          }, timeout: const Duration(seconds: 10));

      _logger.d('✅ Generated DO ID: $generatedGrId');
      return generatedGrId;
    } catch (e) {
      _logger.e('❌ Error generating DO ID: $e');
      throw Exception('Gagal generate DO ID: $e');
    }
  }

  Future<Map<String, dynamic>> saveGrWithGeneratedId({
    required String poNumber, // Ini adalah 'soid'
    required List<DeliveryOrderDetailModel> details,
    required String currentUser,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final grId = await generateGrIdAtSave(); // Ini menghasilkan 'doid'

        if (grId.isEmpty) {
          throw Exception('Gagal generate DO ID');
        }
        final newGr = DeliveryOrderModel(
          grId: grId, // Properti model (diasumsikan 'grId' akan map ke 'doid')
          poNumber:
              poNumber, // Properti model (diasumsikan 'poNumber' akan map ke 'soid')
          createdBy: currentUser, // Properti model (map ke 'createdby')
          createdAt: DateTime.now(), // Properti model (map ke 'createdat')
          status: 'drafted',
          details: details,
        );

        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore.collection('delivery_order').doc(grId);
          final docSnapshot = await transaction.get(docRef);

          if (docSnapshot.exists) {
            throw Exception('DO ID $grId sudah digunakan oleh pengguna lain');
          }
          // Asumsi newGr.toFirestore() akan map ke field 'doid', 'soid', dll.
          transaction.set(docRef, newGr.toFirestore());
        });

        _logger.d('✅ DO berhasil disimpan dengan ID: $grId');

        return {
          'success': true,
          'grId': grId, // Mengembalikan 'doid'
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

  // Getter untuk access dari UI
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
