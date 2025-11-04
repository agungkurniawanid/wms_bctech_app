import 'package:cloud_firestore/cloud_firestore.dart';

class GrSequenceModel {
  final String year;
  final int lastSequence;
  final DateTime lastUpdated;
  final Map<String, dynamic>? reservedSequences;

  GrSequenceModel({
    required this.year,
    required this.lastSequence,
    required this.lastUpdated,
    this.reservedSequences,
  });

  factory GrSequenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GrSequenceModel(
      year: data['year'] ?? '',
      lastSequence: data['lastSequence'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      reservedSequences: data['reservedSequences'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      'lastSequence': lastSequence,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'reservedSequences': reservedSequences ?? {},
    };
  }
}
