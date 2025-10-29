// history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'in/in_detail_model.dart';
import 'out/out_detail_model.dart';
import 'immobileitem_model.dart';
import 'stock_detail_model.dart';
import 'detail_double_out_model.dart';

class HistoryModel extends StockDetail implements ImmobileItem {
  String? aedat;
  String? ebeln;
  String? group;
  String? lifnr;
  String? clientId;
  String? ernam;
  List<InDetail>? tData;
  String? mblnr;
  String? approveDate;
  String? isSync;
  String? orgId;
  String? created;
  String? createdBy;
  String? updated;
  String? updatedBy;
  String? docType;
  String? werks;
  String? lgort;
  String? dlvComp;
  String? bwart;
  String? truck;

  String? recordId;
  String? createdAt;

  @override
  set inventoryGroup(String? value) => super.inventoryGroup = value;

  String? _location;
  String? locationName;
  String? deliveryDate;
  int? totalItem;
  String? totalQuantity;
  String? item;
  List<OutDetailModel>? detail;
  List<DetailDouble>? detailDouble;
  String? isApprove;
  String? documentNo;

  String? color;

  @override
  set formattedUpdatedAt(String? value) => super.formattedUpdatedAt = value;

  @override
  set updatedAt(String? value) => super.updatedAt = value;

  List<StockDetail>? detailStockCheck;
  String? postingDate;

  @override
  String get location => _location ?? '';

  @override
  String getApprovedat(String user) {
    return (updatedBy == user) ? (updated ?? "") : "";
  }

  HistoryModel({
    this.aedat,
    this.ebeln,
    this.group,
    this.lifnr,
    this.clientId,
    this.ernam,
    this.tData,
    this.mblnr,
    this.approveDate,
    this.isSync,
    this.orgId,
    this.created,
    this.createdBy,
    this.updated,
    this.updatedBy,
    this.docType,
    this.werks,
    this.lgort,
    this.dlvComp,
    this.bwart,
    this.truck,
    this.recordId,
    String? location,
    this.locationName,
    this.createdAt,
    String? inventoryGroup,
    this.deliveryDate,
    this.totalItem,
    this.totalQuantity,
    this.item,
    this.detail,
    this.detailDouble,
    this.isApprove,
    this.documentNo,
    this.color,
    String? formattedUpdatedAt,
    String? updatedAt,
    this.detailStockCheck,
    this.postingDate,
  }) {
    _location = location;
    super.inventoryGroup = inventoryGroup;
    super.formattedUpdatedAt = formattedUpdatedAt;
    super.updatedAt = updatedAt;
  }

  HistoryModel cloneStockCheck() => HistoryModel.clone(this);

  factory HistoryModel.fromJsonDetail(Map<String, dynamic> data) {
    return HistoryModel(
      aedat: data['aedat'],
      ebeln: data['ebeln'],
      group: data['group'],
      lifnr: data['lifnr'],
      clientId: data['clientid'],
      ernam: data['ernam'],
      tData: (data['detail'] as List?)
          ?.map((item) => InDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
      mblnr: data['mblnr'],
      approveDate: data['approvedate'],
      isSync: data['issync'],
      orgId: data['orgid'],
      created: data['created'],
      createdBy: data['createdby'],
      updated: data['updated'],
      updatedBy: data['updatedby'],
      docType: data['doctype'],
      werks: data['werks'],
      lgort: data['lgort'],
      dlvComp: data['dlv_comp'],
      bwart: data['bwart'],
      truck: data['truck'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'aedat': aedat,
      'ebeln': ebeln,
      'group': group,
      'lifnr': lifnr,
      'clientid': clientId,
      'T_DATA': tData?.map((item) => item.toMap()).toList(),
      'mblnr': mblnr,
      'approvedate': approveDate,
      'issync': isSync,
      'ernam': ernam,
      'orgid': orgId,
      'created': created,
      'createdby': createdBy,
      'updated': updated,
      'updatedby': updatedBy,
      'doctype': docType,
      'werks': werks,
      'lgort': lgort,
      'dlv_comp': dlvComp,
      'bwart': bwart,
      'truck': truck,
      'recordid': recordId,
      'location': _location,
      'location_name': locationName,
      'createdat': createdAt,
      'inventory_group': inventoryGroup,
      'delivery_date': deliveryDate,
      'total_item': totalItem,
      'total_quantities': totalQuantity,
      'grouped_items': item,
      'details': detail?.map((d) => d.toMap()).toList(),
      'detaildouble': detailDouble?.map((d) => d.toMap()).toList(),
      'isapprove': isApprove,
      'documentno': documentNo,
      'color': color,
      'formatted_updated_at': formattedUpdatedAt,
      'updated_at': updatedAt,
      'detail_stockcheck': detailStockCheck?.map((s) => s.toMap()).toList(),
      'postingdate': postingDate,
    };
  }

  HistoryModel.fromDocumentSnapshotInModel(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};

      aedat = data['AEDAT'] ?? "";
      ebeln = data['EBELN'] ?? "";
      group = data['GROUP'] ?? "";
      lifnr = data['LIFNR'] ?? "";
      ernam = data['ERNAM'] ?? "";
      clientId = data['clientid'] ?? "";

      final tDataList = data['T_DATA'] as List?;
      tData = tDataList
          ?.map((item) => InDetail.fromJson(item as Map<String, dynamic>))
          .toList();

      isSync = data['sync'] ?? "";
      orgId = data['orgid'] ?? "";
      created = data['created'] ?? "";
      createdBy = data['createdby'] ?? "";
      updated = data['updated'] ?? "";
      updatedBy = data['updatedby'] ?? "";
      docType = data['doctype'] ?? "";
      werks = data['WERKS'] ?? "";
      lgort = data['LGORT'] ?? "";
      dlvComp = data['DLV_COMP'] ?? "";
      bwart = data['BWART'] ?? "";
      truck = data['TRUCK'] ?? "";
      mblnr = data['MBLNR'] ?? "";
    } catch (e) {
      debugPrint('Error in fromDocumentSnapshotInModel: $e');
    }
  }

  HistoryModel.clone(HistoryModel other) {
    try {
      recordId = other.recordId;
      color = other.color;
      formattedUpdatedAt = other.formattedUpdatedAt;
      _location = other._location;
      locationName = other.locationName;
      updatedAt = other.updatedAt;
      isApprove = other.isApprove;
      isSync = other.isSync;
      clientId = other.clientId;

      detail = other.detail?.map<OutDetailModel>((item) {
        try {
          final cloned = (item as dynamic).clone();
          if (cloned is OutDetailModel) return cloned;
        } catch (_) {}
        return item;
      }).toList();

      detailStockCheck = other.detailStockCheck?.map<StockDetail>((item) {
        try {
          final cloned = (item as dynamic).clone();
          if (cloned is StockDetail) return cloned;
        } catch (_) {}
        return item;
      }).toList();

      created = other.created;
      createdBy = other.createdBy;
      orgId = other.orgId;
      updated = other.updated;
      updatedBy = other.updatedBy;
      docType = other.docType;
    } catch (e) {
      debugPrint('Error in clone: $e');
    }
  }

  HistoryModel.fromDocumentSnapshotStock(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};
      recordId = data['recordid'] ?? "";
      color = data['color'] ?? "";
      formattedUpdatedAt = data['formatted_updated_at'] ?? "";
      _location = data['location'] ?? "";
      locationName = data['location_name'] ?? "";
      updatedAt = data['updated_at'] ?? "";
      isApprove = data['isapprove'] ?? "";
      isSync = data['sync'] ?? "";
      clientId = data['clientid'] ?? "";
      created = data['created'] ?? "";
      createdBy = data['createdby'] ?? "";
      orgId = data['orgid'] ?? "";
      updated = data['updated']?.toString() ?? "";
      updatedBy = data['updatedby'] ?? "";
      docType = data['doctype'] ?? "";

      final detailList = data['detail'] as List?;
      detailStockCheck = detailList
          ?.map((item) => StockDetail.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error in fromDocumentSnapshotStock: $e');
    }
  }

  HistoryModel.fromDocumentSnapshotOut(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};

      recordId = data['recordid'] ?? "";
      createdAt = data['createdat'] ?? "";
      inventoryGroup = data['inventory_group'] ?? "";
      _location = data['location'] ?? "";
      locationName = data['location_name'] ?? "";
      deliveryDate = data['delivery_date'] ?? "";
      totalItem = (data['total_item'] ?? 0) as int;
      totalQuantity = data['total_quantities'] ?? "";
      item = data['grouped_items'] ?? "";

      final detailList = data['details'] as List?;
      detail = detailList
          ?.map((item) => OutDetailModel.fromJson(item as Map<String, dynamic>))
          .toList();

      isApprove = data['isapprove'] ?? "";
      isSync = data['sync'] ?? "";
      clientId = data['clientid'] ?? "";
      orgId = data['orgid'] ?? "";
      created = data['created'] ?? "";
      updated = data['updated'] ?? "";
      updatedBy = data['updatedby'] ?? "";
      createdBy = data['createdby'] ?? "";
      docType = data['doctype'] ?? "";
      documentNo = data['documentno'] ?? "";
      mblnr = data['MATDOC'] ?? "";
      postingDate = data['postingdate'] ?? "";
    } catch (e) {
      debugPrint('Error in fromDocumentSnapshotOut: $e');
    }
  }
}
