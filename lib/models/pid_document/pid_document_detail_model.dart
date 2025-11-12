class PidDocumentDetailModel {
  final String productId; // ID produk
  final String? productSN;
  final int physicalQty; // Jumlah fisik (physical quantity)
  final double? different;
  final double? labst;

  PidDocumentDetailModel({
    required this.productId,
    required this.physicalQty,
    this.productSN,
    this.different,
    this.labst,
  });

  /// Konversi dari Map (misal dari Firestore)
  factory PidDocumentDetailModel.fromMap(Map<String, dynamic> map) {
    return PidDocumentDetailModel(
      productId: map['productid'] ?? map['productId'] ?? '',
      productSN: map['productSN'],
      physicalQty: (map['physicalQty'] as num?)?.toInt() ?? 0,
      different: (map['different'] as num?)?.toDouble(),
      labst: (map['labst'] as num?)?.toDouble(),
    );
  }

  /// Konversi ke Map (untuk simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'productid': productId,
      'productSN': productSN,
      'physicalQty': physicalQty,
      'different': different,
      'labst': labst,
    };
  }

  @override
  String toString() {
    return 'PidDocumentDetailModel(productId: $productId, productSN: $productSN, physicalQty: $physicalQty)';
  }
}
