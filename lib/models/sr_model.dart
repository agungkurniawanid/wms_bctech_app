import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'detail_sr_model.dart';

class SrModel {
  final String? recordid;
  final String? createdat;
  final String? created;
  final String? createdby;
  final String? inventoryGroup;
  final String? location;
  final String? locationName;
  final String? deliveryDate;
  final int? totalItem;
  final String? totalQuantity;
  final String? item;
  final List<DetailSR>? detail;
  final String? isApprove;
  final String? isSync;
  final String? doctype;
  final String? clientid;
  final String? orgid;
  final String? updated;
  final String? updatedby;
  final String? documentno;

  SrModel({
    this.recordid,
    this.createdat,
    this.inventoryGroup,
    this.location,
    this.locationName,
    this.deliveryDate,
    this.totalItem,
    this.totalQuantity,
    this.item,
    this.detail,
    this.isApprove,
    this.isSync,
    this.doctype,
    this.clientid,
    this.orgid,
    this.created,
    this.createdby,
    this.updated,
    this.updatedby,
    this.documentno,
  });

  factory SrModel.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};

      return SrModel(
        recordid: data['recordid']?.toString() ?? '',
        createdat: data['createdat']?.toString() ?? '',
        inventoryGroup: data['inventory_group']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        locationName: data['location_name']?.toString() ?? '',
        deliveryDate: data['delivery_date']?.toString() ?? '',
        totalItem: (data['total_item'] is int)
            ? data['total_item']
            : int.tryParse(data['total_item']?.toString() ?? '0') ?? 0,
        totalQuantity: data['total_quantities']?.toString() ?? '',
        item: data['grouped_items']?.toString() ?? '',
        detail: (data['details'] is List)
            ? (data['details'] as List)
                  .map((e) => DetailSR.fromJson(e))
                  .toList()
            : [],
        isApprove: data['isapprove']?.toString() ?? '',
        isSync: data['sync']?.toString() ?? '',
        clientid: data['clientid']?.toString() ?? '',
        orgid: data['orgid']?.toString() ?? '',
        created: data['created']?.toString() ?? '',
        updated: data['updated']?.toString() ?? '',
        updatedby: data['updatedby']?.toString() ?? '',
        createdby: data['createdby']?.toString() ?? '',
        doctype: data['doctype']?.toString() ?? '',
        documentno: data['documentno']?.toString() ?? '',
      );
    } catch (e) {
      Logger().e('Error parsing SrModel: $e');
      return SrModel();
    }
  }

  Map<String, dynamic> toJson() => {
    'recordid': recordid,
    'createdat': createdat,
    'inventory_group': inventoryGroup,
    'location': location,
    'location_name': locationName,
    'delivery_date': deliveryDate,
    'total_item': totalItem,
    'total_quantities': totalQuantity,
    'grouped_items': item,
    'details': detail?.map((e) => e.toJson()).toList(),
    'isapprove': isApprove,
    'sync': isSync,
    'doctype': doctype,
    'clientid': clientid,
    'orgid': orgid,
    'created': created,
    'createdby': createdby,
    'updated': updated,
    'updatedby': updatedby,
    'documentno': documentno,
  };

  @override
  String toString() => jsonEncode(toJson());
}
