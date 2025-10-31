import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:wms_bctech/models/stock_detail_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/controllers/pid_controller.dart';
import 'package:wms_bctech/components/text_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DetailPidPage extends StatefulWidget {
  final int index;
  final String flag;

  const DetailPidPage({super.key, required this.index, required this.flag});

  @override
  State<DetailPidPage> createState() => _DetailPidPageState();
}

class _DetailPidPageState extends State<DetailPidPage> {
  final PidViewModel pidVM = Get.find();
  final GlobalVM globalVM = Get.find();
  final InVM inVM = Get.find();

  bool allow = true;
  int idPeriodSelected = 1;

  final List<String> sortList = ['PO Date', 'Vendor'];

  final List<ItemChoice> listchoice = [
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
  late TextEditingController _searchQuery;
  late ScrollController controller;

  final List<Category> listcategory = [];
  final List<StockDetail> listdetailstock = [];

  bool leading = true;
  final GlobalKey srKey = GlobalKey();
  StockModel? clone;

  String? barcodeScanRes;
  bool fromscan = true;
  bool _isSearching = false;
  String? searchQuery;

  final NumberFormat currency = NumberFormat("#,###", "en_US");

  // Mobile Scanner Controller
  MobileScannerController mobileScannerController = MobileScannerController(
    formats: [BarcodeFormat.all],
    returnImage: false,
  );

  bool isScanning = false;

  String barcodeString = "Barcode will be shown here";
  String barcodeSymbology = "Symbology will be shown here";
  String scanTime = "Scan Time will be shown here";

  @override
  void initState() {
    super.initState();
    handleCountedResult();
    _searchQuery = TextEditingController();
    clone = pidVM.tolistpid[widget.index].clone();
    GlobalVar.choicecategory = "AB";
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
            orElse: () => details.first,
          );

          pickedctnmain.value = foundItem.warehouseStockMainCtn ?? 0;
          pickedctngood.value = foundItem.warehouseStockGoodCtn ?? 0;
          pickedpcsmain.value = foundItem.warehouseStockMain ?? 0;
          pickedpcsgood.value = foundItem.warehouseStockGood ?? 0;

          fromscan = false;

          // Stop scanning setelah berhasil scan
          mobileScannerController.stop();
          isScanning = false;

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
  void startMobileScan() async {
    try {
      setState(() {
        isScanning = true;
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Scan Barcode"),
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
              child: Text("Cancel"),
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

    startMobileScan();
  }

  String calculateStock(int mainstock, int goodstock) {
    int totalstock = mainstock + goodstock;
    return currency.format(totalstock).toString();
  }

  void handleCountedResult() {
    pidVM.counted().then((result) {
      pidVM.countedstring.value = result;
    });
  }

  double _calculateMargin(String value, double fem) {
    return value.length == 1 ? 45 * fem : 30 * fem;
  }

  void _setupControllers(bool pcsCtnValue) {
    if (pcsCtnValue) {
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

    tabs = pcsCtnValue ? 1 : 0;
  }

  Future _showMyDialogApprove(
    StockModel stockmodel,
    StockDetail stockdetail,
    String tanda,
  ) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
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
                        color: Color(0xff2d2d2d),
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
                            // cancelbutton8Nf (11:1273)
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
                              border: Border.all(color: Color(0xfff44236)),
                              color: Color(0xffffffff),
                              borderRadius: BorderRadius.circular(12 * fem),
                            ),
                            child: Center(
                              // cancelnCK (11:1275)
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
                            // savebuttonSnf (11:1278)
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              // checkcircle7du (11:1280)
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
                            var username = await DatabaseHelper.db.getUser();

                            String todaytime = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(DateTime.now());

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
                              stockmodel.recordid = pidVM.countedstring.value;
                              final details =
                                  pidVM.tolistpid[widget.index].detail ?? [];

                              final maptdata = details
                                  .where((element) => element.checked == 1)
                                  .map((person) => person.toMap())
                                  .toList();

                              pidVM.approveAll(stockmodel, "Y", maptdata);
                              pidVM.sendToHistory(stockmodel, maptdata);
                              pidVM.sendCounted(stockmodel.recordid ?? "");

                              await pidVM.refreshStock(
                                pidVM.tolistpid[widget.index],
                              );

                              Get.back();
                            } else {
                              final details =
                                  pidVM.tolistpid[widget.index].detail ?? [];
                              final maptdata = details
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

  Future _showMyDialogReject(String flag) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
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
                        color: Color(0xff2d2d2d),
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
                              border: Border.all(color: Color(0xfff44236)),
                              color: Color(0xffffffff),
                              borderRadius: BorderRadius.circular(12 * fem),
                            ),
                            child: Center(
                              // cancelnCK (11:1275)
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
                            // Get.back();
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
                              color: Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
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

  Future _showMyDialog(StockDetail indetail, bool type) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: CupertinoSlidingSegmentedControl(
                      groupValue: tabs,
                      children: myTabs,
                      onValueChanged: (i) {
                        setState(() {
                          tabs = i as int;
                          tabs == 0 ? type = false : type = true;

                          if (type == true) {
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
                  SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
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
                          child: Center(
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
                              if (type == false) {
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _controllermain,
                          onChanged: (i) {
                            setState(() {
                              if (type == false && tabs == 0) {
                                typeIndexmain = int.parse(_controllermain.text);
                                pickedctnmain.value = typeIndexmain;
                              } else if (type == true && tabs == 1) {
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
                          child: Center(
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
                              if (type == false) {
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
                  SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
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
                          child: Center(
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
                              if (type == false) {
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _controllergood,
                          onChanged: (i) {
                            setState(() {
                              if (type == false && tabs == 0) {
                                typeIndexgood = int.parse(_controllergood.text);
                                pickedctngood.value = typeIndexgood;
                              } else if (type == true && tabs == 1) {
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
                          child: Center(
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
                              if (type == false) {
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
                  SizedBox(height: 30),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      // autogroupf5ebdRu (UM6eDoseJp3PyzDupvF5EB)
                      width: double.infinity,
                      height: 30 * fem,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Container(
                              // cancelbutton8Nf (11:1273)
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
                                border: Border.all(color: Color(0xfff44236)),
                                color: Color(0xffffffff),
                                borderRadius: BorderRadius.circular(12 * fem),
                              ),
                              child: Center(
                                // cancelnCK (11:1275)
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
                              // savebuttonSnf (11:1278)
                              padding: EdgeInsets.fromLTRB(
                                24 * fem,
                                5 * fem,
                                25 * fem,
                                5 * fem,
                              ),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xff2cab0c),
                                borderRadius: BorderRadius.circular(12 * fem),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x3f000000),
                                    offset: Offset(0 * fem, 4 * fem),
                                    blurRadius: 2 * fem,
                                  ),
                                ],
                              ),
                              child: Center(
                                // checkcircle7du (11:1280)
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
                              // _refreshBottomSheet(indetail);
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
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: GlobalVar.height * 0.85,
      child: Container(
        padding: EdgeInsets.fromLTRB(0 * fem, 10 * fem, 0 * fem, 0 * fem),
        width: double.infinity,
        decoration: BoxDecoration(color: Color(0xffffffff)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  child: Text(
                    ' ${detail.itemName}',
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 16 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xfff44236),
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
              // borderJAC (25:1583)
              margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
              width: double.infinity,
              height: 1 * fem,
              decoration: BoxDecoration(color: Color(0xffa8a8a8)),
            ),
            GestureDetector(
              child: Container(
                // imagedCU (25:1595)
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
                  border: Border.all(color: Color(0xfff44236)),
                  color: Color(0xffffffff),
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
              decoration: BoxDecoration(color: Color(0xffa8a8a8)),
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
                builder: (BuildContext context, bool pcsCtnValue, Widget? child) {
                  return ValueListenableBuilder<int>(
                    valueListenable: pcsCtnValue == false
                        ? pickedctnmain
                        : pickedpcsmain,
                    builder: (BuildContext context, int mainValue, Widget? child) {
                      return ValueListenableBuilder<int>(
                        valueListenable: pcsCtnValue == false
                            ? pickedctngood
                            : pickedpcsgood,
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
                                      onTap: () {
                                        setState(() {
                                          pcsctnnotifier.value = false;
                                        });
                                      },
                                      child: Container(
                                        width: 54 * fem,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: pcsCtnValue == false
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
                                    ),
                                    // PCS Button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          pcsctnnotifier.value = true;
                                        });
                                      },
                                      child: Container(
                                        width: 54 * fem,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: pcsCtnValue
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
                                  ],
                                ),
                              ),

                              // Current Quantity Title
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
                                                pcsCtnValue
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
                                    // Good Stock
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
                                                pcsCtnValue
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
                                      onTap: () {
                                        _setupControllers(pcsCtnValue);
                                        _showMyDialog(detail, pcsCtnValue);
                                      },
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
                                                      _calculateMargin(
                                                        mainValue.toString(),
                                                        fem,
                                                      ),
                                                      1 * fem,
                                                      10 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      pcsCtnValue
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
                                    ),
                                    // Good Input
                                    GestureDetector(
                                      onTap: () {
                                        _setupControllers(pcsCtnValue);
                                        _showMyDialog(detail, pcsCtnValue);
                                      },
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
                                                      _calculateMargin(
                                                        goodValue.toString(),
                                                        fem,
                                                      ),
                                                      1 * fem,
                                                      9 * fem,
                                                      0 * fem,
                                                    ),
                                                    child: Text(
                                                      pcsCtnValue
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
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons
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
                                    // Cancel Button
                                    GestureDetector(
                                      onTap: () {
                                        Get.back();
                                      },
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
                                    ),
                                    // Save Button
                                    GestureDetector(
                                      onTap: () async {
                                        _showMyDialogApprove(
                                          pidVM.tolistpid[widget.index],
                                          detail,
                                          "modal",
                                        );
                                      },
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
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 25 * fem, 7 * fem),
      // width: double.infinity,
      // height: 102 * fem,
      margin: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.circular(8 * fem),
        boxShadow: [
          BoxShadow(
            color: Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: ListTile(
        // contentPadding: EdgeInsets.fromLTRB(7 * fem, 0 * fem, 9 * fem, 0 * fem),
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
                        color: Color(0xff2d2d2d),
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
                        color: Color(0xff9a9a9a),
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
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                  Text(
                    (stockmodel.formattedUpdatedAt?.contains("Today") ?? false)
                        ? 'Last Stock Check: ${stockmodel.formattedUpdatedAt ?? ""}'
                        : (stockmodel.formattedUpdatedAt?.contains(
                                "Yesterday",
                              ) ??
                              false)
                        ? 'Last Stock Check: ${stockmodel.formattedUpdatedAt ?? ""}'
                        : globalVM.stringToDateWithTime(
                            stockmodel.formattedUpdatedAt ?? "",
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
                : SizedBox(),
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
                              color: Color(0xfff44236),
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
                            color: Color(0xff2d2d2d),
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
                              fontSize: 20 * ffem,
                              fontWeight: FontWeight.w600,
                              height: 1.1725 * ffem / fem,
                              color: Color(0xfff44236),
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
                            color: Color(0xff2d2d2d),
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
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.fromLTRB(3 * fem, 0 * fem, 2 * fem, 5 * fem),
        child: Container(
          padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 17.5 * fem, 7 * fem),
          width: double.infinity,
          height: 102 * fem,
          decoration: BoxDecoration(
            color: Color(0xffffffff),
            borderRadius: BorderRadius.circular(8 * fem),
            boxShadow: [
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
            children: [
              SizedBox(
                height: double.infinity,
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
                          color: Color(0xff2d2d2d),
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
                          color: Color(0xff9a9a9a),
                        ),
                      ),
                    ),

                    Text(
                      (stockmodel.formattedUpdatedAt?.contains("Today") ??
                              false)
                          ? 'Last Stock Check: \n${stockmodel.formattedUpdatedAt ?? ""}'
                          : (stockmodel.formattedUpdatedAt?.contains(
                                  "Yesterday",
                                ) ??
                                false)
                          ? 'Last Stock Check: \n${stockmodel.formattedUpdatedAt ?? ""}'
                          : 'Last Stock Check: \n${globalVM.stringToDateWithTime(stockmodel.formattedUpdatedAt ?? "")}',
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
                  : SizedBox(),
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
                                color: Color(0xfff44236),
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
                              color: Color(0xff2d2d2d),
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
                                fontSize: 15 * ffem,
                                fontWeight: FontWeight.w600,
                                height: 1.1725 * ffem / fem,
                                color: Color(0xfff44236),
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
                              color: Color(0xff2d2d2d),
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
        children: [
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

  void searchWF(String search) async {
    final currentPid = pidVM.tolistpid[widget.index];
    currentPid.detail ??= [];

    currentPid.detail!.clear();
    final query = search.toLowerCase();

    final locallist2 = listdetailstock
        .where(
          (element) => (element.itemCode?.toLowerCase() ?? '').contains(query),
        )
        .toList();

    final localsku = listdetailstock
        .where(
          (element) => (element.itemName?.toLowerCase() ?? '').contains(query),
        )
        .toList();

    final results = locallist2.isNotEmpty ? locallist2 : localsku;

    currentPid.detail!.addAll(results);
  }

  void _startSearch() {
    setState(() {
      listdetailstock.clear();

      final currentPid = pidVM.tolistpid.isNotEmpty
          ? pidVM.tolistpid[widget.index]
          : null;

      final locallist = currentPid?.detail ?? [];

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

      if (pidVM.tolistpid.isNotEmpty && widget.index < pidVM.tolistpid.length) {
        final currentPid = pidVM.tolistpid[widget.index];

        currentPid.detail ??= [];
        currentPid.detail!.clear();
        currentPid.detail!.addAll(listdetailstock);
      }
    });
  }

  Widget _buildSearchField() {
    Logger().d("masuk");
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
              _stopSearching();
            } else {
              _clearSearchQuery();
            }
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

    final pidList = pidVM.tolistpid;
    final currentPid = (pidList.isNotEmpty && widget.index < pidList.length)
        ? pidList[widget.index]
        : null;

    final bool hasScannedItems =
        currentPid?.detail?.any((e) => (e.isScanned?.contains('Y') ?? false)) ??
        false;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20,
              onPressed: () => Get.back(),
            ),
            actions:
                (widget.flag == "history" || currentPid?.isApprove == "Counted")
                ? null
                : _buildActions(), // Akan menggunakan mobile scanner
            title: _isSearching
                ? _buildSearchField()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: TextWidget(
                      text:
                          "${currentPid?.location ?? ''} - ${currentPid?.locationName ?? ''}",
                      maxLines: 2,
                      color: Colors.white,
                    ),
                  ),
            centerTitle: true,
          ),

          backgroundColor: kWhiteColor,
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 25,
                    children: listchoice.map((ItemChoice e) {
                      final bool isSelected = idPeriodSelected == (e.id);

                      return ChoiceChip(
                        label: Text(e.label),
                        labelStyle: const TextStyle(color: Colors.white),
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        selected: isSelected,
                        selectedColor: switch (GlobalVar.choicecategory) {
                          "AB" => Colors.red,
                          "FZ" => Colors.blue,
                          _ => Colors.green,
                        },
                        elevation: 10,
                        onSelected: (_) {
                          setState(() {
                            idPeriodSelected = e.id;
                            final int choice = (idPeriodSelected) - 1;

                            GlobalVar.choicecategory = switch (choice) {
                              0 => "AB",
                              1 => "CH",
                              _ => "FZ",
                            };
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                Visibility(
                  visible: light0 == false && !hasScannedItems,
                  child: const SizedBox(height: 20),
                ),

                if (!hasScannedItems)
                  SizedBox(
                    width: 252 * fem,
                    height: 225 * fem,
                    child: Image.asset(
                      'data/images/undrawnodatarekwbl-1-1.png',
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Obx(() {
                    final filteredList =
                        currentPid?.detail
                            ?.where(
                              (e) =>
                                  (e.inventoryGroup?.contains(
                                        GlobalVar.choicecategory,
                                      ) ??
                                      false) &&
                                  (e.isScanned?.contains('Y') ?? false),
                            )
                            .toList() ??
                        [];

                    return Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return GestureDetector(
                            onTap: () async {
                              if (widget.flag == "history" ||
                                  currentPid?.isApprove == "Counted") {
                                return;
                              }

                              if (ontap) {
                                pcsctnnotifier.value = false;

                                pickedctnmain.value =
                                    item.warehouseStockMainCtn ?? 0;
                                pickedctngood.value =
                                    item.warehouseStockGoodCtn ?? 0;
                                pickedpcsmain.value =
                                    item.warehouseStockMain ?? 0;
                                pickedpcsgood.value =
                                    item.warehouseStockGood ?? 0;

                                await showModalBottomSheet(
                                  context: context,
                                  builder: (_) => modalBottomSheet(item),
                                );
                              }
                            },
                            child: headerCard2(item),
                          );
                        },
                      ),
                    );
                  }),

                Visibility(
                  visible:
                      light0 == false &&
                      (currentPid?.detail
                              ?.where(
                                (e) => e.isScanned?.contains("Y") ?? false,
                              )
                              .toList()
                              .isEmpty ??
                          true),
                  child: const SizedBox(height: 180),
                ),

                if (widget.flag != "history" &&
                    currentPid?.isApprove != "Counted")
                  Container(
                    width: double.infinity,
                    height: 40 * fem,
                    padding: const EdgeInsets.only(left: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 30 * fem),
                          child: TextButton(
                            onPressed: () => _showMyDialogReject("reject"),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5 * fem,
                                horizontal: 52 * fem,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xfff44236),
                                ),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12 * fem),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x3f000000),
                                    offset: Offset(0, 4),
                                    blurRadius: 2,
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
                            final pid = currentPid;
                            final details = pid?.detail;

                            if (pid == null ||
                                details == null ||
                                details.isEmpty) {
                              return;
                            }

                            _showMyDialogApprove(pid, details.first, "all");
                          },

                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5 * fem,
                              horizontal: 52 * fem,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3f000000),
                                  offset: Offset(0, 4),
                                  blurRadius: 2,
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

  ItemChoice(this.id, this.label);
}
