import 'dart:convert';

class StockDetail {
  int? checked;
  String? formattedUpdatedAt;
  String? inventoryGroup;
  String? itemName;
  String? location;
  String? recordid;
  int? stockBad;
  int? stockGood;
  int? stockMain;
  int? stockBadCtn;
  int? stockGoodCtn;
  int? stockMainCtn;
  int? warehouseStockBad;
  int? warehouseStockGood;
  int? warehouseStockMain;
  int? warehouseStockBadCtn;
  int? warehouseStockGoodCtn;
  int? warehouseStockMainCtn;
  String? updatedAt;
  String? itemCode;
  String? approveName;
  String? isScanned;
  String? itemImage;
  String? uom;
  int? stockTotal;

  StockDetail({
    this.checked,
    this.formattedUpdatedAt,
    this.inventoryGroup,
    this.itemName,
    this.location,
    this.recordid,
    this.stockBad,
    this.stockGood,
    this.stockMain,
    this.stockBadCtn,
    this.stockGoodCtn,
    this.stockMainCtn,
    this.warehouseStockBad,
    this.warehouseStockGood,
    this.warehouseStockMain,
    this.warehouseStockBadCtn,
    this.warehouseStockGoodCtn,
    this.warehouseStockMainCtn,
    this.updatedAt,
    this.itemCode,
    this.approveName,
    this.isScanned,
    this.itemImage,
    this.uom,
    this.stockTotal,
  });

  StockDetail.clone(StockDetail data)
    : checked = data.checked ?? 0,
      formattedUpdatedAt = data.formattedUpdatedAt ?? '',
      inventoryGroup = data.inventoryGroup ?? '',
      itemName = data.itemName ?? '',
      location = data.location ?? '',
      recordid = data.recordid ?? '',
      stockBad = data.stockBad ?? 0,
      stockGood = data.stockGood ?? 0,
      stockMain = data.stockMain ?? 0,
      stockBadCtn = data.stockBadCtn ?? 0,
      stockGoodCtn = data.stockGoodCtn ?? 0,
      stockMainCtn = data.stockMainCtn ?? 0,
      warehouseStockBad = data.warehouseStockBad ?? 0,
      warehouseStockGood = data.warehouseStockGood ?? 0,
      warehouseStockMain = data.warehouseStockMain ?? 0,
      warehouseStockBadCtn = data.warehouseStockBadCtn ?? 0,
      warehouseStockGoodCtn = data.warehouseStockGoodCtn ?? 0,
      warehouseStockMainCtn = data.warehouseStockMainCtn ?? 0,
      updatedAt = data.updatedAt ?? '',
      itemCode = data.itemCode ?? '',
      approveName = data.approveName ?? '',
      isScanned = data.isScanned ?? '',
      itemImage = data.itemImage ?? '',
      uom = data.uom ?? '',
      stockTotal = data.stockTotal ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'checked': checked,
      'formatted_updated_at': formattedUpdatedAt,
      'inventory_group': inventoryGroup,
      'item_name': itemName,
      'location': location,
      'recordid': recordid,
      'stock_bad': stockBad,
      'stock_good': stockGood,
      'stock_main': stockMain,
      'stock_bad_ctn': stockBadCtn,
      'stock_good_ctn': stockGoodCtn,
      'stock_main_ctn': stockMainCtn,
      'warehouse_stock_bad': warehouseStockBad,
      'warehouse_stock_good': warehouseStockGood,
      'warehouse_stock_main': warehouseStockMain,
      'warehouse_stock_bad_ctn': warehouseStockBadCtn,
      'warehouse_stock_good_ctn': warehouseStockGoodCtn,
      'warehouse_stock_main_ctn': warehouseStockMainCtn,
      'updated_at': updatedAt,
      'item_code': itemCode,
      'approvename': approveName,
      'is_scanned': isScanned,
      'item_image': itemImage,
      'uom': uom,
      'stock_total': stockTotal,
    };
  }

  factory StockDetail.fromJson(Map<String, dynamic> data) {
    return StockDetail(
      checked: data['checked'] ?? 0,
      formattedUpdatedAt: data['formatted_updated_at'] ?? '',
      inventoryGroup: data['inventory_group'] ?? '',
      itemName: data['item_name'] ?? '',
      location: data['location'] ?? '',
      recordid: data['recordid'] ?? '',
      stockBad: data['stock_bad'] ?? 0,
      stockGood: data['stock_good'] ?? 0,
      stockMain: data['stock_main'] ?? 0,
      stockBadCtn: data['stock_bad_ctn'] ?? 0,
      stockGoodCtn: data['stock_good_ctn'] ?? 0,
      stockMainCtn: data['stock_main_ctn'] ?? 0,
      warehouseStockBad: data['warehouse_stock_bad'] ?? 0,
      warehouseStockGood: data['warehouse_stock_good'] ?? 0,
      warehouseStockMain: data['warehouse_stock_main'] ?? 0,
      warehouseStockBadCtn: data['warehouse_stock_bad_ctn'] ?? 0,
      warehouseStockGoodCtn: data['warehouse_stock_good_ctn'] ?? 0,
      warehouseStockMainCtn: data['warehouse_stock_main_ctn'] ?? 0,
      updatedAt: data['updated_at'] ?? '',
      itemCode: data['item_code'] ?? '',
      approveName: data['approvename'] ?? '',
      isScanned: data['is_scanned'] ?? '',
      itemImage: data['item_image'] ?? '',
      uom: data['uom'] ?? '',
      stockTotal: data['stock_total'] ?? 0,
    );
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}
