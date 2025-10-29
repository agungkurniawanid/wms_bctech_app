// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:wms_bctech/constants/utils_constant.dart';
// import 'package:wms_bctech/models/history_model.dart';
// import 'package:wms_bctech/models/in_model.dart';
// import 'package:wms_bctech/models/out_model.dart';
// import 'package:wms_bctech/models/stock_check_model.dart';
// import 'package:wms_bctech/pages/detail_pid_page.dart';
// import 'package:wms_bctech/pages/detail_stock_check_page.dart';
// import 'package:wms_bctech/pages/in_detail_page.dart';
// import 'package:wms_bctech/pages/out_detail_page.dart';
// import 'package:wms_bctech/controllers/global_controller.dart';
// import 'package:wms_bctech/controllers/history_controller.dart';
// import 'package:wms_bctech/controllers/in_controller.dart';
// import 'package:wms_bctech/controllers/pid_controller.dart';
// import 'package:wms_bctech/controllers/stock_check_controlller.dart';
// import 'package:wms_bctech/controllers/stock_request_controller.dart';
// import 'package:wms_bctech/widgets/text_widget.dart';
// import 'package:intl/intl.dart';

// class HistoryPage extends StatefulWidget {
//   const HistoryPage({super.key});

//   @override
//   State<HistoryPage> createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   final InVM inVM = Get.find();
//   final StockCheckVM stockcheckVM = Get.find();
//   final PidViewModel pidVM = Get.find();
//   final StockRequestVM stockrequestVM = Get.find();
//   final GlobalVM globalVM = Get.find();
//   final HistoryViewModel historyVM = Get.find();

//   final ScrollController controller = ScrollController();
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   void _initializeData() {
//     final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     historyVM.selectedDate.value = today;
//     historyVM.onReady();
//   }

//   List<Widget> _buildAppBarActions() {
//     return [
//       IconButton(
//         icon: const Icon(Icons.calendar_today_outlined),
//         onPressed: _selectDate,
//       ),
//     ];
//   }

//   Future<void> _selectDate() async {
//     final DateTime currentDate = DateTime.now();
//     final DateTime? selectedDate = await showDatePicker(
//       context: context,
//       initialDate: currentDate,
//       firstDate: currentDate.subtract(const Duration(days: 365)),
//       lastDate: currentDate,
//     );

//     if (selectedDate == null) return;

//     setState(() {
//       historyVM.selectedDate.value = DateFormat(
//         'yyyy-MM-dd',
//       ).format(selectedDate);
//       historyVM.onReady();
//     });
//   }

//   Widget _buildHistoryItem(HistoryModel historyItem) {
//     final double baseWidth = 360;
//     final double fem = MediaQuery.of(context).size.width / baseWidth;
//     final double ffem = fem * 0.97;

//     Color getDocTypeColor(String? docType) {
//       switch (docType) {
//         case "stockcheck":
//           return Colors.blue;
//         case "PID":
//           return Colors.black;
//         case "SR":
//           return Colors.green;
//         default:
//           return const Color(0xfff44236);
//       }
//     }

//     String getTitle(HistoryModel item) {
//       final docType = item.docType ?? '';
//       if (docType == "IN") {
//         return "$docType - ${item.ebeln}";
//       } else if (docType == "stockcheck" || docType == "PID") {
//         return "${docType.toUpperCase()} - ${item.recordid}";
//       } else {
//         return "$docType - ${item.documentNo}";
//       }
//     }

//     return SizedBox(
//       width: double.infinity,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 2),
//           Container(
//             width: 200 * fem,
//             height: 35 * fem,
//             color: getDocTypeColor(historyItem.docType),
//             child: Center(
//               child: Text(
//                 getTitle(historyItem),
//                 style: safeGoogleFont(
//                   'Roboto',
//                   fontSize: 14 * ffem,
//                   fontWeight: FontWeight.w600,
//                   height: 1.1725 * ffem / fem,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.only(left: 12 * fem),
//                   child: Text(
//                     'Approved By      :   ${historyItem.updatedBy}',
//                     style: safeGoogleFont(
//                       'Roboto',
//                       fontSize: 14 * ffem,
//                       height: 1.1725 * ffem / fem,
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 10),
//                 child: Image.asset(
//                   'data/images/vector-1HV.png',
//                   width: 11 * fem,
//                   height: 30 * fem,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Padding(
//             padding: EdgeInsets.only(left: 12 * fem),
//             child: Text(
//               historyItem is StockModel
//                   ? 'Approved Date  :   ${globalVM.stringToDateWithTime(historyItem.updatedAt ?? '')}'
//                   : 'Approved Date  :   ${globalVM.stringToDateWithTime(historyItem.updated ?? '')}',
//               style: safeGoogleFont(
//                 'Roboto',
//                 fontSize: 14 * ffem,
//                 height: 1.1725 * ffem / fem,
//               ),
//             ),
//           ),
//           if (historyItem.mblnr != null && historyItem.mblnr!.isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Padding(
//               padding: EdgeInsets.only(left: 12 * fem),
//               child: Text(
//                 'Doc No               :   ${historyItem.mblnr}',
//                 style: safeGoogleFont(
//                   'Roboto',
//                   fontSize: 14 * ffem,
//                   height: 1.1725 * ffem / fem,
//                 ),
//               ),
//             ),
//           ],
//           Container(
//             height: 1,
//             color: Colors.grey,
//             margin: EdgeInsets.only(top: 20 * fem),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToDetailPage(HistoryModel historyItem) {
//     if (historyItem.docType == "IN") {
//       final inModel = InModel(
//         tData: historyItem.tData,
//         aedat: historyItem.aedat,
//         approvedate: historyItem.approveDate,
//         bwart: historyItem.bwart,
//         clientid: historyItem.clientId,
//         created: historyItem.created,
//         createdby: historyItem.createdBy,
//         dlvComp: historyItem.dlvComp,
//         doctype: historyItem.docType,
//         ebeln: historyItem.ebeln,
//         ernam: historyItem.ernam,
//         group: historyItem.group,
//         issync: historyItem.isSync,
//         lgort: historyItem.lgort,
//         lifnr: historyItem.lifnr,
//         mblnr: historyItem.mblnr,
//         orgid: historyItem.orgId,
//         truck: historyItem.truck,
//         updated: historyItem.updated,
//         updatedby: historyItem.updatedBy,
//         werks: historyItem.werks,
//       );

//       inVM.tolistPO
//         ..clear()
//         ..add(inModel);
//       Get.to(() => InDetailPage(0, "history", null));
//     } else if (historyItem.docType == "SR") {
//       final outModel = OutModel(
//         postingDate: historyItem.postingDate ?? "20231017",
//         clientId: historyItem.clientId,
//         created: historyItem.created,
//         createdAt: historyItem.createdAt,
//         createdBy: historyItem.createdBy,
//         deliveryDate: historyItem.deliveryDate,
//         detail: historyItem.detail,
//         detailDouble: historyItem.detailDouble,
//         docType: historyItem.docType,
//         documentNo: historyItem.documentNo,
//         inventoryGroup: historyItem.inventoryGroup,
//         item: historyItem.item,
//         location: historyItem.location,
//         locationName: historyItem.locationName,
//         orgId: historyItem.orgId,
//         recordId: historyItem.recordId,
//         totalItem: historyItem.totalItem,
//         totalQuantity: historyItem.totalQuantity,
//         updated: historyItem.updated,
//         updatedBy: historyItem.updatedBy,
//         matDoc: historyItem.mblnr,
//       );

//       stockrequestVM.srOutList
//         ..clear()
//         ..add(outModel);
//       Get.to(
//         () => OutDetailPage(
//           0,
//           "SR",
//           "history",
//           stockrequestVM.srOutList.first.documentNo ?? "",
//         ),
//       );
//     } else if (historyItem.docType == "PID") {
//       final stockModel = StockModel(
//         clientid: historyItem.clientId,
//         color: historyItem.color,
//         created: historyItem.created,
//         createdby: historyItem.createdBy,
//         detail: historyItem.detailStockCheck,
//         doctype: historyItem.docType,
//         formattedUpdatedAt: historyItem.formattedUpdatedAt,
//         isApprove: historyItem.isApprove,
//         isSync: historyItem.isSync,
//         location: historyItem.location,
//         locationName: historyItem.locationName,
//         orgid: historyItem.orgId,
//         recordid: historyItem.recordid,
//         updated: historyItem.updated,
//         updatedAt: historyItem.updatedAt,
//         updatedby: historyItem.updatedBy,
//       );

//       pidVM.tolistpid
//         ..clear()
//         ..add(stockModel);
//       Get.to(() => DetailPidPage(0, "history"));
//     } else {
//       final stockModel = StockModel(
//         clientid: historyItem.clientId,
//         color: historyItem.color,
//         created: historyItem.created,
//         createdby: historyItem.createdBy,
//         detail: historyItem.detailStockCheck,
//         doctype: historyItem.docType,
//         formattedUpdatedAt: historyItem.formattedUpdatedAt,
//         isApprove: historyItem.isApprove,
//         isSync: historyItem.isSync,
//         location: historyItem.location,
//         locationName: historyItem.locationName,
//         orgid: historyItem.orgId,
//         recordid: historyItem.recordid,
//         updated: historyItem.updated,
//         updatedAt: historyItem.updatedAt,
//         updatedby: historyItem.updatedBy,
//       );

//       stockcheckVM.toliststock
//         ..clear()
//         ..add(stockModel);
//       Get.to(() => DetailStockCheckPage(0, "history"));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           backgroundColor: Colors.red,
//           title: TextWidget(text: "History", maxLines: 2, color: Colors.white),
//           actions: _buildAppBarActions(),
//           centerTitle: true,
//         ),
//         body: Column(
//           mainAxisSize: MainAxisSize.max,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Expanded(
//               child: Obx(() {
//                 historyVM.historyList.sort(
//                   (a, b) => (b.updated ?? '').compareTo(a.updated ?? ''),
//                 );

//                 if (historyVM.historyList.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Image.asset(
//                           'data/images/undrawnodatarekwbl-1-1.png',
//                           width: 252,
//                           height: 225,
//                           fit: BoxFit.cover,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No history available',
//                           style: safeGoogleFont(
//                             'Roboto',
//                             fontSize: 16,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   controller: controller,
//                   shrinkWrap: true,
//                   itemCount: historyVM.historyList.length,
//                   itemBuilder: (context, index) {
//                     final historyItem = historyVM.historyList[index];
//                     return GestureDetector(
//                       onTap: () => _navigateToDetailPage(historyItem),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         child: _buildHistoryItem(historyItem),
//                       ),
//                     );
//                   },
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
// }
