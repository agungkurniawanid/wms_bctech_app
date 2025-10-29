import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_detail_model.dart';

class GoodReceiveSerialNumberModel {
  final String grId;
  final String poNumber;
  final String? createdBy;
  final DateTime? createdAt;
  final List<GoodReceiveSerialNumberDetailModel> details;

  GoodReceiveSerialNumberModel({
    required this.grId,
    required this.poNumber,
    required this.details,
    this.createdBy,
    this.createdAt,
  });

  // Factory method untuk membuat model dari DocumentSnapshot
  factory GoodReceiveSerialNumberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return GoodReceiveSerialNumberModel(
      grId: data['grid'] ?? '',
      poNumber: data['ponumber'] ?? '',
      createdBy: data['createdby'] ?? '',
      createdAt: (data['createdat'] as Timestamp?)?.toDate(),
      details: _parseDetails(data['details']),
    );
  }

  // Method untuk parsing array details
  static List<GoodReceiveSerialNumberDetailModel> _parseDetails(
    List<dynamic>? detailsData,
  ) {
    if (detailsData == null) return [];

    return detailsData.map((detail) {
      return GoodReceiveSerialNumberDetailModel(
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
      'details': details.map((detail) => detail.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'GoodReceiveSerialNumberModel(grid: $grId, ponumber: $poNumber, details: $details)';
  }
}
