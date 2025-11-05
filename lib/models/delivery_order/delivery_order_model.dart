import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/delivery_order/delivery_order_detail_model.dart';

class DeliveryOrderModel {
  final String grId;
  final String poNumber;
  final String? createdBy;
  final DateTime? createdAt;
  final String? status;
  final List<DeliveryOrderDetailModel> details;

  DeliveryOrderModel({
    required this.grId,
    required this.poNumber,
    required this.details,
    this.createdBy,
    this.createdAt,
    this.status,
  });

  factory DeliveryOrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return DeliveryOrderModel(
      grId: data['grid'] ?? '',
      poNumber: data['ponumber'] ?? '',
      createdBy: data['createdby'] ?? '',
      createdAt: (data['createdat'] as Timestamp?)?.toDate(),
      details: _parseDetails(data['details']),
      status: data['status'] ?? '',
    );
  }

  // Method untuk parsing array details
  static List<DeliveryOrderDetailModel> _parseDetails(
    List<dynamic>? detailsData,
  ) {
    if (detailsData == null) return [];

    return detailsData.map((detail) {
      return DeliveryOrderDetailModel(
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
    };
  }

  @override
  String toString() {
    return 'DeliveryOrderModel(grid: $grId, ponumber: $poNumber, details: $details)';
  }
}
