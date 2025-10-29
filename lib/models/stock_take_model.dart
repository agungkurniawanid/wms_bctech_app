import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'stock_take_detail_model.dart';

class StocktickModel {
  final List<StockTakeDetailModel> detail;
  final List<String> lGORT;
  String updated;
  String updatedby;
  final String created;
  final String createdby;
  final String isapprove;
  final String doctype;
  final String documentno;

  StocktickModel({
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

  factory StocktickModel.fromJson(Map<String, dynamic> data) {
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

      return StocktickModel(
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
      Logger().e('Error in StocktickModel.fromJson: $e');
      return StocktickModel.empty();
    }
  }

  factory StocktickModel.fromDocumentSnapshot(
    DocumentSnapshot documentSnapshot,
  ) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      return StocktickModel.fromJson(data);
    } catch (e) {
      Logger().e('Error in StocktickModel.fromDocumentSnapshot: $e');
      return StocktickModel.empty();
    }
  }

  factory StocktickModel.fromDocumentSnapshotWithDetail(
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

      return StocktickModel(
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
      Logger().e('Error in StocktickModel.fromDocumentSnapshotWithDetail: $e');
      return StocktickModel.empty();
    }
  }

  factory StocktickModel.empty() {
    return StocktickModel(
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

  StocktickModel copyWith({
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
    return StocktickModel(
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
    return other is StocktickModel &&
        other.documentno == documentno &&
        other.doctype == doctype;
  }

  @override
  int get hashCode {
    return Object.hash(documentno, doctype);
  }
}
