import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'stock_detail_model.dart';
import 'immobileitem_model.dart';

class StockModel implements ImmobileItem {
  String? recordid;
  String? color;
  String? created;
  String? createdby;
  String? orgid;
  String? updated;
  String? updatedby;
  String? location;
  String? formattedUpdatedAt;
  String? isApprove;
  String? locationName;
  String? updatedAt;
  String? clientid;
  String? isSync;
  String? doctype;
  List<StockDetail>? detail;

  StockModel({
    this.recordid,
    this.color,
    this.created,
    this.createdby,
    this.orgid,
    this.updated,
    this.updatedby,
    this.location,
    this.formattedUpdatedAt,
    this.isApprove,
    this.locationName,
    this.updatedAt,
    this.clientid,
    this.isSync,
    this.doctype,
    this.detail,
  });

  StockModel copyWith({
    String? recordid,
    String? color,
    String? created,
    String? createdby,
    String? orgid,
    String? updated,
    String? updatedby,
    String? location,
    String? formattedUpdatedAt,
    String? isApprove,
    String? locationName,
    String? updatedAt,
    String? clientid,
    String? isSync,
    String? doctype,
    List<StockDetail>? detail,
  }) {
    return StockModel(
      recordid: recordid ?? this.recordid,
      color: color ?? this.color,
      created: created ?? this.created,
      createdby: createdby ?? this.createdby,
      orgid: orgid ?? this.orgid,
      updated: updated ?? this.updated,
      updatedby: updatedby ?? this.updatedby,
      location: location ?? this.location,
      formattedUpdatedAt: formattedUpdatedAt ?? this.formattedUpdatedAt,
      isApprove: isApprove ?? this.isApprove,
      locationName: locationName ?? this.locationName,
      updatedAt: updatedAt ?? this.updatedAt,
      clientid: clientid ?? this.clientid,
      isSync: isSync ?? this.isSync,
      doctype: doctype ?? this.doctype,
      detail: detail ?? this.detail,
    );
  }

  StockModel clone() => StockModel(
    recordid: recordid,
    color: color,
    created: created,
    createdby: createdby,
    orgid: orgid,
    updated: updated,
    updatedby: updatedby,
    location: location,
    formattedUpdatedAt: formattedUpdatedAt,
    isApprove: isApprove,
    locationName: locationName,
    updatedAt: updatedAt,
    clientid: clientid,
    isSync: isSync,
    doctype: doctype,
    detail: detail != null
        ? detail!.map((item) => StockDetail.clone(item)).toList()
        : [],
  );

  @override
  String getApprovedat(String user) {
    String maxDate = "2000-01-01";

    if (detail == null || detail!.isEmpty) return maxDate;

    for (var item in detail!.where(
      (item) =>
          item.approveName == user && (item.updatedAt?.isNotEmpty ?? false),
    )) {
      final updatedAtDate = DateTime.tryParse(item.updatedAt ?? "2000-01-01");
      final maxDateParsed = DateTime.tryParse(maxDate);

      if (updatedAtDate != null &&
          maxDateParsed != null &&
          updatedAtDate.isAfter(maxDateParsed)) {
        maxDate = item.updatedAt!;
      }
    }
    return maxDate;
  }

  factory StockModel.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};

      return StockModel(
        recordid: data['recordid']?.toString(),
        color: data['color']?.toString(),
        formattedUpdatedAt: data['formatted_updated_at']?.toString(),
        location: data['location']?.toString(),
        locationName: data['location_name']?.toString(),
        updatedAt: data['updated_at']?.toString(),
        isApprove: data['isapprove']?.toString(),
        isSync: data['sync']?.toString(),
        clientid: data['clientid']?.toString(),
        created: data['created']?.toString(),
        createdby: data['createdby']?.toString(),
        orgid: data['orgid']?.toString(),
        updated: data['updated']?.toString(),
        updatedby: data['updatedby']?.toString(),
        doctype: data['doctype']?.toString(),
        detail: (data['detail'] is List)
            ? (data['detail'] as List)
                  .map((item) => StockDetail.fromJson(item))
                  .toList()
            : [],
      );
    } catch (e) {
      Logger().e('Error parsing StockModel: $e');
      return StockModel();
    }
  }

  Map<String, dynamic> toJson() => {
    'recordid': recordid,
    'color': color,
    'created': created,
    'createdby': createdby,
    'orgid': orgid,
    'updated': updated,
    'updatedby': updatedby,
    'location': location,
    'formatted_updated_at': formattedUpdatedAt,
    'isapprove': isApprove,
    'location_name': locationName,
    'updated_at': updatedAt,
    'clientid': clientid,
    'sync': isSync,
    'doctype': doctype,
    'detail': detail?.map((e) => e.toMap()).toList(),
  };

  @override
  String toString() => jsonEncode(toJson());
}
