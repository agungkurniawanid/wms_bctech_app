class OutDetailModel {
  String? cOrderId;
  String? cTaxId;
  String? cUomId;
  List<String>? flag;
  List<String>? sN;
  String? isSN;
  String? mProductId;
  double? priceactual;
  double? priceentered;
  double? pricelist;
  double? qtydelivered;
  double? qtyinvoiced;
  double? qtyordered;
  double? qtyreserved;
  List<String>? updateddate;
  String? updatedByUsername;
  String? updated;
  String? cloned;
  String? appUser;
  String? appVersion;

  OutDetailModel({
    this.cOrderId,
    this.cTaxId,
    this.cUomId,
    this.flag,
    this.sN,
    this.isSN,
    this.mProductId,
    this.priceactual,
    this.priceentered,
    this.pricelist,
    this.qtydelivered,
    this.qtyinvoiced,
    this.qtyordered,
    this.qtyreserved,
    this.updateddate,
    this.updatedByUsername,
    this.updated,
    this.cloned,
    this.appUser,
    this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'c_order_id': cOrderId,
      'c_tax_id': cTaxId,
      'c_uom_id': cUomId,
      'flag': flag,
      'SN': sN,
      'isSN': isSN,
      'm_product_id': mProductId,
      'priceactual': priceactual ?? 0.0,
      'priceentered': priceentered ?? 0.0,
      'pricelist': pricelist ?? 0.0,
      'qtydelivered': qtydelivered ?? 0.0,
      'qtyinvoiced': qtyinvoiced ?? 0.0,
      'qtyordered': qtyordered ?? 0.0,
      'qtyreserved': qtyreserved ?? 0.0,
      'updateddate': updateddate,
      'UPDATEDBYUSERNAME': updatedByUsername,
      'UPDATED': updated,
      'CLONE': cloned,
      'APP_USER': appUser,
      'APP_VERSION': appVersion,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory OutDetailModel.fromJson(Map<String, dynamic> data) {
    return OutDetailModel(
      cOrderId: data['c_order_id']?.toString() ?? '',
      cTaxId: data['c_tax_id']?.toString() ?? '',
      cUomId: data['c_uom_id']?.toString() ?? '',
      flag: data['flag'] != null ? List<String>.from(data['flag']) : [],
      sN: data['SN'] != null ? List<String>.from(data['SN']) : [],
      isSN: data['isSN']?.toString() ?? '',
      mProductId: data['m_product_id']?.toString() ?? '',
      priceactual: (data['priceactual'] is num)
          ? (data['priceactual'] as num).toDouble()
          : 0.0,
      priceentered: (data['priceentered'] is num)
          ? (data['priceentered'] as num).toDouble()
          : 0.0,
      pricelist: (data['pricelist'] is num)
          ? (data['pricelist'] as num).toDouble()
          : 0.0,
      qtydelivered: (data['qtydelivered'] is num)
          ? (data['qtydelivered'] as num).toDouble()
          : 0.0,
      qtyinvoiced: (data['qtyinvoiced'] is num)
          ? (data['qtyinvoiced'] as num).toDouble()
          : 0.0,
      qtyordered: (data['qtyordered'] is num)
          ? (data['qtyordered'] as num).toDouble()
          : 0.0,
      qtyreserved: (data['qtyreserved'] is num)
          ? (data['qtyreserved'] as num).toDouble()
          : 0.0,
      updateddate: data['updateddate'] != null
          ? List<String>.from(data['updateddate'])
          : [],
      updatedByUsername: data['UPDATEDBYUSERNAME']?.toString() ?? '',
      updated: data['UPDATED']?.toString() ?? '',
      cloned: data['CLONE']?.toString() ?? '',
      appUser: data['APP_USER']?.toString() ?? '',
      appVersion: data['APP_VERSION']?.toString() ?? '',
    );
  }

  OutDetailModel.clone(OutDetailModel data) {
    cOrderId = data.cOrderId;
    cTaxId = data.cTaxId;
    cUomId = data.cUomId;
    flag = data.flag != null ? List.from(data.flag!) : null;
    sN = data.sN != null ? List.from(data.sN!) : null;
    isSN = data.isSN;
    mProductId = data.mProductId;
    priceactual = data.priceactual;
    priceentered = data.priceentered;
    pricelist = data.pricelist;
    qtydelivered = data.qtydelivered;
    qtyinvoiced = data.qtyinvoiced;
    qtyordered = data.qtyordered;
    qtyreserved = data.qtyreserved;
    updateddate = data.updateddate != null
        ? List.from(data.updateddate!)
        : null;
    updatedByUsername = data.updatedByUsername;
    updated = data.updated;
    cloned = data.cloned;
    appUser = data.appUser;
    appVersion = data.appVersion;
  }

  OutDetailModel clone() => OutDetailModel.clone(this);

  // Untuk kompatibilitas dengan kode existing
  String? get ebeln => cOrderId;
  String? get matnr => mProductId;
  String? get maktx => mProductId;
  String? get meins => cUomId;
  double? get menge => qtyordered;
  double? get grqty => qtydelivered;
  String? get ebelp => '1';
}
