import 'package:flutter/foundation.dart';
import 'detail_double_out_model.dart';

class DetailSR {
  final String itemCode;
  final String itemName;
  final String itemImage;
  final List<DetailDouble> uom;
  final String compatible;
  final String requiredString;
  final String inventoryGroup;
  final String orderId;

  const DetailSR({
    this.itemCode = '',
    this.itemName = '',
    this.itemImage = '',
    this.uom = const [],
    this.compatible = '',
    this.requiredString = '',
    this.inventoryGroup = '',
    this.orderId = '',
  });

  factory DetailSR.fromJson(Map<String, dynamic> data) {
    List<DetailDouble> uomList = const [];

    try {
      if (data['uom_data'] is List) {
        uomList = (data['uom_data'] as List)
            .map<DetailDouble>((item) => DetailDouble.fromJson(item))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing uom_data: $e');
      }
    }

    return DetailSR(
      itemCode: data['item_code']?.toString() ?? '',
      itemName: data['item_name']?.toString() ?? '',
      itemImage: data['item_image']?.toString() ?? '',
      uom: uomList,
      compatible: data['compatible']?.toString() ?? '',
      requiredString: data['required']?.toString() ?? '',
      inventoryGroup: data['inventory_group']?.toString() ?? '',
      orderId: data['order_id']?.toString() ?? '',
    );
  }

  DetailSR copyWith({
    String? itemCode,
    String? itemName,
    String? itemImage,
    List<DetailDouble>? uom,
    String? compatible,
    String? requiredString,
    String? inventoryGroup,
    String? orderId,
  }) {
    return DetailSR(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      itemImage: itemImage ?? this.itemImage,
      uom: uom ?? this.uom,
      compatible: compatible ?? this.compatible,
      requiredString: requiredString ?? this.requiredString,
      inventoryGroup: inventoryGroup ?? this.inventoryGroup,
      orderId: orderId ?? this.orderId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'item_image': itemImage,
      'uom_data': uom.map((element) => element.toMap()).toList(),
      'compatible': compatible,
      'required': requiredString,
      'inventory_group': inventoryGroup,
      'order_id': orderId,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'DetailSR(itemCode: $itemCode, itemName: $itemName, itemImage: $itemImage, uom: $uom, compatible: $compatible, requiredString: $requiredString, inventoryGroup: $inventoryGroup, orderId: $orderId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetailSR &&
        other.itemCode == itemCode &&
        other.itemName == itemName &&
        other.itemImage == itemImage &&
        listEquals(other.uom, uom) &&
        other.compatible == compatible &&
        other.requiredString == requiredString &&
        other.inventoryGroup == inventoryGroup &&
        other.orderId == orderId;
  }

  @override
  int get hashCode {
    return Object.hash(
      itemCode,
      itemName,
      itemImage,
      Object.hashAll(uom),
      compatible,
      requiredString,
      inventoryGroup,
      orderId,
    );
  }
}
