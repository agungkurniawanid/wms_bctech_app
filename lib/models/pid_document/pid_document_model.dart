import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/pid_document/pid_document_detail_model.dart';

class PidDocumentModel {
  final String pidDocument; // ID unik dokumen PID
  final String? createdBy;
  final DateTime? createdAt;
  final String? status;
  final String? whValue;
  final String? whName;
  final String? locatorValue;
  final String? orgValue;
  final String? orgName;
  final List<PidDocumentDetailModel> products;

  PidDocumentModel({
    required this.pidDocument,
    required this.products,
    this.createdBy,
    this.createdAt,
    this.status,
    this.whValue,
    this.whName,
    this.locatorValue,
    this.orgValue,
    this.orgName,
  });

  /// Factory method untuk membuat model dari Firestore snapshot
  factory PidDocumentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return PidDocumentModel(
      pidDocument: data['pidDocument'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? '',
      whValue: data['whValue'] ?? '',
      whName: data['whName'] ?? '',
      locatorValue: data['locatorValue'] ?? '',
      orgValue: data['orgValue'] ?? '',
      orgName: data['orgName'] ?? '',
      products: _parseProducts(data['products']),
    );
  }

  /// Helper untuk parsing array of products
  static List<PidDocumentDetailModel> _parseProducts(
    List<dynamic>? productsData,
  ) {
    if (productsData == null) return [];

    return productsData
        .map(
          (item) =>
              PidDocumentDetailModel.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Convert ke Map (untuk disimpan ke Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'pidDocument': pidDocument,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'status': status,
      'whValue': whValue,
      'whName': whName,
      'locatorValue': locatorValue,
      'orgValue': orgValue,
      'orgName': orgName,
      'products': products.map((p) => p.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'PidDocumentModel(pidDocument: $pidDocument, products: $products)';
  }
}
