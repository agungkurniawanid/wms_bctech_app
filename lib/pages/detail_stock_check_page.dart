import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:wms_bctech/models/stock_detail_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/controllers/stock_check_controlller.dart';
import 'package:wms_bctech/components/text_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DetailStockCheckPage extends StatefulWidget {
  final int? index;
  final String? flag;

  const DetailStockCheckPage(this.index, this.flag, {super.key});

  @override
  State<DetailStockCheckPage> createState() => _DetailStockCheckPage();
}

class _DetailStockCheckPage extends State<DetailStockCheckPage> {
  final StockCheckVM stockcheckVM = Get.find();
  final GlobalVM globalVM = Get.find();
  final InVM inVM = Get.find();

  bool allow = true;
  int idPeriodSelected = 1;
  final List<String> sortList = ['PO Date', 'Vendor'];

  final List<ItemChoice> listchoice = <ItemChoice>[
    ItemChoice(1, 'Ambient'),
    ItemChoice(2, 'Chiller'),
    ItemChoice(3, 'Frozen'),
  ];

  bool light0 = false;
  bool ontap = true;
  bool pcsctnvalidation = true;
  final ValueNotifier<bool> pcsctnnotifier = ValueNotifier(false);
  final ValueNotifier<int> pickedctnmain = ValueNotifier(0);
  final ValueNotifier<int> pickedctngood = ValueNotifier(0);
  final ValueNotifier<int> pickedpcsmain = ValueNotifier(0);
  final ValueNotifier<int> pickedpcsgood = ValueNotifier(0);

  int typeIndexmain = 0;
  int typeIndexgood = 0;
  int tabs = 0;

  final Map<int, Widget> myTabs = const <int, Widget>{
    0: Text("CTN"),
    1: Text("PCS"),
  };

  late TextEditingController _controllermain;
  late TextEditingController _controllergood;
  List<Category> listcategory = [];
  late ScrollController controller;
  bool leading = true;
  final GlobalKey srKey = GlobalKey();
  late StockModel clone;
  String? barcodeScanRes;
  bool fromscan = true;
  bool _isSearching = false;
  late TextEditingController _searchQuery;
  String searchQuery = "";
  final List<StockDetail> listdetailstock = <StockDetail>[];

  MobileScannerController mobileScannerController = MobileScannerController(
    formats: [BarcodeFormat.all],
    returnImage: false,
    autoStart: false,
  );

  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _searchQuery = TextEditingController();
    final originalStock = stockcheckVM.toliststock[widget.index!];
    clone = originalStock.clone();
    GlobalVar.choicecategory = "AB";
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    mobileScannerController.dispose();
    super.dispose();
  }

  // Method untuk menangani hasil scan dari MobileScanner
  void _handleBarcodeScan(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty && mounted) {
      final String barcodeString = barcodes.first.rawValue ?? "";

      setState(() {
        if (widget.flag != "history" && barcodeString.isNotEmpty) {
          final stock = stockcheckVM.toliststock[widget.index!];

          final List<StockDetail> matchingItems =
              stock.detail
                  ?.where(
                    (element) =>
                        element.itemCode?.contains(barcodeString) == true,
                  )
                  .toList() ??
              [];

          if (matchingItems.isNotEmpty) {
            pcsctnnotifier.value = false;
            pickedctnmain.value = matchingItems[0].warehouseStockMainCtn ?? 0;
            pickedctngood.value = matchingItems[0].warehouseStockGoodCtn ?? 0;
            pickedpcsmain.value = matchingItems[0].warehouseStockMain ?? 0;
            pickedpcsgood.value = matchingItems[0].warehouseStockGood ?? 0;
            fromscan = false;

            // Stop scanning dan tutup dialog
            mobileScannerController.stop();
            isScanning = false;
            Navigator.of(context).pop(); // Tutup dialog scanner

            showModalBottomSheet(
              context: context,
              builder: (context) => modalBottomSheet(matchingItems[0]),
            );
          }
        }
      });
    }
  }

  Future<void> startMobileScan() async {
    try {
      setState(() {
        isScanning = true;
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Scan Barcode"),
          content: SizedBox(
            height: 300,
            child: MobileScanner(
              controller: mobileScannerController,
              onDetect: _handleBarcodeScan,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                mobileScannerController.stop();
                isScanning = false;
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error starting mobile scanner: $e");
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> scanBarcode() async {
    if (isScanning) {
      return;
    }

    await startMobileScan();
  }

  String barcodeString = "Barcode will be shown here";
  String barcodeSymbology = "Symbology will be shown here";
  String scanTime = "Scan Time will be shown here";

  String calculateStock(int mainstock, int goodstock) {
    final int totalstock = mainstock + goodstock;
    return totalstock.toString();
  }

  Future<void> _showMyDialogApprove(
    StockModel stockmodel,
    StockDetail stockdetail,
    String tanda,
  ) async {
    final double baseWidth = 312;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      1 * fem,
                      15.5 * fem,
                    ),
                    width: 35 * fem,
                    height: 35 * fem,
                    child: Image.asset(
                      'data/images/mdi-warning-circle-vJo.png',
                      width: 35 * fem,
                      height: 35 * fem,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      48 * fem,
                    ),
                    constraints: BoxConstraints(maxWidth: 256 * fem),
                    child: Text(
                      'Are you sure to save all changes made in this Product? ',
                      textAlign: TextAlign.center,
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xff2d2d2d),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 25 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              20 * fem,
                              0 * fem,
                              16 * fem,
                              0 * fem,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xfff44236),
                              ),
                              color: const Color(0xffffffff),
                              borderRadius: BorderRadius.circular(12 * fem),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/cancel-viF.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Get.back();
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/check-circle-fg7.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () async {
                            final String username =
                                (await DatabaseHelper.db.getUser()) ??
                                "Unknown";

                            final String todaytime = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(DateTime.now());

                            List<Map<String, dynamic>> maptdata = [];

                            if (fromscan == false) {
                              stockdetail.isScanned = "Y";
                            }

                            final stock =
                                stockcheckVM.toliststock[widget.index!];
                            final stockDetailList = stock.detail ?? [];

                            if (tanda == "all") {
                              if (_isSearching) {
                                stockDetailList.clear();
                                stockDetailList.addAll(listdetailstock);
                              }

                              stockmodel.isApprove = "Y";
                              stockmodel.updatedby = username;
                              stockmodel.updated = todaytime;
                            } else {
                              stockdetail.stockGood = pickedpcsgood.value;
                              stockdetail.stockGoodCtn = pickedctngood.value;
                              stockdetail.stockMain = pickedpcsmain.value;
                              stockdetail.stockMainCtn = pickedctnmain.value;
                              stockdetail.checked = 1;
                              stockdetail.approveName = username;
                              stockdetail.updatedAt = todaytime;
                            }

                            maptdata = stockDetailList
                                .map((person) => person.toMap())
                                .toList();

                            Get.back();
                            Get.back();

                            if (tanda == "all") {
                              stockcheckVM.approveall(stockmodel, "Y");
                              stockcheckVM.sendtohistory(stockmodel, maptdata);
                            } else {
                              stockcheckVM.approvestock(stock, maptdata);
                            }

                            Fluttertoast.showToast(
                              fontSize: 22,
                              gravity: ToastGravity.TOP,
                              msg: "Document has been approved",
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMyDialogReject(String flag) async {
    final double baseWidth = 312;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      1 * fem,
                      15.5 * fem,
                    ),
                    width: 35 * fem,
                    height: 35 * fem,
                    child: Image.asset(
                      'data/images/mdi-warning-circle-9um.png',
                      width: 35 * fem,
                      height: 35 * fem,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      48 * fem,
                    ),
                    constraints: BoxConstraints(maxWidth: 256 * fem),
                    child: Text(
                      'Are you sure to discard all changes made in this Area?',
                      textAlign: TextAlign.center,
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xff2d2d2d),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 25 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              20 * fem,
                              0 * fem,
                              16 * fem,
                              0 * fem,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xfff44236),
                              ),
                              color: const Color(0xffffffff),
                              borderRadius: BorderRadius.circular(12 * fem),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/cancel-viF.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.back();
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/check-circle-fg7.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () async {
                            if (flag == "refresh") {
                              Get.back();
                            } else {
                              Get.back();
                              Get.back();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMyDialog(StockDetail indetail, bool type) async {
    final double baseWidth = 312;
    final double fem = MediaQuery.of(context).size.width / baseWidth;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      '${indetail.itemName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: tabs,
                      children: myTabs,
                      onValueChanged: (int? i) {
                        setState(() {
                          tabs = i ?? 0;
                          type = tabs == 1;

                          if (type) {
                            _controllermain = TextEditingController(
                              text: pickedpcsmain.value.toString(),
                            );
                            typeIndexmain = int.parse(_controllermain.text);

                            _controllergood = TextEditingController(
                              text: pickedpcsgood.value.toString(),
                            );
                            typeIndexgood = int.parse(_controllergood.text);
                          } else {
                            _controllermain = TextEditingController(
                              text: pickedctnmain.value.toString(),
                            );
                            typeIndexmain = int.parse(_controllermain.text);

                            _controllergood = TextEditingController(
                              text: pickedctngood.value.toString(),
                            );
                            typeIndexgood = int.parse(_controllergood.text);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      'Main',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: const Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (!type) {
                                if (_controllermain.text[0] == '0') {
                                  typeIndexmain = 0;
                                  _controllermain = TextEditingController(
                                    text: typeIndexmain.toString(),
                                  );
                                } else {
                                  typeIndexmain--;
                                  _controllermain = TextEditingController(
                                    text: typeIndexmain.toString(),
                                  );
                                }
                                pickedctnmain.value = typeIndexmain;
                              } else {
                                if (_controllermain.text[0] == '0') {
                                  typeIndexmain = 0;
                                  _controllermain = TextEditingController(
                                    text: typeIndexmain.toString(),
                                  );
                                } else {
                                  typeIndexmain--;
                                  _controllermain = TextEditingController(
                                    text: typeIndexmain.toString(),
                                  );
                                }
                                pickedpcsmain.value = typeIndexmain;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _controllermain,
                          onChanged: (String i) {
                            setState(() {
                              if (!type && tabs == 0) {
                                typeIndexmain = int.parse(_controllermain.text);
                                pickedctnmain.value = typeIndexmain;
                              } else if (type && tabs == 1) {
                                typeIndexmain = int.parse(_controllermain.text);
                                pickedpcsmain.value = typeIndexmain;
                              }
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (!type) {
                                typeIndexmain++;
                                _controllermain = TextEditingController(
                                  text: typeIndexmain.toString(),
                                );
                                pickedctnmain.value = typeIndexmain;
                              } else {
                                typeIndexmain++;
                                _controllermain = TextEditingController(
                                  text: typeIndexmain.toString(),
                                );
                                pickedpcsmain.value = typeIndexmain;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      'Good',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: const Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (!type) {
                                if (_controllergood.text[0] == '0') {
                                  typeIndexgood = 0;
                                  _controllergood = TextEditingController(
                                    text: typeIndexgood.toString(),
                                  );
                                } else {
                                  typeIndexgood--;
                                  _controllergood = TextEditingController(
                                    text: typeIndexgood.toString(),
                                  );
                                }
                                pickedctngood.value = typeIndexgood;
                              } else {
                                if (_controllergood.text[0] == '0') {
                                  typeIndexgood = 0;
                                  _controllergood = TextEditingController(
                                    text: typeIndexgood.toString(),
                                  );
                                } else {
                                  typeIndexgood--;
                                  _controllergood = TextEditingController(
                                    text: typeIndexgood.toString(),
                                  );
                                }
                                pickedpcsgood.value = typeIndexgood;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _controllergood,
                          onChanged: (String i) {
                            setState(() {
                              if (!type && tabs == 0) {
                                typeIndexgood = int.parse(_controllergood.text);
                                pickedctngood.value = typeIndexgood;
                              } else if (type && tabs == 1) {
                                typeIndexgood = int.parse(_controllergood.text);
                                pickedpcsgood.value = typeIndexgood;
                              }
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (!type) {
                                typeIndexgood++;
                                _controllergood = TextEditingController(
                                  text: typeIndexgood.toString(),
                                );
                                pickedctngood.value = typeIndexgood;
                              } else {
                                typeIndexgood++;
                                _controllergood = TextEditingController(
                                  text: typeIndexgood.toString(),
                                );
                                pickedpcsgood.value = typeIndexgood;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      height: 30 * fem,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Container(
                              margin: EdgeInsets.fromLTRB(
                                20 * fem,
                                0 * fem,
                                16 * fem,
                                0 * fem,
                              ),
                              padding: EdgeInsets.fromLTRB(
                                24 * fem,
                                5 * fem,
                                25 * fem,
                                5 * fem,
                              ),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xfff44236),
                                ),
                                color: const Color(0xffffffff),
                                borderRadius: BorderRadius.circular(12 * fem),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 30 * fem,
                                  height: 30 * fem,
                                  child: Image.asset(
                                    'data/images/cancel-viF.png',
                                    width: 30 * fem,
                                    height: 30 * fem,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              pickedctnmain.value =
                                  indetail.warehouseStockMainCtn ?? 0;
                              pickedctngood.value =
                                  indetail.warehouseStockGoodCtn ?? 0;
                              pickedpcsmain.value =
                                  indetail.warehouseStockMain ?? 0;
                              pickedpcsgood.value =
                                  indetail.warehouseStockGood ?? 0;
                              Get.back();
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                24 * fem,
                                5 * fem,
                                25 * fem,
                                5 * fem,
                              ),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xff2cab0c),
                                borderRadius: BorderRadius.circular(12 * fem),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x3f000000),
                                    offset: Offset(0 * fem, 4 * fem),
                                    blurRadius: 2 * fem,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 30 * fem,
                                  height: 30 * fem,
                                  child: Image.asset(
                                    'data/images/check-circle-fg7.png',
                                    width: 30 * fem,
                                    height: 30 * fem,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              Get.back();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget modalBottomSheet(StockDetail detail) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: GlobalVar.height * 0.85,
      child: Container(
        padding: EdgeInsets.fromLTRB(0 * fem, 10 * fem, 0 * fem, 0 * fem),
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xffffffff)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Text(
                      ' ${detail.itemName}',
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xfff44236),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  child: GestureDetector(
                    child: Image.asset(
                      'data/images/cancel-viF.png',
                      width: 30 * fem,
                      height: 30 * fem,
                    ),
                    onTap: () {
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
              width: double.infinity,
              height: 1 * fem,
              decoration: const BoxDecoration(color: Color(0xffa8a8a8)),
            ),
            GestureDetector(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  120 * fem,
                  0 * fem,
                  120 * fem,
                  6 * fem,
                ),
                padding: EdgeInsets.fromLTRB(
                  5 * fem,
                  6 * fem,
                  5 * fem,
                  6 * fem,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xfff44236)),
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(8 * fem),
                ),
                child: Center(
                  child: SizedBox(
                    width: 110 * fem,
                    height: 108 * fem,
                    child: Image.asset(
                      'data/images/cancel-viF.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              onTap: () {
                Get.back();
              },
            ),
            Container(
              width: double.infinity,
              height: 1 * fem,
              decoration: const BoxDecoration(color: Color(0xffa8a8a8)),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                51 * fem,
                11 * fem,
                16 * fem,
                8 * fem,
              ),
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable: pcsctnnotifier,
                builder: (BuildContext context, bool value, Widget? child) {
                  return ValueListenableBuilder<int>(
                    valueListenable: !value ? pickedctnmain : pickedpcsmain,
                    builder: (BuildContext context, int mainValue, Widget? child) {
                      return ValueListenableBuilder<int>(
                        valueListenable: !value ? pickedctngood : pickedpcsgood,
                        builder: (BuildContext context, int goodValue, Widget? child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  69 * fem,
                                  0 * fem,
                                  104 * fem,
                                  8 * fem,
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  2 * fem,
                                  2 * fem,
                                  2 * fem,
                                  2 * fem,
                                ),
                                width: double.infinity,
                                height: 30 * fem,
                                decoration: BoxDecoration(
                                  color: const Color(0xffd9d9d9),
                                  borderRadius: BorderRadius.circular(8 * fem),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        width: 54 * fem,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: !value
                                              ? const Color(0xffffffff)
                                              : const Color(0xffd9d9d9),
                                          borderRadius: BorderRadius.circular(
                                            8 * fem,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'CTN',
                                            textAlign: TextAlign.center,
                                            style: safeGoogleFont(
                                              'Roboto',
                                              fontSize: 12 * ffem,
                                              fontWeight: FontWeight.w600,
                                              height: 1.1725 * ffem / fem,
                                              color: const Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          pcsctnnotifier.value = false;
                                        });
                                      },
                                    ),
                                    GestureDetector(
                                      child: Container(
                                        width: 54 * fem,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: value
                                              ? const Color(0xffffffff)
                                              : const Color(0xffd9d9d9),
                                          borderRadius: BorderRadius.circular(
                                            8 * fem,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${detail.uom}',
                                            textAlign: TextAlign.center,
                                            style: safeGoogleFont(
                                              'Roboto',
                                              fontSize: 12 * ffem,
                                              fontWeight: FontWeight.w600,
                                              height: 1.1725 * ffem / fem,
                                              color: const Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          pcsctnnotifier.value = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  0 * fem,
                                  0 * fem,
                                  36 * fem,
                                  6 * fem,
                                ),
                                child: Text(
                                  'Current Quantity',
                                  textAlign: TextAlign.center,
                                  style: safeGoogleFont(
                                    'Roboto',
                                    fontSize: 16 * ffem,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1725 * ffem / fem,
                                    color: const Color(0xff000000),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  16 * fem,
                                  0 * fem,
                                  51 * fem,
                                  12 * fem,
                                ),
                                width: double.infinity,
                                height: 69 * fem,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(
                                        0 * fem,
                                        0 * fem,
                                        68 * fem,
                                        0 * fem,
                                      ),
                                      width: 79 * fem,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          6 * fem,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.fromLTRB(
                                              0 * fem,
                                              0 * fem,
                                              0 * fem,
                                              4 * fem,
                                            ),
                                            width: double.infinity,
                                            height: 46 * fem,
                                            decoration: BoxDecoration(
                                              color: const Color(0xffe0e0e0),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    6 * fem,
                                                  ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                value
                                                    ? '${detail.stockMain}'
                                                    : '${detail.stockMainCtn}',
                                                textAlign: TextAlign.center,
                                                style: safeGoogleFont(
                                                  'Roboto',
                                                  fontSize: 24 * ffem,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.1725 * ffem / fem,
                                                  color: const Color(
                                                    0xff000000,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Main',
                                            textAlign: TextAlign.center,
                                            style: safeGoogleFont(
                                              'Roboto',
                                              fontSize: 16 * ffem,
                                              fontWeight: FontWeight.w600,
                                              height: 1.1725 * ffem / fem,
                                              color: const Color(0xff9a9a9a),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 79 * fem,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          6 * fem,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.fromLTRB(
                                              0 * fem,
                                              0 * fem,
                                              0 * fem,
                                              4 * fem,
                                            ),
                                            width: double.infinity,
                                            height: 46 * fem,
                                            decoration: BoxDecoration(
                                              color: const Color(0xffe0e0e0),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    6 * fem,
                                                  ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                value
                                                    ? '${detail.stockGood}'
                                                    : '${detail.stockGoodCtn}',
                                                textAlign: TextAlign.center,
                                                style: safeGoogleFont(
                                                  'Roboto',
                                                  fontSize: 24 * ffem,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.1725 * ffem / fem,
                                                  color: const Color(
                                                    0xff000000,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Good',
                                            textAlign: TextAlign.center,
                                            style: safeGoogleFont(
                                              'Roboto',
                                              fontSize: 16 * ffem,
                                              fontWeight: FontWeight.w600,
                                              height: 1.1725 * ffem / fem,
                                              color: const Color(0xff9a9a9a),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  0 * fem,
                                  0 * fem,
                                  32 * fem,
                                  6 * fem,
                                ),
                                child: Text(
                                  'Actual Quantity',
                                  textAlign: TextAlign.center,
                                  style: safeGoogleFont(
                                    'Roboto',
                                    fontSize: 16 * ffem,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1725 * ffem / fem,
                                    color: const Color(0xff000000),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  0 * fem,
                                  0 * fem,
                                  27 * fem,
                                  12 * fem,
                                ),
                                width: double.infinity,
                                height: 69 * fem,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        margin: EdgeInsets.fromLTRB(
                                          0 * fem,
                                          0 * fem,
                                          32 * fem,
                                          0 * fem,
                                        ),
                                        width: 117 * fem,
                                        height: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                0 * fem,
                                                0 * fem,
                                                0 * fem,
                                                4 * fem,
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                5 * fem,
                                                7 * fem,
                                                2 * fem,
                                                7 * fem,
                                              ),
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xffe0e0e0,
                                                  ),
                                                ),
                                                color: const Color(0xffffffff),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      6 * fem,
                                                    ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      (detail.warehouseStockMain
                                                                      .toString()
                                                                      .length ==
                                                                  1 ||
                                                              detail.warehouseStockMainCtn
                                                                      .toString()
                                                                      .length ==
                                                                  1)
                                                          ? 45 * fem
                                                          : 30 * fem,
                                                      1 * fem,
                                                      10 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      value
                                                          ? '$mainValue'
                                                          : '$mainValue',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: safeGoogleFont(
                                                        'Roboto',
                                                        fontSize: 24 * ffem,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height:
                                                            1.1725 * ffem / fem,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        color: const Color(
                                                          0xff000000,
                                                        ),
                                                        decorationColor:
                                                            const Color(
                                                              0xff000000,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                0 * fem,
                                                0 * fem,
                                                4 * fem,
                                                0 * fem,
                                              ),
                                              child: Text(
                                                'Main',
                                                textAlign: TextAlign.center,
                                                style: safeGoogleFont(
                                                  'Roboto',
                                                  fontSize: 16 * ffem,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.1725 * ffem / fem,
                                                  color: const Color(
                                                    0xff9a9a9a,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        if (value) {
                                          _controllermain =
                                              TextEditingController(
                                                text: pickedpcsmain.value
                                                    .toString(),
                                              );
                                          typeIndexmain = int.parse(
                                            _controllermain.text,
                                          );
                                          _controllergood =
                                              TextEditingController(
                                                text: pickedpcsgood.value
                                                    .toString(),
                                              );
                                          typeIndexgood = int.parse(
                                            _controllergood.text,
                                          );
                                        } else {
                                          _controllermain =
                                              TextEditingController(
                                                text: pickedctnmain.value
                                                    .toString(),
                                              );
                                          typeIndexmain = int.parse(
                                            _controllermain.text,
                                          );
                                          _controllergood =
                                              TextEditingController(
                                                text: pickedctngood.value
                                                    .toString(),
                                              );
                                          typeIndexgood = int.parse(
                                            _controllergood.text,
                                          );
                                        }
                                        tabs = value ? 1 : 0;
                                        _showMyDialog(detail, value);
                                      },
                                    ),
                                    GestureDetector(
                                      child: SizedBox(
                                        width: 117 * fem,
                                        height: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                0 * fem,
                                                0 * fem,
                                                0 * fem,
                                                4 * fem,
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                3 * fem,
                                                7 * fem,
                                                3 * fem,
                                                7 * fem,
                                              ),
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xffe0e0e0,
                                                  ),
                                                ),
                                                color: const Color(0xffffffff),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      6 * fem,
                                                    ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      (pickedpcsgood.value
                                                                      .toString()
                                                                      .length ==
                                                                  1 ||
                                                              pickedpcsgood
                                                                      .value
                                                                      .toString()
                                                                      .length ==
                                                                  1)
                                                          ? 50 * fem
                                                          : 30 * fem,
                                                      1 * fem,
                                                      9 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      value
                                                          ? '$goodValue'
                                                          : '$goodValue',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: safeGoogleFont(
                                                        'Roboto',
                                                        fontSize: 24 * ffem,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height:
                                                            1.1725 * ffem / fem,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        color: const Color(
                                                          0xff000000,
                                                        ),
                                                        decorationColor:
                                                            const Color(
                                                              0xff000000,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                0 * fem,
                                                0 * fem,
                                                4 * fem,
                                                0 * fem,
                                              ),
                                              child: Text(
                                                'Good',
                                                textAlign: TextAlign.center,
                                                style: safeGoogleFont(
                                                  'Roboto',
                                                  fontSize: 16 * ffem,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.1725 * ffem / fem,
                                                  color: const Color(
                                                    0xff9a9a9a,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        if (value) {
                                          _controllermain =
                                              TextEditingController(
                                                text: pickedpcsmain.value
                                                    .toString(),
                                              );
                                          typeIndexmain = int.parse(
                                            _controllermain.text,
                                          );
                                          _controllergood =
                                              TextEditingController(
                                                text: pickedpcsgood.value
                                                    .toString(),
                                              );
                                          typeIndexgood = int.parse(
                                            _controllergood.text,
                                          );
                                        } else {
                                          _controllermain =
                                              TextEditingController(
                                                text: pickedctnmain.value
                                                    .toString(),
                                              );
                                          typeIndexmain = int.parse(
                                            _controllermain.text,
                                          );
                                          _controllergood =
                                              TextEditingController(
                                                text: pickedctngood.value
                                                    .toString(),
                                              );
                                          typeIndexgood = int.parse(
                                            _controllergood.text,
                                          );
                                        }
                                        tabs = value ? 1 : 0;
                                        _showMyDialog(detail, value);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                  105 * fem,
                                  0 * fem,
                                  0 * fem,
                                  0 * fem,
                                ),
                                width: double.infinity,
                                height: 40 * fem,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        margin: EdgeInsets.fromLTRB(
                                          0 * fem,
                                          0 * fem,
                                          16 * fem,
                                          0 * fem,
                                        ),
                                        padding: EdgeInsets.fromLTRB(
                                          24 * fem,
                                          5 * fem,
                                          25 * fem,
                                          5 * fem,
                                        ),
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xfff44236),
                                          ),
                                          color: const Color(0xffffffff),
                                          borderRadius: BorderRadius.circular(
                                            12 * fem,
                                          ),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 30 * fem,
                                            height: 30 * fem,
                                            child: Image.asset(
                                              'data/images/cancel-viF.png',
                                              width: 30 * fem,
                                              height: 30 * fem,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        Get.back();
                                      },
                                    ),
                                    GestureDetector(
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(
                                          24 * fem,
                                          5 * fem,
                                          25 * fem,
                                          5 * fem,
                                        ),
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xff2cab0c),
                                          borderRadius: BorderRadius.circular(
                                            12 * fem,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0x3f000000),
                                              offset: Offset(0 * fem, 4 * fem),
                                              blurRadius: 2 * fem,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 30 * fem,
                                            height: 30 * fem,
                                            child: Image.asset(
                                              'data/images/check-circle-fg7.png',
                                              width: 30 * fem,
                                              height: 30 * fem,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onTap: () async {
                                        _showMyDialogApprove(
                                          stockcheckVM.toliststock[widget
                                              .index!],
                                          detail,
                                          "modal",
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerCard(StockDetail stockmodel) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 25 * fem, 7 * fem),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        borderRadius: BorderRadius.circular(8 * fem),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: ListTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      2 * fem,
                    ),
                    constraints: BoxConstraints(maxWidth: 160 * fem),
                    child: Text(
                      '${stockmodel.itemName}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xff2d2d2d),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      1 * fem,
                    ),
                    child: Text(
                      'SKU: ${stockmodel.itemCode}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      1 * fem,
                    ),
                    child: Text(
                      stockmodel.checked == 1
                          ? 'Main: ${stockmodel.warehouseStockMain}      Good: ${stockmodel.warehouseStockGood} '
                          : 'Main: ${stockmodel.stockMain}      Good: ${stockmodel.stockGood} ',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: const Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                  Text(
                    stockmodel.formattedUpdatedAt != null
                        ? (stockmodel.formattedUpdatedAt!.contains("Today") ||
                                  stockmodel.formattedUpdatedAt!.contains(
                                    "Yesterday",
                                  )
                              ? 'Last Stock Check: ${stockmodel.formattedUpdatedAt}'
                              : globalVM.stringToDateWithTime(
                                  stockmodel.formattedUpdatedAt!,
                                ))
                        : 'Last Stock Check: -', // fallback jika null
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: const Color(0xff9a9a9a),
                    ),
                  ),
                ],
              ),
            ),
            if (stockmodel.checked != 0)
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Image.asset(
                  'data/images/check-circle-TqJ.png',
                  width: 26 * fem,
                  height: 26 * fem,
                ),
              ),
            Expanded(
              flex: 1,
              child: stockmodel.checked == 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            0 * fem,
                            2 * fem,
                          ),
                          constraints: BoxConstraints(maxWidth: 41 * fem),
                          child: Text(
                            'Total\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15 * ffem,
                              fontWeight: FontWeight.w600,
                              height: 1.1725 * ffem / fem,
                              color: const Color(0xfff44236),
                            ),
                          ),
                        ),
                        Text(
                          calculateStock(
                            stockmodel.warehouseStockMain ?? 0,
                            stockmodel.warehouseStockGood ?? 0,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20 * ffem,
                            fontWeight: FontWeight.w600,
                            height: 1.1725 * ffem / fem,
                            color: const Color(0xff2d2d2d),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            0 * fem,
                            2 * fem,
                          ),
                          constraints: BoxConstraints(maxWidth: 41 * fem),
                          child: Text(
                            'Total\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12 * ffem,
                              fontWeight: FontWeight.w600,
                              height: 1.1725 * ffem / fem,
                            ),
                          ),
                        ),
                        Text(
                          calculateStock(
                            stockmodel.warehouseStockMain ?? 0,
                            stockmodel.warehouseStockGood ?? 0,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15 * ffem,
                            fontWeight: FontWeight.w600,
                            height: 1.1725 * ffem / fem,
                            color: const Color(0xff2d2d2d),
                          ),
                        ),
                      ],
                    ),
            ),
            if (widget.flag != "history")
              Container(
                margin: EdgeInsets.fromLTRB(
                  20 * fem,
                  0 * fem,
                  0 * fem,
                  0 * fem,
                ),
                width: 11 * fem,
                height: 20 * fem,
                child: Image.asset(
                  'data/images/vector-1HV.png',
                  width: 11 * fem,
                  height: 20 * fem,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: scanBarcode, // Ini akan memanggil mobile scanner
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              _showMyDialogReject("refresh");
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildActionsHistory() {
    return <Widget>[
      Row(
        children: [
          Switch(
            value: light0,
            onChanged: (bool value) {
              setState(() {
                light0 = value;
              });
            },
          ),
        ],
      ),
    ];
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      searchWF(newQuery);
    });
  }

  void searchWF(String search) {
    final index = widget.index!; // pastikan tidak null
    stockcheckVM.toliststock[index].detail!.clear();

    final List<StockDetail> locallist2 = listdetailstock
        .where(
          (element) =>
              element.itemCode?.toLowerCase().contains(search.toLowerCase()) ??
              false,
        )
        .toList();

    final List<StockDetail> localsku = listdetailstock
        .where(
          (element) =>
              element.itemName?.toLowerCase().contains(search.toLowerCase()) ??
              false,
        )
        .toList();

    if (locallist2.isNotEmpty) {
      for (final element in locallist2) {
        stockcheckVM.toliststock[index].detail!.add(element);
      }
    } else {
      for (final element in localsku) {
        stockcheckVM.toliststock[index].detail!.add(element);
      }
    }
  }

  void _startSearch() {
    setState(() {
      listdetailstock.clear();
      final index = widget.index!;
      final List<StockDetail> locallist =
          stockcheckVM.toliststock[index].detail ?? [];
      listdetailstock.addAll(locallist);
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _isSearching = false;
      _searchQuery.clear();
      _isSearching = false;

      stockcheckVM.toliststock[widget.index!].detail?.clear();
      stockcheckVM.toliststock[widget.index!].detail?.addAll(listdetailstock);
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQuery,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white30),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: updateSearchQuery,
    );
  }

  List<Widget> _buildActions2() {
    if (_isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              _stopSearching();
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }
    return <Widget>[
      Row(
        children: [
          Switch(
            value: light0,
            onChanged: (bool value) {
              setState(() {
                light0 = value;
              });
            },
          ),
          IconButton(icon: const Icon(Icons.qr_code), onPressed: scanBarcode),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              _showMyDialogReject("refresh");
            },
          ),
          if (light0)
            IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions: widget.flag == "history"
                ? _buildActionsHistory()
                : stockcheckVM.toliststock[widget.index!].location != "HQ"
                ? _buildActions2()
                : _buildActions(),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20.0,
              onPressed: () {
                Get.back();
              },
            ),
            backgroundColor: Colors.red,
            title: _isSearching
                ? _buildSearchField()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: TextWidget(
                      text:
                          "${stockcheckVM.toliststock[widget.index!].location} - ${stockcheckVM.toliststock[widget.index!].locationName}",
                      maxLines: 2,
                      color: Colors.white,
                    ),
                  ),
            centerTitle: true,
          ),
          backgroundColor: kWhiteColor,
          body: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (stockcheckVM.toliststock[widget.index!].location != "HQ" &&
                    light0 == false)
                  Visibility(
                    visible: light0 == true,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        0 * fem,
                        0 * fem,
                        0 * fem,
                        9 * fem,
                      ),
                      width: double.infinity,
                      height: 50 * fem,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Container(
                              width: 180 * fem,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: ontap
                                      ? const Color(0xfff44236)
                                      : const Color(0xffa8a8a8),
                                ),
                                color: ontap
                                    ? const Color(0xfffeeceb)
                                    : const Color(0xffffffff),
                              ),
                              child: Center(
                                child: Text(
                                  'Stock List',
                                  textAlign: TextAlign.center,
                                  style: safeGoogleFont(
                                    'Roboto',
                                    fontSize: 16 * ffem,
                                    fontWeight: FontWeight.w500,
                                    height: 1.1725 * ffem / fem,
                                    color: ontap
                                        ? const Color(0xfff44236)
                                        : const Color(0xffa8a8a8),
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                ontap = true;
                              });
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              width: 165 * fem,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: !ontap
                                      ? const Color(0xfff44236)
                                      : const Color(0xffa8a8a8),
                                ),
                                color: !ontap
                                    ? const Color(0xfffeeceb)
                                    : const Color(0xffffffff),
                              ),
                              child: Center(
                                child: Text(
                                  'Scanned Stock',
                                  textAlign: TextAlign.center,
                                  style: safeGoogleFont(
                                    'Roboto',
                                    fontSize: 16 * ffem,
                                    fontWeight: FontWeight.w500,
                                    height: 1.1725 * ffem / fem,
                                    color: !ontap
                                        ? const Color(0xfff44236)
                                        : const Color(0xffa8a8a8),
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                ontap = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      9 * fem,
                    ),
                    width: double.infinity,
                    height: 50 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                            width: 165 * fem,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ontap
                                    ? const Color(0xfff44236)
                                    : const Color(0xffa8a8a8),
                              ),
                              color: ontap
                                  ? const Color(0xfffeeceb)
                                  : const Color(0xffffffff),
                            ),
                            child: Center(
                              child: Text(
                                'Stock List',
                                textAlign: TextAlign.center,
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 16 * ffem,
                                  fontWeight: FontWeight.w500,
                                  height: 1.1725 * ffem / fem,
                                  color: ontap
                                      ? const Color(0xfff44236)
                                      : const Color(0xffa8a8a8),
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              ontap = true;
                            });
                          },
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          child: Container(
                            width: 160 * fem,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: !ontap
                                    ? const Color(0xfff44236)
                                    : const Color(0xffa8a8a8),
                              ),
                              color: !ontap
                                  ? const Color(0xfffeeceb)
                                  : const Color(0xffffffff),
                            ),
                            child: Center(
                              child: Text(
                                'Scanned Stock',
                                textAlign: TextAlign.center,
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 16 * ffem,
                                  fontWeight: FontWeight.w500,
                                  height: 1.1725 * ffem / fem,
                                  color: !ontap
                                      ? const Color(0xfff44236)
                                      : const Color(0xffa8a8a8),
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              ontap = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Visibility(
                  visible:
                      (stockcheckVM.toliststock[widget.index!].location ??
                          '') ==
                      "HQ",
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 25,
                      children: listchoice.map((e) {
                        final bool isSelected = idPeriodSelected == e.id;
                        return ChoiceChip(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          label: Text(
                            e.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.grey,
                          selected: isSelected,
                          selectedColor: isSelected
                              ? (GlobalVar.choicecategory == "AB"
                                    ? Colors.red
                                    : GlobalVar.choicecategory == "FZ"
                                    ? Colors.blue
                                    : Colors.green)
                              : Colors.grey,
                          elevation: 10,
                          onSelected: (_) {
                            setState(() {
                              idPeriodSelected = e.id;

                              final int choice = idPeriodSelected - 1;
                              if (choice == 0) {
                                GlobalVar.choicecategory = "AB";
                              } else if (choice == 1) {
                                GlobalVar.choicecategory = "CH";
                              } else {
                                GlobalVar.choicecategory = "FZ";
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Jika light0 false dan tidak ada item yang di-scan
                if (!light0 &&
                    (stockcheckVM.toliststock[widget.index!].detail
                            ?.where(
                              (element) =>
                                  element.isScanned?.contains("Y") ?? false,
                            )
                            .isEmpty ??
                        true))
                  const SizedBox(height: 130),

                if (!light0 &&
                    (stockcheckVM.toliststock[widget.index!].detail
                            ?.where(
                              (element) =>
                                  element.isScanned?.contains("Y") ?? false,
                            )
                            .isEmpty ??
                        true))
                  Center(
                    child: SizedBox(
                      width: 252 * fem,
                      height: 225 * fem,
                      child: Image.asset(
                        'data/images/undrawnodatarekwbl-1-1.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Obx(() {
                    final index = widget.index!;
                    final detailList =
                        stockcheckVM.toliststock[index].detail ?? [];
                    final int itemCount = (ontap && light0)
                        ? detailList.length
                        : (stockcheckVM.toliststock[index].location == "HQ")
                        ? detailList
                              .where(
                                (element) =>
                                    (element.inventoryGroup?.contains(
                                          GlobalVar.choicecategory,
                                        ) ??
                                        false) &&
                                    element.isScanned == "Y",
                              )
                              .length
                        : detailList
                              .where(
                                (element) =>
                                    element.isScanned?.contains("Y") ?? false,
                              )
                              .length;

                    return Expanded(
                      child: ListView.builder(
                        controller: controller,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: itemCount,
                        itemBuilder: (BuildContext context, int idx) {
                          final StockDetail item = (ontap && light0)
                              ? stockcheckVM
                                    .toliststock[widget.index!]
                                    .detail![idx]
                              : (stockcheckVM
                                        .toliststock[widget.index!]
                                        .location ==
                                    "HQ")
                              ? (stockcheckVM.toliststock[widget.index!].detail
                                        ?.where(
                                          (element) =>
                                              (element.inventoryGroup?.contains(
                                                    GlobalVar.choicecategory,
                                                  ) ??
                                                  false) &&
                                              element.isScanned == "Y",
                                        )
                                        .toList()[idx] ??
                                    StockDetail())
                              : (stockcheckVM.toliststock[widget.index!].detail
                                        ?.where(
                                          (element) =>
                                              element.isScanned?.contains(
                                                "Y",
                                              ) ??
                                              false,
                                        )
                                        .toList()[idx] ??
                                    StockDetail());

                          return GestureDetector(
                            child: headerCard(item),
                            onTap: () async {
                              if (widget.flag != "history" && ontap) {
                                pcsctnnotifier.value = false;

                                pickedctnmain.value =
                                    item.warehouseStockMainCtn ?? 0;
                                pickedctngood.value =
                                    item.warehouseStockGoodCtn ?? 0;
                                pickedpcsmain.value =
                                    item.warehouseStockMain ?? 0;
                                pickedpcsgood.value =
                                    item.warehouseStockGood ?? 0;

                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => modalBottomSheet(item),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  }),
                if (widget.flag != "history" && ontap && light0)
                  Container(
                    padding: const EdgeInsets.only(left: 22),
                    width: double.infinity,
                    height: 40 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            30 * fem,
                            0 * fem,
                          ),
                          child: TextButton(
                            onPressed: () {
                              _showMyDialogReject("reject");
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                52 * fem,
                                5 * fem,
                                53 * fem,
                                5 * fem,
                              ),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xfff44236),
                                ),
                                color: const Color(0xffffffff),
                                borderRadius: BorderRadius.circular(12 * fem),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x3f000000),
                                    offset: Offset(0 * fem, 4 * fem),
                                    blurRadius: 2 * fem,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 30 * fem,
                                  height: 30 * fem,
                                  child: Image.asset(
                                    'data/images/cancel-ecb.png',
                                    width: 30 * fem,
                                    height: 30 * fem,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              final index = widget.index!;
                              final stock = stockcheckVM.toliststock[index];
                              final firstDetail =
                                  stock.detail != null &&
                                      stock.detail!.isNotEmpty
                                  ? stock.detail![0]
                                  : null;

                              if (firstDetail != null) {
                                _showMyDialogApprove(stock, firstDetail, "all");
                              }
                            });
                          },

                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              52 * fem,
                              5 * fem,
                              53 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/check-circle-LCb.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if ((stockcheckVM.toliststock[widget.index!].detail
                        ?.where(
                          (element) =>
                              element.isScanned?.contains("Y") ?? false,
                        )
                        .isNotEmpty) ??
                    false)
                  Container(
                    padding: const EdgeInsets.only(left: 22),
                    width: double.infinity,
                    height: 40 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            30 * fem,
                            0 * fem,
                          ),
                          child: TextButton(
                            onPressed: () {
                              // _showMyDialogReject(inVM.tolistPO.value[widget.index]);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                52 * fem,
                                5 * fem,
                                53 * fem,
                                5 * fem,
                              ),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xfff44236),
                                ),
                                color: const Color(0xffffffff),
                                borderRadius: BorderRadius.circular(12 * fem),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x3f000000),
                                    offset: Offset(0 * fem, 4 * fem),
                                    blurRadius: 2 * fem,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 30 * fem,
                                  height: 30 * fem,
                                  child: Image.asset(
                                    'data/images/cancel-ecb.png',
                                    width: 30 * fem,
                                    height: 30 * fem,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              // _showMyDialogApprove(inVM.tolistPO.value[widget.index]);
                            });
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              52 * fem,
                              5 * fem,
                              53 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/check-circle-LCb.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemChoice {
  final int id;
  final String label;

  const ItemChoice(this.id, this.label);
}
