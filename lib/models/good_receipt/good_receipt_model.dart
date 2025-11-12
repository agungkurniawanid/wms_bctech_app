import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_detail_model.dart';

class GoodReceiptModel {
  final String grId;
  final String poNumber;
  final String? createdBy;
  final DateTime? createdAt;
  final String? status;
  final List<GoodReceiptDetailModel> details;
  final DateTime? updatedAt;

  GoodReceiptModel({
    required this.grId,
    required this.poNumber,
    required this.details,
    this.createdBy,
    this.createdAt,
    this.status,
    this.updatedAt,
  });

  // Factory method untuk membuat model dari DocumentSnapshot
  factory GoodReceiptModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return GoodReceiptModel(
      grId: data['grid'] ?? '',
      poNumber: data['ponumber'] ?? '',
      createdBy: data['createdby'] ?? '',
      createdAt: (data['createdat'] as Timestamp?)?.toDate(),
      details: _parseDetails(data['details']),
      status: data['status'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Method untuk parsing array details
  static List<GoodReceiptDetailModel> _parseDetails(
    List<dynamic>? detailsData,
  ) {
    if (detailsData == null) return [];

    return detailsData.map((detail) {
      return GoodReceiptDetailModel(
        sn: detail['SN'],
        productid: detail['productid'] ?? '',
        qty: (detail['qty'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  // Method untuk convert ke Map (jika diperlukan untuk write operations)
  Map<String, dynamic> toFirestore() {
    return {
      'grid': grId,
      'ponumber': poNumber,
      'createdby': createdBy,
      'createdat': createdAt,
      'status': status,
      'details': details.map((detail) => detail.toMap()).toList(),
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'GoodReceiptModel(grid: $grId, ponumber: $poNumber, details: $details)';
  }
}
