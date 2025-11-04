import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class DeliveryOrderSequenceController extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String sequenceCollection = 'gr_sequences';
  static const String reservationCollection = 'gr_reservations';
  static const String grinCollection = 'good_receipt';
  static const int maxRetries = 5;
  static const int reservationTimeoutMinutes = 5;

  @override
  void onInit() {
    super.onInit();
    _startAutoCleanup();
  }

  void _startAutoCleanup() {
    Future.delayed(const Duration(minutes: 5), () {
      cleanupExpiredReservations();
      _startAutoCleanup();
    });
  }

  Future<int> getNextAvailableSequence() async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await cleanupExpiredReservations();
        final cancelledSequences = await _findCancelledSequencesFromToday();

        if (cancelledSequences.isNotEmpty) {
          for (final sequence in cancelledSequences) {
            final reserved = await _tryReserveSequence(sequence);
            if (reserved) {
              _logger.d('🔄 Using CANCELLED sequence: $sequence');
              return sequence;
            }
          }
        }
        final nextSequence = await _findNextAvailableNewSequence();
        final reserved = await _tryReserveSequence(nextSequence);

        if (reserved) {
          _logger.d('📈 Using NEW sequence: $nextSequence');
          return nextSequence;
        }
        retryCount++;
        await Future.delayed(Duration(milliseconds: 200 * retryCount));
      } catch (e) {
        _logger.e(
          'Error getting next available sequence (attempt ${retryCount + 1}): $e',
        );
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 200 * retryCount));
      }
    }
    throw Exception(
      'Failed to get available sequence after $maxRetries attempts',
    );
  }

  Future<int> _findNextAvailableNewSequence() async {
    try {
      final lastSequence = await _getLastSuccessfulSequence();
      final currentYear = DateTime.now().year;
      int candidateSequence = lastSequence + 1;

      for (int i = 0; i < 100; i++) {
        final docId =
            '${currentYear}_${candidateSequence.toString().padLeft(7, '0')}';
        final doc = await _firestore
            .collection(reservationCollection)
            .doc(docId)
            .get();

        if (!doc.exists) {
          _logger.d('Found available new sequence: $candidateSequence');
          return candidateSequence;
        }

        final data = doc.data();
        if (data != null) {
          final status = data['status'] as String?;
          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
          final now = DateTime.now();

          if (status == 'completed') {
            candidateSequence++;
            continue;
          }
          if (status == 'cancelled' ||
              status == 'expired' ||
              (status == 'reserved' &&
                  expiresAt != null &&
                  expiresAt.isBefore(now))) {
            _logger.d(
              'Found available sequence (was $status): $candidateSequence',
            );
            return candidateSequence;
          }
          if (status == 'reserved' &&
              expiresAt != null &&
              expiresAt.isAfter(now)) {
            candidateSequence++;
            continue;
          }
        }
        return candidateSequence;
      }
      _logger.w(
        'Could not find available sequence in 100 attempts, using lastSequence + 1',
      );
      return lastSequence + 1;
    } catch (e) {
      _logger.e('Error finding next available sequence: $e');
      return await _getLastSuccessfulSequence() + 1;
    }
  }

  Future<bool> _tryReserveSequence(int sequence) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final docId = '${year}_${sequence.toString().padLeft(7, '0')}';
      final reservationDoc = _firestore
          .collection(reservationCollection)
          .doc(docId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(reservationDoc);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final status = data['status'] as String?;
          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

          if (status == 'reserved' &&
              expiresAt != null &&
              expiresAt.isAfter(now)) {
            _logger.d(
              '❌ Sequence $sequence already reserved (expires: $expiresAt)',
            );
            return false;
          }

          if (status == 'completed') {
            _logger.d('❌ Sequence $sequence already completed');
            return false;
          }

          if (status == 'expired' || status == 'cancelled') {
            transaction.update(reservationDoc, {
              'sequence': sequence,
              'reservedAt': Timestamp.fromDate(now),
              'expiresAt': Timestamp.fromDate(
                now.add(Duration(minutes: reservationTimeoutMinutes)),
              ),
              'status': 'reserved',
              'updatedAt': Timestamp.fromDate(now),
              'previousStatus': status,
            });
            _logger.d('✅ Reserved sequence $sequence (was $status)');
            return true;
          }
        }

        transaction.set(reservationDoc, {
          'sequence': sequence,
          'year': year,
          'reservedAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(
            now.add(Duration(minutes: reservationTimeoutMinutes)),
          ),
          'status': 'reserved',
          'createdAt': Timestamp.fromDate(now),
        });

        _logger.d('✅ Reserved NEW sequence $sequence');
        return true;
      }, timeout: const Duration(seconds: 10));
    } catch (e) {
      _logger.e('Error trying to reserve sequence $sequence: $e');
      return false;
    }
  }

  Future<List<int>> _findCancelledSequencesFromToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final currentYear = now.year;
      final cancelledSequences = <int>{};

      final cancelledReservations = await _firestore
          .collection(reservationCollection)
          .where('year', isEqualTo: currentYear)
          .where('status', isEqualTo: 'cancelled')
          .where(
            'cancelledAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('cancelledAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (final doc in cancelledReservations.docs) {
        final data = doc.data();
        final sequence = data['sequence'] as int?;
        if (sequence != null) {
          cancelledSequences.add(sequence);
        }
      }
      try {
        final grinCancelled = await _firestore
            .collection(grinCollection)
            .where('grid', isGreaterThanOrEqualTo: 'GR$currentYear')
            .where('grid', isLessThan: 'GR${currentYear + 1}')
            .where('status', isEqualTo: 'cancelled')
            .where(
              'cancelledAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('cancelledAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (final doc in grinCancelled.docs) {
          final grId = doc.id;
          final sequence = _extractSequenceFromGrId(grId);
          if (sequence != null) {
            cancelledSequences.add(sequence);
          }
        }
      } catch (e) {
        _logger.w('Could not query good_receipt for cancelled sequences: $e');
      }
      final sortedList = cancelledSequences.toList()..sort();

      if (sortedList.isNotEmpty) {
        _logger.d(
          'Found ${sortedList.length} cancelled sequences from today: $sortedList',
        );
      }

      return sortedList;
    } catch (e) {
      _logger.e('Error finding cancelled sequences: $e');
      return [];
    }
  }

  int? _extractSequenceFromGrId(String grId) {
    final sequenceMatch = RegExp(r'GR\d{4}(\d{7})$').firstMatch(grId);
    if (sequenceMatch != null) {
      return int.tryParse(sequenceMatch.group(1)!);
    }
    return null;
  }

  Future<int> _getLastSuccessfulSequence() async {
    try {
      final currentYear = DateTime.now().year;

      final lastReservation = await _firestore
          .collection(reservationCollection)
          .where('year', isEqualTo: currentYear)
          .where('status', isEqualTo: 'completed')
          .orderBy('sequence', descending: true)
          .limit(1)
          .get();

      if (lastReservation.docs.isNotEmpty) {
        final sequence = lastReservation.docs.first.data()['sequence'] as int;
        _logger.d('Last successful sequence from reservations: $sequence');
        return sequence;
      }
      try {
        final lastGrQuery = await _firestore
            .collection(grinCollection)
            .where('grid', isGreaterThanOrEqualTo: 'GR$currentYear')
            .where('grid', isLessThan: 'GR${currentYear + 1}')
            .where('status', isEqualTo: 'completed')
            .orderBy('grid', descending: true)
            .limit(1)
            .get();

        if (lastGrQuery.docs.isNotEmpty) {
          final lastGrId = lastGrQuery.docs.first.id;
          final sequence = _extractSequenceFromGrId(lastGrId);
          if (sequence != null) {
            _logger.d('Last successful sequence from good_receipt: $sequence');
            return sequence;
          }
        }
      } catch (e) {
        _logger.w('Could not query good_receipt for last sequence: $e');
      }
      _logger.d('No successful sequence found, starting from 0');
      return 0;
    } catch (e) {
      _logger.e('Error getting last successful sequence: $e');
      return 0;
    }
  }

  Future<void> completeReservation(int sequence) async {
    try {
      final year = DateTime.now().year;
      final docId = '${year}_${sequence.toString().padLeft(7, '0')}';
      final reservationDoc = _firestore
          .collection(reservationCollection)
          .doc(docId);

      await reservationDoc.update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      _logger.d('✅ Sequence $sequence marked as completed');
    } catch (e) {
      _logger.e('Error completing reservation: $e');
      rethrow;
    }
  }

  Future<void> cancelReservation(int sequence) async {
    try {
      final year = DateTime.now().year;
      final docId = '${year}_${sequence.toString().padLeft(7, '0')}';
      final reservationDoc = _firestore
          .collection(reservationCollection)
          .doc(docId);

      await reservationDoc.update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _logger.d('✅ Sequence $sequence marked as cancelled');
    } catch (e) {
      _logger.e('Error cancelling reservation: $e');
      rethrow;
    }
  }

  Future<void> cleanupExpiredReservations() async {
    try {
      final now = DateTime.now();
      final currentYear = now.year;

      final expiredQuery = await _firestore
          .collection(reservationCollection)
          .where('year', isEqualTo: currentYear)
          .where('status', isEqualTo: 'reserved')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .limit(50)
          .get();

      if (expiredQuery.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'reason':
              'Auto-cancelled: expired after $reservationTimeoutMinutes minutes',
        });
      }
      await batch.commit();
      _logger.d(
        '🧹 Cleaned up ${expiredQuery.docs.length} expired reservations',
      );
    } catch (e) {
      _logger.e('Error cleaning up expired reservations: $e');
    }
  }

  Future<void> forceCleanupAll() async {
    try {
      final now = DateTime.now();

      final expiredQuery = await _firestore
          .collection(reservationCollection)
          .where('status', isEqualTo: 'reserved')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'reason': 'Force cleanup by admin',
        });
      }
      await batch.commit();
      _logger.d(
        '🧹 Force cleanup completed: ${expiredQuery.docs.length} reservations',
      );
    } catch (e) {
      _logger.e('Error force cleanup: $e');
    }
  }
}
