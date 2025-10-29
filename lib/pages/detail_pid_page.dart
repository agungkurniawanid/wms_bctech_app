import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:wms_bctech/models/stock_detail_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/controllers/pid_controller.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DetailPidPage extends StatefulWidget {
  final int index;
  final String flag;

  const DetailPidPage(this.index, this.flag, {super.key});

  @override
  State<DetailPidPage> createState() => _DetailPidPageState();
}

class _DetailPidPageState extends State<DetailPidPage> {
  final PidViewModel pidVM = Get.find();
  final GlobalVM globalVM = Get.find();
  final InVM inVM = Get.find();

  bool allow = true;
  int idPeriodSelected = 1;
  bool light0 = false;
  bool ontap = true;
  bool pcsctnvalidation = true;
  bool leading = true;
  bool fromscan = true;
  bool _isSearching = false;

  final List<String> sortList = ['PO Date', 'Vendor'];

  final List<ItemChoice> listchoice = <ItemChoice>[
    ItemChoice(1, 'Ambient'),
    ItemChoice(2, 'Chiller'),
    ItemChoice(3, 'Frozen'),
  ];

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
  late TextEditingController _searchQuery;

  final List<Category> listcategory = [];
  late ScrollController controller;
  final GlobalKey srKey = GlobalKey();

  StockModel? clone;
  String? barcodeScanRes;
  String? searchQuery;

  final List<StockDetail> listdetailstock = [];
  final NumberFormat currency = NumberFormat("#,###", "en_US");

  MobileScannerController mobileScannerController = MobileScannerController(
    formats: [BarcodeFormat.all],
    returnImage: false,
    autoStart: false,
  );

  bool isScanning = false;
  String barcodeString = "Barcode will be shown here";
  String barcodeSymbology = "Symbology will be shown here";
  String scanTime = "Scan Time will be shown here";

  @override
  void initState() {
    super.initState();

    handleCountedResult();

    _controllermain = TextEditingController();
    _controllergood = TextEditingController();
    _searchQuery = TextEditingController();
    controller = ScrollController();
    clone = pidVM.tolistpid[widget.index].clone();
    GlobalVar.choicecategory = "AB";
  }

  String calculateStock(int mainstock, int goodstock) {
    final int totalstock = mainstock + goodstock;
    return currency.format(totalstock);
  }

  void handleCountedResult() {
    pidVM.counted().then((String result) {
      pidVM.countedstring.value = result;
    });
  }

  @override
  void dispose() {
    _controllermain.dispose();
    _controllergood.dispose();
    _searchQuery.dispose();
    controller.dispose();
    mobileScannerController.dispose();
    super.dispose();
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
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                      children: <Widget>[
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
                              boxShadow: <BoxShadow>[
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
                            final String? username = await DatabaseHelper.db
                                .getUser();
                            final bool fromscan = false;

                            final String todaytime = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(DateTime.now());
                            List<Map<String, dynamic>> maptdata;

                            if (fromscan == false) {
                              stockdetail.isScanned = "Y";
                            }

                            if (tanda == "all") {
                              stockmodel.isApprove = "Counted";
                              stockmodel.updatedby = username;
                              stockmodel.updated = todaytime;
                              stockmodel.formattedUpdatedAt = todaytime;
                              stockmodel.color = "GREEN";
                            } else {
                              stockdetail.warehouseStockGood =
                                  pickedpcsgood.value;
                              stockdetail.warehouseStockGoodCtn =
                                  pickedctngood.value;
                              stockdetail.warehouseStockMain =
                                  pickedpcsmain.value;
                              stockdetail.warehouseStockMainCtn =
                                  pickedctnmain.value;
                              stockdetail.checked = 1;
                              stockdetail.approveName = username;
                              stockdetail.updatedAt = todaytime;
                            }

                            Get.back();
                            Get.back();

                            if (tanda == "all") {
                              stockmodel.recordid =
                                  PidViewModel().countedstring.value;

                              maptdata =
                                  (pidVM.tolistpid[widget.index].detail ?? [])
                                      .where((element) => element.checked == 1)
                                      .map((person) => person.toMap())
                                      .toList();

                              pidVM.approveAll(stockmodel, "Y", maptdata);
                              pidVM.sendToHistory(stockmodel, maptdata);
                              pidVM.sendCounted(stockmodel.recordid!);

                              Get.back();
                            } else {
                              maptdata =
                                  (pidVM.tolistpid[widget.index].detail ?? [])
                                      .map((person) => person.toMap())
                                      .toList();

                              pidVM.approveStock(
                                pidVM.tolistpid[widget.index],
                                maptdata,
                              );
                            }

                            Fluttertoast.showToast(
                              fontSize: 22,
                              gravity: ToastGravity.TOP,
                              msg: "Document has been created",
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

  void handleBarcodeScan(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty && mounted) {
      final String barcodeString = barcodes.first.rawValue ?? "";

      setState(() {
        final stock = pidVM.tolistpid[widget.index];

        if (stock.isApprove == "Counted" || widget.flag == "history") {
          return;
        }

        if (barcodeString.isNotEmpty) {
          pcsctnnotifier.value = false;

          final details = stock.detail ?? [];

          final foundItem = details.firstWhere(
            (element) => element.itemCode?.contains(barcodeString) ?? false,
            orElse: () => details.isNotEmpty ? details.first : StockDetail(),
          );

          pickedctnmain.value = foundItem.warehouseStockMainCtn ?? 0;
          pickedctngood.value = foundItem.warehouseStockGoodCtn ?? 0;
          pickedpcsmain.value = foundItem.warehouseStockMain ?? 0;
          pickedpcsgood.value = foundItem.warehouseStockGood ?? 0;

          fromscan = false;

          mobileScannerController.stop();
          isScanning = false;
          Navigator.of(context).pop();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => modalBottomSheet(foundItem),
          );
        }
      });
    }
  }

  // Method untuk memulai scan dengan MobileScanner
  Future<void> startMobileScan() async {
    try {
      setState(() {
        isScanning = true;
      });

      // Tampilkan dialog scanner
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Scan Barcode"),
          content: SizedBox(
            height: 300,
            child: MobileScanner(
              controller: mobileScannerController,
              onDetect: handleBarcodeScan,
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

  // Method scanBarcode yang diperbarui menggunakan mobile_scanner
  Future<void> scanBarcode() async {
    if (isScanning) {
      return;
    }
    await startMobileScan();
  }

  Future<void> _showMyDialogReject(String flag) async {
    final double baseWidth = 312;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                      children: <Widget>[
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
                              boxShadow: <BoxShadow>[
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
        builder: (BuildContext context, StateSetter setState) {
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
                          type = i == 1;

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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      'Main',
                      style: TextStyle(
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
                          inputFormatters: <TextInputFormatter>[
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      'Good',
                      style: TextStyle(
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
                          inputFormatters: <TextInputFormatter>[
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
                        children: <Widget>[
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
                                boxShadow: <BoxShadow>[
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
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
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
                    valueListenable: !pcsctnnotifier.value
                        ? pickedctnmain
                        : pickedpcsmain,
                    builder: (BuildContext context, int value, Widget? child) {
                      return ValueListenableBuilder<int>(
                        valueListenable: !pcsctnnotifier.value
                            ? pickedctngood
                            : pickedpcsgood,
                        builder: (BuildContext context, int value, Widget? child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
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
                                  children: <Widget>[
                                    GestureDetector(
                                      child: Container(
                                        width: 54 * fem,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: !pcsctnnotifier.value
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
                                    Container(
                                      margin: EdgeInsets.fromLTRB(
                                        0 * fem,
                                        0 * fem,
                                        2 * fem,
                                        0 * fem,
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            pcsctnnotifier.value = true;
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Container(
                                          width: 54 * fem,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: pcsctnnotifier.value
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
                                      ),
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
                                  children: <Widget>[
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
                                        children: <Widget>[
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
                                                pcsctnnotifier.value
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
                                        children: <Widget>[
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
                                                pcsctnnotifier.value
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
                                  children: <Widget>[
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
                                          children: <Widget>[
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
                                                children: <Widget>[
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      detail.warehouseStockMain
                                                                      .toString()
                                                                      .length ==
                                                                  1 ||
                                                              detail.warehouseStockMainCtn
                                                                      .toString()
                                                                      .length ==
                                                                  1
                                                          ? 45 * fem
                                                          : 30 * fem,
                                                      1 * fem,
                                                      10 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      pcsctnnotifier.value
                                                          ? '${pickedpcsmain.value}'
                                                          : '${pickedctnmain.value}',
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
                                        if (pcsctnnotifier.value) {
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
                                        if (!pcsctnnotifier.value) {
                                          tabs = 0;
                                        } else {
                                          tabs = 1;
                                        }
                                        _showMyDialog(
                                          detail,
                                          pcsctnnotifier.value,
                                        );
                                      },
                                    ),
                                    GestureDetector(
                                      child: SizedBox(
                                        width: 117 * fem,
                                        height: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
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
                                                children: <Widget>[
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      pickedpcsgood.value
                                                                      .toString()
                                                                      .length ==
                                                                  1 ||
                                                              pickedpcsgood
                                                                      .value
                                                                      .toString()
                                                                      .length ==
                                                                  1
                                                          ? 50 * fem
                                                          : 30 * fem,
                                                      1 * fem,
                                                      9 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      pcsctnnotifier.value
                                                          ? '${pickedpcsgood.value}'
                                                          : '${pickedctngood.value}',
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
                                        if (pcsctnnotifier.value) {
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
                                        if (!pcsctnnotifier.value) {
                                          tabs = 0;
                                        } else {
                                          tabs = 1;
                                        }
                                        _showMyDialog(
                                          detail,
                                          pcsctnnotifier.value,
                                        );
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
                                  children: <Widget>[
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
                                          boxShadow: <BoxShadow>[
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
                                          pidVM.tolistpid[widget.index],
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: ListTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                    (stockmodel.formattedUpdatedAt ?? '').contains("Today")
                        ? 'Last Stock Check: ${stockmodel.formattedUpdatedAt ?? ''}'
                        : (stockmodel.formattedUpdatedAt ?? '').contains(
                            "Yesterday",
                          )
                        ? 'Last Stock Check: ${stockmodel.formattedUpdatedAt ?? ''}'
                        : globalVM.stringToDateWithTime(
                            stockmodel.formattedUpdatedAt ?? '',
                          ),
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
            stockmodel.checked != 0
                ? Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Image.asset(
                      'data/images/check-circle-TqJ.png',
                      width: 26 * fem,
                      height: 26 * fem,
                    ),
                  )
                : const SizedBox(),
            Expanded(
              flex: 1,
              child: stockmodel.checked == 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
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
                      children: <Widget>[
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
                              fontSize: 20 * ffem,
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
                            fontSize: 15 * ffem,
                            fontWeight: FontWeight.w600,
                            height: 1.1725 * ffem / fem,
                            color: const Color(0xff2d2d2d),
                          ),
                        ),
                      ],
                    ),
            ),
            Visibility(
              visible: widget.flag != "history",
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget headerCard2(StockDetail stockmodel) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.fromLTRB(3 * fem, 0 * fem, 2 * fem, 5 * fem),
        child: Container(
          padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 17.5 * fem, 7 * fem),
          width: double.infinity,
          height: 102 * fem,
          decoration: BoxDecoration(
            color: const Color(0xffffffff),
            borderRadius: BorderRadius.circular(8 * fem),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x3f000000),
                offset: Offset(0 * fem, 4 * fem),
                blurRadius: 5 * fem,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SizedBox(
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                    Text(
                      (stockmodel.formattedUpdatedAt ?? '').contains("Today")
                          ? 'Last Stock Check: \n${stockmodel.formattedUpdatedAt ?? ''}'
                          : (stockmodel.formattedUpdatedAt ?? '').contains(
                              "Yesterday",
                            )
                          ? 'Last Stock Check: \n${stockmodel.formattedUpdatedAt ?? ''}'
                          : 'Last Stock Check: \n${globalVM.stringToDateWithTime(stockmodel.formattedUpdatedAt ?? '')}',
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
              stockmodel.checked != 0
                  ? Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Image.asset(
                        'data/images/check-circle-TqJ.png',
                        width: 26 * fem,
                        height: 26 * fem,
                      ),
                    )
                  : const SizedBox(),
              Expanded(
                flex: 1,
                child: stockmodel.checked == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
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
                        children: <Widget>[
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
                              fontSize: 15 * ffem,
                              fontWeight: FontWeight.w600,
                              height: 1.1725 * ffem / fem,
                              color: const Color(0xff2d2d2d),
                            ),
                          ),
                        ],
                      ),
              ),
              Visibility(
                visible:
                    widget.flag != "history" &&
                    pidVM.tolistpid[widget.index].isApprove != "Counted",
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      Row(
        children: <Widget>[
          IconButton(icon: const Icon(Icons.qr_code), onPressed: scanBarcode),
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

  List<Widget> buildActionsHistory() {
    return <Widget>[
      Row(
        children: <Widget>[
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

  void searchWF(String search) async {
    final detailList = pidVM.tolistpid[widget.index].detail ?? [];
    detailList.clear();

    final locallist2 = listdetailstock
        .where(
          (element) => (element.itemCode?.toLowerCase() ?? '').contains(
            search.toLowerCase(),
          ),
        )
        .toList();

    final localsku = listdetailstock
        .where(
          (element) => (element.itemName?.toLowerCase() ?? '').contains(
            search.toLowerCase(),
          ),
        )
        .toList();

    if (locallist2.isNotEmpty) {
      detailList.addAll(locallist2);
    } else {
      detailList.addAll(localsku);
    }

    pidVM.tolistpid.refresh();
  }

  void _startSearch() {
    setState(() {
      listdetailstock.clear();
      final List<StockDetail> locallist =
          pidVM.tolistpid[widget.index].detail ?? [];

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

      final detailList = pidVM.tolistpid[widget.index].detail ?? [];

      detailList.clear();
      detailList.addAll(listdetailstock);

      pidVM.tolistpid.refresh();
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

  List<Widget> buildActions2() {
    if (_isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              setState(() {
                _stopSearching();
              });
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }
    return <Widget>[
      Row(
        children: <Widget>[
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
          Visibility(
            visible: light0,
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions:
                widget.flag == "history" ||
                    pidVM.tolistpid[widget.index].isApprove == "Counted"
                ? null
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
                : SizedBox(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${pidVM.tolistpid[widget.index].location} - ${pidVM.tolistpid[widget.index].locationName}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ),
            centerTitle: true,
          ),
          backgroundColor: Colors.white,
          body: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 25,
                    children: listchoice
                        .map(
                          (ItemChoice e) => ChoiceChip(
                            padding: const EdgeInsets.only(left: 15, right: 10),
                            labelStyle:
                                Theme.of(context).scaffoldBackgroundColor ==
                                    Colors.grey[100]
                                ? (idPeriodSelected == e.id
                                      ? const TextStyle(color: Colors.white)
                                      : const TextStyle(color: Colors.white))
                                : (idPeriodSelected == e.id
                                      ? const TextStyle(color: Colors.white)
                                      : const TextStyle(color: Colors.white)),
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor ==
                                    Colors.grey[100]
                                ? Colors.grey
                                : Colors.grey,
                            label: Text(e.label),
                            selected: idPeriodSelected == e.id,
                            onSelected: (bool _) {
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
                            selectedColor: GlobalVar.choicecategory == "AB"
                                ? Colors.red
                                : GlobalVar.choicecategory == "FZ"
                                ? Colors.blue
                                : Colors.green,
                            elevation: 10,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Visibility(
                  visible:
                      !light0 &&
                      (pidVM.tolistpid[widget.index].detail
                              ?.where(
                                (element) =>
                                    element.isScanned?.contains("Y") ?? false,
                              )
                              .isEmpty ??
                          true),
                  child: const SizedBox(height: 20),
                ),
                (pidVM.tolistpid[widget.index].detail
                            ?.where(
                              (element) =>
                                  element.isScanned?.contains("Y") ?? false,
                            )
                            .isEmpty ??
                        true)
                    ? SizedBox(
                        width: 252 * fem,
                        height: 225 * fem,
                        child: Image.asset(
                          'data/images/undrawnodatarekwbl-1-1.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Obx(() {
                        return Expanded(
                          child: ListView.builder(
                            controller: controller,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount:
                                pidVM.tolistpid[widget.index].detail
                                    ?.where(
                                      (StockDetail element) =>
                                          element.inventoryGroup?.contains(
                                                GlobalVar.choicecategory,
                                              ) ==
                                              true &&
                                          element.isScanned == "Y",
                                    )
                                    .toList()
                                    .length ??
                                0,
                            itemBuilder: (BuildContext context, int index) {
                              final filteredList =
                                  pidVM.tolistpid[widget.index].detail
                                      ?.where(
                                        (StockDetail element) =>
                                            element.inventoryGroup?.contains(
                                                  GlobalVar.choicecategory,
                                                ) ==
                                                true &&
                                            element.isScanned == "Y",
                                      )
                                      .toList() ??
                                  [];

                              return GestureDetector(
                                child: headerCard2(filteredList[index]),
                                onTap: () async {
                                  if (widget.flag == "history" ||
                                      pidVM.tolistpid[widget.index].isApprove ==
                                          "Counted") {
                                    return;
                                  } else {
                                    if (ontap) {
                                      pcsctnnotifier.value = false;

                                      if (index < filteredList.length) {
                                        final data = filteredList[index];

                                        pickedctnmain.value =
                                            data.warehouseStockMainCtn ?? 0;
                                        pickedctngood.value =
                                            data.warehouseStockGoodCtn ?? 0;
                                        pickedpcsmain.value =
                                            data.warehouseStockMain ?? 0;
                                        pickedpcsgood.value =
                                            data.warehouseStockGood ?? 0;

                                        showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              modalBottomSheet(data),
                                        );
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        );
                      }),
                Visibility(
                  visible:
                      light0 == false &&
                      (pidVM.tolistpid[widget.index].detail
                                  ?.where(
                                    (StockDetail element) =>
                                        element.isScanned?.contains("Y") ==
                                        true,
                                  )
                                  .toList()
                                  .length ??
                              0) ==
                          0,
                  child: const SizedBox(height: 180),
                ),

                widget.flag == "history"
                    ? Container()
                    : Visibility(
                        visible:
                            pidVM.tolistpid[widget.index].isApprove !=
                            "Counted",
                        child: Container(
                          padding: const EdgeInsets.only(left: 22),
                          width: double.infinity,
                          height: 40 * fem,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
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
                                      borderRadius: BorderRadius.circular(
                                        12 * fem,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x3f000000),
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
                                  final pidList = pidVM.tolistpid;
                                  if (pidList.length > widget.index &&
                                      pidList[widget.index].detail != null &&
                                      pidList[widget.index]
                                          .detail!
                                          .isNotEmpty) {
                                    setState(() {
                                      _showMyDialogApprove(
                                        pidList[widget.index],
                                        pidList[widget.index].detail![0],
                                        "all",
                                      );
                                    });
                                  }
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
                                    color: const Color(0xff2cab0c),
                                    borderRadius: BorderRadius.circular(
                                      12 * fem,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x3f000000),
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
