class PidDocumentDetailModel {
  final String productId; // ID produk
  final int physicalQty; // Jumlah fisik (physical quantity)

  PidDocumentDetailModel({required this.productId, required this.physicalQty});

  /// Konversi dari Map (misal dari Firestore)
  factory PidDocumentDetailModel.fromMap(Map<String, dynamic> map) {
    return PidDocumentDetailModel(
      productId: map['productid'] ?? map['productId'] ?? '',
      physicalQty: (map['physicalQty'] as num?)?.toInt() ?? 0,
    );
  }

  /// Konversi ke Map (untuk simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {'productid': productId, 'physicalQty': physicalQty};
  }

  @override
  String toString() {
    return 'PidDocumentDetailModel(productId: $productId, physicalQty: $physicalQty)';
  }
}
