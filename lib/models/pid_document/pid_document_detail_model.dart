class PidDocumentDetailModel {
  final String productId; // ID produk
  final String? productSN;
  final int physicalQty; // Jumlah fisik (physical quantity)

  PidDocumentDetailModel({
    required this.productId,
    required this.physicalQty,
    this.productSN,
  });

  /// Konversi dari Map (misal dari Firestore)
  factory PidDocumentDetailModel.fromMap(Map<String, dynamic> map) {
    return PidDocumentDetailModel(
      productId: map['productid'] ?? map['productId'] ?? '',
      productSN: map['productSN'],
      physicalQty: (map['physicalQty'] as num?)?.toInt() ?? 0,
    );
  }

  /// Konversi ke Map (untuk simpan ke Firesto
  /// re)
  Map<String, dynamic> toMap() {
    return {
      'productid': productId,
      'productSN': productSN,
      'physicalQty': physicalQty,
    };
  }

  @override
  String toString() {
    return 'PidDocumentDetailModel(productId: $productId, productSN: $productSN, physicalQty: $physicalQty)';
  }
}
