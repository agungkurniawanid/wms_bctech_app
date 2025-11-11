import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wms_bctech/models/out/out_detail_model.dart';
import '../immobileitem_model.dart';

class OutModel implements ImmobileItem {
  String? dateordered;
  String? documentno;
  String? docstatus;
  String? adClientId;
  List<String>? adOrgId;
  String? cBpartnerId;
  String? cBpartnerName;
  String? cCurrencyId;
  String? cDoctypeId;
  String? cDoctypetargetId;
  String? deliveryviarule;
  List<OutDetailModel>? details;
  String? freightcostrule;
  String? isFullyDelivered;
  String? mPricelistId;
  String? mProductCategoryId;
  String? mWarehouseId;
  String? priorityrule;
  double? totallines;
  String? user1Id;
  String? clientid;
  String? created;
  String? createdby;
  String? updated;
  String? updatedby;
  String? issync;
  String? orgid;
  String? truck;
  String? invoiceno;
  String? vendorpo;

  // variable testing
  String? approvedate;

  OutModel({
    this.dateordered,
    this.documentno,
    this.docstatus,
    this.adClientId,
    this.adOrgId,
    this.cBpartnerId,
    this.cBpartnerName,
    this.cCurrencyId,
    this.cDoctypeId,
    this.cDoctypetargetId,
    this.deliveryviarule,
    this.details,
    this.freightcostrule,
    this.isFullyDelivered,
    this.mPricelistId,
    this.mProductCategoryId,
    this.mWarehouseId,
    this.priorityrule,
    this.totallines,
    this.user1Id,
    this.clientid,
    this.created,
    this.createdby,
    this.updated,
    this.updatedby,
    this.issync,
    this.orgid,
    this.truck,
    this.invoiceno,
    this.vendorpo,

    // variable testing
    this.approvedate,
  });

  @override
  String getApprovedat(String user) {
    if (updatedby == user) {
      return updated ?? "";
    }
    return "";
  }

  factory OutModel.clone(OutModel data) {
    return OutModel(
      dateordered: data.dateordered,
      documentno: data.documentno,
      docstatus: data.docstatus,
      adClientId: data.adClientId,
      adOrgId: data.adOrgId != null ? List.from(data.adOrgId!) : null,
      cBpartnerId: data.cBpartnerId,
      cBpartnerName: data.cBpartnerName,
      cCurrencyId: data.cCurrencyId,
      cDoctypeId: data.cDoctypeId,
      cDoctypetargetId: data.cDoctypetargetId,
      deliveryviarule: data.deliveryviarule,
      details: data.details?.map((item) => OutDetailModel.clone(item)).toList(),
      freightcostrule: data.freightcostrule,
      isFullyDelivered: data.isFullyDelivered,
      mPricelistId: data.mPricelistId,
      mProductCategoryId: data.mProductCategoryId,
      mWarehouseId: data.mWarehouseId,
      priorityrule: data.priorityrule,
      totallines: data.totallines,
      user1Id: data.user1Id,
      clientid: data.clientid,
      created: data.created,
      createdby: data.createdby,
      updated: data.updated,
      updatedby: data.updatedby,
      issync: data.issync,
      orgid: data.orgid,
      truck: data.truck,
      invoiceno: data.invoiceno,
      vendorpo: data.vendorpo,
    );
  }

  factory OutModel.fromJson(Map<String, dynamic> json) {
    return OutModel(
      dateordered: json['dateordered'],
      documentno: json['documentno'],
      docstatus: json['docstatus'],
      adClientId: json['ad_client_id'],
      adOrgId:
          (json['ad_org_id'] as List?) // <-- DIPERBAIKI: Konversi List<dynamic>
              ?.map(
                (e) => e.toString(),
              ) // <-- DIPERBAIKI: Konversi setiap item ke String
              .toList(), // <-- DIPERBAIKI
      cBpartnerId: json['c_bpartner_id'],
      cBpartnerName: json['c_bpartner_name'],
      cCurrencyId: json['c_currency_id'],
      cDoctypeId: json['c_doctype_id'],
      cDoctypetargetId: json['c_doctypetarget_id'],
      deliveryviarule: json['deliveryviarule'],
      details: (json['details'] as List?)
          ?.map((e) => OutDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      freightcostrule: json['freightcostrule'],
      isFullyDelivered: json['is_fully_delivered'],
      mPricelistId: json['m_pricelist_id'],
      mProductCategoryId: json['m_product_category_id'],
      mWarehouseId: json['m_warehouse_id'],
      priorityrule: json['priorityrule'],
      totallines: (json['totallines'] as num?)?.toDouble(),
      user1Id: json['user1_id'],
      clientid: json['clientid'],
      created: json['created'],
      createdby: json['createdby'],
      updated: json['updated'],
      updatedby: json['updatedby'],
      issync: json['issync'],
      orgid: json['orgid'],
      truck: json['truck'],
      invoiceno: json['invoiceno'],
      vendorpo: json['vendorpo'],

      // variable testing
      approvedate: json['approvedate'],
    );
  }

  factory OutModel.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>?;
    if (data == null) return OutModel();

    String _timestampToString(dynamic ts) {
      if (ts == null) {
        return ""; // Kembalikan string kosong jika null
      }
      if (ts is Timestamp) {
        // Ubah Timestamp ke DateTime, lalu format ke String
        // Gunakan format yang SAMA seperti di fungsi 'approveIn' Anda
        return DateFormat('yyyy-MM-dd kk:mm:ss').format(ts.toDate());
      }
      if (ts is String) {
        return ts; // Kembalikan string jika datanya memang sudah string
      }
      return ""; // Fallback
    }

    return OutModel(
      dateordered: data['dateordered'] ?? "",
      documentno: data['documentno'] ?? "",
      docstatus: data['docstatus'] ?? "",
      adClientId: data['ad_client_id'] ?? "",
      adOrgId:
          (data['ad_org_id'] as List?) // <-- DIPERBAIKI: Konversi List<dynamic>
              ?.map(
                (e) => e.toString(),
              ) // <-- DIPERBAIKI: Konversi setiap item ke String
              .toList(), // <-- DIPERBAIKI
      cBpartnerId: data['c_bpartner_id'] ?? "",
      cBpartnerName: data['c_bpartner_name'] ?? "",
      cCurrencyId: data['c_currency_id'] ?? "",
      cDoctypeId: data['c_doctype_id'] ?? "",
      cDoctypetargetId: data['c_doctypetarget_id'] ?? "",
      deliveryviarule: data['deliveryviarule'] ?? "",
      details: (data['details'] as List?)
          ?.map((e) => OutDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      freightcostrule: data['freightcostrule'] ?? "",
      isFullyDelivered:
          data['is_fully_delivered'] ??
          "N", // <-- DIPERBAIKI: Default value harus String, bukan boolean false
      mPricelistId: data['m_pricelist_id'] ?? "",
      mProductCategoryId: data['m_product_category_id'] ?? "",
      mWarehouseId: data['m_warehouse_id'] ?? "",
      priorityrule: data['priorityrule'] ?? "",
      totallines: (data['totallines'] as num?)?.toDouble() ?? 0.0,
      user1Id: data['user1_id'] ?? "",
      clientid: data['clientid'] ?? "",
      created: _timestampToString(data['created']),
      createdby: data['createdby'] ?? "",
      updated: _timestampToString(data['updated']),
      updatedby: data['updatedby'] ?? "",
      issync: data['issync'] ?? "", // <-- DIPERBAIKI: Key 'issync' bukan 'sync'
      orgid: data['orgid'] ?? "",
      truck: data['truck'] ?? "", // <-- DIPERBAIKI: Key 'truck' (lowercase)
      invoiceno:
          data['invoiceno'] ??
          "", // <-- DIPERBAIKI: Key 'invoiceno' (lowercase)
      vendorpo:
          data['vendorpo'] ?? "", // <-- DIPERBAIKI: Key 'vendorpo' (lowercase)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateordered': dateordered,
      'documentno': documentno,
      'docstatus': docstatus,
      'ad_client_id': adClientId,
      'ad_org_id': adOrgId,
      'c_bpartner_id': cBpartnerId,
      'c_bpartner_name': cBpartnerName,
      'c_currency_id': cCurrencyId,
      'c_doctype_id': cDoctypeId,
      'c_doctypetarget_id': cDoctypetargetId,
      'deliveryviarule': deliveryviarule,
      'details': details?.map((e) => e.toJson()).toList(),
      'freightcostrule': freightcostrule,
      'is_fully_delivered': isFullyDelivered,
      'm_pricelist_id': mPricelistId,
      'm_product_category_id': mProductCategoryId,
      'm_warehouse_id': mWarehouseId,
      'priorityrule': priorityrule,
      'totallines': totallines,
      'user1_id': user1Id,
      'clientid': clientid,
      'created': created,
      'createdby': createdby,
      'updated': updated,
      'updatedby': updatedby,
      'issync': issync,
      'orgid': orgid,
      'truck': truck,
      'invoiceno': invoiceno,
      'vendorpo': vendorpo,

      // variable testing
      'approvedate': approvedate,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // Untuk kompatibilitas dengan kode existing
  String? get ebeln => documentno;
  String? get aedat => dateordered;
  String? get lifnr => cBpartnerId;
  String? get ernam => user1Id;
  String? get group => adClientId;
  String? get werks => mWarehouseId;
  String? get lgort => mWarehouseId;
  String? get dlvComp => deliveryviarule;
  String? get bwart => freightcostrule;
  List<OutDetailModel>? get tData => details;

  // code testing
  set tData(List<OutDetailModel>? value) => details = value;
  set dlvComp(String? value) => deliveryviarule = value;
}
