import 'package:flutter/material.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart' as model;
import 'package:wms_bctech/pages/in_page.dart';
import 'package:wms_bctech/pages/in_detail_page.dart';
import 'package:wms_bctech/pages/out_detail_page.dart';
import 'package:wms_bctech/pages/out_page.dart';
import 'package:wms_bctech/pages/stock_take_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/controllers/reports_controller.dart';
import 'package:wms_bctech/controllers/stock_check_controlller.dart';
import 'package:wms_bctech/controllers/stock_request_controller.dart';
import 'package:wms_bctech/controllers/weborder_controller.dart';
import 'package:wms_bctech/widgets/recent_in_widget.dart';
import 'package:wms_bctech/widgets/recent_sr_widget.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int idPeriodSelected = 1;
  List<model.ItemChoice> listchoice = [];
  List<Category> listcategory = [];
  List<Category> listforin = [];
  WeborderVM weborderVM = Get.find();
  StockCheckVM stockcheckVM = Get.find();
  StockRequestVM stockrequestVM = Get.find();
  GlobalVM globalVM = Get.find();
  InVM inVM = Get.find();
  ReportsVM reportsVM = Get.find();
  GlobalKey p4Key = GlobalKey();
  GlobalKey srKey = GlobalKey();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    getchoicechip();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
      globalVM.version.value = _packageInfo.version;
    });
  }

  Future<String> getName() async {
    try {
      var document = await FirebaseFirestore.instance
          .collection('user')
          .doc(globalVM.username.value)
          .get();

      if (document.exists) {
        return document.data()?['name'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      Logger().e("Failed to get user name: $e");
      return '';
    }
  }

  void getchoicechip() async {
    try {
      listcategory = await DatabaseHelper.db.getCategoryWithRole("OUT");
      listforin = await DatabaseHelper.db.getCategoryWithRole("IN");

      if (listforin.isNotEmpty) {
        for (int i = 0; i < listforin.length; i++) {
          if (listforin[i].inventoryGroupName == "Others") {
            listforin.removeWhere(
              (element) =>
                  element.inventoryGroupId == listforin[i].inventoryGroupId,
            );
          }
          if (listcategory.any(
            (element) =>
                element.inventoryGroupId == listforin[i].inventoryGroupId,
          )) {
            listcategory.removeWhere(
              (element) =>
                  element.inventoryGroupId == listforin[i].inventoryGroupId,
            );
            listcategory.add(listforin[i]);
          } else {
            listcategory.add(listforin[i]);
          }
        }
      }

      setState(() {
        model.ItemChoice? choiceforall;

        if (listcategory.length == 1) {
          model.ItemChoice choicelocal = model.ItemChoice(
            id: listchoice.length + 1,
            label: listcategory[0].inventoryGroupId,
            labelName: listcategory[0].inventoryGroupName,
          );
          listchoice.add(choicelocal);
        } else {
          for (int i = 0; i < listcategory.length; i++) {
            if (listcategory[i].inventoryGroupName == "All") {
              model.ItemChoice choicelocal = model.ItemChoice(
                id: 10,
                label: listcategory[i].inventoryGroupId,
                labelName: listcategory[i].inventoryGroupName,
              );
              choiceforall = choicelocal;
            } else {
              model.ItemChoice choicelocal = model.ItemChoice(
                id: listchoice.length + 1,
                label: listcategory[i].inventoryGroupId,
                labelName: listcategory[i].inventoryGroupName,
              );
              listchoice.add(choicelocal);
            }
          }
        }

        if (choiceforall != null) {
          listchoice.add(choiceforall);
        }

        globalVM.choicecategory.value = listchoice[0].label ?? '';
        GlobalVar.choicecategory = listchoice[0].label ?? '';
        weborderVM.choiceWO.value = listchoice[0].label ?? '';
        stockrequestVM.choicesr.value = listchoice[0].label ?? '';

        if (listforin.isNotEmpty) {
          inVM.onReady();
        }

        inVM.isLoading.value = false;

        if (listcategory.isNotEmpty) {
          stockrequestVM.onReady();
        }

        stockrequestVM.isLoading.value = false;
      });
    } catch (e) {
      Logger().e(e);
    }
  }

  Widget modalBottomSheet() {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: GlobalVar.height * 0.50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * fem),
          topRight: Radius.circular(24 * fem),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 4 * fem,
            child: Stack(
              children: [
                Positioned(
                  left: 1 * fem,
                  top: 0 * fem,
                  child: Align(
                    child: SizedBox(
                      width: 42 * fem,
                      height: 4 * fem,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20 * fem),
                          color: const Color(0xffd9d9d9),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(1 * fem, 0 * fem, 0 * fem, 36 * fem),
            child: Text(
              'More',
              textAlign: TextAlign.center,
              style: safeGoogleFont(
                'Roboto',
                fontSize: 20 * ffem,
                fontWeight: FontWeight.w600,
                height: 1.1725 * ffem / fem,
                color: const Color(0xff363636),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(37 * fem, 0 * fem, 0 * fem, 48 * fem),
            height: 68 * fem,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureButton(
                  onPressed: () => Get.to(InPage()),
                  icon: 'data/images/login.png',
                  label: 'In',
                  fem: fem,
                  ffem: ffem,
                ),
                SizedBox(width: 40 * fem),
                _buildFeatureButton(
                  onPressed: () => Get.to(OutPage()),
                  icon: 'data/images/logout-rounded-Npj.png',
                  label: 'Out',
                  fem: fem,
                  ffem: ffem,
                ),
                SizedBox(width: 20 * fem),
                _buildFeatureButton(
                  onPressed: () => Get.to(StockTickPage()),
                  icon: 'data/images/adjust.png',
                  label: 'Stock\nTake',
                  fem: fem,
                  ffem: ffem,
                  isMultiLine: true,
                ),
              ],
            ),
          ),
          Container(
            width: 360 * fem,
            height: 1 * fem,
            decoration: const BoxDecoration(color: Color(0xffa8a8a8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required VoidCallback onPressed,
    required String icon,
    required String label,
    required double fem,
    required double ffem,
    bool isMultiLine = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Container(
        padding: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 6.97 * fem),
        width: 68 * fem,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5 * fem),
          boxShadow: [
            BoxShadow(
              color: const Color(0x3f000000),
              offset: Offset(0 * fem, 8 * fem),
              blurRadius: 4 * fem,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(
                0 * fem,
                0 * fem,
                0 * fem,
                7.32 * fem,
              ),
              padding: EdgeInsets.fromLTRB(
                17.78 * fem,
                3.14 * fem,
                18.83 * fem,
                4.18 * fem,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffebebeb),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5 * fem),
                  topRight: Radius.circular(5 * fem),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 31.38 * fem,
                  height: 31.38 * fem,
                  child: Image.asset(icon, fit: BoxFit.contain),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(
                1.05 * fem,
                0 * fem,
                0 * fem,
                0 * fem,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: safeGoogleFont(
                  'Roboto',
                  fontSize: isMultiLine ? 11 * ffem : 12 * ffem,
                  fontWeight: FontWeight.w600,
                  height: 1.1725 * ffem / fem,
                  color: const Color(0xff363636),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: GlobalVar.width,
            decoration: const BoxDecoration(color: Color(0xfff2f2f2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(fem, ffem),
                _buildStockRequestSection(fem, ffem),
                _buildRecentStockRequestSection(fem, ffem),
                _buildRecentPurchaseOrderSection(fem, ffem),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double fem, double ffem) {
    return Container(
      padding: EdgeInsets.fromLTRB(14 * fem, 8 * fem, 14 * fem, 19 * fem),
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('data/images/background-red-dcw.png'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(3 * fem, 0 * fem, 3 * fem, 14 * fem),
            padding: EdgeInsets.fromLTRB(16 * fem, 8 * fem, 7 * fem, 10 * fem),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * fem),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    0 * fem,
                    11 * fem,
                  ),
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          0 * fem,
                          0 * fem,
                          89 * fem,
                          0 * fem,
                        ),
                        constraints: BoxConstraints(maxWidth: 169 * fem),
                        child: FutureBuilder<String>(
                          future: getName(),
                          builder: (context, snapshot) {
                            return Text(
                              'Hello, \n${snapshot.data ?? ''}',
                              style: safeGoogleFont(
                                'Montserrat',
                                fontSize: 20 * ffem,
                                fontWeight: FontWeight.w600,
                                height: 1.2175 * ffem / fem,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    7 * fem,
                    0 * fem,
                  ),
                  width: double.infinity,
                  height: 15 * fem,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          0 * fem,
                          0 * fem,
                          47 * fem,
                          0 * fem,
                        ),
                        height: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Version: ${_packageInfo.version}',
                              style: safeGoogleFont(
                                'Roboto',
                                fontSize: 12 * ffem,
                                fontWeight: FontWeight.w600,
                                height: 1.1725 * ffem / fem,
                                color: const Color(0xffa8a8a8),
                              ),
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
          _buildFeatureButtons(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildFeatureButtons(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      height: 68 * fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMainFeatureButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InPage()),
            ),
            icon: 'data/images/login.png',
            label: 'In',
            fem: fem,
            ffem: ffem,
          ),
          SizedBox(width: 20 * fem),
          _buildMainFeatureButton(
            onPressed: () => Get.to(OutPage()),
            icon: 'data/images/logout-rounded-Npj.png',
            label: 'Out',
            fem: fem,
            ffem: ffem,
          ),
          SizedBox(width: 20 * fem),
          _buildMainFeatureButton(
            onPressed: () => Get.to(StockTickPage()),
            icon: 'data/images/adjust.png',
            label: 'Stock\nTake',
            fem: fem,
            ffem: ffem,
            isMultiLine: true,
          ),
          SizedBox(width: 20 * fem),
          _buildMainFeatureButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => modalBottomSheet(),
            ),
            icon: 'data/images/view-more-Zsy.png',
            label: 'More',
            fem: fem,
            ffem: ffem,
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeatureButton({
    required VoidCallback onPressed,
    required String icon,
    required String label,
    required double fem,
    required double ffem,
    bool isMultiLine = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Container(
        padding: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 6.97 * fem),
        width: 68 * fem,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5 * fem),
          boxShadow: [
            BoxShadow(
              color: const Color(0x3f000000),
              offset: Offset(0 * fem, 8 * fem),
              blurRadius: 4 * fem,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(
                0 * fem,
                0 * fem,
                0 * fem,
                7.32 * fem,
              ),
              padding: EdgeInsets.fromLTRB(
                17.78 * fem,
                3.14 * fem,
                18.83 * fem,
                4.18 * fem,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffebebeb),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5 * fem),
                  topRight: Radius.circular(5 * fem),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 31.38 * fem,
                  height: 31.38 * fem,
                  child: Image.asset(icon, fit: BoxFit.contain),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(
                1.05 * fem,
                0 * fem,
                0 * fem,
                0 * fem,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: safeGoogleFont(
                  'Roboto',
                  fontSize: isMultiLine ? 11 * ffem : 12 * ffem,
                  fontWeight: FontWeight.w600,
                  height: 1.1725 * ffem / fem,
                  color: const Color(0xff363636),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockRequestSection(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            child: Text(
              'Recent Stock Request',
              style: safeGoogleFont(
                'Montserrat',
                fontSize: 17 * ffem,
                fontWeight: FontWeight.w600,
                height: 1.2175 * ffem / fem,
                color: const Color(0xff202020),
              ),
            ),
          ),
          _buildCategory(context),
        ],
      ),
    );
  }

  Widget _buildRecentStockRequestSection(double fem, double ffem) {
    return Container(
      width: GlobalVar.width,
      height: GlobalVar.height * 0.20,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: GlobalVar.height * 0.30,
            width: GlobalVar.width,
            child: Obx(() {
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                ),
                itemCount: stockrequestVM.srOutList.length <= 10
                    ? stockrequestVM.srOutList.length
                    : 10,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Container(
                        key: index == 0 ? srKey : null,
                        child: Column(children: [RecentSR(index: index)]),
                      ),
                    ),
                    onTap: () async {
                      Get.to(
                        OutDetailPage(
                          index,
                          "SR",
                          "outpage",
                          stockrequestVM.srOutList[index].documentNo ?? "",
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchaseOrderSection(double fem, double ffem) {
    return Container(
      width: GlobalVar.width,
      height: GlobalVar.height * 0.30 + 10,
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        width: GlobalVar.width,
        height: GlobalVar.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              child: Align(
                child: Text(
                  ' Recent Purchase Order',
                  style: safeGoogleFont(
                    'Montserrat',
                    fontSize: 16 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.2175 * ffem / fem,
                    color: const Color(0xff202020),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: GlobalVar.height * 0.30,
              width: GlobalVar.width,
              child: Obx(() {
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                  ),
                  itemCount: inVM.tolistPO.length <= 10
                      ? inVM.tolistPO.length
                      : 10,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          key: index == 0 ? p4Key : null,
                          child: Column(children: [RecentIn(index: index)]),
                        ),
                      ),
                      onTap: () async {
                        Get.to(InDetailPage(index, "home", null));
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(BuildContext context) {
    return SizedBox(
      child: Wrap(
        spacing: 10,
        children: listchoice
            .map(
              (e) => ChoiceChip(
                padding: const EdgeInsets.only(left: 10, right: 10),
                labelStyle: TextStyle(
                  color: idPeriodSelected == e.id ? Colors.white : Colors.white,
                ),
                backgroundColor: Colors.grey,
                label: Text(e.labelName ?? ""),
                selected: idPeriodSelected == e.id,
                onSelected: (_) {
                  try {
                    setState(() {
                      idPeriodSelected = e.id ?? 0;
                      if (e.id == 10) {
                        GlobalVar.choicecategory = "ALL";
                        globalVM.choicecategory.value = "ALL";
                      } else {
                        int choice = idPeriodSelected - 1;
                        GlobalVar.choicecategory =
                            listchoice[choice].label ?? "";
                        globalVM.choicecategory.value =
                            listchoice[choice].label ?? "";
                      }

                      stockrequestVM.choicesr.value =
                          globalVM.choicecategory.value;
                      stockrequestVM.srOutList.value = stockrequestVM
                          .srBackupList
                          .where(
                            (element) =>
                                (element.inventoryGroup?.contains(
                                  GlobalVar.choicecategory,
                                ) ??
                                false),
                          )
                          .toList();

                      if (listcategory.isNotEmpty) {
                        stockrequestVM.onReady();
                      }

                      stockrequestVM.isLoading.value = false;
                      inVM.isLoading.value = false;

                      if (listforin.isNotEmpty) {
                        inVM.onReady();
                      }
                    });
                  } catch (e) {
                    Logger().e(e);
                  }
                },
                selectedColor: _getSelectedColor(globalVM.choicecategory.value),
                elevation: 10,
              ),
            )
            .toList(),
      ),
    );
  }

  Color _getSelectedColor(String category) {
    switch (category) {
      case "FZ":
        return Colors.blue;
      case "CH":
        return Colors.green;
      case "ALL":
        return Colors.orange;
      default:
        return const Color(0xfff44236);
    }
  }
}
