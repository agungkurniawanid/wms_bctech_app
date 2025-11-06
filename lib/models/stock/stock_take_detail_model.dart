import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// Asumsi Marm ada di file ini atau di-import
class Marm {
  final String? matnr;
  final String? umrez;
  final String? umren;
  final String? meinh;

  static final _logger = Logger();

  const Marm({this.matnr, this.umrez, this.umren, this.meinh});

  Map<String, dynamic> toMap() {
    return {
      'matnr': matnr ?? '',
      'umrez': umrez ?? '',
      'umren': umren ?? '',
      'meinh': meinh ?? '',
    };
  }

  factory Marm.fromJson(Map<String, dynamic> json) {
    try {
      return Marm(
        matnr: json['matnr'] as String?,
        umrez: json['umrez'] as String?,
        umren: json['umren'] as String?,
        meinh: json['meinh'] as String?,
      );
    } catch (e, stack) {
      _logger.e('Error in Marm.fromJson: $e', stackTrace: stack);
      return const Marm();
    }
  }

  Marm copyWith({String? matnr, String? umrez, String? umren, String? meinh}) {
    return Marm(
      matnr: matnr ?? this.matnr,
      umrez: umrez ?? this.umrez,
      umren: umren ?? this.umren,
      meinh: meinh ?? this.meinh,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Marm &&
        other.matnr == matnr &&
        other.umrez == umrez &&
        other.umren == umren &&
        other.meinh == meinh;
  }

  @override
  int get hashCode => Object.hash(matnr, umrez, umren, meinh);
}

class StockTakeDetailModel {
  final String? werks;
  final String? matnr;
  final double labst;
  final String? lgort;
  final double insme;
  final double speme;
  final String? normt;
  final String? meins;
  final String? matkl;
  final String maktx;
  final String? serno; // <-- FIELD BARU DITAMBAHKAN
  String isApprove;
  String selectedChoice;
  final List<Marm>? marm;
  final ValueNotifier<bool> checkboxValidation;
  final String nORMT;
  final String mATNR;
  final String mAKTX;

  static final _logger = Logger();

  StockTakeDetailModel({
    this.werks,
    this.matnr,
    required this.labst,
    this.lgort,
    required this.insme,
    required this.speme,
    this.normt,
    this.meins,
    this.matkl,
    required this.maktx,
    this.serno, // <-- DITAMBAHKAN DI CONSTRUCTOR
    required this.isApprove,
    required this.selectedChoice,
    this.marm,
    ValueNotifier<bool>? checkboxValidation,
  }) : mATNR = matnr ?? '',
       nORMT = normt ?? '',
       mAKTX = maktx,
       checkboxValidation = checkboxValidation ?? ValueNotifier<bool>(false);

  Map<String, dynamic> toMap() {
    try {
      return {
        // MENGGUNAKAN KEY LOWERCASE
        'werks': werks ?? '',
        'matnr': matnr ?? '',
        'labst': labst,
        'lgort': lgort ?? '',
        'insme': insme,
        'speme': speme,
        'normt': normt ?? '',
        'meins': meins ?? '',
        'matkl': matkl ?? '',
        'maktx': maktx,
        'serno': serno ?? '', // <-- FIELD BARU
        'isapprove': isApprove,
        'selectedChoice': selectedChoice,
        'marm': marm?.map((e) => e.toMap()).toList(), // key lowercase
        'checkboxvalidation': checkboxValidation.value,
      };
    } catch (e, stack) {
      _logger.e('Error in toMap: $e', stackTrace: stack);
      return {};
    }
  }

  factory StockTakeDetailModel.fromJson(Map<String, dynamic> data) {
    try {
      final marmList =
          data['marm'] !=
              null // key lowercase
          ? List<Marm>.from((data['marm'] as List).map((x) => Marm.fromJson(x)))
          : null;

      return StockTakeDetailModel(
        // MENGGUNAKAN KEY LOWERCASE
        werks: data['werks'] as String?,
        matnr: data['matnr'] as String?,
        labst: (data['labst'] as num?)?.toDouble() ?? 0.0,
        lgort: data['lgort'] as String?,
        insme: (data['insme'] as num?)?.toDouble() ?? 0.0,
        speme: (data['speme'] as num?)?.toDouble() ?? 0.0,
        normt: data['normt'] as String?,
        meins: data['meins'] as String?,
        matkl: data['matkl'] as String?,
        maktx: (data['maktx'] as String?)?.trim() ?? 'No description',
        serno: data['serno'] as String?, // <-- FIELD BARU
        isApprove: data['isapprove'] as String? ?? '',
        selectedChoice: data['selectedChoice'] as String? ?? 'UU',
        marm: marmList,
        checkboxValidation: ValueNotifier<bool>(
          data['checkboxvalidation'] as bool? ?? false,
        ),
      );
    } catch (e, stack) {
      _logger.e('Error in fromJson: $e', stackTrace: stack);
      return StockTakeDetailModel(
        labst: 0.0,
        insme: 0.0,
        speme: 0.0,
        maktx: 'No description',
        isApprove: '',
        selectedChoice: 'UU',
      );
    }
  }

  factory StockTakeDetailModel.fromDocumentSnapshot(
    DocumentSnapshot documentSnapshot,
  ) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      return StockTakeDetailModel.fromJson(data);
    } catch (e, stack) {
      _logger.e('Error in fromDocumentSnapshot: $e', stackTrace: stack);
      return StockTakeDetailModel(
        labst: 0.0,
        insme: 0.0,
        speme: 0.0,
        maktx: 'No description',
        isApprove: '',
        selectedChoice: 'UU',
      );
    }
  }

  StockTakeDetailModel copyWith({
    String? werks,
    String? matnr,
    double? labst,
    String? lgort,
    double? insme,
    double? speme,
    String? normt,
    String? meins,
    String? matkl,
    String? maktx,
    String? serno, // <-- FIELD BARU
    String? isApprove,
    String? selectedChoice,
    List<Marm>? marm,
    ValueNotifier<bool>? checkboxValidation,
  }) {
    return StockTakeDetailModel(
      werks: werks ?? this.werks,
      matnr: matnr ?? this.matnr,
      labst: labst ?? this.labst,
      lgort: lgort ?? this.lgort,
      insme: insme ?? this.insme,
      speme: speme ?? this.speme,
      normt: normt ?? this.normt,
      meins: meins ?? this.meins,
      matkl: matkl ?? this.matkl,
      maktx: maktx ?? this.maktx,
      serno: serno ?? this.serno, // <-- FIELD BARU
      isApprove: isApprove ?? this.isApprove,
      selectedChoice: selectedChoice ?? this.selectedChoice,
      marm: marm ?? this.marm?.map((e) => e.copyWith()).toList(),
      checkboxValidation: checkboxValidation ?? this.checkboxValidation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockTakeDetailModel &&
        other.werks == werks &&
        other.matnr == matnr &&
        other.labst == labst &&
        other.lgort == lgort &&
        other.serno == serno; // <-- FIELD BARU
  }

  @override
  int get hashCode => Object.hash(werks, matnr, labst, lgort, serno); // <-- FIELD BARU
}
