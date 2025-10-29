import 'package:cloud_firestore/cloud_firestore.dart';

class InputStockTake {
  String section;
  int countBox;
  double countBun;
  String createdBy;
  String created;
  String documentNo;
  String batchId;
  String matnr;
  String selectedChoice;
  String unitBox;
  String unitBun;
  String sapStockBun;
  String sapStockBox;
  String downloadTime;
  String sloc;
  String plant;
  bool isTick;

  InputStockTake({
    this.section = "",
    this.countBox = 0,
    this.countBun = 0.0,
    this.createdBy = "",
    this.created = "",
    this.documentNo = "",
    this.batchId = "",
    this.matnr = "",
    this.selectedChoice = "",
    this.unitBox = "",
    this.unitBun = "",
    this.sapStockBun = "",
    this.sapStockBox = "",
    this.downloadTime = "",
    this.sloc = "",
    this.plant = "",
    this.isTick = false,
  });

  factory InputStockTake.fromDocumentSnapshot(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>? ?? {};
    return InputStockTake(
      section: data['section'] ?? "",
      countBox: (data['count_box'] ?? 0) is int
          ? data['count_box']
          : int.tryParse(data['count_box'].toString()) ?? 0,
      countBun: (data['count_bun'] ?? 0.0) is num
          ? (data['count_bun'] as num).toDouble()
          : double.tryParse(data['count_bun'].toString()) ?? 0.0,
      created: data['created'] ?? "",
      createdBy: data['createdby'] ?? "",
      documentNo: data['documentno'] ?? "",
      batchId: data['batchid'] ?? "",
      matnr: data['matnr'] ?? "",
      selectedChoice: data['selectedChoice'] ?? "",
      unitBox: data['unit_box'] ?? "",
      unitBun: data['unit_bun'] ?? "",
      sapStockBun: data['SAP_STOCK_BUN'] ?? "",
      sapStockBox: data['SAP_STOCK_BOX'] ?? "",
      downloadTime: data['DOWNLOADTIME'] ?? "",
      sloc: data['sloc'] ?? "",
      plant: data['plant'] ?? "",
      isTick: data['istick'] ?? false,
    );
  }

  InputStockTake clone() => InputStockTake(
    section: section,
    countBox: countBox,
    countBun: countBun,
    created: created,
    createdBy: createdBy,
    documentNo: documentNo,
    batchId: batchId,
    matnr: matnr,
    selectedChoice: selectedChoice,
    unitBox: unitBox,
    unitBun: unitBun,
    sapStockBun: sapStockBun,
    sapStockBox: sapStockBox,
    downloadTime: downloadTime,
    sloc: sloc,
    plant: plant,
    isTick: isTick,
  );

  Map<String, dynamic> toMap() {
    return {
      "documentno": documentNo,
      "createdby": createdBy,
      "created": created,
      "matnr": matnr,
      "section": section,
      "batchid": batchId,
      "selectedChoice": selectedChoice,
      "count_box": countBox,
      "unit_box": unitBox,
      "count_bun": countBun,
      "unit_bun": unitBun,
      "SAP_STOCK_BUN": sapStockBun,
      "SAP_STOCK_BOX": sapStockBox,
      "DOWNLOADTIME": downloadTime,
      "sloc": sloc,
      "plant": plant,
      "istick": isTick,
    };
  }

  static Map<String, dynamic> toMapWithMultipleInputs(
    List<InputStockTake> items,
  ) {
    List<Map<String, dynamic>> dataInputs = items
        .map((item) => item.toMap())
        .toList();

    return {"DESTCLIENT": "402", "DATA_INPUT": dataInputs};
  }

  factory InputStockTake.fromJson(Map<String, dynamic> data) {
    return InputStockTake(
      section: data['section'] ?? "",
      countBox: (data['count_box'] ?? 0) is int
          ? data['count_box']
          : int.tryParse(data['count_box'].toString()) ?? 0,
      countBun: (data['count_bun'] ?? 0.0) is num
          ? (data['count_bun'] as num).toDouble()
          : double.tryParse(data['count_bun'].toString()) ?? 0.0,
      created: data['created'] ?? "",
      createdBy: data['createdby'] ?? "",
      documentNo: data['documentno'] ?? "",
      batchId: data['batchid'] ?? "",
      matnr: data['matnr'] ?? "",
      selectedChoice: data['selectedChoice'] ?? "",
      unitBox: data['unit_box'] ?? "",
      unitBun: data['unit_bun'] ?? "",
      sapStockBun: data['SAP_STOCK_BUN'] ?? "",
      sapStockBox: data['SAP_STOCK_BOX'] ?? "",
      downloadTime: data['DOWNLOADTIME'] ?? "",
      sloc: data['sloc'] ?? "",
      plant: data['plant'] ?? "",
      isTick: data['istick'] ?? false,
    );
  }
}
