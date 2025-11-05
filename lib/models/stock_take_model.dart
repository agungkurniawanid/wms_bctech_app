import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'stock_take_detail_model.dart';

class StockTakeModel {
  final List<StockTakeDetailModel> detail;
  final List<String> lGORT;
  String updated;
  String updatedby;
  final String created;
  final String createdby;
  final String isapprove;
  final String doctype;
  final String documentno;

  StockTakeModel({
    required this.detail,
    required this.lGORT,
    required this.updated,
    required this.updatedby,
    required this.created,
    required this.createdby,
    required this.isapprove,
    required this.doctype,
    required this.documentno,
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

      final lgortList = List<String>.from(
        data['LGORT'] as List<dynamic>? ?? [],
      );

      return StockTakeModel(
        detail: detailList,
        lGORT: lgortList,
        updated: data['updated'] as String? ?? '',
        updatedby: data['updatedby'] as String? ?? '',
        created: data['created'] as String? ?? '',
        createdby: data['createdby'] as String? ?? '',
        isapprove: data['isapprove'] as String? ?? '',
        doctype: data['doctype'] as String? ?? 'stocktick',
        documentno: data['documentno'] as String? ?? '',
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
      return StockTakeModel.fromJson(data);
    } catch (e) {
      Logger().e('Error in StockTakeModel.fromDocumentSnapshot: $e');
      return StockTakeModel.empty();
    }
  }

  factory StockTakeModel.fromDocumentSnapshotWithDetail(
    DocumentSnapshot documentSnapshot,
  ) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;

      final detailList =
          (data['detail'] as List<dynamic>?)
              ?.map(
                (itemWord) => StockTakeDetailModel.fromJson(
                  itemWord as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [];

      final lgortList = List<String>.from(
        data['LGORT'] as List<dynamic>? ?? [],
      );

      return StockTakeModel(
        detail: detailList,
        lGORT: lgortList,
        updated: data['updated'] as String? ?? '',
        updatedby: data['updatedby'] as String? ?? '',
        created: data['created'] as String? ?? '',
        createdby: data['createdby'] as String? ?? '',
        isapprove: data['isapprove'] as String? ?? '',
        doctype: data['doctype'] as String? ?? 'stocktick',
        documentno: data['documentno'] as String? ?? '',
      );
    } catch (e) {
      Logger().e('Error in StockTakeModel.fromDocumentSnapshotWithDetail: $e');
      return StockTakeModel.empty();
    }
  }

  factory StockTakeModel.empty() {
    return StockTakeModel(
      detail: [],
      lGORT: [],
      updated: '',
      updatedby: '',
      created: '',
      createdby: '',
      isapprove: '',
      doctype: 'stocktick',
      documentno: '',
    );
  }

  StockTakeModel copyWith({
    List<StockTakeDetailModel>? detail,
    List<String>? lGORT,
    String? updated,
    String? updatedby,
    String? created,
    String? createdby,
    String? isapprove,
    String? doctype,
    String? documentno,
  }) {
    return StockTakeModel(
      detail: detail ?? this.detail,
      lGORT: lGORT ?? this.lGORT,
      updated: updated ?? this.updated,
      updatedby: updatedby ?? this.updatedby,
      created: created ?? this.created,
      createdby: createdby ?? this.createdby,
      isapprove: isapprove ?? this.isapprove,
      doctype: doctype ?? this.doctype,
      documentno: documentno ?? this.documentno,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'detail': detail.map((e) => e.toMap()).toList(),
      'LGORT': lGORT,
      'updated': updated,
      'updatedby': updatedby,
      'created': created,
      'createdby': createdby,
      'isapprove': isapprove,
      'doctype': doctype,
      'documentno': documentno,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockTakeModel &&
        other.documentno == documentno &&
        other.doctype == doctype;
  }

  @override
  int get hashCode {
    return Object.hash(documentno, doctype);
  }
}
