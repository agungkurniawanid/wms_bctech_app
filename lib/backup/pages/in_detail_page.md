import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/in_detail_model.dart';
import 'package:wms_bctech/models/in_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/pages/my_dialog_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/widgets/text_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class InDetailPage extends StatefulWidget {
  final int index;
  final String from;
  final InModel? flag;

  const InDetailPage(this.index, this.from, this.flag, {super.key});

  @override
  State<InDetailPage> createState() => _InDetailPageState();
}

class _InDetailPageState extends State<InDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  bool allow = true;
  int idPeriodSelected = 1;
  final List<String> sortList = ['PO Date', 'Vendor'];
  final InVM inVM = Get.find();
  final List<ItemChoice> listchoice = [];
  final List<Category> listcategory = [];
  late final ScrollController scrollController;
  late InModel cloned;
  late InModel forclose;
  bool leading = true;
  bool checkingscan = false;
  final GlobalKey srKey = GlobalKey();
  final GlobalKey<FormState> keypcs = GlobalKey<FormState>();
  final pcsFieldKey = GlobalKey<FormFieldState<String>>();
  TextEditingController pcsinput = TextEditingController();
  TextEditingController ctninput = TextEditingController();
  TextEditingController expiredinput = TextEditingController();
  TextEditingController palletinput = TextEditingController();
  TextEditingController descriptioninput = TextEditingController();
  final TextEditingController containerinput = TextEditingController();
  final descriptioninputkey = GlobalKey<FormFieldState<String>>();
  final formKey = GlobalKey<FormState>();

  TextEditingController? _controllerctn;
  TextEditingController? _controllerpcs;
  TextEditingController? _controllerkg;

  int typeIndexctn = 0;
  int typeIndexpcs = 0;
  double typeIndexkg = 0.0;
  String datetime = "";

  final List<TextEditingController> listpcsinput = [];
  final List<TextEditingController> listctninput = [];
  final List<TextEditingController> listpallet = [];
  final List<TextEditingController> listexpired = [];
  final List<TextEditingController> listdesc = [];

  int tabs = 0;
  bool anyum = false;
  final List<InDetail> listindetaillocal = [];
  final InModel listinmodel = InModel();

  final ValueNotifier<String> expireddate = ValueNotifier("");
  final ValueNotifier<int> pcs = ValueNotifier(0);
  final ValueNotifier<int> ctn = ValueNotifier(0);
  final ValueNotifier<double> kg = ValueNotifier(0);

  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController _searchQuery = TextEditingController();
  String? searchQuery;

  final NumberFormat currency = NumberFormat("#,###", "en_US");
  final NumberFormat currencydecimal = NumberFormat("#,###.##", "en_US");
  DateTime? date;

  String? ebeln;
  String? barcodeScanRes;

  final Map<int, Widget> myTabs = const {
    0: Text("CTN"),
    1: Text("PCS"),
    2: Text("KG"),
  };

  final Map<int, Widget> myTabs2 = const {0: Text("KG")};
  final GlobalVM globalVM = Get.find();

  String barcodeString = "Barcode will be shown here";
  String barcodeSymbology = "Symbology will be shown here";
  String scanTime = "Scan Time will be shown here";

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
    containerinput.text = '';

    if (widget.from == "sync") {
      ebeln = widget.flag?.ebeln;
      cloned = InModel.clone(widget.flag!);
      forclose = InModel.clone(widget.flag!);
    } else {
      ebeln = inVM.tolistPO[widget.index].ebeln;
      cloned = InModel.clone(inVM.tolistPO[widget.index]);
      forclose = InModel.clone(inVM.tolistPO[widget.index]);
    }
  }

  void _handleBarcodeScan(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty && mounted) {
      final String barcodeString = barcodes.first.rawValue ?? "";

      setState(() {
        if (!checkingscan && barcodeString.isNotEmpty) {
          pcsinput = TextEditingController();
          ctninput = TextEditingController();
          expiredinput = TextEditingController();
          palletinput = TextEditingController();
          descriptioninput = TextEditingController();

          List<dynamic> barcode;

          if (widget.from == "sync") {
            final tData = widget.flag?.tData ?? [];
            barcode = tData
                .where(
                  (element) => (element.barcode ?? '').contains(barcodeString),
                )
                .toList();
          } else {
            final tData = inVM.tolistPO[widget.index].tData ?? [];
            barcode = tData
                .where(
                  (element) => (element.barcode ?? '').contains(barcodeString),
                )
                .toList();
          }

          if (barcode.isNotEmpty) {
            pcs.value = barcode[0].qtuom.toInt();
            ctn.value = barcode[0].qtctn;
            kg.value = barcode[0].qtuom;

            typeIndexctn = ctn.value;
            typeIndexpcs = pcs.value;
            typeIndexkg = kg.value;
            expireddate.value = barcode[0].vfdat;

            checkingscan = true;

            // Stop scanning dan tutup dialog
            mobileScannerController.stop();
            isScanning = false;
            Navigator.of(context).pop(); // Tutup dialog scanner

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => PopScope<Object?>(
                canPop: true,
                onPopInvokedWithResult: (bool didPop, Object? result) {
                  if (!mounted) return;
                  setState(() {
                    checkingscan = false;
                  });
                },
                child: modalBottomSheet(barcode[0]),
              ),
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

  @override
  void dispose() {
    _searchQuery.dispose();
    mobileScannerController.dispose();
    super.dispose();
  }

  String calculateTotalPcs() {
    final tData = widget.from == "sync"
        ? widget.flag?.tData ?? []
        : inVM.tolistPO[widget.index].tData ?? [];

    final total = tData.fold<double>(0, (sum, item) => sum + (item.qtuom ?? 0));
    return total.toString();
  }

  String calculateTotalCtn() {
    final tData = widget.from == "sync"
        ? widget.flag?.tData ?? []
        : inVM.tolistPO[widget.index].tData ?? [];

    final total = tData.fold<int>(0, (sum, item) => sum + (item.qtctn ?? 0));
    return total.toString();
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              setState(_stopSearching);
            } else {
              _clearSearchQuery();
            }
          },
        ),
      ];
    }

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: scanBarcode, // Gunakan mobile scanner
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      ),
    ];
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

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      searchWF(newQuery);
    });
  }

  void searchWF(String search) async {
    final query = search.toLowerCase();

    if (widget.from == "sync") {
      final flag = widget.flag;
      if (flag == null) return;

      flag.tData?.clear();

      final filteredByName = listindetaillocal
          .where((e) => (e.maktx?.toLowerCase() ?? '').contains(query))
          .toList();

      final filteredBySku = listindetaillocal
          .where((e) => (e.matnr?.toLowerCase() ?? '').contains(query))
          .toList();

      final results = filteredByName.isNotEmpty
          ? filteredByName
          : filteredBySku;
      flag.tData?.addAll(results);
    } else {
      final poList = inVM.tolistPO;
      if (poList.isEmpty || widget.index >= poList.length) return;

      final tData = poList[widget.index].tData ?? [];
      tData.clear();

      final filteredByName = listindetaillocal
          .where((e) => (e.maktx?.toLowerCase() ?? '').contains(query))
          .toList();

      final filteredBySku = listindetaillocal
          .where((e) => (e.matnr?.toLowerCase() ?? '').contains(query))
          .toList();

      final results = filteredByName.isNotEmpty
          ? filteredByName
          : filteredBySku;
      tData.addAll(results);
    }
  }

  void _startSearch() {
    setState(() {
      listindetaillocal.clear();

      final sourceData = widget.from == "sync"
          ? (widget.flag?.tData ?? [])
          : (inVM.tolistPO[widget.index].tData ?? []);

      listindetaillocal.addAll(sourceData);
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
      _searchQuery.clear();
      _isSearching = false;

      final sourceData = listindetaillocal;

      if (widget.from == "sync") {
        widget.flag?.tData?.clear();
        widget.flag?.tData?.addAll(sourceData);
      } else {
        final tData = inVM.tolistPO[widget.index].tData ?? [];
        tData.clear();
        tData.addAll(sourceData);
      }
    });
  }

  Future _showMyDialogReject(InModel indetail) async {
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
                      'Are you sure to discard all changes made in this purchase order?',
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
                          onTap: () {
                            final clonedData = cloned.tData ?? [];
                            final forCloseData = forclose.tData ?? [];

                            if (clonedData.isEmpty) {
                            } else if (widget.from == "sync") {
                            } else {
                              final tDataList =
                                  inVM.tolistPO[widget.index].tData ?? [];
                              tDataList
                                ..clear()
                                ..addAll(forCloseData);
                            }

                            Get.back();
                            Get.back();
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

  Future<void> _showMyDialogApprove(InModel indetail) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
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
                  'Are you sure to save all changes made in this purchase order? ',
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
                        // height: double infinity,
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
                        DateTime now = DateTime.now();
                        String formattedDate = DateFormat(
                          'yyyy-MM-dd kk:mm:ss',
                        ).format(now);
                        indetail.approvedate = formattedDate;
                        indetail.truck = containerinput.text;

                        final tDataList = indetail.tData ?? [];

                        for (int i = 0; i < tDataList.length; i++) {
                          tDataList[i].appUser = globalVM.username.value;
                          tDataList[i].appVersion = globalVM.version.value;
                        }

                        indetail.tData = tDataList;

                        List<Map<String, dynamic>> maptdata = tDataList
                            .map((item) => item.toMap())
                            .toList();

                        Get.back();
                        Get.back();

                        indetail.dlvComp = "I";
                        bool sukses = await inVM.approveIn(indetail, maptdata);
                        inVM.isapprove.value = true;

                        if (!sukses) {
                          Get.dialog(MyDialogAnimation("reject"));
                        } else {
                          Get.dialog(MyDialogAnimation("approve"));
                          await inVM.sendHistory(indetail, maptdata);

                          if (widget.from != "sync" && ebeln != null) {
                            inVM.tolistPO.removeWhere((e) => e.ebeln == ebeln);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showMyDialogAnimation(BuildContext context, String type) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) {},
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Lottie.asset(
              type == "reject"
                  ? 'assets/lottie/reject_animation.json'
                  : 'assets/lottie/success_animation.json',
              repeat: false,
              onLoaded: (composition) async {
                await Future.delayed(composition.duration);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future _showMyDialog(InDetail indetail, String type) async {
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
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      '${indetail.maktx}',
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
                          if (type == "kg") {
                          } else {
                            tabs = i as int;
                            tabs == 0
                                ? type = "ctn"
                                : tabs == 1
                                ? type = "pcs"
                                : type = "kg";

                            type == "ctn"
                                ? _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  )
                                : type == "kg"
                                ? _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  )
                                : _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                          }
                        });
                      },
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
                              if (type == "ctn") {
                                if (typeIndexctn == 0) {
                                  _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  );
                                } else {
                                  typeIndexctn--;
                                  _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  );
                                }
                              } else if (type == "pcs") {
                                if (typeIndexpcs == 0) {
                                  _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                                } else {
                                  typeIndexpcs--;
                                  _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                                }
                              } else {
                                if (typeIndexkg == 0) {
                                  _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  );
                                } else {
                                  typeIndexkg--;

                                  _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  );
                                }
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: type == "kg"
                              ? TextInputType.numberWithOptions(decimal: true)
                              : TextInputType.number,
                          inputFormatters: [
                            type == "kg"
                                ? FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  )
                                : FilteringTextInputFormatter.digitsOnly,
                          ],
                          focusNode: _focusNode,
                          controller: type == "ctn"
                              ? _controllerctn
                              : type == "kg"
                              ? _controllerkg
                              : _controllerpcs,
                          onChanged: (i) {
                            try {
                              setState(() {
                                final listPo =
                                    inVM.tolistPO[widget.index].tData ?? [];

                                if (type == "ctn" && tabs == 0) {
                                  final int check = listPo
                                      .where(
                                        (element) =>
                                            element.matnr == indetail.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) => (element.matnr ?? '')
                                              .contains(indetail.matnr ?? ''),
                                        )
                                        .where(
                                          (element) =>
                                              !(element.cloned?.contains(
                                                    indetail.cloned ?? '',
                                                  ) ??
                                                  false),
                                        )
                                        .toList();

                                    final int hasilctn = listpo.fold<int>(
                                      0,
                                      (prev, e) => prev + (e.qtctn ?? 0),
                                    );
                                    final double hasilpcs = listpo.fold<double>(
                                      0,
                                      (prev, e) => prev + (e.qtuom ?? 0),
                                    );

                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final double hasil =
                                        (indetail.menge?.toDouble() ?? 0) -
                                        ((hasilctn * (indetail.umrez ?? 0)) +
                                            (currentCtn *
                                                (indetail.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (indetail.menge?.toDouble() ?? 0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((indetail.menge?.toDouble() ?? 0) -
                                                      ((hasilctn *
                                                              (indetail.umrez ??
                                                                  0)) +
                                                          currentPcs +
                                                          hasilpcs)) /
                                                  (indetail.umrez == 0
                                                      ? 1
                                                      : (indetail.umrez ?? 1)))
                                              .toInt();

                                      typeIndexctn = hasil2;
                                      _controllerctn?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  } else {
                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (currentCtn * (indetail.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                            (indetail.menge?.toInt() ?? 0) &&
                                        (indetail.menge?.toInt() ?? 0) >
                                            (indetail.umrez ?? 0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((indetail.menge?.toDouble() ?? 0) -
                                                      currentPcs) /
                                                  (indetail.umrez == 0
                                                      ? 1
                                                      : (indetail.umrez ?? 1)))
                                              .toInt();

                                      typeIndexctn = hasil2;
                                      _controllerctn?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  }
                                } else if (type == "pcs" && tabs == 1) {
                                  final int check = listPo
                                      .where(
                                        (element) =>
                                            element.matnr == indetail.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) =>
                                              element.matnr == indetail.matnr,
                                        )
                                        .where(
                                          (element) =>
                                              element.cloned != indetail.cloned,
                                        )
                                        .toList();

                                    final int hasilctn = listpo.fold<int>(
                                      0,
                                      (prev, e) => prev + (e.qtctn ?? 0),
                                    );
                                    final int hasilpcs = listpo.fold<int>(
                                      0,
                                      (prev, e) =>
                                          prev + (e.qtuom?.toInt() ?? 0),
                                    );

                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (indetail.menge?.toInt() ?? 0) -
                                        ((hasilctn * (indetail.umrez ?? 0)) +
                                            (currentCtn *
                                                (indetail.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (indetail.menge?.toInt() ?? 0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (indetail.menge?.toInt() ?? 0) -
                                          ((hasilctn * (indetail.umrez ?? 0)) +
                                              (currentCtn *
                                                  (indetail.umrez ?? 0)) +
                                              hasilpcs);
                                      typeIndexpcs = hasil2;
                                      _controllerpcs?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  } else {
                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (currentCtn * (indetail.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                        (indetail.menge?.toInt() ?? 0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (indetail.menge?.toInt() ?? 0) -
                                          (currentCtn * (indetail.umrez ?? 0));
                                      typeIndexpcs = hasil2;
                                      _controllerpcs?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  }
                                } else {
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0.0',
                                      ) ??
                                      0.0;

                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0.0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  }
                                }
                              });
                            } catch (e, st) {
                              debugPrint('Error onChanged: $e\n$st');
                            }
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
                              final listPo =
                                  inVM.tolistPO[widget.index].tData ?? [];

                              final check = listPo
                                  .where(
                                    (element) =>
                                        element.matnr == indetail.matnr,
                                  )
                                  .length;

                              if (check > 1) {
                                final listpo = listPo
                                    .where(
                                      (element) =>
                                          element.matnr == indetail.matnr,
                                    )
                                    .where(
                                      (element) =>
                                          element.cloned != indetail.cloned,
                                    )
                                    .toList();

                                final int hasilCtn = listpo.fold<int>(
                                  0,
                                  (prev, e) => prev + (e.qtctn ?? 0),
                                );
                                final double hasilPcs = listpo.fold<double>(
                                  0,
                                  (prev, e) => prev + (e.qtuom ?? 0.0),
                                );

                                if (type == "ctn") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((hasilCtn * (indetail.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (indetail.umrez ?? 0)) +
                                          typeIndexpcs +
                                          hasilPcs);

                                  if (hasil >= (indetail.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((hasilCtn * (indetail.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (indetail.umrez ?? 0)) +
                                          hasilPcs);

                                  if (typeIndexpcs < hasil) {
                                    typeIndexpcs++;
                                    _controllerpcs?.text = typeIndexpcs
                                        .toString();
                                  }
                                } else {
                                  // tipe "kg"
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0',
                                      ) ??
                                      0.0;
                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  } else {
                                    typeIndexkg++;
                                    _controllerkg?.text = typeIndexkg
                                        .toStringAsFixed(2);
                                  }
                                }
                              } else {
                                // Hanya satu item dengan matnr yang sama
                                if (type == "ctn") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn * (indetail.umrez ?? 0)) +
                                          typeIndexpcs);

                                  if (hasil >= (indetail.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn * (indetail.umrez ?? 0)));

                                  if (typeIndexpcs < hasil) {
                                    typeIndexpcs++;
                                    _controllerpcs?.text = typeIndexpcs
                                        .toString();
                                  }
                                } else {
                                  // tipe "kg"
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0',
                                      ) ??
                                      0.0;
                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  } else {
                                    typeIndexkg++;
                                    _controllerkg?.text = typeIndexkg
                                        .toStringAsFixed(2);
                                  }
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
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
                          onTap: () {
                            ctn.value = typeIndexctn;
                            pcs.value = typeIndexpcs;
                            kg.value = typeIndexkg;
                            Get.back();
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

  Widget modalBottomSheet(InDetail indetail) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        height: GlobalVar.height * 0.95,
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
                    ' Edit - ${indetail.maktx}',
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
                    onTap: () {
                      final listPo =
                          inVM.tolistPO[widget.index].tData
                              ?.where(
                                (element) => element.ebelp == indetail.ebelp,
                              )
                              .toList() ??
                          [];

                      for (final item in listPo) {
                        typeIndexkg = item.qtuom ?? 0.0;
                        typeIndexctn = item.qtctn ?? 0;
                        typeIndexpcs = (item.qtuom ?? 0).toInt();

                        ctn.value = typeIndexctn;
                        pcs.value = typeIndexpcs;
                        kg.value = typeIndexkg;
                      }

                      Get.back();
                    },
                    child: Image.asset(
                      'data/images/cancel-viF.png',
                      width: 30 * fem,
                      height: 30 * fem,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
              width: double.infinity,
              height: 1 * fem,
              decoration: BoxDecoration(color: Color(0xffa8a8a8)),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(
                120 * fem,
                0 * fem,
                120 * fem,
                6 * fem,
              ),
              padding: EdgeInsets.fromLTRB(
                5 * fem,
                31 * fem,
                6.01 * fem,
                31 * fem,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Color(0xffffffff),
                borderRadius: BorderRadius.circular(8 * fem),
              ),
              child: Center(
                // image7rxK (13:505)
                child: SizedBox(
                  width: 108.99 * fem,
                  height: 58 * fem,
                  child: indetail.image == "kosong"
                      ? Image.asset(
                          'data/images/no_image.png',
                          width: 80 * fem,
                          height: 80 * fem,
                        )
                      : Image.network(
                          '${indetail.image}',
                          width: 30 * fem,
                          height: 30 * fem,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: Image.asset(
                                'data/images/no_image.png',
                                width: 80 * fem,
                                height: 80 * fem,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 1 * fem,
              decoration: BoxDecoration(color: Color(0xffa8a8a8)),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16 * fem,
                5 * fem,
                16 * fem,
                8 * fem,
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      7 * fem,
                    ),
                    width: double.infinity,
                    height: 45 * fem,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0 * fem,
                          top: 5 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 328 * fem,
                              height: 40 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4 * fem),
                                  border: Border.all(color: Color(0xff9c9c9c)),
                                  color: Color(0xffe0e0e0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          // rectangle187fH (11:1253)
                          left: 11 * fem,
                          top: 0 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 46 * fem,
                              height: 11 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffffffff),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 11.7142333984 * fem,
                          top: 0 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 41 * fem,
                              height: 13 * fem,
                              child: Text(
                                'Material',
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 11 * ffem,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1725 * ffem / fem,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          // 4iw (11:1255)
                          left: 10 * fem,
                          top: 15 * fem,
                          child: Align(
                            child: SizedBox(
                              width: GlobalVar.width,
                              height: 19 * fem,
                              child: Text(
                                '${indetail.matnr}',
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 16 * ffem,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1725 * ffem / fem,
                                  color: Color(0xff000000),
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
                      0 * fem,
                      11 * fem,
                    ),
                    width: double.infinity,
                    height: 45 * fem,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0 * fem,
                          top: 5 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 328 * fem,
                              height: 40 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4 * fem),
                                  border: Border.all(color: Color(0xff9c9c9c)),
                                  color: Color(0xffe0e0e0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 11 * fem,
                          top: 0 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 105 * fem,
                              height: 11 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffffffff),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          // materialdescriptionZhd (11:1259)
                          left: 12 * fem,
                          top: 0 * fem,
                          child: Align(
                            child: SizedBox(
                              width: 99 * fem,
                              height: 13 * fem,
                              child: Text(
                                'Material Description',
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 11 * ffem,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1725 * ffem / fem,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10 * fem,
                          top: 15 * fem,
                          child: Align(
                            child: SizedBox(
                              width: GlobalVar.width,
                              height: 19 * fem,
                              child: Text(
                                '${indetail.maktx}',
                                style: safeGoogleFont(
                                  'Roboto',
                                  fontSize: 16 * ffem,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1725 * ffem / fem,
                                  color: Color(0xff2d2d2d),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 46 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            16 * fem,
                            0 * fem,
                          ),
                          width: 160 * fem,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 6 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 160 * fem,
                                    height: 40 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4 * fem,
                                        ),
                                        border: Border.all(
                                          color: Color(0xff9c9c9c),
                                        ),
                                        color: Color(0xffe0e0e0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 15.5844726562 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 73.77 * fem,
                                    height: 11 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 15.5844726562 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 66 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'PO QTY',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 11 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10.8754882812 * fem,
                                top: 15 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 150 * fem,
                                    height: 19 * fem,
                                    child: Text(
                                      indetail.pounitori == "KG"
                                          ? "${currencydecimal.format(indetail.menge ?? 0)} ${indetail.pounitori ?? ''}"
                                          : "${currency.format((indetail.menge ?? 0).toInt())} ${indetail.pounitori ?? ''}",
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 16 * ffem,
                                        fontWeight: FontWeight.w400,
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
                        SizedBox(
                          // stockrequestQWP (13:2219)
                          width: 150 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
                                // rectangle17EEX (13:2220)
                                left: 0 * fem,
                                top: 5 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 150 * fem,
                                    height: 40 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4 * fem,
                                        ),
                                        border: Border.all(
                                          color: Color(0xff9c9c9c),
                                        ),
                                        color: Color(0xffe0e0e0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                // rectangle18QoD (13:2221)
                                left: 16 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 60 * fem,
                                    height: 11 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                // stockrequestp6F (13:2222)
                                left: 16.6667480469 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 71 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'Compatible',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 11 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                // bgsr000001Fqm (13:2223)
                                left: 12.2221679688 * fem,
                                top: 15 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 95 * fem,
                                    height: 19 * fem,
                                    child: Text(
                                      "1 X ${indetail.umrez}",
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 16 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
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
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        child: SizedBox(
                          width: 100 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 5 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 100 * fem,
                                    height: 40 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4 * fem,
                                        ),
                                        border: Border.all(
                                          color: Color(0xff9c9c9c),
                                        ),
                                        color:
                                            (indetail.maktx?.contains(
                                                      "Pallet",
                                                    ) ??
                                                    false) ||
                                                (indetail.pounitori == "KG")
                                            ? const Color(0xffe0e0e0)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                // rectangle18QoD (13:2221)
                                left: 16 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 23 * fem,
                                    height: 11 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16.6667480469 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 71 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'CTN',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 11 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: ctn,
                                builder:
                                    (
                                      BuildContext context,
                                      int value,
                                      Widget? child,
                                    ) {
                                      return Positioned(
                                        left: 12.222 * fem,
                                        top: 15 * fem,
                                        child: Align(
                                          child: SizedBox(
                                            width: 95 * fem,
                                            height: 19 * fem,
                                            child: Text(
                                              "$value",
                                              style: safeGoogleFont(
                                                'Roboto',
                                                fontSize: 16 * ffem,
                                                fontWeight: FontWeight.w400,
                                                height: 1.1725 * ffem / fem,
                                                color: const Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!(indetail.maktx?.contains("Pallet") ?? false) &&
                              indetail.pounitori != "KG") {
                            _controllerctn = TextEditingController(
                              text: ctn.value.toString(),
                            );
                            typeIndexctn = ctn.value;
                            _controllerpcs = TextEditingController(
                              text: pcs.value.toString(),
                            );
                            typeIndexpcs = pcs.value;
                            setState(() {
                              tabs = 0;
                              _showMyDialog(indetail, "ctn");
                            });
                          }
                        },
                      ),
                      GestureDetector(
                        child: SizedBox(
                          width: 100 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 5 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 100 * fem,
                                    height: 40 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4 * fem,
                                        ),
                                        border: Border.all(
                                          color: Color(0xff9c9c9c),
                                        ),
                                        color: indetail.pounitori == "KG"
                                            ? Color(0xffe0e0e0)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 23 * fem,
                                    height: 11 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16.6667480469 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 71 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'PCS',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 11 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: pcs,
                                builder:
                                    (
                                      BuildContext context,
                                      int value,
                                      Widget? child,
                                    ) {
                                      return Positioned(
                                        left: 12.222 * fem,
                                        top: 15 * fem,
                                        child: Align(
                                          child: SizedBox(
                                            width: 95 * fem,
                                            height: 19 * fem,
                                            child: Text(
                                              value.toString(),
                                              style: safeGoogleFont(
                                                'Roboto',
                                                fontSize: 16 * ffem,
                                                fontWeight: FontWeight.w400,
                                                height: 1.1725 * ffem / fem,
                                                color: const Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (indetail.pounitori == "KG") {
                            } else {
                              tabs = 1;
                              _controllerctn = TextEditingController(
                                text: ctn.value.toString(),
                              );
                              typeIndexctn = ctn.value;
                              _controllerpcs = TextEditingController(
                                text: pcs.value.toString(),
                              );
                              typeIndexpcs = pcs.value;
                              _showMyDialog(indetail, "pcs");
                            }
                          });
                        },
                      ),
                      GestureDetector(
                        child: SizedBox(
                          width: 100 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 5 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 100 * fem,
                                    height: 40 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          4 * fem,
                                        ),
                                        border: Border.all(
                                          color: Color(0xff9c9c9c),
                                        ),
                                        color:
                                            (indetail.maktx?.contains(
                                                  "Pallet",
                                                ) ??
                                                false)
                                            ? const Color(0xffe0e0e0)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 40 * fem,
                                    height: 11 * fem,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16.6667480469 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 71 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'KG',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 11 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<double>(
                                valueListenable: kg,
                                builder:
                                    (
                                      BuildContext context,
                                      double value,
                                      Widget? child,
                                    ) {
                                      return Positioned(
                                        left: 12.2221679688 * fem,
                                        top: 15 * fem,
                                        child: Align(
                                          child: SizedBox(
                                            width: 95 * fem,
                                            height: 19 * fem,
                                            child: Text(
                                              value.toString(),
                                              style: safeGoogleFont(
                                                'Roboto',
                                                fontSize: 16 * ffem,
                                                fontWeight: FontWeight.w400,
                                                height: 1.1725 * ffem / fem,
                                                color: const Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if ((indetail.maktx ?? '').contains("Pallet")) {
                          } else {
                            setState(() {
                              tabs = 2;
                              _controllerkg = TextEditingController(
                                text: kg.value.toString(),
                              );
                              typeIndexkg = kg.value;
                              _showMyDialog(indetail, "kg");
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        0 * fem,
                        0 * fem,
                        0 * fem,
                        13 * fem,
                      ),
                      width: double.infinity,
                      height: 45 * fem,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0 * fem,
                            top: 5 * fem,
                            child: SizedBox(
                              width: 327 * fem,
                              height: 40 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4 * fem),
                                  border: Border.all(color: Color(0xff9c9c9c)),
                                  color:
                                      (indetail.maktx ?? '').contains("Pallet")
                                      ? Color(0xffe0e0e0)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14 * fem,
                            top: 0 * fem,
                            child: SizedBox(
                              width: 70 * fem,
                              height: 11 * fem,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffffffff),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 15 * fem,
                            top: 0 * fem,
                            child: SizedBox(
                              width: 100 * fem,
                              height: 13 * fem,
                              child: Text(
                                'Expired Date',
                                style: TextStyle(
                                  fontSize: 11 * ffem,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1725 * ffem / fem,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 11 * fem,
                            top: 10 * fem,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(
                                    0 * fem,
                                    0 * fem,
                                    193 * fem,
                                    1 * fem,
                                  ),
                                  child: ValueListenableBuilder<String>(
                                    valueListenable: expireddate,
                                    builder:
                                        (
                                          BuildContext context,
                                          String value,
                                          Widget? child,
                                        ) {
                                          final displayText =
                                              (value == "0000-00-00")
                                              ? ''
                                              : inVM.dateToString(value, "tes");

                                          final textColor =
                                              (value == "0000-00-00")
                                              ? Color(0xff9c9c9c)
                                              : Colors.black;

                                          return Text(
                                            displayText ?? '',
                                            style: safeGoogleFont(
                                              'Roboto',
                                              fontSize: 16 * ffem,
                                              fontWeight: FontWeight.w400,
                                              height: 1.1725 * ffem / fem,
                                              color: textColor,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                SizedBox(
                                  // tearoffcalendarqsR (39:952)
                                  width: 30 * fem,
                                  height: 30 * fem,
                                  child: Icon(Icons.calendar_today),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      if (indetail.maktx?.contains("Pallet") ?? false) {
                        return;
                      }

                      final DateTime? newDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (newDate == null) return;

                      setState(() {
                        expireddate.value = DateFormat(
                          'yyyyMMdd',
                        ).format(newDate);
                      });
                    },
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      13 * fem,
                    ),
                    width: double.infinity,
                    height: 45 * fem,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0 * fem,
                          top: 5 * fem,
                          child: SizedBox(
                            width: 327 * fem,
                            height: 40 * fem,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4 * fem),
                                border: Border.all(color: Color(0xff9c9c9c)),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14 * fem,
                          top: 0 * fem,
                          child: SizedBox(
                            width: 70 * fem,
                            height: 11 * fem,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xffffffff),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 15 * fem,
                          top: 0 * fem,
                          child: SizedBox(
                            width: 100 * fem,
                            height: 13 * fem,
                            child: Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 11 * ffem,
                                fontWeight: FontWeight.w400,
                                height: 1.1725 * ffem / fem,
                                color: Color(0xff000000),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 11 * fem,
                          // top: 15 * fem,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 10),
                            child: SizedBox(
                              width: 300 * fem,
                              height: 30 * fem,
                              child: TextFormField(
                                key: Key('description'),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(
                                    top: 15,
                                    left: 8,
                                  ),
                                  isDense: true,
                                  labelText: "",
                                  fillColor: Colors.white,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  labelStyle: TextStyle(color: Colors.grey),
                                ),
                                keyboardType: TextInputType.text,
                                controller: descriptioninput,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      150 * fem,
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
                              border: Border.all(color: Color(0xfff44236)),
                              color: Color(0xffffffff),
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
                            setState(() {
                              List<InDetail> listpo = [];

                              if (widget.from == "sync") {
                                if (widget.flag?.tData != null) {
                                  listpo = widget.flag!.tData!
                                      .where(
                                        (element) =>
                                            element.ebelp == indetail.ebelp,
                                      )
                                      .toList();
                                }
                              } else {
                                final poItem =
                                    inVM.tolistPO.length > widget.index
                                    ? inVM.tolistPO[widget.index]
                                    : null;

                                if (poItem?.tData != null) {
                                  listpo = poItem!.tData!
                                      .where(
                                        (element) =>
                                            element.ebelp == indetail.ebelp,
                                      )
                                      .toList();
                                }
                              }

                              for (final item in listpo) {
                                typeIndexkg = item.qtuom ?? 0.0;
                                typeIndexctn = item.qtctn ?? 0;
                                typeIndexpcs = (item.qtuom ?? 0.0).toInt();

                                ctn.value = typeIndexctn;
                                pcs.value = typeIndexpcs;
                                kg.value = typeIndexkg;
                              }

                              Get.back();
                            });
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
                            setState(() {
                              if (expireddate.value == "0000-00-00" ||
                                  expireddate.value == "") {
                                Fluttertoast.showToast(
                                  fontSize: 22,
                                  gravity: ToastGravity.TOP,
                                  msg: "Please Input Expired Date",
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              } else {
                                DateTime now = DateTime.now();
                                String formattedDate = DateFormat(
                                  'yyyy-MM-dd kk:mm:ss',
                                ).format(now);
                                indetail.updatedByUsername =
                                    globalVM.username.value;
                                indetail.updated = formattedDate;
                                ctn.value = typeIndexctn;
                                pcs.value = typeIndexpcs;
                                kg.value = typeIndexkg;
                                indetail.qtuom = kg.value;
                                indetail.qtctn = ctn.value;
                                if (indetail.pounitori == "KG") {
                                  indetail.qtuom = kg.value.toDouble();
                                } else {
                                  indetail.qtuom = pcs.value.toDouble();
                                }

                                indetail.vfdat = expireddate.value;
                                indetail.descr = descriptioninput.text;
                                Get.back();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerCard2History(InDetail indetail) {
    double baseWidth = 360.0028076172;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 17.88 * fem, 12 * fem),
      margin: EdgeInsets.fromLTRB(5 * fem, 0 * fem, 10 * fem, 10 * fem),
      width: double.infinity,
      height: indetail.updated != "" ? 170 * fem : 100 * fem,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 17 * fem, 0 * fem),
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    0 * fem,
                    4 * fem,
                  ),
                  constraints: BoxConstraints(maxWidth: 145 * fem),
                  child: Text(
                    '${indetail.maktx}',
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 13 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff2d2d2d),
                    ),
                  ),
                ),
                Text(
                  'SKU: ${indetail.matnr}',
                  style: safeGoogleFont(
                    'Roboto',
                    fontSize: 13 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: Color(0xff9a9a9a),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'PO QTY : ${currency.format(indetail.poqtyori ?? 0)} ${indetail.pounitori ?? ''}',
                  style: safeGoogleFont(
                    'Roboto',
                    fontSize: 13 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: const Color(0xff9a9a9a),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.descr != "",
                  child: Text(
                    // sku292214NGY (11:704)
                    'Description : ${indetail.descr}',
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 13 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff9a9a9a),
                    ),
                  ),
                ),

                SizedBox(height: 5),
                Visibility(
                  visible: indetail.updatedByUsername != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      'Update By: ${indetail.updatedByUsername}',
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.updated != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      indetail.updated != ""
                          ? 'Updated: ${globalVM.stringToDateWithTime(indetail.updated ?? '')}'
                          : 'Updated: ${indetail.updated}',
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.vfdat != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      indetail.vfdat != ""
                          ? 'Exp Date: ${globalVM.dateToString(indetail.vfdat ?? '')}'
                          : 'Exp Date: ${indetail.vfdat}',
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
          Visibility(
            visible: !(indetail.maktx?.contains("Pallet") ?? false),
            child: Container(
              margin: EdgeInsets.fromLTRB(0 * fem, 20 * fem, 12 * fem, 0 * fem),
              width: 56 * fem,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      4 * fem,
                    ),
                    width: double.infinity,
                    height: 28 * fem,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xffa8a8a8)),
                      color: Color(0xffffffff),
                      borderRadius: BorderRadius.circular(8 * fem),
                    ),
                    child: Center(
                      child: Text(
                        '${indetail.qtctn}',
                        textAlign: TextAlign.center,
                        style: safeGoogleFont(
                          'Roboto',
                          fontSize: 14 * ffem,
                          fontWeight: FontWeight.w600,
                          height: 1.1725 * ffem / fem,
                          color: Color(0xff2d2d2d),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    // pcsgpx (11:705)
                    'CTN',
                    textAlign: TextAlign.center,
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 10 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff2d2d2d),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0 * fem, 20 * fem, 16 * fem, 0 * fem),
            width: 56 * fem,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    0 * fem,
                    4 * fem,
                  ),
                  width: double.infinity,
                  height: 28 * fem,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffa8a8a8)),
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.circular(8 * fem),
                  ),
                  child: Center(
                    child: Text(
                      '${indetail.qtuom}',
                      textAlign: TextAlign.center,
                      style: safeGoogleFont(
                        'Roboto',
                        fontSize: 14 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff2d2d2d),
                      ),
                    ),
                  ),
                ),
                Text(
                  // ctnpTJ (11:706)
                  'PCS',
                  textAlign: TextAlign.center,
                  style: safeGoogleFont(
                    'Roboto',
                    fontSize: 10 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: Color(0xff2d2d2d),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: widget.from != "history",
            child: SizedBox(
              width: 11.57 * fem,
              height: 17 * fem,
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'data/images/vector-1HV.png',
                  width: 11.57 * fem,
                  height: 17 * fem,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget headerCard2(InDetail indetail) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double baseWidth = 360.0;
        final double fem = constraints.maxWidth / baseWidth;
        final double ffem = fem * 0.97;

        return Slidable(
          key: Key(indetail.hashCode.toString()),
          groupTag: 'slidable_group',
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _onAddPressed(indetail),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.add,
                label: 'Add',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _onDeletePressed(indetail),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8 * fem,
              8 * fem,
              17.88 * fem,
              12 * fem,
            ),
            margin: EdgeInsets.fromLTRB(5 * fem, 0, 10 * fem, 10 * fem),
            width: double.infinity,
            height: (indetail.updated?.isNotEmpty ?? false)
                ? 185 * fem
                : 100 * fem,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8 * fem),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: Offset(0 * fem, 4 * fem),
                  blurRadius: 5 * fem,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildLeftContent(indetail, fem, ffem)),
                _buildQuantitySections(indetail, fem, ffem),
                if (widget.from != "history") ...[
                  SizedBox(width: 8 * fem),
                  _buildTrailingIcon(fem),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftContent(InDetail indetail, double fem, double ffem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Container(
          constraints: BoxConstraints(maxWidth: 145 * fem),
          child: Text(
            indetail.maktx ?? '',
            style: TextStyle(
              fontSize: 13 * ffem,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2d2d2d),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SKU: ${indetail.matnr}',
          style: TextStyle(
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PO QTY: ${_formatNumber(indetail.poqtyori)} ${indetail.pounitori}',
          style: TextStyle(
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),

        // Conditional fields
        if ((indetail.descr?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Description: ${indetail.descr}',
              style: TextStyle(
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if ((indetail.updatedByUsername?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Update By: ${indetail.updatedByUsername}',
              style: TextStyle(
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((indetail.updated?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Updated: ${_formatUpdatedDate(indetail.updated ?? '')}',
              style: TextStyle(
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((indetail.vfdat?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Exp Date: ${_formatExpDate(indetail.vfdat ?? '')}',
              style: TextStyle(
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySections(InDetail indetail, double fem, double ffem) {
    return Row(
      children: [
        if (_shouldShowCtnSection(indetail)) ...[
          _buildQuantityItem(
            value: indetail.qtctn.toString(),
            label: 'CTN',
            fem: fem,
            ffem: ffem,
          ),
          SizedBox(width: 12 * fem),
        ],
        _buildQuantityItem(
          value: indetail.pounitori == "KG"
              ? indetail.qtuom.toString()
              : indetail.qtuom.toString(),
          label: indetail.pounitori == "KG" ? 'KG' : 'PCS',
          fem: fem,
          ffem: ffem,
        ),
      ],
    );
  }

  Widget _buildQuantityItem({
    required String value,
    required String label,
    required double fem,
    required double ffem,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56 * fem,
          height: 28 * fem,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffa8a8a8)),
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * fem),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff2d2d2d),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff2d2d2d),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(double fem) {
    return SizedBox(
      width: 11.57 * fem,
      height: 17 * fem,
      child: Icon(Icons.chevron_right, color: Colors.grey, size: 17 * fem),
    );
  }

  bool _shouldShowCtnSection(InDetail indetail) {
    return indetail.pounitori != "KG" &&
        !(indetail.maktx?.contains("Pallet") ?? false);
  }

  String _formatNumber(dynamic number) {
    return number.toString();
  }

  String _formatUpdatedDate(String updated) {
    return updated.isNotEmpty
        ? (globalVM.stringToDateWithTime(updated) ?? updated)
        : updated;
  }

  String _formatExpDate(String vfdat) {
    return vfdat.isNotEmpty ? (globalVM.dateToString(vfdat) ?? vfdat) : vfdat;
  }

  void _onAddPressed(InDetail indetail) {
    setState(() {
      if (widget.from == "sync") {
        _addToSyncList(indetail);
      } else {
        _addToInVMList(indetail);
      }
    });
  }

  void _onDeletePressed(InDetail indetail) {
    setState(() {
      if (widget.from == "sync") {
        if (widget.flag?.tData != null) {
          widget.flag!.tData!.remove(indetail);
        }
      } else {
        final listPO = inVM.tolistPO[widget.index];
        if (listPO.tData != null) {
          listPO.tData!.remove(indetail);
        }
      }
    });
  }

  void _addToSyncList(InDetail indetail) {
    final tData = widget.flag?.tData;
    if (tData == null) return;

    final clone2 = InModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == indetail.matnr).toList() ?? [];

    for (int i = 0; i < clones.length; i++) {
      final clone = clones[i];
      clone.qtctn = 0;
      clone.qtuom = 0;
      clone.cloned = "cloned $i";
      tData.add(clone);
    }
  }

  void _addToInVMList(InDetail indetail) {
    final listPO = inVM.tolistPO[widget.index];
    final tData = listPO.tData;
    if (tData == null) return;

    final clone2 = InModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == indetail.matnr).toList() ?? [];

    for (int i = 0; i < clones.length; i++) {
      final clone = clones[i];
      clone.qtctn = 0;
      clone.qtuom = 0;
      clone.cloned = "cloned $i";
      tData.add(clone);
    }
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 360.0028076172;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(fem, ffem),
          backgroundColor: kWhiteColor,
          body: _buildBody(fem, ffem),
        ),
      ),
    );
  }

  AppBar _buildAppBar(double fem, double ffem) {
    return AppBar(
      actions: widget.from == "history" ? null : _buildActions(),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        iconSize: 20.0,
        onPressed: _handleBackPress,
      ),
      backgroundColor: Colors.red,
      title: _isSearching ? _buildSearchField() : _buildAppBarTitle(fem, ffem),
    );
  }

  Widget _buildBody(double fem, double ffem) {
    return Container(
      height: GlobalVar.height,
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      decoration: BoxDecoration(color: Color(0xffffffff)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildHeaderData(fem, ffem),
                _buildDivider(fem),
                _buildProductList(fem, ffem),
              ],
            ),
          ),
          _buildBottomActionBar(fem, ffem),
        ],
      ),
    );
  }

  // Header Data Section
  Widget _buildHeaderData(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(12 * fem, 0 * fem, 12 * fem, 8 * fem),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDateField(fem, ffem),
          _buildVendorField(fem, ffem),
          _buildContainerField(fem, ffem),
          _buildDocNoSapField(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildDateField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 8 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 0 * fem,
            child: Container(
              width: 104 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 0 * fem,
            child: Text(
              'Purchase Order Date',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 12.4677734375 * fem,
            top: 15 * fem,
            child: Text(
              _getDateValue(),
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 39 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text('Vendor', style: _buildTextStyle(ffem, fontSize: 11)),
          ),
          Positioned(
            left: 11 * fem,
            top: 15 * fem,
            child: Text(
              _getVendorValue(),
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerField(double fem, double ffem) {
    if (widget.from == "history") {
      return _buildHistoryContainerField(fem, ffem);
    } else {
      return _buildEditableContainerField(fem, ffem);
    }
  }

  Widget _buildHistoryContainerField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 70 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text(
              'Container No',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 15 * fem,
            child: Text(
              '${inVM.tolistPO[widget.index].truck}',
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableContainerField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.red),
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 70 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text(
              'Container No',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 11 * fem,
            child: Padding(
              padding: EdgeInsets.only(left: 5, bottom: 10),
              child: SizedBox(
                width: 300 * fem,
                height: 30 * fem,
                child: TextFormField(
                  key: Key('description'),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 15, left: 8),
                    isDense: true,
                    labelText: "",
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.text,
                  controller: containerinput,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocNoSapField(double fem, double ffem) {
    return Visibility(
      visible:
          widget.from == "history" && inVM.tolistPO[widget.index].mblnr != null,
      child: Container(
        margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
        width: double.infinity,
        height: 45 * fem,
        child: Stack(
          children: [
            Positioned(
              left: 0 * fem,
              top: 5 * fem,
              child: Container(
                width: 336 * fem,
                height: 40 * fem,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4 * fem),
                  border: Border.all(color: Color(0xff9c9c9c)),
                  color: Color(0xffe0e0e0),
                ),
              ),
            ),
            Positioned(
              left: 14 * fem,
              top: 0 * fem,
              child: Container(
                width: 50 * fem,
                height: 11 * fem,
                color: Color(0xffffffff),
              ),
            ),
            Positioned(
              left: 15 * fem,
              top: 0 * fem,
              child: Text(
                'Doc No SAP',
                style: _buildTextStyle(ffem, fontSize: 11),
              ),
            ),
            Positioned(
              left: 11 * fem,
              top: 15 * fem,
              child: Text(
                '${inVM.tolistPO[widget.index].mblnr}',
                style: _buildTextStyle(ffem, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 7 * fem),
      width: double.infinity,
      height: 1 * fem,
      decoration: BoxDecoration(color: Color(0xff9c9c9c)),
    );
  }

  Widget _buildProductList(double fem, double ffem) {
    return Expanded(
      child: SizedBox(
        child: Obx(() {
          final listPO = inVM.tolistPO;
          if (listPO.isNotEmpty) {
            final tData = listPO[widget.index].tData ?? [];
            tData.sort((a, b) => (b.matnr ?? '').compareTo(a.matnr ?? ''));
          }

          return ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: _getProductCount(),
            itemBuilder: (BuildContext context, int index) {
              return _buildProductItem(context, index, fem, ffem);
            },
          );
        }),
      ),
    );
  }

  Widget _buildBottomActionBar(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 0 * fem),
      padding: EdgeInsets.fromLTRB(22.5 * fem, 6 * fem, 22.5 * fem, 6 * fem),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8 * fem),
          topRight: Radius.circular(8 * fem),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 2 * fem,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSummaryInfo(fem, ffem),
          _buildActionButtons(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSummaryItem(
            'Number of Items:',
            '${_getItemCount()}',
            94 * fem,
            ffem,
          ),
          SizedBox(width: 23 * fem),
          _buildSummaryItem(
            'Total GR in CTN:',
            calculateTotalCtn(),
            88 * fem,
            ffem,
          ),
          SizedBox(width: 23 * fem),
          _buildSummaryItem(
            'Total GR in PCS / KG:',
            calculateTotalPcs(),
            87 * fem,
            ffem,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double fem, double ffem) {
    return Visibility(
      visible: widget.from != "history",
      child: widget.from == "sync"
          ? _buildSyncActionButtons(fem, ffem)
          : _buildNormalActionButtons(fem, ffem),
    );
  }

  Widget _buildSyncActionButtons(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      height: 40 * fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCancelButton(fem, ffem),
          _buildApproveButton(fem, ffem, isSync: true),
        ],
      ),
    );
  }

  Widget _buildNormalActionButtons(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      height: 40 * fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCancelButton(fem, ffem),
          _buildApproveButton(fem, ffem, isSync: false),
        ],
      ),
    );
  }

  // Helper Methods
  String _getDateValue() {
    return widget.from == "sync"
        ? '${inVM.dateToString(widget.flag?.aedat, "tes")}'
        : '${inVM.dateToString(inVM.tolistPO[widget.index].aedat, "tes")}';
  }

  String _getVendorValue() {
    return widget.from == "sync"
        ? '${widget.flag?.lifnr}'
        : '${inVM.tolistPO[widget.index].lifnr}';
  }

  int _getProductCount() {
    if (widget.from == "sync") {
      return widget.flag?.tData?.length ?? 0;
    } else {
      return inVM.tolistPO.isNotEmpty
          ? inVM.tolistPO[widget.index].tData?.length ?? 0
          : 0;
    }
  }

  int _getItemCount() {
    return inVM.tolistPO.isNotEmpty
        ? inVM.tolistPO[widget.index].tData?.length ?? 0
        : 0;
  }

  void _handleBackPress() {
    if (widget.from == "history") {
      Get.back();
    } else if (widget.from == "sync") {
      if (widget.flag == null) return;
      _showMyDialogReject(widget.flag!);
    } else {
      final model = inVM.tolistPO.isNotEmpty
          ? inVM.tolistPO[widget.index]
          : null;
      if (model == null) return;
      _showMyDialogReject(model);
    }
  }

  Widget _buildAppBarTitle(double fem, double ffem) {
    return SizedBox(
      child: TextWidget(
        text: widget.from == "sync"
            ? "${widget.flag?.ebeln}"
            : "${inVM.tolistPO[widget.index].ebeln}",
        maxLines: 2,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    double width,
    double ffem,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: width),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: _buildTextStyle(
            ffem,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$title\n'),
            TextSpan(
              text: value,
              style: _buildTextStyle(
                ffem,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 30 * fem, 0 * fem),
      child: TextButton(
        onPressed: _handleCancelPress,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Container(
          padding: EdgeInsets.fromLTRB(52 * fem, 5 * fem, 53 * fem, 5 * fem),
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xfff44236)),
            color: Color(0xffffffff),
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
                'data/images/cancel-ecb.png',
                width: 30 * fem,
                height: 30 * fem,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApproveButton(double fem, double ffem, {bool isSync = false}) {
    final isDisabled = containerinput.text == "";

    return TextButton(
      onPressed: isDisabled ? null : () => _handleApprovePress(isSync),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: isDisabled ? Colors.grey : Color(0xff2cab0c),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * fem),
        ),
        shadowColor: Color(0x3f000000),
        elevation: 2 * fem,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(52 * fem, 5 * fem, 53 * fem, 5 * fem),
        height: double.infinity,
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
    );
  }

  void _handleCancelPress() {
    _showMyDialogReject(inVM.tolistPO[widget.index]);
  }

  void _handleApprovePress(bool isSync) {
    final model = isSync
        ? widget.flag
        : inVM.tolistPO.isNotEmpty
        ? inVM.tolistPO[widget.index]
        : null;
    if (model == null) return;

    setState(() {
      _showMyDialogApprove(model);
    });
  }

  TextStyle _buildTextStyle(
    double ffem, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return safeGoogleFont(
      'Roboto',
      fontSize: fontSize * ffem,
      fontWeight: fontWeight,
      height: 1.1725 * ffem / ffem,
      color: Color(0xff000000),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    int index,
    double fem,
    double ffem,
  ) {
    return Container(); // Placeholder
  }
}
