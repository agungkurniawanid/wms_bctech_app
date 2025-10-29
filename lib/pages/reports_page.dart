// import 'package:flutter/material.dart';
// import 'package:wms_bctech/config/database_config.dart';
// import 'package:wms_bctech/models/category_model.dart';
// import 'package:wms_bctech/models/details_out_model.dart';
// import 'package:wms_bctech/controllers/global_controller.dart';
// import 'package:wms_bctech/controllers/in_controller.dart';
// import 'package:wms_bctech/controllers/pid_controller.dart';
// import 'package:wms_bctech/controllers/reports_controller.dart';
// import 'package:wms_bctech/controllers/stock_check_controlller.dart';
// import 'package:wms_bctech/controllers/stock_request_controller.dart';
// import 'package:wms_bctech/widgets/text_widget.dart';
// import 'package:intl/intl.dart';
// import 'package:get/get.dart';
// import 'package:wms_bctech/models/item_choice_model.dart' as model;
// import 'package:logger/logger.dart';

// class ReportsPage extends StatefulWidget {
//   const ReportsPage({super.key});

//   @override
//   State<ReportsPage> createState() => _ReportsPageState();
// }

// class _ReportsPageState extends State<ReportsPage> {
//   int idPeriodSelected = 1;
//   List<model.ItemChoice> listchoice = [];
//   List<Category> listcategory = [];
//   InVM inVM = Get.find();
//   StockCheckVM stockcheckVM = Get.find();
//   PidViewModel pidVM = Get.find();
//   StockRequestVM stockrequestVM = Get.find();
//   GlobalVM globalVM = Get.find();
//   ReportsVM reportsVM = Get.find();
//   GlobalKey p4Key = GlobalKey();
//   GlobalKey srKey = GlobalKey();
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();
//   String name = '';
//   ScrollController controller = ScrollController();
//   List<String> sortList = [];

//   @override
//   void initState() {
//     super.initState();
//     String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     if (sortList.isEmpty) {
//       getDataCategory();
//     }

//     reportsVM.choicedate.value = today;
//   }

//   Future<List<String>> getDataCategory() async {
//     reportsVM.choice.value = "";
//     listcategory = await DatabaseHelper.db.getCategoryWithRole("OUT");
//     if (listcategory.isNotEmpty) {
//       for (int i = 0; i < listcategory.length; i++) {
//         if (listcategory[i].inventoryGroupId != "ALL") {
//           sortList.add(listcategory[i].inventoryGroupId ?? "");
//         }
//       }
//     }
//     sortList.add("OT");
//     sortList.add("ALL");
//     reportsVM.choice.value = sortList[0];
//     reportsVM.onReady();
//     return sortList;
//   }

//   String calculTotalpcsbyadmin(String doctype) {
//     int total = 0;
//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where(
//             (element) =>
//                 element.doctype == "SR" &&
//                 element.mblnr != "" &&
//                 element.mblnr != null,
//           )
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calcultotalboxbyadmin(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where(
//             (element) =>
//                 element.doctype == "SR" &&
//                 element.mblnr != "" &&
//                 element.mblnr != null,
//           )
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calculTotalpcsreq(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalItem);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalItem);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calcultotalboxreq(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalItem);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalItem);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calculTotalpcsbycategory(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calcultotalboxbycategory(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         for (var i = 0; i < justout[j].detail!.length; i++) {
//           var justforctn = justout[j].detail![i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       var justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();
//       for (var j = 0; j < justout.length; j++) {
//         var validation = justout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calculTotalpcssr(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       for (var j = 0; j < reportsVM.tolisthistoryout.length; j++) {
//         for (var i = 0; i < reportsVM.tolisthistoryout[j].detail!.length; i++) {
//           var justforctn = reportsVM.tolisthistoryout[j].detail![i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       for (var j = 0; j < reportsVM.tolisthistoryout.length; j++) {
//         var validation = reportsVM.tolisthistoryout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "PCS")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calcultotalboxsr(String doctype) {
//     int total = 0;

//     if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       for (var j = 0; j < reportsVM.tolisthistoryout.length; j++) {
//         for (var i = 0; i < reportsVM.tolisthistoryout[j].detail!.length; i++) {
//           var justforctn = reportsVM.tolisthistoryout[j].detail![i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     } else {
//       for (var j = 0; j < reportsVM.tolisthistoryout.length; j++) {
//         var validation = reportsVM.tolisthistoryout[j].detail!
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();
//         for (var i = 0; i < validation.length; i++) {
//           var justforctn = validation[i].uom
//               .where((element) => element.uom == "CTN")
//               .toList();
//           if (justforctn.isNotEmpty) {
//             total += int.parse(justforctn[0].totalPicked);
//           }
//         }
//       }
//     }

//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calculTotalpcs(String doctype) {
//     double total = 0;

//     if (doctype == "IN") {
//       final justin = reportsVM.tolisthistory
//           .where((element) => element.doctype == "IN")
//           .toList();

//       for (var j = 0; j < justin.length; j++) {
//         final tDataList = justin[j].tData ?? [];
//         for (var i = 0; i < tDataList.length; i++) {
//           total += tDataList[i].qtuom ?? 0;
//         }
//       }
//     } else if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       final justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();

//       for (var j = 0; j < justout.length; j++) {
//         final details = justout[j].detail ?? [];
//         for (var i = 0; i < details.length; i++) {
//           final pcsList = (details[i].uom)
//               .where((element) => element.uom == "PCS")
//               .toList();

//           if (pcsList.isNotEmpty) {
//             total += double.tryParse(pcsList.first.totalPicked) ?? 0;
//           }
//         }
//       }
//     } else {
//       final justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();

//       for (var j = 0; j < justout.length; j++) {
//         final details = (justout[j].detail ?? [])
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();

//         for (var i = 0; i < details.length; i++) {
//           final pcsList = (details[i].uom)
//               .where((element) => element.uom == "PCS")
//               .toList();

//           if (pcsList.isNotEmpty) {
//             total += double.tryParse(pcsList.first.totalPicked) ?? 0;
//           }
//         }
//       }
//     }

//     return total.toString();
//   }

//   String calcultotalbox(String doctype) {
//     int total = 0;

//     if (doctype == "IN") {
//       final justin = reportsVM.tolisthistory
//           .where((element) => element.doctype == "IN")
//           .toList();

//       for (var j = 0; j < justin.length; j++) {
//         final tDataList = justin[j].tData ?? [];
//         for (var i = 0; i < tDataList.length; i++) {
//           total += tDataList[i].qtctn ?? 0;
//         }
//       }
//     } else if (doctype == "OUT" && reportsVM.choice.value == "ALL") {
//       final justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();

//       for (var j = 0; j < justout.length; j++) {
//         final details = justout[j].detail ?? [];
//         for (var i = 0; i < details.length; i++) {
//           final ctnList = (details[i].uom)
//               .where((element) => element.uom == "CTN")
//               .toList();

//           if (ctnList.isNotEmpty) {
//             total += int.tryParse(ctnList.first.totalPicked) ?? 0;
//           }
//         }
//       }
//     } else {
//       final justout = reportsVM.tolisthistory
//           .where((element) => element.doctype == "SR")
//           .toList();

//       for (var j = 0; j < justout.length; j++) {
//         final filteredDetails = (justout[j].detail ?? [])
//             .where(
//               (element) => element.inventoryGroup == reportsVM.choice.value,
//             )
//             .toList();

//         for (var i = 0; i < filteredDetails.length; i++) {
//           final ctnList = (filteredDetails[i].uom)
//               .where((element) => element.uom == "CTN")
//               .toList();

//           if (ctnList.isNotEmpty) {
//             total += int.tryParse(ctnList.first.totalPicked) ?? 0;
//           }
//         }
//       }
//     }

//     return total.toString();
//   }

//   String calcultotalboxwithdoc(List<DetailItem> justout) {
//     int total = 0;
//     var validation = justout
//         .where((element) => element.inventoryGroup == reportsVM.choice.value)
//         .toList();
//     for (var i = 0; i < validation.length; i++) {
//       var justforctn = validation[i].uom
//           .where((element) => element.uom == "CTN")
//           .toList();
//       if (justforctn.isNotEmpty) {
//         total += int.parse(justforctn[0].totalPicked);
//       }
//     }
//     String totalstring = total.toString();
//     return totalstring;
//   }

//   String calculTotalpcswithdoc(List<DetailItem> justout) {
//     int total = 0;
//     var validation = justout
//         .where((element) => element.inventoryGroup == reportsVM.choice.value)
//         .toList();
//     for (var i = 0; i < validation.length; i++) {
//       var justforctn = validation[i].uom
//           .where((element) => element.uom == "PCS")
//           .toList();
//       if (justforctn.isNotEmpty) {
//         total += int.parse(justforctn[0].totalPicked);
//       }
//     }
//     String totalstring = total.toString();
//     return totalstring;
//   }

//   void getchoicechip() async {
//     try {
//       final List<Map<String, String>> data = [
//         {'id': "0", 'label': 'IN', 'labelname': 'IN'},
//         {'id': "1", 'label': 'OUT', 'labelname': 'OUT'},
//       ];

//       setState(() {
//         for (int i = 0; i < data.length; i++) {
//           model.ItemChoice choicelocal = model.ItemChoice(
//             id: i + 1,
//             label: data[i]["label"],
//             labelName: data[i]["labelname"],
//           );
//           listchoice.add(choicelocal);
//         }

//         reportsVM.choicechip.value = listchoice[0].label ?? '';
//         reportsVM.onReady();
//       });
//     } catch (e) {
//       Logger().e(e);
//     }
//   }

//   // flutter 3.35.5 syntax
//   List<Widget> _buildActions() {
//     return [
//       Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today_outlined),
//             onPressed: () async {
//               final currentDate = DateTime.now();

//               final DateTime? newDate = await showDatePicker(
//                 context: context,
//                 initialDate: currentDate,
//                 firstDate: currentDate.subtract(const Duration(days: 365)),
//                 lastDate: currentDate,
//               );

//               if (newDate == null) return;

//               setState(() {
//                 reportsVM.choicedate.value = DateFormat(
//                   'yyyy-MM-dd',
//                 ).format(newDate);
//                 reportsVM.onReady();
//               });
//             },
//           ),
//         ],
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           backgroundColor: Colors.red,
//           title: SizedBox(
//             child: Column(
//               children: [
//                 TextWidget(
//                   text: "Daily Reports",
//                   maxLines: 2,
//                   fontSize: 18,
//                   color: Colors.white,
//                 ),
//                 TextWidget(
//                   text:
//                       "( ${globalVM.dateToString(reportsVM.choicedate.value)} )",
//                   maxLines: 2,
//                   fontSize: 18,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//           actions: _buildActions(),
//           centerTitle: true,
//         ),
//         body: DefaultTabController(
//           initialIndex: 0,
//           length: 2,
//           child: SafeArea(
//             child: Obx(() {
//               return SizedBox(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       color: Colors.red,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(
//                               left: 10.0,
//                               right: 10,
//                               bottom: 5,
//                               top: 8,
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             flex: 5,
//                                             child: SizedBox(
//                                               child: TextWidget(
//                                                 text: 'Total IN',
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             child: TextWidget(
//                                               text: ':',
//                                               fontSize: 13,
//                                             ),
//                                           ),
//                                           Expanded(
//                                             flex: 10,
//                                             child: Container(
//                                               padding: EdgeInsets.only(
//                                                 left: 10,
//                                               ),
//                                               alignment: Alignment.centerLeft,
//                                               child: TextWidget(
//                                                 maxLines: 2,
//                                                 text:
//                                                     "${calcultotalbox("IN")} CTN + ${calculTotalpcs("IN")} PCS",
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             flex: 5,
//                                             child: SizedBox(
//                                               child: TextWidget(
//                                                 text: 'Total Picker',
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             child: TextWidget(
//                                               text: ':',
//                                               fontSize: 13,
//                                             ),
//                                           ),
//                                           Expanded(
//                                             flex: 10,
//                                             child: Container(
//                                               padding: EdgeInsets.only(
//                                                 left: 10,
//                                               ),
//                                               alignment: Alignment.centerLeft,
//                                               child: TextWidget(
//                                                 maxLines: 2,
//                                                 text:
//                                                     "${calcultotalboxbycategory("OUT")} CTN + ${calculTotalpcsbycategory("OUT")} PCS",
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             flex: 5,
//                                             child: SizedBox(
//                                               child: TextWidget(
//                                                 text: 'Total ALL',
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             child: TextWidget(
//                                               text: ':',
//                                               fontSize: 13,
//                                             ),
//                                           ),
//                                           Expanded(
//                                             flex: 10,
//                                             child: Container(
//                                               padding: EdgeInsets.only(
//                                                 left: 10,
//                                               ),
//                                               alignment: Alignment.centerLeft,
//                                               child: TextWidget(
//                                                 maxLines: 2,
//                                                 text:
//                                                     "${calcultotalboxbyadmin("OUT")} CTN + ${calculTotalpcsbyadmin("OUT")} PCS",
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             flex: 5,
//                                             child: SizedBox(
//                                               child: TextWidget(
//                                                 text: 'Total SR',
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             child: TextWidget(
//                                               text: ':',
//                                               fontSize: 13,
//                                             ),
//                                           ),
//                                           Expanded(
//                                             flex: 10,
//                                             child: Container(
//                                               padding: EdgeInsets.only(
//                                                 left: 10,
//                                               ),
//                                               alignment: Alignment.centerLeft,
//                                               child: TextWidget(
//                                                 maxLines: 2,
//                                                 text:
//                                                     "${calcultotalboxsr("OUT")} CTN + ${calculTotalpcssr("OUT")} PCS",
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Obx(() {
//                                   return SizedBox(
//                                     child: DropdownButton(
//                                       dropdownColor: Colors.red,
//                                       icon: Icon(
//                                         Icons.arrow_drop_down,
//                                         color: Colors.white,
//                                       ),
//                                       hint: TextWidget(
//                                         text: 'Sort By ',
//                                         fontSize: 16.0,
//                                       ),
//                                       value: reportsVM.choice.value,
//                                       items: sortList.map((value) {
//                                         return DropdownMenuItem(
//                                           value: value,
//                                           child: TextWidget(
//                                             text: value,
//                                             color: Colors.white,
//                                           ),
//                                         );
//                                       }).toList(),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           reportsVM.choice.value = value ?? '';
//                                           reportsVM.onReady();
//                                         });
//                                       },
//                                     ),
//                                   );
//                                 }),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: reportsVM.tolisthistory.isEmpty
//                           ? Center(
//                               child: SizedBox(
//                                 width: 250,
//                                 height: 250,
//                                 child: Column(
//                                   children: [
//                                     Image.asset(
//                                       'data/images/undrawnodatarekwbl-1-1.png',
//                                       fit: BoxFit.cover,
//                                     ),
//                                     TextWidget(text: "No Data"),
//                                   ],
//                                 ),
//                               ),
//                             )
//                           : SizedBox(
//                               child: SingleChildScrollView(
//                                 scrollDirection: Axis.vertical,
//                                 child: SingleChildScrollView(
//                                   scrollDirection: Axis.horizontal,
//                                   child: Obx(
//                                     () => DataTable(
//                                       // 🔄 Ganti dataRowHeight → dataRowMinHeight & dataRowMaxHeight
//                                       dataRowMinHeight: 40.0,
//                                       dataRowMaxHeight: 40.0,

//                                       columnSpacing: 13.0,

//                                       // 🔄 Ganti MaterialStateColor → WidgetStateColor
//                                       headingRowColor:
//                                           WidgetStateColor.resolveWith(
//                                             (states) => Colors.grey[700]!,
//                                           ),
//                                       headingTextStyle: const TextStyle(
//                                         color: Colors.white,
//                                       ),

//                                       dataRowColor:
//                                           WidgetStateColor.resolveWith(
//                                             (states) => Colors.grey[800]!,
//                                           ),
//                                       dataTextStyle: const TextStyle(
//                                         color: Colors.white,
//                                       ),

//                                       columns: const [
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: Text(
//                                               'Type',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerRight,
//                                             child: Text(
//                                               'Doc No',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: Text(
//                                               'CTN',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: Text(
//                                               'PCS',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: Text(
//                                               'Received By',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.center,
//                                             child: Text(
//                                               'Received',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                         DataColumn(
//                                           label: Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: Text(
//                                               'Doc SAP',
//                                               style: TextStyle(fontSize: 12),
//                                             ),
//                                           ),
//                                         ),
//                                       ],

//                                       rows: reportsVM.tolisthistory.map((item) {
//                                         return DataRow(
//                                           cells: [
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.doctype ?? '',
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.doctype == "IN"
//                                                       ? (item.ebeln ?? "-")
//                                                       : (item.documentNo ??
//                                                             "-"),
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.doctype == "IN"
//                                                       ? '${item.tData!.fold<int>(0, (prev, el) => prev + (el.qtctn ?? 0))}'
//                                                       : calcultotalboxwithdoc(
//                                                           item.detail ?? [],
//                                                         ),
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.doctype == "IN"
//                                                       ? '${item.tData!.fold<double>(0.0, (prev, el) => prev + (el.qtuom ?? 0.0))}'
//                                                       : calculTotalpcswithdoc(
//                                                           item.detail ?? [],
//                                                         ),
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.updatedby ?? '',
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   globalVM.stringToDateWithHour(
//                                                         item.updated ?? '',
//                                                       ) ??
//                                                       '',
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   item.flag == "Y"
//                                                       ? (item.mblnr ?? "")
//                                                       : "",
//                                                   style: const TextStyle(
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         );
//                                       }).toList(),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }
