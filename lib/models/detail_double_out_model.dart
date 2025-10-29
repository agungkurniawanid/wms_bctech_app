class DetailDouble {
  final String uom;
  final String totalItem;
  final String totalPicked;
  final String compatible;
  final String barcode;

  const DetailDouble({
    this.uom = '',
    this.totalItem = '',
    this.totalPicked = '',
    this.compatible = '',
    this.barcode = '',
  });

  factory DetailDouble.fromJson(Map<String, dynamic> data) {
    return DetailDouble(
      uom: data['uom']?.toString() ?? '',
      totalItem: data['total_item']?.toString() ?? '',
      totalPicked: data['total_picked']?.toString() ?? '',
      compatible: data['compatible']?.toString() ?? '',
      barcode: data['barcode']?.toString() ?? '',
    );
  }

  DetailDouble copyWith({
    String? uom,
    String? totalItem,
    String? totalPicked,
    String? compatible,
    String? barcode,
  }) {
    return DetailDouble(
      uom: uom ?? this.uom,
      totalItem: totalItem ?? this.totalItem,
      totalPicked: totalPicked ?? this.totalPicked,
      compatible: compatible ?? this.compatible,
      barcode: barcode ?? this.barcode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uom': uom,
      'total_item': totalItem,
      'total_picked': totalPicked,
      'compatible': compatible,
      'barcode': barcode,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'DetailDouble(uom: $uom, totalItem: $totalItem, totalPicked: $totalPicked, compatible: $compatible, barcode: $barcode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetailDouble &&
        other.uom == uom &&
        other.totalItem == totalItem &&
        other.totalPicked == totalPicked &&
        other.compatible == compatible &&
        other.barcode == barcode;
  }

  @override
  int get hashCode {
    return Object.hash(uom, totalItem, totalPicked, compatible, barcode);
  }
}
