import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/models/stock/stock_take_detail_model.dart';

class StockTakeModel {
  final String documentid;
  final String lastQuery;
  final int countDetail;
  final List<StockTakeDetailModel> detail; // Asumsi (array) adalah 'detail'
  final String locatorValue;
  final String whName;
  final String whValue;

  // testing
  final String isApprove;
  final String createdBy;
  final String created;
  final List<String> lGort;
  final String updated;
  final String updatedby;
  final String doctype;

  StockTakeModel({
    required this.documentid,
    required this.lastQuery,
    required this.countDetail,
    required this.detail,
    required this.locatorValue,
    required this.whName,
    required this.whValue,
    required this.isApprove,
    required this.createdBy,
    required this.created,
    required this.lGort,
    required this.updated,
    required this.updatedby,
    required this.doctype,
  });

  factory StockTakeModel.fromJson(Map<String, dynamic> data) {
    try {
      final detailList =
          (data['detail'] as List<dynamic>?)
              ?.map(
                (e) => StockTakeDetailModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      return StockTakeModel(
        documentid: data['_documentid'] as String? ?? '',
        lastQuery: data['_last_query'] as String? ?? '',
        countDetail: (data['count_detail'] as num?)?.toInt() ?? 0,
        detail: detailList, // Mem-parsing array 'detail'
        locatorValue: data['locator_value'] as String? ?? '',
        whName: data['wh_name'] as String? ?? '',
        whValue: data['wh_value'] as String? ?? '',
        isApprove: data['isapprove'] as String? ?? '',
        createdBy: data['createdby'] as String? ?? '',
        created: data['created'] as String? ?? '',
        lGort: data['lGort'] as List<String>? ?? [],
        updated: data['updated'] as String? ?? '',
        updatedby: data['updatedby'] as String? ?? '',
        doctype: data['doctype'] as String? ?? '',
      );
    } catch (e) {
      Logger().e('Error in StockTakeModel.fromJson: $e');
      return StockTakeModel.empty();
    }
  }

  factory StockTakeModel.fromDocumentSnapshot(
    DocumentSnapshot documentSnapshot,
  ) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      // Menambahkan documentid dari snapshot jika tidak ada di data
      final finalData = {
        ...data,
        '_documentid': data['_documentid'] ?? documentSnapshot.id,
      };
      return StockTakeModel.fromJson(finalData);
    } catch (e) {
      Logger().e('Error in StockTakeModel.fromDocumentSnapshot: $e');
      return StockTakeModel.empty();
    }
  }

  factory StockTakeModel.empty() {
    return StockTakeModel(
      documentid: '',
      lastQuery: '',
      countDetail: 0,
      detail: [],
      locatorValue: '',
      whName: '',
      whValue: '',
      isApprove: '',
      createdBy: '',
      created: '',
      lGort: [],
      updated: '',
      updatedby: '',
      doctype: '',
    );
  }

  StockTakeModel copyWith({
    String? documentid,
    String? lastQuery,
    int? countDetail,
    List<StockTakeDetailModel>? detail,
    String? locatorValue,
    String? whName,
    String? whValue,
  }) {
    return StockTakeModel(
      documentid: documentid ?? this.documentid,
      lastQuery: lastQuery ?? this.lastQuery,
      countDetail: countDetail ?? this.countDetail,
      detail: detail ?? this.detail,
      locatorValue: locatorValue ?? this.locatorValue,
      whName: whName ?? this.whName,
      whValue: whValue ?? this.whValue,
      isApprove: '',
      createdBy: '',
      created: '',
      lGort: [],
      updated: '',
      updatedby: '',
      doctype: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_documentid': documentid,
      '_last_query': lastQuery,
      'count_detail': countDetail,
      'detail': detail.map((e) => e.toMap()).toList(),
      'locator_value': locatorValue,
      'wh_name': whName,
      'wh_value': whValue,
      'isapprove': isApprove,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockTakeModel && other.documentid == documentid;
  }

  @override
  int get hashCode {
    return documentid.hashCode;
  }
}
