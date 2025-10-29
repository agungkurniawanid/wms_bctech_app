class GoodReceiveSerialNumberDetailModel {
  final String? sn;
  final String productid;
  final int qty;

  GoodReceiveSerialNumberDetailModel({
    this.sn,
    required this.productid,
    required this.qty,
  });

  Map<String, dynamic> toMap() {
    return {'SN': sn, 'productid': productid, 'qty': qty};
  }

  @override
  String toString() {
    return 'GRDetail(sn: $sn, productid: $productid, qty: $qty)';
  }
}
