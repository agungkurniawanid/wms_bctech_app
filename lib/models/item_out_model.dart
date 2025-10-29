import 'dart:convert';

class Item {
  String? pcs;
  String? uom;

  Item({this.pcs, this.uom});

  factory Item.fromJson(Map<String, dynamic> data) {
    return Item(pcs: data['total']?.toString() ?? '', uom: data['uom'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'pcs': pcs, 'uom': uom};
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => 'pcs: $pcs, uom: $uom';
}
