import 'dart:async';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/controllers/good_receipt/good_receipt_sequence_controller.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_detail_model.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_model.dart';
import 'package:logger/web.dart';

class GoodReceiptController extends GetxController {
  final Logger _logger = Logger();
  final RxList<GoodReceiptModel> grinList = <GoodReceiptModel>[].obs;
  final RxList<GoodReceiptModel> grinListBackup = <GoodReceiptModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'Created Date'.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoodReceiptSequenceController _sequenceService =
      GoodReceiptSequenceController();

  // ✅ FIXED: Gunakan debouncer untuk search
  final Rx<String> _currentSearchQuery = ''.obs;
  Timer? _searchDebounceTimer;

  // ✅ FIXED: Track search operation
  bool _isSearchOperationRunning = false;
  String _lastCompletedSearchQuery = '';

  // Pagination variables
  final int _pageSize = 20; // Fetch 20 data per kali
  DocumentSnapshot? _lastDocument; // Last document untuk pagination
  final RxBool _hasMoreData = true.obs; // Flag apakah masih ada data
  final RxInt _totalLoaded = 0.obs; // Total data yang sudah diload
  final RxBool isLoadingMore = false.obs;

  @override
  void onReady() {
    _logger.d('🎯 GoodReceiptController onReady dipanggil');
    super.onReady();
    // loadGrinData();
    loadInitialGrinData();
  }

  @override
  void onInit() {
    super.onInit();
    _logger.d('🎯 GoodReceiptController onInit');

    // Listen untuk search query changes dengan debounce
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

      _logger.d('✅ Data GRIN awal berhasil diload: ${grinList.length} items');
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading initial GRIN data: $e');
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
      _logger.e('❌ Error loading more GRIN data: $e');
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
          .collection('good_receipt')
          .orderBy('createdat', descending: true)
          .limit(_pageSize);

      // Jika bukan initial load, gunakan lastDocument untuk pagination
      if (!isInitial && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMoreData.value = false;
        _logger.d('🏁 Tidak ada data lagi untuk diload');
        return;
      }

      final List<GoodReceiptModel> newGrList = [];

      for (final doc in snapshot.docs) {
        try {
          final grModel = GoodReceiptModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );
          newGrList.add(grModel);
        } catch (e) {
          _logger.e('❌ Error parsing GR document ${doc.id}: $e');
        }
      }

      // Update last document untuk pagination berikutnya
      _lastDocument = snapshot.docs.last;

      // Tambahkan data baru ke list
      if (isInitial) {
        grinList.assignAll(newGrList);
        grinListBackup.assignAll(newGrList);
      } else {
        grinList.addAll(newGrList);
        grinListBackup.addAll(newGrList);
      }

      _totalLoaded.value = grinList.length;

      // Cek apakah masih ada data lagi
      _hasMoreData.value = snapshot.docs.length == _pageSize;

      _logger.d(
        '✅ Loaded ${newGrList.length} GR documents, total: ${grinList.length}',
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
      // Cancel search mode jika aktif
      if (isSearching.value) {
        clearSearch();
      }

      await loadInitialGrinData();
    } catch (e, stackTrace) {
      _logger.e('❌ Error refreshing data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    }
  }

  void _handleSearchQueryChange(String query) {
    _logger.d('🔄 Search query changed: "$query"');

    // Cancel previous debounce
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _logger.d('🧹 Query kosong, clear search immediately');
      _clearSearchImmediately();
      return;
    }

    // Debounce search operation
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _executeSearch(query);
    });
  }

  void _clearSearchImmediately() {
    _logger.d('🧹 Immediate clear search');

    // Cancel any pending search
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;

    // Reset state
    isSearching.value = false;
    searchQuery.value = '';

    // Restore data
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

      // Fallback: restore data on error
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

    final listToFilter = List<GoodReceiptModel>.from(grinListBackup);
    final searchKey = query.toLowerCase().trim();

    _logger.d('🔍 Filtering ${listToFilter.length} items for: "$searchKey"');

    try {
      final filteredList = await Isolate.run(() {
        try {
          return listToFilter.where((gr) {
            try {
              final grId = gr.grId.toLowerCase();
              final poNumber = gr.poNumber.toLowerCase();
              final createdBy = TextHelper.formatUserName(
                gr.createdBy ?? 'Unknown',
              ).toLowerCase();

              final hasMatchingDetail = gr.details.any((detail) {
                final sn = detail.sn?.toLowerCase() ?? '';
                return sn.contains(searchKey);
              });

              return grId.contains(searchKey) ||
                  poNumber.contains(searchKey) ||
                  createdBy.contains(searchKey) ||
                  hasMatchingDetail;
            } catch (e) {
              return false;
            }
          }).toList();
        } catch (e) {
          return <GoodReceiptModel>[];
        }
      });

      _logger.d('🏁 Isolate completed, found: ${filteredList.length} items');

      // ✅ FIXED: Check if we should still update (query hasn't changed)
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

  // ✅ FIXED: Enhanced setSearchMode
  void setSearchMode(bool searching) {
    _logger.d('🔄 setSearchMode: $searching, current: ${isSearching.value}');

    if (isSearching.value == searching) {
      _logger.d('⏭️ Same search mode, skipping');
      return;
    }

    // Cancel any pending search operations
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;

    isSearching.value = searching;

    if (!searching) {
      _clearSearchImmediately();
    } else {
      _logger.d('🔍 Entering search mode');
    }
  }

  // ✅ FIXED: Simplified updateSearchQuery
  void updateSearchQuery(String newQuery) {
    _logger.d('📝 updateSearchQuery: "$newQuery"');
    searchQuery.value = newQuery;
  }

  // ✅ FIXED: Enhanced clearSearch
  void clearSearch() {
    _logger.d('🧹 clearSearch called');
    setSearchMode(false);
  }

  void updateSearchQueryGrinPage(String newQuery) {
    _logger.d('🔄 updateSearchQueryGrinPage: "$newQuery"');

    // ✅ FIXED: Handle empty query dengan benar
    if (newQuery.isEmpty) {
      setSearchMode(false);
    } else {
      setSearchMode(true);
      searchGrin(newQuery);
    }
  }

  // ✅ PERBAIKAN: Gunakan Isolate.run untuk filter async
  // Di GoodReceiptController - PERBAIKI method searchGrin
  void searchGrin(String query) async {
    _logger.d('🔍 searchGrin dipanggil dengan query: "$query"');

    try {
      // GUNAKAN METHOD INI UNTUK MEMASTIKAN KONSISTENSI STATE
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

      final listToFilter = List<GoodReceiptModel>.from(grinListBackup);
      final searchKey = query.toLowerCase().trim();

      _logger.d('🚀 Memulai filter di Isolate untuk keyword: "$searchKey"');

      final filteredList = await Isolate.run(() {
        return listToFilter.where((gr) {
          final grId = gr.grId.toLowerCase();
          final poNumber = gr.poNumber.toLowerCase();
          final createdBy = TextHelper.formatUserName(
            gr.createdBy ?? 'Unknown',
          ).toLowerCase();

          final hasMatchingDetail = gr.details.any((detail) {
            final sn = detail.sn?.toLowerCase() ?? '';
            return sn.contains(searchKey);
          });

          return grId.contains(searchKey) ||
              poNumber.contains(searchKey) ||
              createdBy.contains(searchKey) ||
              hasMatchingDetail;
        }).toList();
      });

      _logger.d('🏁 Isolate selesai, hasil: ${filteredList.length} items');

      // PASTIKAN QUERY MASIH SAMA SEBELUM UPDATE STATE
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
      // PASTIKAN STATE DIBERSIHKAN MESKIPUN ERROR
      await _updateSearchState('', false);
    }
  }

  // TAMBAHKAN METHOD BARU UNTUK MENGATUR STATE DENGAN AMAN
  Future<void> _updateSearchState(String query, bool searching) async {
    // GUNAKAN MICROTASK UNTUK MEMASTIKAN UPDATE SETELAH BUILD CYCLE
    await Future.microtask(() {
      searchQuery.value = query;
      isSearching.value = searching;
    });
  }

  // ✅ PERBAIKAN: Pastikan backup data selalu terisi
  Future<void> loadGrinData() async {
    _logger.d('📥 loadGrinData dipanggil');
    try {
      isLoading.value = true;

      await getGrinStream().first;
      _logger.d('✅ Data GRIN berhasil diload');

      isLoading.value = false;
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading GRIN data: $e');
      _logger.e('📋 Stack trace: $stackTrace');
      isLoading.value = false;
    }
  }

  Stream<List<GoodReceiptModel>> getGrinStream() {
    _logger.d('📡 getGrinStream dipanggil');

    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final startOfDay = DateTime(
      oneMonthAgo.year,
      oneMonthAgo.month,
      oneMonthAgo.day,
    );

    return _firestore
        .collection('good_receipt')
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

          final List<GoodReceiptModel> grList = [];

          for (final doc in snapshot.docs) {
            try {
              final grModel = GoodReceiptModel.fromFirestore(doc, null);
              grList.add(grModel);
            } catch (e) {
              _logger.e('❌ Error parsing GR document ${doc.id}: $e');
            }
          }

          // Sort by created date
          grList.sort((a, b) {
            final dateA = a.createdAt;
            final dateB = b.createdAt;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // ✅ PERBAIKAN: Pastikan backup data selalu terupdate
          grinListBackup.value = List.from(grList);
          grinList.value = List.from(grList);

          _logger.d('✅ Backup data diupdate: ${grList.length} items');
          _logger.d('✅ Loaded ${grList.length} GR documents dari last 30 days');

          return grList;
        })
        .handleError((error) {
          _logger.e('❌ Stream error in getGrinStream: $error');
          return <GoodReceiptModel>[];
        });
  }

  Future<bool> isSerialNumberUniqueGlobal(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim().toLowerCase();

      if (trimmedSerial.isEmpty) {
        return true;
      }
      _logger.d('🔍 Validasi serial number global: $trimmedSerial');
      final querySnapshot = await _firestore.collection('good_receipt').get();

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
                _logger.w('   Serial: $trimmedSerial');
                _logger.w('   GR ID: ${doc.id}');
                _logger.w('   Product: ${detail['productid']}');
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

  // Tambahkan method ini ke dalam GoodReceiptController class
  void sortGroupedGrin(String sortBy) {
    selectedSort.value = sortBy;

    final List<GoodReceiptModel> sortedList = List.from(grinList);

    switch (sortBy) {
      case 'GR ID':
        sortedList.sort((a, b) => a.grId.compareTo(b.grId));
        break;
      case 'PO Number':
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

  // Update method search untuk mendukung grouped data
  // Di dalam GoodReceiptController class

  Future<bool> isSerialNumberUniqueOptimized(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return true;

      final querySnapshot = await _firestore
          .collection('good_receipt')
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
      final querySnapshot = await _firestore.collection('good_receipt').get();

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
      final trimmed = serialNumber.trim().toLowerCase();
      if (trimmed.isEmpty) return true;

      final doc = await FirebaseFirestore.instance
          .collection('serial_numbers')
          .doc(trimmed)
          .get();

      if (doc.exists) {
        _logger.w('❌ SN $trimmed sudah ada di GR: ${doc['gr_id']}');
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
    required String grId,
    required List<GoodReceiptDetailModel> newDetails,
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

      return await updateGrDetails(grId: grId, details: newDetails);
    } catch (e) {
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetailsWithValidation({
    required String grId,
    required List<GoodReceiptDetailModel> newDetails,
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
      return await updateGrDetails(grId: grId, details: newDetails);
    } catch (e) {
      _logger.e('❌ Error update GR details dengan validasi: $e');
      return {'success': false, 'error': 'Validasi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGrDetails({
    required String grId,
    required List<GoodReceiptDetailModel> details,
  }) async {
    try {
      final docRef = _firestore.collection('good_receipt').doc(grId);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('GR document dengan ID $grId tidak ditemukan');
        }

        transaction.update(docRef, {
          'details': details.map((detail) => detail.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      _logger.d('✅ GR details updated: $grId dengan ${details.length} items');
      return {
        'success': true,
        'message': 'Details berhasil diupdate dengan ${details.length} items',
      };
    } catch (e) {
      _logger.e('❌ Error updating GR details: $e');
      return {'success': false, 'error': 'Gagal update details: $e'};
    }
  }

  Future<String> generateGrId() async {
    final currentYear = DateTime.now().year.toString();

    try {
      final sequenceToUse = await _sequenceService.getNextAvailableSequence();
      final sequenceString = sequenceToUse.toString().padLeft(7, '0');
      final generatedGrId = 'GR$currentYear$sequenceString';

      _logger.d(
        '🎯 Generated GR ID: $generatedGrId (sequence: $sequenceToUse)',
      );

      return generatedGrId;
    } catch (e) {
      _logger.e('❌ CRITICAL: Failed to generate GR ID after retries: $e');

      Get.snackbar(
        'Error',
        'Gagal generate GR ID. Silakan coba lagi.',
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
      final sequenceMatch = RegExp(r'GR\d{4}(\d{7})$').firstMatch(grId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.cancelReservation(sequence);
          await _markGrAsCancelled(grId);

          _logger.d('✅ GR creation CANCELLED: $grId (sequence: $sequence)');
        }
      }
    } catch (e) {
      _logger.e('Error cancelling GR creation: $e');
    }
  }

  Future<void> _markGrAsCancelled(String grId) async {
    try {
      final docRef = _firestore.collection('good_receipt').doc(grId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'status': 'cancelled',
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
        });
        _logger.d('✅ Marked GR as cancelled: $grId');
      }
    } catch (e) {
      _logger.e('Error marking GR as cancelled: $e');
    }
  }

  Future<void> saveSerialNumberGlobal({
    required String serialNumber,
    required String grId,
    required String productId,
  }) async {
    try {
      final trimmed = serialNumber.trim().toLowerCase();
      if (trimmed.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('serial_numbers')
          .doc(trimmed)
          .set({
            'gr_id': grId,
            'productid': productId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _logger.d(
        '✅ Serial number $trimmed disimpan ke koleksi global serial_numbers',
      );
    } catch (e) {
      _logger.e('❌ Gagal simpan serial number global: $e');
    }
  }

  // Future<void> refreshData() async {
  //   try {
  //     isLoading.value = true;
  //     await Future.delayed(const Duration(seconds: 1));
  //     loadGrinData();
  //   } catch (e) {
  //     _logger.e('Error refreshing GRIN data: $e');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void sortGrin(String sortBy) {
    selectedSort.value = sortBy;

    final List<GoodReceiptModel> sortedList = List.from(grinList);

    switch (sortBy) {
      case 'GR ID':
        sortedList.sort((a, b) => a.grId.compareTo(b.grId));
        break;
      case 'PO Number':
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
    required String grId,
    required String poNumber,
    required List<GoodReceiptDetailModel> details,
  }) async {
    try {
      final now = DateTime.now();
      final username = 'current_user';

      final grinData = {
        'grid': grId,
        'ponumber': poNumber,
        'createdby': username,
        'createdat': Timestamp.fromDate(now),
        'status': 'pending',
        'details': details.map((d) => d.toMap()).toList(),
      };

      await _firestore.collection('good_receipt').doc(grId).set(grinData);
      _logger.i('✅ GRIN $grId berhasil ditambahkan');
      return true;
    } catch (e) {
      _logger.e('Error adding new GRIN: $e');
      return false;
    }
  }

  Future<GoodReceiptModel?> getGrinById(String grId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('good_receipt')
          .doc(grId)
          .get();

      if (doc.exists) {
        return GoodReceiptModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting GRIN by ID: $e');
      return null;
    }
  }

  Future<void> confirmGrCreation(String grId) async {
    try {
      final sequenceMatch = RegExp(r'GR\d{4}(\d{7})$').firstMatch(grId);
      if (sequenceMatch != null) {
        final sequence = int.tryParse(sequenceMatch.group(1)!);
        if (sequence != null) {
          await _sequenceService.completeReservation(sequence);
          await _markGrAsCompleted(grId);
          _logger.d('✅ GR creation CONFIRMED: $grId');
        }
      }
    } catch (e) {
      _logger.e('Error confirming GR creation: $e');
    }
  }

  Future<void> _markGrAsCompleted(String grId) async {
    try {
      await _firestore.collection('good_receipt').doc(grId).update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      _logger.d('✅ Marked GR as completed: $grId');
    } catch (e) {
      _logger.e('Error marking GR as completed: $e');
    }
  }

  Future<String> generateGrIdAtSave() async {
    final currentYear = DateTime.now().year.toString();
    try {
      final generatedGrId = await FirebaseFirestore.instance
          .runTransaction<String>((transaction) async {
            final lastGrQuery = await _firestore
                .collection('good_receipt')
                .where('grid', isGreaterThanOrEqualTo: 'GR$currentYear')
                .where('grid', isLessThan: 'GR${int.parse(currentYear) + 1}')
                .orderBy('grid', descending: true)
                .limit(1)
                .get();

            int nextSequence = 1;

            if (lastGrQuery.docs.isNotEmpty) {
              final lastGrId = lastGrQuery.docs.first.id;
              final sequenceMatch = RegExp(
                r'GR\d{4}(\d{7})$',
              ).firstMatch(lastGrId);
              if (sequenceMatch != null) {
                final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
                nextSequence = lastSequence + 1;
              }
            }
            final sequenceString = nextSequence.toString().padLeft(7, '0');
            final newGrId = 'GR$currentYear$sequenceString';
            final existingDoc = await _firestore
                .collection('good_receipt')
                .doc(newGrId)
                .get();
            if (existingDoc.exists) {
              nextSequence++;
              final retrySequenceString = nextSequence.toString().padLeft(
                7,
                '0',
              );
              final retryGrId = 'GR$currentYear$retrySequenceString';
              final retryExistingDoc = await _firestore
                  .collection('good_receipt')
                  .doc(retryGrId)
                  .get();
              if (retryExistingDoc.exists) {
                throw Exception('GR ID sudah digunakan, silakan coba lagi');
              }
              return retryGrId;
            }

            return newGrId;
          }, timeout: const Duration(seconds: 10));

      _logger.d('✅ Generated GR ID: $generatedGrId');
      return generatedGrId;
    } catch (e) {
      _logger.e('❌ Error generating GR ID: $e');
      throw Exception('Gagal generate GR ID: $e');
    }
  }

  Future<Map<String, dynamic>> saveGrWithGeneratedId({
    required String poNumber,
    required List<GoodReceiptDetailModel> details,
    required String currentUser,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final grId = await generateGrIdAtSave();

        if (grId.isEmpty) {
          throw Exception('Gagal generate GR ID');
        }
        final newGr = GoodReceiptModel(
          grId: grId,
          poNumber: poNumber,
          createdBy: currentUser,
          createdAt: DateTime.now(),
          status: 'drafted',
          details: details,
        );

        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore.collection('good_receipt').doc(grId);
          final docSnapshot = await transaction.get(docRef);

          if (docSnapshot.exists) {
            throw Exception('GR ID $grId sudah digunakan oleh pengguna lain');
          }

          transaction.set(docRef, newGr.toFirestore());
        });

        _logger.d('✅ GR berhasil disimpan dengan ID: $grId');

        return {
          'success': true,
          'grId': grId,
          'message': 'GR berhasil disimpan',
        };
      } catch (e) {
        retryCount++;
        _logger.e('❌ Attempt $retryCount failed: $e');

        if (retryCount >= maxRetries) {
          return {
            'success': false,
            'error': 'Gagal menyimpan GR setelah $maxRetries percobaan: $e',
          };
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return {'success': false, 'error': 'Gagal menyimpan GR'};
  }

  Future<void> handleRefreshGoodReceiptPage() async {
    await refreshData();
  }

  // Getter untuk access dari UI
  bool get hasMoreData => _hasMoreData.value;
  bool get isLoadingMoreData => isLoadingMore.value;
  int get totalLoaded => _totalLoaded.value;

  @override
  void onClose() {
    _logger.d('🧹 GoodReceiptController onClose');
    _searchDebounceTimer?.cancel();
    _isSearchOperationRunning = false;
    super.onClose();
  }
}
