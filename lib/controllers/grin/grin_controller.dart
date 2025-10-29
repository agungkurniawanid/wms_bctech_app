import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/controllers/grin/gr_sequence_controller.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_detail_model.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_model.dart';
import 'package:logger/web.dart';

class GrinController extends GetxController {
  final Logger _logger = Logger();
  final RxList<GoodReceiveSerialNumberModel> grinList =
      <GoodReceiveSerialNumberModel>[].obs;
  final RxList<GoodReceiveSerialNumberModel> grinListBackup =
      <GoodReceiveSerialNumberModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'Created Date'.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GrSequenceService _sequenceService = GrSequenceService();

  @override
  void onReady() {
    super.onReady();
    loadGrinData();
  }

  Future<bool> isSerialNumberUniqueGlobal(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim().toLowerCase();

      if (trimmedSerial.isEmpty) {
        return true;
      }
      _logger.d('🔍 Validasi serial number global: $trimmedSerial');
      final querySnapshot = await _firestore.collection('gr_in').get();

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

  // Tambahkan method ini ke dalam GrinController class
  void sortGroupedGrin(String sortBy) {
    selectedSort.value = sortBy;

    final List<GoodReceiveSerialNumberModel> sortedList = List.from(grinList);

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
  void searchGrin(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      grinList.assignAll(grinListBackup);
      return;
    }

    final filteredList = grinListBackup.where((gr) {
      final grId = gr.grId.toLowerCase();
      final poNumber = gr.poNumber.toLowerCase();
      final searchLower = query.toLowerCase();

      return grId.contains(searchLower) || poNumber.contains(searchLower);
    }).toList();

    grinList.assignAll(filteredList);
  }

  Future<bool> isSerialNumberUniqueOptimized(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim();
      if (trimmedSerial.isEmpty) return true;

      final querySnapshot = await _firestore
          .collection('gr_in')
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
      final querySnapshot = await _firestore.collection('gr_in').get();

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
    required List<GoodReceiveSerialNumberDetailModel> newDetails,
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
    required List<GoodReceiveSerialNumberDetailModel> newDetails,
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

  Stream<List<GoodReceiveSerialNumberModel>> getGrinStream() {
    // Hitung batas waktu: 30 hari ke belakang
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final startOfDay = DateTime(
      oneMonthAgo.year,
      oneMonthAgo.month,
      oneMonthAgo.day,
    );

    return FirebaseFirestore.instance
        .collection('gr_in')
        .where(
          'createdat',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('createdat', descending: true) // Urutkan di Firestore
        .snapshots()
        .asyncMap((snapshot) async {
          final List<GoodReceiveSerialNumberModel> grList = [];

          for (final doc in snapshot.docs) {
            try {
              final grModel = GoodReceiveSerialNumberModel.fromFirestore(
                doc,
                null,
              );
              grList.add(grModel);
            } catch (e) {
              _logger.e('Error parsing GR document ${doc.id}: $e');
            }
          }

          // Tidak perlu sort lagi karena sudah di-orderBy di Firestore
          // Tapi tetap sort ulang jika ada data yang createdAt null
          grList.sort((a, b) {
            final dateA = a.createdAt;
            final dateB = b.createdAt;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // Update reactive list
          grinList.value = grList;
          _logger.d('Loaded ${grList.length} GR documents from last 30 days');

          return grList;
        })
        .handleError((error) {
          _logger.e('Stream error in getGrinStream: $error');
          return <GoodReceiveSerialNumberModel>[];
        });
  }

  Future<Map<String, dynamic>> updateGrDetails({
    required String grId,
    required List<GoodReceiveSerialNumberDetailModel> details,
  }) async {
    try {
      final docRef = _firestore.collection('gr_in').doc(grId);

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
      final docRef = _firestore.collection('gr_in').doc(grId);
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

  Future<void> loadGrinData() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = true;
      });

      await getGrinStream().first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    } catch (e) {
      _logger.e('Error loading GRIN data: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
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

  @override
  void onInit() {
    super.onInit();

    Future.delayed(Duration.zero, () {
      loadGrinData();
    });
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));
      loadGrinData();
    } catch (e) {
      _logger.e('Error refreshing GRIN data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    grinList.assignAll(grinListBackup);
  }

  void sortGrin(String sortBy) {
    selectedSort.value = sortBy;

    final List<GoodReceiveSerialNumberModel> sortedList = List.from(grinList);

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
    required List<GoodReceiveSerialNumberDetailModel> details,
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

      await _firestore.collection('gr_in').doc(grId).set(grinData);
      _logger.i('✅ GRIN $grId berhasil ditambahkan');
      return true;
    } catch (e) {
      _logger.e('Error adding new GRIN: $e');
      return false;
    }
  }

  Future<GoodReceiveSerialNumberModel?> getGrinById(String grId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gr_in')
          .doc(grId)
          .get();

      if (doc.exists) {
        return GoodReceiveSerialNumberModel.fromFirestore(doc, null);
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
      await _firestore.collection('gr_in').doc(grId).update({
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
                .collection('gr_in')
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
                .collection('gr_in')
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
                  .collection('gr_in')
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
    required List<GoodReceiveSerialNumberDetailModel> details,
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
        final newGr = GoodReceiveSerialNumberModel(
          grId: grId,
          poNumber: poNumber,
          createdBy: currentUser,
          createdAt: DateTime.now(),
          details: details,
        );

        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore.collection('gr_in').doc(grId);
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

  void updateSearchQueryGrinPage(String newQuery) {
    searchGrin(newQuery);
  }

  Future<void> handleRefreshGrinPage() async {
    await refreshData();
  }

  @override
  void onClose() {
    // Cleanup jika diperlukan
    super.onClose();
  }
}
