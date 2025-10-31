import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/input_stock_take_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/models/stock_take_detail_model.dart';
import 'package:wms_bctech/models/stock_take_model.dart';
import 'package:wms_bctech/pages/counted_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/stock_tick_controller.dart';
import 'package:wms_bctech/components/text_widget.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StockTakeDetail extends StatefulWidget {
  final StocktickModel stocktake;
  final int index;
  final String documentno;

  const StockTakeDetail(
    this.stocktake,
    this.index,
    this.documentno, {
    super.key,
  });

  @override
  State<StockTakeDetail> createState() => _StockTakeDetailState();
}

class _StockTakeDetailState extends State<StockTakeDetail> {
  bool allow = true;
  int idPeriodSelected = 1;
  String namechoice = "";
  ValueNotifier<List<String>> sortListBatch = ValueNotifier([]);
  ValueNotifier<List<String>> sortListSection = ValueNotifier([]);
  GlobalVM globalvm = Get.find();
  StockTickVM stocktickvm = Get.find();
  List<ItemChoice> listchoice = [];
  List<ItemChoice> listchoice2 = [];
  List<Category> listcategory = [];
  ScrollController controller = ScrollController();
  bool leading = true;
  GlobalKey srKey = GlobalKey();
  bool _isSearching = false;
  TextEditingController _searchQuery = TextEditingController();
  String searchQuery = '', barcodeScanRes = '';
  List<StockTakeDetailModel> detaillocal = [];
  ValueNotifier<String> selectedSection = ValueNotifier("");
  ValueNotifier<String> selectedBatch = ValueNotifier("");
  int typeIndexbox = 0;
  double typeIndexbun = 0;
  ValueNotifier<double> totalinput = ValueNotifier(0.0);
  ValueNotifier<double> bun = ValueNotifier(0.0);
  ValueNotifier<int> box = ValueNotifier(0);
  ValueNotifier<double> localpcsvalue = ValueNotifier(0.0);
  ValueNotifier<int> localctnvalue = ValueNotifier(0);
  ValueNotifier<double> stockbun = ValueNotifier(0.0);
  ValueNotifier<String> totalbox = ValueNotifier("");
  ValueNotifier<String> totalbun = ValueNotifier("");
  ValueNotifier<double> stockbox = ValueNotifier(0.0);
  ValueNotifier<bool> checkboxvalidation = ValueNotifier(false);
  var choicein = "".obs;
  TextEditingController _controllerbox = TextEditingController();
  TextEditingController _controllerbun = TextEditingController();
  int tabs = 0;
  final Map<int, Widget> myTabs = const <int, Widget>{
    0: Text("BUN"),
    1: Text("BOX"),
  };
  FocusNode focusNode = FocusNode();
  int localctn = 0;
  double localpcs = 0.0;

  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.all],
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _searchQuery = TextEditingController();

    if (sortListSection.value.isEmpty) {
      fetchSectionFromFirestore();
    }
    stocktickvm.document.value = widget.stocktake.documentno;
    stocktickvm.forDetail();

    var testing = stocktickvm
        .newListToDocument(namechoice, stocktickvm.document.value)
        .length;
    Logger().i(testing);
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _controllerbox.dispose();
    _controllerbun.dispose();
    focusNode.dispose();
    cameraController.dispose(); // TAMBAH ini
    super.dispose();
  }

  Future<void> fetchSectionFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stocktakes-section')
        .where('LGORT', arrayContainsAny: widget.stocktake.lGORT)
        .get();

    if (snapshot.docs.isNotEmpty) {
      List<String> tempList = [];

      for (var doc in snapshot.docs) {
        final sectionData = doc['section'];

        if (!sortListSection.value.contains(sectionData)) {
          tempList.add(sectionData);
        }
      }

      tempList.sort();

      sortListSection.value.addAll(tempList);
    }
  }

  String _convertphysicaltobox(StockTakeDetailModel item, String validation) {
    String stringumrez = "";
    double umrez = 0.0;
    if (validation == "KG") {
      var calcu = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.matnr == item.matnr &&
                element.selectedChoice == item.selectedChoice,
          )
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        var listumrez = item.marm!
            .where((element) => element.meinh == "KG")
            .toList();
        if (listumrez.isNotEmpty) {
          stringumrez = listumrez[0].umrez!;
          umrez = double.parse(stringumrez);
        }
      }
    } else {
      var calcu = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.matnr == item.matnr &&
                element.selectedChoice == item.selectedChoice,
          )
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        var listumrez = item.marm!
            .where((element) => element.meinh != "KG" && element.meinh != "PAK")
            .toList();
        if (listumrez.isNotEmpty) {
          stringumrez = listumrez[0].umrez!;
          umrez = double.parse(stringumrez);
        } else {
          var listumrez = item.marm;
          stringumrez = listumrez![0].umrez!;
          umrez = double.parse(stringumrez);
        }
      }
    }

    return umrez.toString();
  }

  String calculTotalbun(StockTakeDetailModel item, String validation) {
    double total = 0;
    double parseumren = 0.0;
    String stringumrez = "";
    double umrez = 0.0;
    if (validation != "KG") {
      var calcu = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.matnr == item.matnr &&
                element.selectedChoice == item.selectedChoice,
          )
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        var listumrez = item.marm!
            .where((element) => element.meinh != "KG" && element.meinh != "PAK")
            .toList();
        if (listumrez.isNotEmpty) {
          stringumrez = listumrez[0].umrez!;
          umrez = double.parse(stringumrez);
        } else {
          var listumren = item.marm;
          stringumrez = listumren![0].umren!;
          umrez = double.parse(stringumrez);
        }
        parseumren = (calcu[j].countBox * umrez);
        total += parseumren += calcu[j].countBun;
      }
    } else {
      var calcu = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.matnr == item.matnr &&
                element.selectedChoice == item.selectedChoice,
          )
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        var listumrez = item.marm!
            .where((element) => element.meinh == "KG")
            .toList();
        if (listumrez.isNotEmpty) {
          stringumrez = listumrez[0].umrez!;
          umrez = double.parse(stringumrez);
        }
        parseumren = (calcu[j].countBox * umrez);
        total += parseumren += calcu[j].countBun;
      }
    }

    String totalstring = total.toString();
    return totalstring;
  }

  String conversion(
    StockTakeDetailModel models,
    String name,
    String validation,
  ) {
    try {
      double parseumren = 0.0;
      String stringumren = "";
      String stringumrez = "";
      double umren = 0.0;
      double umrez = 0.0;

      if (name == "KG") {
        var listumren = models.marm!
            .where((element) => element.meinh == "KG")
            .toList();
        if (listumren.isNotEmpty) {
          stringumren = listumren[0].umren!;
          umren = double.parse(stringumren);
        }

        var listumrez = models.marm!
            .where((element) => element.meinh == "KG")
            .toList();
        if (listumrez.isNotEmpty) {
          stringumrez = listumrez[0].umrez!;
          umrez = double.parse(stringumrez);
        }
      } else {
        if (validation == "Bukan Tampilan") {
          var listumren = models.marm!
              .where(
                (element) => element.meinh != "KG" && element.meinh != "BOX",
              )
              .toList();

          if (listumren.isNotEmpty) {
            stringumren = listumren[0].umren!;
            umren = double.parse(stringumren);
          } else {
            stringumren = models.marm![0].umren!;
            umren = double.parse(stringumren);
          }

          var listumrez = models.marm!
              .where(
                (element) => element.meinh != "KG" && element.meinh != "PAK",
              )
              .toList();

          if (listumrez.isNotEmpty) {
            stringumrez = listumrez[0].umrez!;
            umrez = double.parse(stringumrez);
          } else {
            stringumrez = models.marm![0].umrez!;
            umrez = double.parse(stringumrez);
          }
        } else {
          var listumren = models.marm!
              .where(
                (element) => element.meinh != "KG" && element.meinh != "PAK",
              )
              .toList();

          if (listumren.isNotEmpty) {
            stringumren = listumren[0].umren!;
            umren = double.parse(stringumren);
          } else {
            stringumren = models.marm![0].umren!;
            umren = double.parse(stringumren);
          }

          var listumrez = models.marm!
              .where(
                (element) => element.meinh != "KG" && element.meinh != "PAK",
              )
              .toList();

          if (listumrez.isNotEmpty) {
            stringumrez = listumrez[0].umrez!;
            umrez = double.parse(stringumrez);
          } else {
            stringumrez = models.marm![0].umrez!;
            umrez = double.parse(stringumrez);
          }
        }
      }

      if (models.selectedChoice == "UU") {
        parseumren = (models.labst / umrez) * umren;
      } else if (models.selectedChoice == "QI") {
        parseumren = (models.insme / umrez) * umren;
      } else {
        parseumren = (models.speme / umrez) * umren;
      }

      return parseumren.toStringAsFixed(1);
    } catch (e) {
      Logger().e(e);
      return "0.0";
    }
  }

  void getchoicechip() async {
    try {
      listcategory = await DatabaseHelper.db.getCategoryWithRole("STOCKTAKE");

      setState(() {
        for (int i = 0; i < listcategory.length; i++) {
          ItemChoice choicelocal = ItemChoice(
            id: i + 1,
            label: listcategory[i].inventoryGroupId,
            labelName: listcategory[i].inventoryGroupName,
          );
          listchoice.add(choicelocal);
        }
        namechoice = listchoice[0].label!;
        if (listcategory.isNotEmpty) {}
      });
    } catch (e) {
      Logger().e(e);
    }
  }

  String calculTotalStockPCS(StockTakeDetailModel item, String flag) {
    if (flag == "stock") {
      int total = 0;
      var calcu = stocktickvm.tolistdocument
          .singleWhere((element) => element.documentno == widget.documentno)
          .detail
          .where((element) => element.matnr == item.matnr)
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        total += calcu[j].labst.toInt();
      }
      String totalstring = total.toString();
      return totalstring;
    } else {
      int total = 0;
      var calcu = stocktickvm.tolistforinputstocktake
          .where((element) => element.matnr == item.matnr)
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        total += calcu[j].countBun.toInt();
      }
      String totalstring = total.toString();
      return totalstring;
    }
  }

  String calculTotalStockCTN(StockTakeDetailModel item, String flag) {
    if (flag == "stock") {
      int total = 0;
      var calcu = stocktickvm.tolistdocument
          .singleWhere((element) => element.documentno == widget.documentno)
          .detail
          .where((element) => element.matnr == item.matnr)
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        total += calcu[j].labst.toInt();
      }
      String totalstring = total.toString();
      return totalstring;
    } else {
      int total = 0;
      var calcu = stocktickvm.tolistforinputstocktake
          .where((element) => element.matnr == item.matnr)
          .toList();
      for (var j = 0; j < calcu.length; j++) {
        total += calcu[j].countBox.toInt();
      }
      String totalstring = total.toString();
      return totalstring;
    }
  }

  String calcultotalbox(StockTakeDetailModel item) {
    double total = 0;
    var calcu = stocktickvm.tolistforinputstocktake
        .where(
          (element) =>
              element.batchId == item.matnr && element.matnr == item.matnr,
        )
        .toList();
    for (var j = 0; j < calcu.length; j++) {
      total += calcu[j].countBox;
    }
    String totalstring = total.toString();
    return totalstring;
  }

  String calculTotalpcs(StockTakeDetailModel item) {
    double total = 0;

    final calcu = stocktickvm.tolistforinputstocktake
        .where((element) => element.matnr == item.matnr)
        .toList();

    for (final data in calcu) {
      total += data.countBun;
    }

    return total.toStringAsFixed(2);
  }

  Future _showMyDialog(StockTakeDetailModel indetail, String type) async {
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
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                        child: Text(
                          indetail.nORMT.trim(),
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                        child: Text(
                          indetail.mAKTX,
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: CupertinoSlidingSegmentedControl(
                      groupValue: tabs,
                      children: myTabs,
                      onValueChanged: (i) {
                        setState(() {
                          tabs = i ?? 0;
                          tabs == 0 ? type = "bun" : type = "box";

                          if (type == "box") {
                            _controllerbox = TextEditingController(
                              text: typeIndexbox.toString(),
                            );
                          } else {
                            _controllerbun = TextEditingController(
                              text: typeIndexbun.toString(),
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
                              style: GoogleFonts.roboto(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (type == "box" && typeIndexbox > 0) {
                                typeIndexbox--;
                                _controllerbox = TextEditingController(
                                  text: typeIndexbox.toString(),
                                );
                              } else if (type == "bun" && typeIndexbun > 0) {
                                typeIndexbun--;
                                _controllerbun = TextEditingController(
                                  text: typeIndexbun.toString(),
                                );
                              }
                            });
                          },
                        ),
                      ),
                      // Input Field
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          controller: type == "box"
                              ? _controllerbox
                              : _controllerbun,
                          onChanged: (i) {
                            try {
                              setState(() {
                                if (type == "box") {
                                  typeIndexbox = int.parse(_controllerbox.text);
                                } else {
                                  typeIndexbun = double.parse(
                                    _controllerbun.text,
                                  );
                                }
                              });
                            } catch (e) {
                              Logger().e(e);
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
                              style: GoogleFonts.roboto(
                                color: Colors.red,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (type == "box") {
                                typeIndexbox++;
                                _controllerbox = TextEditingController(
                                  text: typeIndexbox.toString(),
                                );
                              } else {
                                typeIndexbun++;
                                _controllerbun = TextEditingController(
                                  text: typeIndexbun.toString(),
                                );
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
                            box.value = typeIndexbox;
                            bun.value = typeIndexbun;
                            double total = 0.0;
                            double totalpcslocal = 0.0;

                            var calcu = stocktickvm.tolistforinputstocktake
                                .where(
                                  (element) => element.matnr == indetail.matnr,
                                )
                                .toList();

                            if (calcu.isEmpty) {
                              totalbox.value = box.value.toString();
                              totalbun.value = bun.value.toString();
                            } else {
                              for (var j = 0; j < calcu.length; j++) {
                                if (calcu[j].section == selectedSection.value) {
                                } else {
                                  total += calcu[j].countBox;
                                }
                              }
                              total += box.value;
                              totalbox.value = total.toString();

                              for (var j = 0; j < calcu.length; j++) {
                                totalpcslocal += calcu[j].countBun;
                              }

                              totalpcslocal += bun.value;
                              totalbun.value = totalpcslocal.toString();
                            }
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

  Widget headerCard2(StockTakeDetailModel inmodel) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      margin: EdgeInsets.fromLTRB(5 * fem, 0 * fem, 10 * fem, 10 * fem),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * fem),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8 * fem),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3f000000),
                  offset: Offset(0, 6 * fem),
                  blurRadius: 5 * fem,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inmodel.mAKTX,
                            style: GoogleFonts.roboto(
                              fontSize: 16 * ffem,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5 * fem),
                          Container(
                            width: Get.width,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(right: 10),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 5,
                              children: ["UU", "QI", "BLOCK"].map((choice) {
                                final isSelected =
                                    inmodel.selectedChoice == choice;
                                final isLightMode =
                                    Theme.of(context).scaffoldBackgroundColor ==
                                    Colors.grey[100];

                                return ChoiceChip(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text(
                                      choice,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16 * ffem,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  backgroundColor: isLightMode
                                      ? Colors.grey
                                      : Colors.grey,
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() {
                                        inmodel.selectedChoice = choice;
                                      });
                                    }
                                  },
                                  selectedColor: choice == "UU"
                                      ? Colors.green
                                      : choice == "QI"
                                      ? Colors.orange[500]!
                                      : Colors.red,
                                  elevation: 10,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10 * fem),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Box: ${inmodel.nORMT}',
                          style: GoogleFonts.roboto(
                            fontSize: 14 * ffem,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'SKU: ${inmodel.matnr}',
                          style: GoogleFonts.roboto(
                            fontSize: 14 * ffem,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: inmodel.checkboxValidation,
                        builder: (context, value, _) {
                          return Checkbox(
                            value: value,
                            onChanged: (bool? newValue) {
                              final updatedValue = newValue ?? false;
                              inmodel.checkboxValidation.value = updatedValue;

                              stocktickvm.updatedetailtick(
                                widget.documentno,
                                stocktickvm.tolistdocumentnosame
                                    .singleWhere(
                                      (element) =>
                                          element.documentno ==
                                          widget.documentno,
                                    )
                                    .detail,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * fem),

                SizedBox(
                  width: Get.width,
                  child: DataTable(
                    // ✅ Ganti deprecated dataRowHeight
                    dataRowMinHeight: 40.0,
                    dataRowMaxHeight: 40.0,

                    columnSpacing: 20.0,
                    horizontalMargin: 0.5,
                    dividerThickness: 1,

                    // ✅ Ganti deprecated MaterialStateColor dengan WidgetStateColor
                    headingRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.grey[800]!,
                    ),
                    headingTextStyle: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dataRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.grey[900]!,
                    ),

                    columns: const [
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('Unit'),
                        ),
                      ),
                      DataColumn(label: Text('Bun')),
                      DataColumn(label: Text('Box')),
                      DataColumn(label: Text('KG')),
                    ],

                    rows: stocktickvm.tolistdocument
                        .singleWhere(
                          (element) => element.documentno == widget.documentno,
                        )
                        .detail
                        .where((element) => element.matnr == inmodel.matnr)
                        .toList()
                        .map((item) {
                          return [
                            // === STOCK ROW ===
                            DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    color: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 8.0,
                                    ),
                                    child: const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Stock',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      inmodel.selectedChoice == "UU"
                                          ? '${item.labst}'
                                          : inmodel.selectedChoice == "QI"
                                          ? '${item.insme}'
                                          : '${item.speme}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      conversion(item, "Box", "tampilan"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      conversion(item, "KG", "tampilan"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // === PHYSICAL ROW ===
                            DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    color: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 8.0,
                                    ),
                                    child: const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Physical',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      calculTotalbun(inmodel, "Bun"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (() {
                                        final total =
                                            double.tryParse(
                                              calculTotalbun(inmodel, "Box"),
                                            ) ??
                                            0.0;
                                        final physical =
                                            double.tryParse(
                                              _convertphysicaltobox(
                                                inmodel,
                                                "Box",
                                              ),
                                            ) ??
                                            0.0;
                                        if (total == 0.0 && physical == 0.0) {
                                          return '0.0';
                                        }
                                        final result = total / physical;
                                        return result.toStringAsFixed(1);
                                      })(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      (() {
                                        final total =
                                            double.tryParse(
                                              calculTotalbun(inmodel, "KG"),
                                            ) ??
                                            0.0;
                                        final physical =
                                            double.tryParse(
                                              _convertphysicaltobox(
                                                inmodel,
                                                "KG",
                                              ),
                                            ) ??
                                            0.0;
                                        if (total == 0.0 && physical == 0.0) {
                                          return '0.0';
                                        }
                                        return (total / physical)
                                            .toStringAsFixed(1);
                                      })(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // === DIFFERENT ROW ===
                            DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    color: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 8.0,
                                    ),
                                    child: const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Different',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (() {
                                        final total =
                                            double.tryParse(
                                              calculTotalbun(inmodel, "Bun"),
                                            ) ??
                                            0.0;
                                        final ref =
                                            inmodel.selectedChoice == "UU"
                                            ? (item.labst)
                                            : inmodel.selectedChoice == "QI"
                                            ? (item.insme)
                                            : (item.speme);
                                        return (total - ref).toStringAsFixed(2);
                                      })(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (() {
                                        final total =
                                            double.tryParse(
                                              calculTotalbun(inmodel, "Box"),
                                            ) ??
                                            0.0;
                                        final physical =
                                            double.tryParse(
                                              _convertphysicaltobox(
                                                inmodel,
                                                "Box",
                                              ),
                                            ) ??
                                            0.0;
                                        final converted =
                                            double.tryParse(
                                              conversion(
                                                item,
                                                "Box",
                                                "tampilan",
                                              ),
                                            ) ??
                                            0.0;
                                        if (total == 0.0 && physical == 0.0) {
                                          return '0.0';
                                        }
                                        return ((total / physical) - converted)
                                            .toStringAsFixed(2);
                                      })(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      (() {
                                        final total =
                                            double.tryParse(
                                              calculTotalbun(inmodel, "KG"),
                                            ) ??
                                            0.0;
                                        final physical =
                                            double.tryParse(
                                              _convertphysicaltobox(
                                                inmodel,
                                                "KG",
                                              ),
                                            ) ??
                                            0.0;
                                        final converted =
                                            double.tryParse(
                                              conversion(
                                                item,
                                                "KG",
                                                "tampilan",
                                              ),
                                            ) ??
                                            0.0;
                                        if (total == 0.0 && physical == 0.0) {
                                          return '0.0';
                                        }
                                        return ((total / physical) - converted)
                                            .toStringAsFixed(2);
                                      })(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ];
                        })
                        .expand((e) => e)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget modalBottomSheet(
    StockTakeDetailModel indetail,
    List<StockTakeDetailModel> inDetailList,
  ) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    sortListSection.value.sort();
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        height: Get.height * 0.80,
        width: double.infinity,
        decoration: BoxDecoration(color: Color(0xffffffff)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  child: Text(
                    ' Edit - ${indetail.nORMT.trim()} ${indetail.mAKTX}',
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
                child: SizedBox(
                  width: 108.99 * fem,
                  height: 58 * fem,
                  child: Image.asset(
                    'data/images/no_image.png',
                    width: 80 * fem,
                    height: 80 * fem,
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
                                    width: 40.77 * fem,
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
                                left: 10.8754882812 * fem,
                                top: 15 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 150 * fem,
                                    height: 19 * fem,
                                    child: Text(
                                      "${indetail.matnr}",
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
                        SizedBox(
                          width: 150 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
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
                                left: 12.2221679688 * fem,
                                top: 15 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 95 * fem,
                                    height: 19 * fem,
                                    child: Text(
                                      indetail.marm!.isEmpty
                                          ? "1 X 0"
                                          : indetail.marm!.length == 1
                                          ? "1 X ${indetail.marm![0].umrez!.trim()}"
                                          : "1 X ${indetail.marm!.where((element) => element.meinh == "KG").toList()[0].umrez!.trim()}",
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
                                '${indetail.nORMT.trim()} ${indetail.mAKTX}',
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
                                    width: 50.77 * fem,
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
                                    width: 80 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'Stock Bun',
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
                                child: ValueListenableBuilder<double>(
                                  valueListenable: stockbun,
                                  builder:
                                      (
                                        BuildContext context,
                                        double value,
                                        Widget? child,
                                      ) {
                                        return Align(
                                          child: SizedBox(
                                            width: 150 * fem,
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
                                        );
                                      },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 150 * fem,
                          height: 45 * fem,
                          child: Stack(
                            children: [
                              Positioned(
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
                                left: 16 * fem,
                                top: 0 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 55 * fem,
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
                                    width: 90 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'Stock BOX',
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
                                left: 12.2221679688 * fem,
                                top: 15 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 95 * fem,
                                    height: 19 * fem,
                                    child: ValueListenableBuilder(
                                      valueListenable: stockbox,
                                      builder: (context, value, child) => Text(
                                        conversion(indetail, "Box", "tampilan"),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              0 * fem,
                              0 * fem,
                              10 * fem,
                              0 * fem,
                            ),
                            height: double.infinity,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0 * fem,
                                  top: 6 * fem,
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
                                          color: Colors.white,
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
                                        'Section',
                                        style: TextStyle(
                                          fontSize: 11 * ffem,
                                          fontWeight: FontWeight.w400,
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
                                      child: ValueListenableBuilder<String>(
                                        valueListenable: selectedSection,
                                        builder:
                                            (
                                              BuildContext context,
                                              String newValue,
                                              Widget? child,
                                            ) {
                                              return ValueListenableBuilder<
                                                List<String>
                                              >(
                                                valueListenable:
                                                    sortListSection,
                                                builder:
                                                    (
                                                      BuildContext context,
                                                      List<String> sectionList,
                                                      Widget? child,
                                                    ) {
                                                      return DropdownButton<
                                                        String
                                                      >(
                                                        value:
                                                            newValue.isNotEmpty
                                                            ? newValue
                                                            : (sectionList
                                                                      .isNotEmpty
                                                                  ? sectionList
                                                                        .first
                                                                  : null),
                                                        onChanged: (String? newValue) {
                                                          if (newValue ==
                                                              null) {
                                                            return;
                                                          }
                                                          selectedSection
                                                                  .value =
                                                              newValue;

                                                          final calculate = stocktickvm
                                                              .tolistforinputstocktake
                                                              .where(
                                                                (element) =>
                                                                    element.batchId ==
                                                                        selectedBatch
                                                                            .value &&
                                                                    element.section ==
                                                                        selectedSection
                                                                            .value &&
                                                                    element.matnr ==
                                                                        indetail
                                                                            .matnr &&
                                                                    element.selectedChoice ==
                                                                        indetail
                                                                            .selectedChoice,
                                                              )
                                                              .toList();

                                                          if (calculate
                                                              .isEmpty) {
                                                            bun.value = 0;
                                                            box.value = 0;
                                                          } else {
                                                            double localpcs = 0;
                                                            double localctn = 0;

                                                            for (var input
                                                                in calculate) {
                                                              localpcs += input
                                                                  .countBun;
                                                              localctn += input
                                                                  .countBox;
                                                            }

                                                            bun.value =
                                                                localpcs;
                                                            box.value = localctn
                                                                .toInt();
                                                          }
                                                        },
                                                        items: sectionList
                                                            .map<
                                                              DropdownMenuItem<
                                                                String
                                                              >
                                                            >(
                                                              (String value) =>
                                                                  DropdownMenuItem<
                                                                    String
                                                                  >(
                                                                    value:
                                                                        value,
                                                                    child: Text(
                                                                      value,
                                                                    ),
                                                                  ),
                                                            )
                                                            .toList(),
                                                        style: TextStyle(
                                                          fontSize: 16 * ffem,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
                                                        underline:
                                                            const SizedBox.shrink(),
                                                        icon: const Icon(
                                                          Icons.arrow_drop_down,
                                                          color: Colors.black,
                                                        ),
                                                        dropdownColor:
                                                            Colors.white,
                                                      );
                                                    },
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            10 * fem,
                            0 * fem,
                          ),
                          width: 100 * fem,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 6 * fem,
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
                                    width: 78.77 * fem,
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
                                    width: 100 * fem,
                                    height: 12 * fem,
                                    child: Text(
                                      'Total Physical Bun',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 10 * ffem,
                                        fontWeight: FontWeight.w400,
                                        height: 1.1725 * ffem / fem,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<double>(
                                valueListenable: bun,
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
                                              value.toStringAsFixed(0),
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
                        Container(
                          // requestdateRh5 (13:2224)
                          margin: EdgeInsets.fromLTRB(
                            0 * fem,
                            0 * fem,
                            6 * fem,
                            0 * fem,
                          ),
                          width: 102 * fem,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0 * fem,
                                top: 6 * fem,
                                child: Align(
                                  child: SizedBox(
                                    width: 102 * fem,
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
                                    width: 77.77 * fem,
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
                                    width: 100 * fem,
                                    height: 13 * fem,
                                    child: Text(
                                      'Total Physical Box',
                                      style: safeGoogleFont(
                                        'Roboto',
                                        fontSize: 10 * ffem,
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
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: box,
                                      builder:
                                          (
                                            BuildContext context,
                                            int value,
                                            Widget? child,
                                          ) {
                                            return Text(
                                              value.toString(),
                                              style: safeGoogleFont(
                                                'Roboto',
                                                fontSize: 16 * ffem,
                                                fontWeight: FontWeight.w400,
                                                height: 1.1725 * ffem / fem,
                                                color: const Color(0xff000000),
                                              ),
                                              textAlign: TextAlign.left,
                                            );
                                          },
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
                  SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 46 * fem,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 100 * fem,
                                      child: GestureDetector(
                                        onTap: () {
                                          _controllerbox =
                                              TextEditingController(
                                                text: box.value.toString(),
                                              );
                                          _controllerbun =
                                              TextEditingController(
                                                text: bun.value.toString(),
                                              );
                                          typeIndexbox = box.value;
                                          typeIndexbun = bun.value;
                                          tabs = 0;
                                          setState(() {
                                            _showMyDialog(indetail, "bun");
                                          });
                                        },
                                        child: SizedBox(
                                          height: double.infinity,
                                          child: Stack(
                                            children: [
                                              SizedBox(
                                                height: double.infinity,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      left: 0 * fem,
                                                      top: 6 * fem,
                                                      child: Align(
                                                        child: SizedBox(
                                                          width: 100 * fem,
                                                          height: 40 * fem,
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4 * fem,
                                                                  ),
                                                              border: Border.all(
                                                                color: Color(
                                                                  0xff9c9c9c,
                                                                ),
                                                              ),
                                                              color:
                                                                  Colors.white,
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
                                                          width: 24.77 * fem,
                                                          height: 11 * fem,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
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
                                                            'BUN',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  11 * ffem,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                0xff000000,
                                                              ),
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
                                    SizedBox(width: 10),
                                    SizedBox(
                                      width: 100 * fem,
                                      child: GestureDetector(
                                        onTap: () async {
                                          _controllerbox =
                                              TextEditingController(
                                                text: box.value.toString(),
                                              );
                                          _controllerbun =
                                              TextEditingController(
                                                text: bun.value.toString(),
                                              );
                                          typeIndexbox = box.value;
                                          typeIndexbun = bun.value;
                                          tabs = 1;
                                          setState(() {
                                            _showMyDialog(indetail, "box");
                                          });
                                        },
                                        child: SizedBox(
                                          height: double.infinity,
                                          child: Stack(
                                            children: [
                                              SizedBox(
                                                width: 100 * fem,
                                                height: double.infinity,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      // Background
                                                      left: 0 * fem,
                                                      top: 6 * fem,
                                                      child: Align(
                                                        child: SizedBox(
                                                          width: 100 * fem,
                                                          height: 40 * fem,
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4 * fem,
                                                                  ),
                                                              border: Border.all(
                                                                color: Color(
                                                                  0xff9c9c9c,
                                                                ),
                                                              ),
                                                              color:
                                                                  Colors.white,
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
                                                          width: 25.77 * fem,
                                                          height: 11 * fem,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
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
                                                            'BOX',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  11 * ffem,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                0xff000000,
                                                              ),
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
                                                          child: ValueListenableBuilder<int>(
                                                            valueListenable:
                                                                box,
                                                            builder:
                                                                (
                                                                  BuildContext
                                                                  context,
                                                                  int value,
                                                                  Widget? child,
                                                                ) {
                                                                  return Text(
                                                                    value
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16 *
                                                                          ffem,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: const Color(
                                                                        0xff000000,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                            height: 50 * fem,
                            padding: EdgeInsets.only(right: 10),
                            child: Image.asset('data/images/add_button.png'),
                          ),
                          onDoubleTap: () {},
                          onTap: () async {
                            if (box.value == 0 && bun.value == 0) {
                              EasyLoading.showInfo(
                                'PCS AND CTN Cannot be 0',
                                dismissOnTap: true,
                              );
                            } else {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat(
                                'yyyy-MM-dd kk:mm:ss',
                              ).format(now);

                              InputStockTake input = InputStockTake();
                              input.section = selectedSection.value;
                              input.countBox = box.value;
                              input.countBun = bun.value;
                              input.created = formattedDate;
                              input.createdBy = globalvm.username.value;
                              input.documentNo = widget.stocktake.documentno;
                              input.batchId = selectedBatch.value;
                              input.matnr = indetail.matnr ?? '';
                              input.selectedChoice = indetail.selectedChoice;
                              DateTime originalTime = DateFormat(
                                "yyyy-MM-dd HH:mm:ss",
                              ).parse(widget.stocktake.created);
                              DateTime updatedTime = originalTime.add(
                                Duration(hours: 7),
                              );

                              String result = DateFormat(
                                "yyyy-MM-dd HH:mm:ss",
                              ).format(updatedTime);

                              input.downloadTime = result;
                              input.sapStockBun = conversion(
                                indetail,
                                "Bun",
                                "Bukan Tampilan",
                              );
                              input.isTick = indetail.checkboxValidation.value;

                              var listumrez = indetail.marm!
                                  .where(
                                    (element) =>
                                        element.meinh != "KG" &&
                                        element.meinh != "PAK",
                                  )
                                  .toList();
                              if (listumrez.isNotEmpty) {
                                input.unitBox = listumrez[0].meinh ?? '';
                              } else {
                                var listpcs = indetail.marm!
                                    .where(
                                      (element) => element.umrez!.contains("1"),
                                    )
                                    .toList();
                                input.unitBox = listpcs[0].meinh ?? '';
                              }

                              var listpcs = indetail.marm!
                                  .where(
                                    (element) =>
                                        element.meinh != "KG" &&
                                        element.umrez!.contains("1"),
                                  )
                                  .toList();
                              if (listpcs.isNotEmpty) {
                                input.unitBun = listpcs[0].meinh ?? '';
                              } else {
                                var listpcs = indetail.marm!
                                    .where(
                                      (element) => element.umrez!.contains("1"),
                                    )
                                    .toList();
                                input.unitBun = listpcs[0].meinh ?? '';
                              }

                              input.sloc = indetail.lgort ?? '';
                              input.plant = indetail.werks ?? '';

                              String baseSection = selectedSection.value.split(
                                '-',
                              )[0];
                              var existing = sortListSection.value
                                  .where((e) => e.startsWith('$baseSection-'))
                                  .toList();

                              int nextIndex = existing.length + 1;
                              String newSection = '$baseSection-$nextIndex';

                              sortListSection.value.add(newSection);
                              selectedSection.value = newSection;

                              bun.value = 0;
                              box.value = 0;

                              await stocktickvm.sendtohistory(input);
                              await stocktickvm.forcounted(input);
                            }
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            height: 50 * fem,
                            padding: EdgeInsets.only(right: 5),
                            child: Image.asset(
                              'data/images/add_button_blue.png',
                            ),
                          ),
                          onDoubleTap: () {},
                          onTap: () async {
                            if (box.value == 0 && bun.value == 0) {
                              EasyLoading.showInfo(
                                'PCS AND CTN Cannot be 0',
                                dismissOnTap: true,
                              );
                            } else {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat(
                                'yyyy-MM-dd kk:mm:ss',
                              ).format(now);

                              InputStockTake input = InputStockTake();
                              input.section = selectedSection.value;
                              input.countBox = box.value;
                              input.countBun = bun.value;
                              input.created = formattedDate;
                              input.createdBy = globalvm.username.value;
                              input.documentNo = widget.stocktake.documentno;
                              input.batchId = selectedBatch.value;
                              input.matnr = indetail.matnr ?? '';
                              input.selectedChoice = indetail.selectedChoice;
                              DateTime originalTime = DateFormat(
                                "yyyy-MM-dd HH:mm:ss",
                              ).parse(widget.stocktake.created);

                              // Tambah 7 jam
                              DateTime updatedTime = originalTime.add(
                                Duration(hours: 7),
                              );

                              // Format kembali ke string
                              String result = DateFormat(
                                "yyyy-MM-dd HH:mm:ss",
                              ).format(updatedTime);

                              input.downloadTime = result;
                              input.sapStockBun = conversion(
                                indetail,
                                "Bun",
                                "Bukan Tampilan",
                              );
                              input.isTick = indetail.checkboxValidation.value;
                              var listumrez = indetail.marm!
                                  .where(
                                    (element) =>
                                        element.meinh != "KG" &&
                                        element.meinh != "PAK",
                                  )
                                  .toList();
                              if (listumrez.isNotEmpty) {
                                input.unitBox = listumrez[0].meinh ?? '';
                              } else {
                                var listpcs = indetail.marm!
                                    .where(
                                      (element) => element.umrez!.contains("1"),
                                    )
                                    .toList();
                                input.unitBox = listpcs[0].meinh ?? '';
                              }

                              var listpcs = indetail.marm!
                                  .where(
                                    (element) =>
                                        element.meinh != "KG" &&
                                        element.umrez!.contains("1"),
                                  )
                                  .toList();
                              if (listpcs.isNotEmpty) {
                                input.unitBun = listpcs[0].meinh ?? '';
                              } else {
                                var listpcs = indetail.marm!
                                    .where(
                                      (element) => element.umrez!.contains("1"),
                                    )
                                    .toList();
                                input.unitBun = listpcs[0].meinh ?? '';
                              }

                              input.sloc = indetail.lgort ?? '';
                              input.plant = indetail.werks ?? '';
                              String baseSection = selectedSection.value.split(
                                '-',
                              )[0];
                              int currentNumber =
                                  int.tryParse(baseSection.substring(1)) ?? 0;

                              int newNumber = currentNumber + 1;

                              String newSection =
                                  '${baseSection[0]}$newNumber-1';
                              sortListSection.value.add(newSection);
                              selectedSection.value = newSection;
                              bun.value = 0;
                              box.value = 0;
                              await stocktickvm.sendtohistory(input);
                              await stocktickvm.forcounted(input);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),
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
                              Get.back();
                            });
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
                          onDoubleTap: () {},
                          onTap: () async {
                            EasyLoading.show(
                              status: 'Loading...',
                              maskType: EasyLoadingMaskType.black,
                            );

                            indetail.isApprove = "Y";

                            var detail = stocktickvm.tolistdocument
                                .singleWhere(
                                  (element) =>
                                      element.documentno == widget.documentno,
                                )
                                .detail;

                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat(
                              'yyyy-MM-dd kk:mm:ss',
                            ).format(now);

                            InputStockTake input = InputStockTake();
                            input.section = selectedSection.value;
                            input.countBox = box.value;
                            input.countBun = bun.value;
                            input.created = formattedDate;
                            input.createdBy = globalvm.username.value;
                            input.documentNo = widget.stocktake.documentno;
                            input.batchId = selectedBatch.value;
                            input.matnr = indetail.matnr ?? "";
                            input.selectedChoice = indetail.selectedChoice;

                            DateTime originalTime = DateFormat(
                              "yyyy-MM-dd HH:mm:ss",
                            ).parse(widget.stocktake.created);
                            DateTime updatedTime = originalTime.add(
                              Duration(hours: 7),
                            );
                            String result = DateFormat(
                              "yyyy-MM-dd HH:mm:ss",
                            ).format(updatedTime);
                            input.downloadTime = result;
                            input.sapStockBun = conversion(
                              indetail,
                              "Bun",
                              "Bukan Tampilan",
                            );
                            input.isTick = indetail.checkboxValidation.value;
                            var listumrez = indetail.marm!
                                .where(
                                  (element) =>
                                      element.meinh != "KG" &&
                                      element.meinh != "PAK",
                                )
                                .toList();
                            if (listumrez.isNotEmpty) {
                              input.unitBox = listumrez[0].meinh ?? "";
                            } else {
                              var listpcs = indetail.marm!
                                  .where(
                                    (element) => element.umrez!.contains("1"),
                                  )
                                  .toList();
                              input.unitBox = listpcs[0].meinh ?? "";
                            }

                            var listpcs = indetail.marm!
                                .where(
                                  (element) =>
                                      element.meinh != "KG" &&
                                      element.umrez!.contains("1"),
                                )
                                .toList();
                            if (listpcs.isNotEmpty) {
                              var forpak = listpcs
                                  .where((element) => element.meinh == "PAK")
                                  .toList();
                              if (forpak.isNotEmpty) {
                                input.unitBun = forpak[0].meinh ?? "";
                              } else {
                                input.unitBun = listpcs[0].meinh ?? "";
                              }
                            } else {
                              var fallback = indetail.marm!
                                  .where(
                                    (element) => element.umrez!.contains("1"),
                                  )
                                  .toList();
                              input.unitBun = fallback[0].meinh ?? "";
                            }

                            input.sloc = indetail.lgort ?? "";
                            input.plant = indetail.werks ?? "";

                            await stocktickvm.sendtohistory(input);
                            await stocktickvm.forcounted(input);
                            await stocktickvm.updatedetail(input, detail);

                            setState(() {});

                            EasyLoading.dismiss();
                            Get.back();
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

  Widget _buildSearchField() {
    Logger().e("masuk");
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
      stocktickvm.searchValue.value = newQuery;
      searchWF(newQuery);
    });
  }

  void searchWF(String search) async {
    stocktickvm.searchValue.value = search;
  }

  void _setDefaultSection() {
    try {
      selectedSection.value = sortListSection.value.singleWhere(
        (element) => element.contains('A1-1'),
      );
    } catch (e) {
      Logger().e('Default section not found: $e');
    }
  }

  void fetchSectionsAndUpdate() {
    fetchSectionFromFirestore()
        .then((_) {
          _setDefaultSection();
        })
        .catchError((e) {
          Logger().e('Error fetching sections: $e');
        });
  }

  void _startSearch() {
    setState(() {
      detaillocal.clear();
      var locallist = stocktickvm.tolistdocumentnosame[widget.index].detail;
      for (var i = 0; i < locallist.length; i++) {
        detaillocal.add(locallist[i]);
      }
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
      detaillocal.clear();
      stocktickvm.searchValue.value = '';

      for (var item in detaillocal) {
        stocktickvm.tolistdocumentnosame
            .singleWhere((element) => element.documentno == widget.documentno)
            .detail
            .add(item);
      }

      // Get.to(InDetailPage(index));
    });
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty || _searchQuery.text.isEmpty) {
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
        children: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () async {
              await stocktickvm.listcounted();
              await Get.to(CountedPage(index: widget.index));
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              scanBarcode(); // Ini akan memanggil method baru kita
            },
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      ),
    ];
  }

  // flutter 3.35.5
  // GANTI dengan method baru menggunakan mobile_scanner:
  Future<void> scanBarcode() async {
    setState(() {
      isScanning = true;
    });

    // Tampilkan dialog scanning
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Scan Barcode'),
          content: SizedBox(
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String barcode = barcodes.first.rawValue ?? '';

                        // Tutup dialog
                        Navigator.of(context).pop();

                        // Proses barcode
                        _processScannedBarcode(barcode);
                      }
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.flash_on),
                      onPressed: () {
                        cameraController.toggleTorch();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_rear),
                      onPressed: () {
                        cameraController.switchCamera();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Arahkan kamera ke barcode',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanning = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Method baru untuk memproses barcode yang discan
  void _processScannedBarcode(String barcode) {
    setState(() {
      isScanning = false;
      barcodeScanRes = barcode;
    });

    if (barcodeScanRes.isEmpty) return;

    try {
      final document = stocktickvm.tolistdocument.singleWhereOrNull(
        (element) => element.documentno == widget.documentno,
      );

      if (document == null) return;

      final barcodeItems = document.detail
          .where((element) => element.nORMT.contains(barcodeScanRes))
          .toList();

      if (barcodeItems.isEmpty) {
        barcodeItems.addAll(
          document.detail
              .where(
                (element) => element.matnr?.contains(barcodeScanRes) ?? false,
              )
              .toList(),
        );
      }

      if (barcodeItems.isEmpty) return;

      final list = document.detail
          .where((element) => element.matnr == barcodeItems[0].matnr)
          .toList();

      if (list.isEmpty) return;

      final selectedChoice = list[0].selectedChoice;
      stockbun.value = selectedChoice == 'BLOCK'
          ? list[0].speme
          : selectedChoice == 'QI'
          ? list[0].insme
          : list[0].labst;

      sortListBatch.value.clear();

      if (stocktickvm.tolistforinputstocktake.isEmpty) {
        bun.value = 0;
        box.value = 0;
        fetchSectionsAndUpdate();
      } else {
        final calculate = stocktickvm.tolistforinputstocktake
            .where(
              (element) =>
                  element.selectedChoice == list[0].selectedChoice &&
                  element.section == 'A1-1' &&
                  element.matnr == list[0].matnr,
            )
            .toList();

        if (calculate.isEmpty) {
          bun.value = 0;
          box.value = 0;
          fetchSectionsAndUpdate();
        } else {
          int localpcs = 0;
          int localctn = 0;

          for (final input in calculate) {
            localpcs += input.countBun.toInt();
            localctn += input.countBox;
          }

          bun.value = localpcs.toDouble();
          box.value = localctn;

          final calculate2 = stocktickvm.tolistforinputstocktake
              .where((element) => element.matnr == list[0].matnr)
              .toList();

          calculate2.sort((a, b) => b.created.compareTo(a.created));

          for (final input in calculate2) {
            if (!sortListSection.value.any(
              (element) => element.contains(input.section),
            )) {
              sortListSection.value.add(input.section);
            }
          }

          _setDefaultSection();
        }
      }

      final validDetails = document.detail
          .where(
            (element) =>
                element.labst != 0 && element.insme != 0 && element.speme != 0,
          )
          .toSet()
          .toList();

      if (validDetails.isNotEmpty) {
        totalbox.value = calcultotalbox(validDetails[0]);
        totalbun.value = calculTotalpcs(validDetails[0]);
      }

      localpcsvalue.value = bun.value;
      localctnvalue.value = box.value;

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => modalBottomSheet(barcodeItems[0], barcodeItems),
        );
      }
    } catch (e) {
      Logger().e('Error processing barcode: $e');
      EasyLoading.showError('Error scanning barcode');
    }
  }

  Future _showMyDialogApprove(StocktickModel stockmodel) async {
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
                      'Are you sure to save this stock take document?',
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
                    // autogroupf5ebdRu (UM6eDoseJp3PyzDupvF5EB)
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
                          onDoubleTap: () {},
                          onTap: () async {
                            List<InputStockTake> listlocal = [];
                            var stockyes = stockmodel.detail
                                .where(
                                  (element) =>
                                      element.checkboxValidation.value == true,
                                )
                                .toList();
                            for (var stocklist in stockyes) {
                              var liststock = stocktickvm
                                  .tolistforinputstocktake
                                  .where(
                                    (element) =>
                                        element.matnr == stocklist.matnr,
                                  )
                                  .toList();
                              for (var listinput in liststock) {
                                listlocal.add(listinput);
                              }
                            }
                            if (listlocal.isEmpty) {
                              EasyLoading.dismiss();
                              Get.snackbar(
                                'Warning',
                                'No stock selected to save.',
                              );
                              return;
                            }
                            Map<String, dynamic> payload = {
                              "topic": "immobile-cp-stocktake",
                              "key": "myUniqueKey",
                              "message": {
                                "data": InputStockTake.toMapWithMultipleInputs(
                                  listlocal,
                                ),
                              },
                            };
                            var forreturn = await stocktickvm.producekafka(
                              payload,
                            );
                            if (forreturn == "Message produced successfully") {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat(
                                'yyyy-MM-dd kk:mm:ss',
                              ).format(now);
                              stockmodel.updated = formattedDate;
                              stockmodel.updatedby = globalvm.username.value;
                              await stocktickvm.approveall(stockmodel);

                              Get.back();
                            } else {}
                            EasyLoading.dismiss();
                            Get.back();
                          },
                        ), // )
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

  // flutter 3.35.5
  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return PopScope(
      canPop: allow,
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: Visibility(
            visible: _isApproveVisible(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _onEmailPressed,
                  backgroundColor: Colors.blue,
                  heroTag: "emailBtn",
                  child: const Icon(Icons.email_outlined),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _onApprovePressed,
                  backgroundColor: _getApproveButtonColor(),
                  heroTag: "approveBtn",
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            elevation: 0,
            actions: _buildActions(),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20.0,
              onPressed: _onBackPressed,
            ),
            backgroundColor: Colors.red,
            title: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _isSearching
                  ? _buildSearchField()
                  : TextWidget(
                      text: widget.stocktake.documentno,
                      maxLines: 2,
                      fontSize: 17 * ffem,
                      color: Colors.white,
                    ),
            ),
            centerTitle: false,
          ),
          backgroundColor: kWhiteColor,
          body: Container(
            padding: const EdgeInsets.only(bottom: 25),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Obx(() => _buildHeaderSection(ffem)),
                Obx(() => _buildProductList(ffem)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // flutter 3.35.5
  bool _isApproveVisible() {
    final stock = stocktickvm.tolistdocument.firstWhere(
      (element) => element.documentno == widget.documentno,
    );
    return stock.isapprove == "N";
  }

  // flutter 3.35.5
  Color _getApproveButtonColor() {
    return switch (namechoice) {
      "FZ" => Colors.blue,
      "CH" => Colors.green,
      "ALL" => Colors.orange,
      _ => const Color(0xfff44236),
    };
  }

  // flutter 3.35.5
  void _onEmailPressed() {
    EasyLoading.dismiss();
    Get.snackbar("INFO", "Email Success Terkirim");
  }

  // flutter 3.35.5
  void _onApprovePressed() {
    final stock = stocktickvm.tolistdocument.firstWhere(
      (element) => element.documentno == widget.documentno,
    );
    _showMyDialogApprove(stock);
  }

  // flutter 3.35.5
  void _onBackPressed() {
    GlobalVar.choicecategory = globalvm.choicecategory.value;
    if (GlobalVar.choicecategory != "ALL" && listcategory.isNotEmpty) {
      stocktickvm.onReady();
    }
    Get.back();
  }

  // flutter 3.35.5
  Widget _buildHeaderSection(double ffem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: Get.height * 1 / 20,
          color: Colors.grey[700],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: _getDataCountText(),
                maxLines: 2,
                color: Colors.white,
                fontSize: 16 * ffem,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextWidget(
                  text: globalvm.username.value,
                  color: Colors.white,
                  maxLines: 2,
                  fontSize: 16 * ffem,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: Get.width,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            spacing: 25,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: listchoice
                .map(
                  (e) => ChoiceChip(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    labelStyle: _getChipTextStyle(),
                    backgroundColor: Colors.grey,
                    label: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        e.labelName ?? '',
                        style: TextStyle(fontSize: 16 * ffem),
                      ),
                    ),
                    selected: idPeriodSelected == e.id,
                    onSelected: (_) => _onChipSelected(e),
                    selectedColor: _getChipSelectedColor(),
                    elevation: 10,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // flutter 3.35.5
  String _getDataCountText() {
    final documents = stocktickvm.newListToDocument(
      namechoice,
      stocktickvm.document.value,
    );
    final approvedCount = documents
        .where((element) => element.isApprove == "Y")
        .length;
    return '$approvedCount of ${documents.length} data shown';
  }

  // flutter 3.35.5
  TextStyle _getChipTextStyle() {
    final isLightTheme =
        Theme.of(context).scaffoldBackgroundColor == Colors.grey[100];
    return TextStyle(color: isLightTheme ? Colors.white : Colors.white);
  }

  // flutter 3.35.5
  Color _getChipSelectedColor() {
    return switch (namechoice) {
      "FZ" => Colors.blue,
      "CH" => Colors.green,
      "ALL" => Colors.orange,
      _ => const Color(0xfff44236),
    };
  }

  // flutter 3.35.5
  void _onChipSelected(ItemChoice e) {
    setState(() {
      idPeriodSelected = e.id ?? 0;
      final choice = idPeriodSelected - 1;
      namechoice = listchoice[choice].label ?? '';

      if (namechoice != "ALL") {
        stocktickvm.forDetail();
      } else {
        stocktickvm.forDetailAll();
      }
    });
  }

  // flutter 3.35.5
  Widget _buildProductList(double ffem) {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: stocktickvm
            .newListToDocument(namechoice, stocktickvm.document.value)
            .length,
        itemBuilder: (BuildContext context, int index) {
          final product = stocktickvm.newListToDocument(
            namechoice,
            stocktickvm.document.value,
          )[index];

          return GestureDetector(
            child: Obx(() => headerCard2(product)),
            onTap: () => _onProductTap(product, index),
          );
        },
      ),
    );
  }

  Future<void> _onProductTap(StockTakeDetailModel product, int index) async {
    final isApproved =
        stocktickvm.tolistdocument
            .firstWhere((element) => element.documentno == widget.documentno)
            .isapprove ==
        "Y";

    if (isApproved) return;

    try {
      await _prepareProductDetail(product, index);
      await _showProductBottomSheet(product);
    } catch (e) {
      Logger().e('Error in product tap: $e');
      EasyLoading.showError('Error loading product details');
    }
  }

  // flutter 3.35.5
  Future<void> _prepareProductDetail(
    StockTakeDetailModel product,
    int index,
  ) async {
    sortListBatch.value.clear();

    final productDetails = stocktickvm.tolistdocument
        .firstWhere((element) => element.documentno == widget.documentno)
        .detail
        .where((element) => element.matnr == product.matnr)
        .toList();

    _calculateStockBun(productDetails.first);
    await _initializeCountValues(product, index);
    _calculateTotalValues(product);
  }

  // flutter 3.35.5
  void _calculateStockBun(StockTakeDetailModel productDetail) {
    stockbun.value = switch (productDetail.selectedChoice) {
      "BLOCK" => productDetail.speme,
      "QI" => productDetail.insme,
      _ => productDetail.labst,
    };
  }

  // flutter 3.35.5
  Future<void> _initializeCountValues(
    StockTakeDetailModel product,
    int index,
  ) async {
    if (stocktickvm.tolistforinputstocktake.isEmpty) {
      bun.value = 0;
      box.value = 0;
      await fetchSectionFromFirestore();
      selectedSection.value = sortListSection.value.firstWhere(
        (element) => element.contains("A1-1"),
      );
    } else {
      await _calculateExistingCounts(product, index);
    }
  }

  // flutter 3.35.5
  Future<void> _calculateExistingCounts(
    StockTakeDetailModel product,
    int index,
  ) async {
    List<InputStockTake> calculations = [];

    if (namechoice == "ALL") {
      calculations = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.batchId == selectedBatch.value &&
                element.section == "A1-1" &&
                element.matnr == product.matnr,
          )
          .toList();
    } else {
      calculations = stocktickvm.tolistforinputstocktake
          .where(
            (element) =>
                element.selectedChoice == product.selectedChoice &&
                element.section == "A1-1" &&
                element.matnr == product.matnr,
          )
          .toList();
    }

    if (calculations.isEmpty) {
      bun.value = 0;
      box.value = 0;
      await fetchSectionFromFirestore();
      selectedSection.value = sortListSection.value.firstWhere(
        (element) => element.contains("A1-1"),
      );
    } else {
      _updateCountValues(calculations);
      await _updateSections(product);
    }
  }

  // flutter 3.35.5
  void _updateCountValues(List<InputStockTake> calculations) {
    if (calculations.length > 1) {
      localpcs = 0;
      localctn = 0;
      for (final input in calculations) {
        localpcs += input.countBun;
        localctn += input.countBox;
      }
      bun.value = localpcs;
      box.value = localctn;
    } else {
      bun.value = calculations.first.countBun;
      box.value = calculations.first.countBox;
    }
  }

  // flutter 3.35.5
  Future<void> _updateSections(StockTakeDetailModel product) async {
    final sectionCalculations = stocktickvm.tolistforinputstocktake
        .where(
          (element) =>
              element.batchId == selectedBatch.value &&
              element.matnr == product.matnr &&
              element.selectedChoice == product.selectedChoice,
        )
        .toList();

    sectionCalculations.sort((a, b) => b.created.compareTo(a.created));

    for (final input in sectionCalculations) {
      if (!sortListSection.value.any(
        (element) => element.contains(input.section),
      )) {
        sortListSection.value.add(input.section);
        await fetchSectionFromFirestore();
      }
    }

    selectedSection.value = sortListSection.value.firstWhere(
      (element) => element.contains("A1-1"),
    );
  }

  // flutter 3.35.5
  void _calculateTotalValues(StockTakeDetailModel product) {
    totalbox.value = calcultotalbox(product);
    totalbun.value = calculTotalpcs(product);
    localpcsvalue.value = bun.value;
    localctnvalue.value = box.value;
  }

  // flutter 3.35.5
  Future<void> _showProductBottomSheet(StockTakeDetailModel product) async {
    final productList = stocktickvm.newListToDocument(
      namechoice,
      stocktickvm.document.value,
    );

    await showModalBottomSheet(
      context: context,
      builder: (context) => modalBottomSheet(product, productList),
    );
  }
}

class TableCellWidget extends StatelessWidget {
  final String value;

  const TableCellWidget({required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70.0,
      height: 40.0,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
