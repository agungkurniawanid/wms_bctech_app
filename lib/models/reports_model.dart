import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import 'in/in_detail_model.dart';
import 'out/out_detail_model.dart';
import 'immobileitem_model.dart';
import 'stock_detail_model.dart';
import 'detail_double_out_model.dart';

class ReportsModel extends StockDetail implements ImmobileItem {
  String? aedat;
  String? ebeln;
  String? group;
  String? lifnr;
  String? clientid;
  String? ernam;
  List<InDetail>? tData;
  String? mblnr;
  String? approvedate;
  String? issync;
  String? orgid;
  String? created;
  String? createdby;
  String? updated;
  String? updatedby;
  String? doctype;
  String? werks;
  String? lgort;
  String? dlvComp;
  String? bwart;
  String? truck;
  String? createdat;
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
  List<StockDetail>? detailStockCheck;
  String? flag;

  ReportsModel({
    this.aedat,
    this.ebeln,
    this.group,
    this.lifnr,
    this.clientid,
    this.tData,
    this.mblnr,
    this.approvedate,
    this.issync,
    this.orgid,
    this.created,
    this.createdby,
    this.updated,
    this.updatedby,
    this.doctype,
    this.ernam,
    this.werks,
    this.lgort,
    this.dlvComp,
    this.bwart,
    this.truck,
    String? recordid,
    this.createdat,
    this.locationName,
    this.deliveryDate,
    this.totalItem,
    this.totalQuantity,
    this.item,
    this.detail,
    this.detailDouble,
    this.isApprove,
    this.documentNo,
    this.color,
    this.detailStockCheck,
    this.flag,
  }) {
    super.recordid = recordid;
  }

  ReportsModel cloneStockCheck() => ReportsModel.clone(this);

  @override
  String getApprovedat(String user) {
    String maxDate = '';
    if (updatedby == user) {
      maxDate = updated ?? '';
    }
    return maxDate;
  }

  factory ReportsModel.fromJsonDetail(Map<String, dynamic> data) {
    return ReportsModel(
      aedat: data['aedat'],
      ebeln: data['ebeln'],
      group: data['group'],
      lifnr: data['lifnr'],
      clientid: data['clientid'],
      tData: (data['detail'] as List?)
          ?.map((e) => InDetail.fromJson(e))
          .toList(),
      mblnr: data['mblnr'],
      approvedate: data['approvedate'],
      issync: data['issync'],
      ernam: data['ernam'],
      orgid: data['orgid'],
      created: data['created'],
      createdby: data['createdby'],
      updated: data['updated'],
      updatedby: data['updatedby'],
      doctype: data['doctype'],
      werks: data['werks'],
      lgort: data['lgort'],
      dlvComp: data['dlv_comp'],
      bwart: data['bwart'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'aedat': aedat,
      'ebeln': ebeln,
      'group': group,
      'lifnr': lifnr,
      'clientid': clientid,
      'T_DATA': tData?.map((e) => e.toJson()).toList(),
      'mblnr': mblnr,
      'approvedate': approvedate,
      'issync': issync,
      'ernam': ernam,
      'orgid': orgid,
      'created': created,
      'createdby': createdby,
      'updated': updated,
      'updatedby': updatedby,
      'doctype': doctype,
      'werks': werks,
      'lgort': lgort,
      'dlv_comp': dlvComp,
      'bwart': bwart,
      'truck': truck,
    };
  }

  ReportsModel.fromDocumentSnapshotInModel({
    required DocumentSnapshot documentSnapshot,
  }) {
    try {
      aedat = documentSnapshot['AEDAT'] ?? '';
      ebeln = documentSnapshot['EBELN'] ?? '';
      group = documentSnapshot['GROUP'] ?? '';
      lifnr = documentSnapshot['LIFNR'] ?? '';
      ernam = documentSnapshot['ERNAM'] ?? '';
      clientid = documentSnapshot['clientid'] ?? '';
      tData = (documentSnapshot['T_DATA'] as List?)
          ?.map((e) => InDetail.fromJson(e))
          .toList();
      issync = documentSnapshot['sync'] ?? '';
      orgid = documentSnapshot['orgid'] ?? '';
      created = documentSnapshot['created'] ?? '';
      createdby = documentSnapshot['createdby'] ?? '';
      updated = documentSnapshot['updated'] ?? '';
      updatedby = documentSnapshot['updatedby'] ?? '';
      doctype = documentSnapshot['doctype'] ?? '';
      werks = documentSnapshot['WERKS'] ?? '';
      lgort = documentSnapshot['LGORT'] ?? '';
      dlvComp = documentSnapshot['DLV_COMP'] ?? '';
      bwart = documentSnapshot['BWART'] ?? '';
      truck = documentSnapshot['TRUCK'] ?? '';
      mblnr = documentSnapshot['MBLNR'] ?? '';
    } catch (e) {
      Logger().e('Error in InModel snapshot: $e');
    }
  }

  ReportsModel.clone(ReportsModel other) {
    try {
      recordid = other.recordid ?? '';
      color = other.color ?? '';
      formattedUpdatedAt = other.formattedUpdatedAt ?? '';
      location = other.location ?? '';
      locationName = other.locationName ?? '';
      updatedAt = other.updatedAt ?? '';
      isApprove = other.isApprove ?? '';
      issync = other.issync ?? '';
      clientid = other.clientid ?? '';
      created = other.created ?? '';
      createdby = other.createdby ?? '';
      orgid = other.orgid ?? '';
      updated = other.updated ?? '';
      updatedby = other.updatedby ?? '';
      doctype = other.doctype ?? '';
      detailStockCheck =
          other.detailStockCheck?.map((e) => StockDetail.clone(e)).toList() ??
          [];
    } catch (e) {
      Logger().e('Error in clone: $e');
    }
  }

  ReportsModel.fromDocumentSnapshotStock({
    required DocumentSnapshot documentSnapshot,
  }) {
    try {
      recordid = documentSnapshot['recordid'] ?? '';
      color = documentSnapshot['color'] ?? '';
      formattedUpdatedAt = documentSnapshot['formatted_updated_at'] ?? '';
      location = documentSnapshot['location'] ?? '';
      locationName = documentSnapshot['location_name'] ?? '';
      updatedAt = documentSnapshot['updated_at'] ?? '';
      isApprove = documentSnapshot['isapprove'] ?? '';
      issync = documentSnapshot['sync'] ?? '';
      clientid = documentSnapshot['clientid'] ?? '';
      created = documentSnapshot['created'] ?? '';
      createdby = documentSnapshot['createdby'] ?? '';
      orgid = documentSnapshot['orgid'] ?? '';
      updated = documentSnapshot['updated']?.toString() ?? '';
      updatedby = documentSnapshot['updatedby'] ?? '';
      doctype = documentSnapshot['doctype'] ?? '';
      detailStockCheck =
          (documentSnapshot['detail'] as List?)
              ?.map((e) => StockDetail.fromJson(e))
              .toList() ??
          [];
    } catch (e) {
      Logger().e('Error in Stock snapshot: $e');
    }
  }

  ReportsModel.fromDocumentSnapshotOut({
    required DocumentSnapshot documentSnapshot,
  }) {
    try {
      recordid = documentSnapshot['recordid'] ?? '';
      createdat = documentSnapshot['createdat'] ?? '';
      inventoryGroup = documentSnapshot['inventory_group'] ?? '';
      location = documentSnapshot['location'] ?? '';
      locationName = documentSnapshot['location_name'] ?? '';
      deliveryDate = documentSnapshot['delivery_date'] ?? '';
      totalItem = documentSnapshot['total_item'] ?? 0;
      totalQuantity = documentSnapshot['total_quantities'] ?? '';
      item = documentSnapshot['grouped_items'] ?? '';
      detail =
          (documentSnapshot['details'] as List?)
              ?.map((e) => OutDetailModel.fromJson(e))
              .toList() ??
          [];
      isApprove = documentSnapshot['isapprove'] ?? '';
      issync = documentSnapshot['sync'] ?? '';
      clientid = documentSnapshot['clientid'] ?? '';
      orgid = documentSnapshot['orgid'] ?? '';
      created = documentSnapshot['created'] ?? '';
      updated = documentSnapshot['updated'] ?? '';
      updatedby = documentSnapshot['updatedby'] ?? '';
      createdby = documentSnapshot['createdby'] ?? '';
      doctype = documentSnapshot['doctype'] ?? '';
      documentNo = documentSnapshot['documentno'] ?? '';
      mblnr = documentSnapshot['MATDOC'] ?? '';
    } catch (e) {
      Logger().e('Error in Out snapshot: $e');
    }
  }
}
