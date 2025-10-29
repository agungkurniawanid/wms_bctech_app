// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:wms_bctech/config/database_config.dart';
// import 'package:wms_bctech/config/global_variable_config.dart';
// import 'package:wms_bctech/constants/theme_constant.dart';
// import 'package:wms_bctech/models/category_model.dart';
// import 'package:wms_bctech/models/detail_double_out_model.dart';
// import 'package:wms_bctech/models/out_detail_model.dart';
// import 'package:wms_bctech/models/item_choice_model.dart';
// import 'package:wms_bctech/models/out_model.dart';
// import 'package:wms_bctech/pages/my_dialog_page.dart';
// import 'package:wms_bctech/controllers/global_controller.dart';
// import 'package:wms_bctech/controllers/out_controller.dart';
// import 'package:wms_bctech/controllers/weborder_controller.dart';
// import 'package:wms_bctech/widgets/out_card_widget.dart';
// import 'package:wms_bctech/widgets/text_widget.dart';
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:lottie/lottie.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class OutDetailPage extends StatefulWidget {
//   final int index;
//   final dynamic choice;
//   final String from;
//   final String documentno;

//   const OutDetailPage(
//     this.index,
//     this.choice,
//     this.from,
//     this.documentno, {
//     super.key,
//   });

//   @override
//   OutDetailPageState createState() => OutDetailPageState();
// }

// class OutDetailPageState extends State<OutDetailPage>
//     with TickerProviderStateMixin {
//   late final AnimationController _controller;
//   bool allow = true;
//   int idPeriodSelected = 1;
//   List<String> sortList = ['PO Date', 'Vendor'];
//   final GlobalVM globalVM = Get.find();
//   List<ItemChoice> listchoice = [];
//   List<Category> listcategory = [];
//   ScrollController? controller;
//   bool leading = true;
//   final GlobalKey srKey = GlobalKey();
//   bool _isSearching = false;
//   final GlobalKey<FormState> keypcs = GlobalKey<FormState>();
//   final pcsFieldKey = GlobalKey<FormFieldState<String>>();
//   final GlobalKey<FormState> keyctn = GlobalKey<FormState>();
//   final ctnFieldKey = GlobalKey<FormFieldState<String>>();
//   final TextEditingController pcsinput = TextEditingController();
//   final TextEditingController ctninput = TextEditingController();
//   TextEditingController? _controllerctn;
//   TextEditingController? _controllerpcs;
//   List<DetailItem> listdetailitem = [];
//   int typeIndexctn = 0;
//   int typeIndexpcs = 0;
//   late OutModel cloned;
//   final WeborderVM weborderVM = Get.find();
//   final StockRequestVM stockrequestVM = Get.find();
//   List<TextEditingController> listpcsinput = [];
//   List<TextEditingController> listctninput = [];
//   var listsrlocal = <OutModel>[].obs;
//   final FocusNode _focusNode = FocusNode();
//   int tabs = 0;
//   final Map<int, Widget> myTabs = const <int, Widget>{
//     0: Text("CTN"),
//     1: Text("PCS"),
//   };
//   final ValueNotifier<int> pickedpcs = ValueNotifier<int>(0);
//   final ValueNotifier<int> pickedctn = ValueNotifier<int>(0);
//   bool anypcs = false;
//   bool anyctn = false;
//   int? backupctn;
//   int? backuppcs;
//   late final TextEditingController _searchQuery;
//   String? ebeln;
//   String? barcodeScanRes;
//   String? searchQuery;
//   static const EventChannel scannerEventChannel = EventChannel(
//     'zebra_scanner_events',
//   );
//   late BuildContext contextLocal;
//   bool scanforbarcode = false;

//   // TAMBAH ini:
//   MobileScannerController cameraController = MobileScannerController(
//     formats: [BarcodeFormat.all],
//     facing: CameraFacing.back,
//     torchEnabled: false,
//   );

//   bool isScanning = false;

//   String barcodeString = "Barcode will be shown here";
//   String barcodeSymbology = "Symbology will be shown here";
//   String scanTime = "Scan Time will be shown here";

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(vsync: this);
//     stockrequestVM.validationDocumentNo = widget.documentno;

//     contextLocal = context;
//     _searchQuery = TextEditingController();

//     final filteredList = stockrequestVM.srOutList
//         .where((element) => element.documentNo == widget.documentno)
//         .toList();

//     if (filteredList.isNotEmpty) {
//       cloned = filteredList[0].clone();
//     } else {
//       throw Exception("Document no ${widget.documentno} not found");
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _searchQuery.dispose();
//     pcsinput.dispose();
//     ctninput.dispose();
//     _focusNode.dispose();
//     cameraController.dispose(); // TAMBAH ini
//     for (var c in listpcsinput) {
//       c.dispose();
//     }
//     for (var c in listctninput) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> showMyDialogAnimation(String type) async {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         _controller.reset();
//         _controller.forward();

//         _controller.addStatusListener((status) {
//           if (status == AnimationStatus.completed) {
//             Timer(const Duration(seconds: 2), () {
//               if (!dialogContext.mounted) {
//                 return;
//               }
//               Navigator.of(dialogContext).pop();
//             });
//           }
//         });

//         return Material(
//           type: MaterialType.transparency,
//           child: AlertDialog(
//             content: Lottie.asset(
//               type == "reject"
//                   ? 'data/images/reject_animation.json'
//                   : 'data/images/success_animation.json',
//               controller: _controller,
//               onLoaded: (composition) {
//                 _controller.duration = composition.duration;
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<String> getName() async {
//     return await DatabaseHelper.db.getUser() ?? "";
//   }

//   Future<void> _showDialogCheckProduct(DetailItem outmodel) async {
//     double baseWidth = 312;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(15)),
//             ),
//             content: SizedBox(
//               height: MediaQuery.of(context).size.height / 4,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       1 * fem,
//                       15.5 * fem,
//                     ),
//                     width: 35 * fem,
//                     height: 35 * fem,
//                     child: Image.asset(
//                       'data/images/mdi-warning-circle-vJo.png',
//                       width: 35 * fem,
//                       height: 35 * fem,
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       48 * fem,
//                     ),
//                     constraints: BoxConstraints(maxWidth: 256 * fem),
//                     child: Text(
//                       'Please Confirm ${outmodel.itemName}',
//                       textAlign: TextAlign.center,
//                       style: safeGoogleFont(
//                         'Roboto',
//                         fontSize: 16 * ffem,
//                         fontWeight: FontWeight.w600,
//                         height: 1.1725 * ffem / fem,
//                         color: Color(0xff2d2d2d),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );

//     await Future.delayed(Duration(seconds: 3));
//     if (!mounted) return;
//     Navigator.of(context).pop();
//   }

//   Future _showMyDialogApprove(OutModel outmodel) async {
//     double baseWidth = 312;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       // user must tap button!
//       builder: (BuildContext context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(15)),
//             ),
//             content: SizedBox(
//               height: MediaQuery.of(context).size.height / 2.5,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       1 * fem,
//                       15.5 * fem,
//                     ),
//                     width: 35 * fem,
//                     height: 35 * fem,
//                     child: Image.asset(
//                       'data/images/mdi-warning-circle-vJo.png',
//                       width: 35 * fem,
//                       height: 35 * fem,
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       48 * fem,
//                     ),
//                     constraints: BoxConstraints(maxWidth: 256 * fem),
//                     child: Text(
//                       'Are you sure to save all changes made in this Stock Request? ',
//                       textAlign: TextAlign.center,
//                       style: safeGoogleFont(
//                         'Roboto',
//                         fontSize: 16 * ffem,
//                         fontWeight: FontWeight.w600,
//                         height: 1.1725 * ffem / fem,
//                         color: Color(0xff2d2d2d),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     // autogroupf5ebdRu (UM6eDoseJp3PyzDupvF5EB)
//                     width: double.infinity,
//                     height: 25 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           child: Container(
//                             // cancelbutton8Nf (11:1273)
//                             margin: EdgeInsets.fromLTRB(
//                               20 * fem,
//                               0 * fem,
//                               16 * fem,
//                               0 * fem,
//                             ),
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Color(0xfff44236)),
//                               color: Color(0xffffffff),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                             ),
//                             child: Center(
//                               // cancelnCK (11:1275)
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/cancel-viF.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             Get.back();
//                           },
//                         ),
//                         GestureDetector(
//                           child: Container(
//                             // savebuttonSnf (11:1278)
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               color: Color(0xff2cab0c),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Color(0x3f000000),
//                                   offset: Offset(0 * fem, 4 * fem),
//                                   blurRadius: 2 * fem,
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               // checkcircle7du (11:1280)
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/check-circle-fg7.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onDoubleTap: () {},
//                           onTap: () async {
//                             DateTime now = DateTime.now();
//                             String formattedDate = DateFormat(
//                               'yyyy-MM-dd kk:mm:ss',
//                             ).format(now);

//                             // Update updated field di outmodel
//                             outmodel = outmodel.clone();
//                             outmodel.updated = formattedDate;

//                             if (GlobalVar.choicecategory == "ALL") {
//                               if (_isSearching) _clearSearchQuery();

//                               Get.back();
//                               Get.back();
//                               stockrequestVM.validationDocumentNo = "";

//                               final check = await stockrequestVM.approveSR(
//                                 outmodel,
//                                 GlobalVar.choicecategory,
//                               );

//                               if (check == null ||
//                                   check.toString().contains("Failed")) {
//                                 Get.dialog(MyDialogAnimation("reject"));
//                               } else {
//                                 outmodel.isApprove = "Y";
//                                 Get.dialog(MyDialogAnimation("approve"));
//                               }
//                             } else {
//                               final outdetail = (outmodel.detail ?? [])
//                                   .where(
//                                     (element) =>
//                                         element.inventoryGroup ==
//                                         GlobalVar.choicecategory,
//                                   )
//                                   .toList();
//                               final List<DetailItem> updatedDetails = List.from(
//                                 outmodel.detail ?? [],
//                               );
//                               for (var detailItem in outdetail) {
//                                 final index = updatedDetails.indexWhere(
//                                   (element) =>
//                                       element.itemCode == detailItem.itemCode,
//                                 );
//                                 if (index != -1) {
//                                   final newDetail = updatedDetails[index]
//                                       .copyWith(
//                                         isApprove: "Y",
//                                         approveName: await DatabaseHelper.db
//                                             .getUser(),
//                                         updatedAt: formattedDate,
//                                       );
//                                   updatedDetails[index] = newDetail;
//                                 }
//                               }
//                               outmodel.detail = updatedDetails;
//                               final maptdata = (outmodel.detail ?? [])
//                                   .map((person) => person.toMap())
//                                   .toList();

//                               Get.back();
//                               Get.back();
//                               stockrequestVM.validationDocumentNo = "";
//                               final sukses = await stockrequestVM.approveOut(
//                                 outmodel,
//                                 maptdata,
//                               );
//                               if (sukses) {
//                                 Get.dialog(MyDialogAnimation("approve"));
//                               } else {
//                                 Get.dialog(MyDialogAnimation("reject"));
//                               }
//                             }
//                             setState(() {});
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future _showMyDialogReject(OutModel outdetail) async {
//     double baseWidth = 312;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       // user must tap button!
//       builder: (BuildContext context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(15)),
//             ),
//             content: SizedBox(
//               height: MediaQuery.of(context).size.height / 2.5,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     // mdiwarningcircleut4 (11:1225)
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       1 * fem,
//                       15.5 * fem,
//                     ),
//                     width: 35 * fem,
//                     height: 35 * fem,
//                     child: Image.asset(
//                       'data/images/mdi-warning-circle-9um.png',
//                       width: 35 * fem,
//                       height: 35 * fem,
//                     ),
//                   ),
//                   Container(
//                     // areyousuretodiscardallchangesm (11:1227)
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       48 * fem,
//                     ),
//                     constraints: BoxConstraints(maxWidth: 256 * fem),
//                     child: Text(
//                       'Are you sure to discard all changes made in this Stock Request?',
//                       textAlign: TextAlign.center,
//                       style: safeGoogleFont(
//                         'Roboto',
//                         fontSize: 16 * ffem,
//                         fontWeight: FontWeight.w600,
//                         height: 1.1725 * ffem / fem,
//                         color: Color(0xff2d2d2d),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     // autogroupf5ebdRu (UM6eDoseJp3PyzDupvF5EB)
//                     width: double.infinity,
//                     height: 25 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           child: Container(
//                             // cancelbutton8Nf (11:1273)
//                             margin: EdgeInsets.fromLTRB(
//                               20 * fem,
//                               0 * fem,
//                               16 * fem,
//                               0 * fem,
//                             ),
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Color(0xfff44236)),
//                               color: Color(0xffffffff),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                             ),
//                             child: Center(
//                               // cancelnCK (11:1275)
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/cancel-viF.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             final document = stockrequestVM.srOutList
//                                 .firstWhere(
//                                   (element) =>
//                                       element.documentNo == widget.documentno,
//                                 );

//                             final listByInventoryGroup = (document.detail ?? [])
//                                 .where(
//                                   (element) =>
//                                       element.inventoryGroup ==
//                                       GlobalVar.choicecategory,
//                                 )
//                                 .toList();

//                             for (var item in listByInventoryGroup) {
//                               final combine = (cloned.detail ?? [])
//                                   .where(
//                                     (element) =>
//                                         element.itemCode == item.itemCode,
//                                   )
//                                   .toList();

//                               for (var combinedItem in combine) {
//                                 document.detail?.removeWhere(
//                                   (element) =>
//                                       element.itemCode == combinedItem.itemCode,
//                                 );
//                                 document.detail?.add(combinedItem);
//                               }
//                             }

//                             Get.back();
//                           },
//                         ),
//                         GestureDetector(
//                           child: Container(
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               color: Color(0xff2cab0c),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Color(0x3f000000),
//                                   offset: Offset(0 * fem, 4 * fem),
//                                   blurRadius: 2 * fem,
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/check-circle-fg7.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             stockrequestVM.validationDocumentNo = "";

//                             final document = stockrequestVM.srOutList
//                                 .firstWhere(
//                                   (element) =>
//                                       element.documentNo == widget.documentno,
//                                 );

//                             document.detail?.clear();

//                             if (cloned.detail != null &&
//                                 cloned.detail!.isNotEmpty) {
//                               document.detail?.addAll(cloned.detail!);
//                             }
//                             Logger().e(document.detail?.length ?? 0);

//                             Get.back();
//                             Get.back();
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _refreshBottomSheet(DetailItem outdetail) {
//     setState(() {
//       if (widget.choice == "WO") {
//         pickedpcs.value = typeIndexpcs;
//         Get.back();
//       } else {
//         List<DetailDouble> updatedUom = List.from(outdetail.uom);

//         if (outdetail.uom.where((element) => element.uom == "CTN").isNotEmpty) {
//           final ctnIndex = outdetail.uom.indexWhere(
//             (element) => element.uom == "CTN",
//           );
//           if (ctnIndex != -1) {
//             updatedUom[ctnIndex] = updatedUom[ctnIndex].copyWith(
//               totalPicked: typeIndexctn.toString(),
//             );
//             Logger().e(typeIndexctn.toString());
//             pickedctn.value = typeIndexctn;
//           }
//         }

//         if (outdetail.uom.where((element) => element.uom == "PCS").isNotEmpty) {
//           final pcsIndex = outdetail.uom.indexWhere(
//             (element) => element.uom == "PCS",
//           );
//           if (pcsIndex != -1) {
//             updatedUom[pcsIndex] = updatedUom[pcsIndex].copyWith(
//               totalPicked: typeIndexpcs.toString(),
//             );
//             pickedpcs.value = typeIndexpcs;
//           }
//         }
//         Get.back();
//       }
//     });
//   }

//   Future _showMyDialog(
//     DetailItem outdetail,
//     String type,
//     int backupctn,
//     int backuppcs,
//   ) async {
//     double baseWidth = 312;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(Radius.circular(15)),
//             ),
//             content: SizedOverflowBox(
//               size: Size(double.infinity, double.infinity),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
//                     child: Text(
//                       outdetail.itemName,
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Visibility(
//                     visible:
//                         widget.choice == "SR" &&
//                         anyctn == true &&
//                         anypcs == true,
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
//                       child: CupertinoSlidingSegmentedControl(
//                         groupValue: tabs,
//                         children: myTabs,
//                         onValueChanged: (i) {
//                           setState(() {
//                             tabs = i as int;
//                             tabs == 0 ? type = "ctn" : type = "pcs";

//                             type == "ctn"
//                                 ? _controllerctn = TextEditingController(
//                                     text: typeIndexctn.toString(),
//                                   )
//                                 : _controllerpcs = TextEditingController(
//                                     text: typeIndexpcs.toString(),
//                                   );
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: <Widget>[
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: InkWell(
//                           child: Center(
//                             child: Text(
//                               '-',
//                               style: TextStyle(
//                                 color: Colors.red,
//                                 fontSize: 30,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             setState(() {
//                               if (type == "ctn") {
//                                 if (_controllerctn?.text[0] == '0') {
//                                   typeIndexctn = 0;
//                                   _controllerctn = TextEditingController(
//                                     text: typeIndexctn.toString(),
//                                   );
//                                 } else {
//                                   typeIndexctn--;
//                                   _controllerctn = TextEditingController(
//                                     text: typeIndexctn.toString(),
//                                   );
//                                 }
//                               } else {
//                                 if (_controllerpcs?.text[0] == '0') {
//                                   typeIndexpcs = 0;
//                                   _controllerctn = TextEditingController(
//                                     text: typeIndexpcs.toString(),
//                                   );
//                                 } else {
//                                   typeIndexpcs--;
//                                   _controllerpcs = TextEditingController(
//                                     text: typeIndexpcs.toString(),
//                                   );
//                                 }
//                               }
//                             });
//                           },
//                         ),
//                       ),
//                       SizedBox(
//                         width: 50,
//                         height: 50,
//                         child: TextField(
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 20,
//                           ),
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           focusNode: _focusNode,
//                           controller: type == "ctn"
//                               ? _controllerctn
//                               : _controllerpcs,
//                           onChanged: (i) {
//                             setState(() {
//                               if (type == "ctn" && tabs == 0) {
//                                 typeIndexctn = int.parse(
//                                   _controllerctn?.text ?? "",
//                                 );
//                                 if (int.parse(
//                                       outdetail.uom
//                                           .where(
//                                             (element) => element.uom == "CTN",
//                                           )
//                                           .toList()[0]
//                                           .totalItem,
//                                     ) >=
//                                     typeIndexctn) {
//                                   pickedctn.value = typeIndexctn;
//                                 } else {
//                                   pickedctn.value = int.parse(
//                                     outdetail.uom
//                                         .where(
//                                           (element) => element.uom == "CTN",
//                                         )
//                                         .toList()[0]
//                                         .totalItem,
//                                   );
//                                   typeIndexctn = pickedctn.value;
//                                   _controllerctn?.text = pickedctn.value
//                                       .toString();
//                                   _focusNode.unfocus();
//                                 }
//                                 // pickedctn.value = typeIndexctn;
//                               } else if (type == "pcs" && tabs == 1) {
//                                 typeIndexpcs = int.parse(
//                                   _controllerpcs?.text ?? "",
//                                 );
//                                 if (int.parse(
//                                       outdetail.uom
//                                           .where(
//                                             (element) => element.uom == "PCS",
//                                           )
//                                           .toList()[0]
//                                           .totalItem,
//                                     ) >=
//                                     typeIndexpcs) {
//                                   pickedpcs.value = typeIndexpcs;
//                                 } else {
//                                   pickedpcs.value = int.parse(
//                                     outdetail.uom
//                                         .where(
//                                           (element) => element.uom == "PCS",
//                                         )
//                                         .toList()[0]
//                                         .totalItem,
//                                   );
//                                   typeIndexpcs = pickedpcs.value;
//                                   _controllerpcs?.text = pickedpcs.value
//                                       .toString();
//                                   _focusNode.unfocus();
//                                 }
//                               }
//                             });
//                           },
//                         ),
//                       ),
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: InkWell(
//                           child: Center(
//                             child: Text(
//                               '+',
//                               style: TextStyle(
//                                 color: Colors.red,
//                                 fontSize: 30,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             setState(() {
//                               if (widget.choice == "WO") {
//                                 if (typeIndexpcs ==
//                                     int.parse(outdetail.uom[0].totalItem)) {
//                                 } else {
//                                   type == "ctn"
//                                       ? typeIndexctn++
//                                       : typeIndexpcs++;
//                                   type == "ctn"
//                                       ? _controllerctn = TextEditingController(
//                                           text: typeIndexctn.toString(),
//                                         )
//                                       : _controllerpcs = TextEditingController(
//                                           text: typeIndexpcs.toString(),
//                                         );
//                                   pickedpcs.value = typeIndexpcs;
//                                   pickedctn.value = typeIndexctn;
//                                 }
//                               } else {
//                                 if (type == "ctn") {
//                                   if (typeIndexctn >=
//                                       int.parse(
//                                         outdetail.uom
//                                             .where(
//                                               (element) => element.uom == "CTN",
//                                             )
//                                             .toList()[0]
//                                             .totalItem,
//                                       )) {
//                                   } else {
//                                     typeIndexctn++;
//                                     _controllerctn = TextEditingController(
//                                       text: typeIndexctn.toString(),
//                                     );
//                                   }
//                                 } else {
//                                   if (typeIndexpcs >=
//                                       int.parse(
//                                         outdetail.uom
//                                             .where(
//                                               (element) => element.uom == "PCS",
//                                             )
//                                             .toList()[0]
//                                             .totalItem,
//                                       )) {
//                                   } else {
//                                     typeIndexpcs++;
//                                     _controllerpcs = TextEditingController(
//                                       text: typeIndexpcs.toString(),
//                                     );
//                                   }
//                                 }
//                               }
//                             });
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 30),
//                   Align(
//                     alignment: Alignment.center,
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 30 * fem,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           GestureDetector(
//                             child: Container(
//                               margin: EdgeInsets.fromLTRB(
//                                 20 * fem,
//                                 0 * fem,
//                                 16 * fem,
//                                 0 * fem,
//                               ),
//                               padding: EdgeInsets.fromLTRB(
//                                 24 * fem,
//                                 5 * fem,
//                                 25 * fem,
//                                 5 * fem,
//                               ),
//                               height: double.infinity,
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Color(0xfff44236)),
//                                 color: Color(0xffffffff),
//                                 borderRadius: BorderRadius.circular(12 * fem),
//                               ),
//                               child: Center(
//                                 // cancelnCK (11:1275)
//                                 child: SizedBox(
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                   child: Image.asset(
//                                     'data/images/cancel-viF.png',
//                                     width: 30 * fem,
//                                     height: 30 * fem,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             onTap: () {
//                               if (outdetail.uom
//                                   .where((element) => element.uom == "CTN")
//                                   .toList()
//                                   .isNotEmpty) {
//                                 pickedctn.value = backupctn;
//                               }
//                               if (outdetail.uom
//                                   .where((element) => element.uom == "PCS")
//                                   .toList()
//                                   .isNotEmpty) {
//                                 pickedpcs.value = backuppcs;
//                               }
//                               Get.back();
//                             },
//                           ),
//                           GestureDetector(
//                             child: Container(
//                               // savebuttonSnf (11:1278)
//                               padding: EdgeInsets.fromLTRB(
//                                 24 * fem,
//                                 5 * fem,
//                                 25 * fem,
//                                 5 * fem,
//                               ),
//                               height: double.infinity,
//                               decoration: BoxDecoration(
//                                 color: Color(0xff2cab0c),
//                                 borderRadius: BorderRadius.circular(12 * fem),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Color(0x3f000000),
//                                     offset: Offset(0 * fem, 4 * fem),
//                                     blurRadius: 2 * fem,
//                                   ),
//                                 ],
//                               ),
//                               child: Center(
//                                 // checkcircle7du (11:1280)
//                                 child: SizedBox(
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                   child: Image.asset(
//                                     'data/images/check-circle-fg7.png',
//                                     width: 30 * fem,
//                                     height: 30 * fem,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             onTap: () {
//                               _refreshBottomSheet(outdetail);
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget modalBottomSheet(DetailItem outdetail, String type) {
//     double baseWidth = 360;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;
//     return Container(
//       // editoverlayahy (11:1248)
//       margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//       height: GlobalVar.height * 0.85,
//       width: double.infinity,
//       decoration: BoxDecoration(color: Color(0xffffffff)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 child: Text(
//                   outdetail.itemName.length >= 35
//                       ? ' Edit - ${outdetail.itemName.substring(0, 35)}'
//                       : ' Edit - ${outdetail.itemName}',
//                   style: safeGoogleFont(
//                     'Roboto',
//                     fontSize: 16 * ffem,
//                     fontWeight: FontWeight.w600,
//                     height: 1.1725 * ffem / fem,
//                     color: Color(0xfff44236),
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 child: GestureDetector(
//                   child: Image.asset(
//                     'data/images/cancel-viF.png',
//                     width: 30 * fem,
//                     height: 30 * fem,
//                   ),
//                   onTap: () {
//                     scanforbarcode = false;

//                     final ctnItem = outdetail.uom.where(
//                       (element) => element.uom == "CTN",
//                     );
//                     if (ctnItem.isNotEmpty) {
//                       pickedctn.value = int.parse(ctnItem.first.totalPicked);
//                     }

//                     final pcsItem = outdetail.uom.where(
//                       (element) => element.uom == "PCS",
//                     );
//                     if (pcsItem.isNotEmpty) {
//                       pickedpcs.value = int.parse(pcsItem.first.totalPicked);
//                     }

//                     Get.back();
//                   },
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
//             width: double.infinity,
//             height: 1 * fem,
//             decoration: BoxDecoration(color: Color(0xffa8a8a8)),
//           ),
//           Container(
//             margin: EdgeInsets.fromLTRB(120 * fem, 0 * fem, 120 * fem, 6 * fem),
//             padding: EdgeInsets.fromLTRB(
//               5 * fem,
//               31 * fem,
//               6.01 * fem,
//               31 * fem,
//             ),
//             width: double.infinity,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               color: Color(0xffffffff),
//               borderRadius: BorderRadius.circular(8 * fem),
//             ),
//             child: Center(
//               child: SizedBox(
//                 width: 108.99 * fem,
//                 height: 58 * fem,
//                 child: outdetail.itemImage == "kosong"
//                     ? Image.asset(
//                         'data/images/no_image.png',
//                         width: 80 * fem,
//                         height: 80 * fem,
//                       )
//                     : Image.network(
//                         outdetail.itemImage,
//                         width: 30 * fem,
//                         height: 30 * fem,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: Colors.white,
//                             alignment: Alignment.center,
//                             child: Image.asset(
//                               'data/images/no_image.png',
//                               width: 80 * fem,
//                               height: 80 * fem,
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ),
//           Container(
//             // line2wTy (13:502)
//             width: double.infinity,
//             height: 1 * fem,
//             decoration: BoxDecoration(color: Color(0xffa8a8a8)),
//           ),
//           Container(
//             // autogroupnv31UTu (UM6eXdhH31hUxLWjPMnV31)
//             padding: EdgeInsets.fromLTRB(16 * fem, 5 * fem, 16 * fem, 8 * fem),
//             width: double.infinity,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   // materialinputy9m (11:1251)
//                   margin: EdgeInsets.fromLTRB(
//                     0 * fem,
//                     0 * fem,
//                     0 * fem,
//                     7 * fem,
//                   ),
//                   width: double.infinity,
//                   height: 45 * fem,
//                   child: Stack(
//                     children: [
//                       Positioned(
//                         // rectangle17GPm (11:1252)
//                         left: 0 * fem,
//                         top: 5 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 328 * fem,
//                             height: 40 * fem,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(4 * fem),
//                                 border: Border.all(color: Color(0xff9c9c9c)),
//                                 color: Color(0xffe0e0e0),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // rectangle187fH (11:1253)
//                         left: 11 * fem,
//                         top: 0 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 46 * fem,
//                             height: 11 * fem,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Color(0xffffffff),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // materialDCX (11:1254)
//                         left: 11.7142333984 * fem,
//                         top: 0 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 41 * fem,
//                             height: 13 * fem,
//                             child: Text(
//                               'Material',
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 11 * ffem,
//                                 fontWeight: FontWeight.w400,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff000000),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // 4iw (11:1255)
//                         left: 10 * fem,
//                         top: 15 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: GlobalVar.width,
//                             height: 19 * fem,
//                             child: Text(
//                               outdetail.itemCode,
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 16 * ffem,
//                                 fontWeight: FontWeight.w400,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff000000),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   // materialdescriptioninput9Eb (11:1256)
//                   margin: EdgeInsets.fromLTRB(
//                     0 * fem,
//                     0 * fem,
//                     0 * fem,
//                     11 * fem,
//                   ),
//                   width: double.infinity,
//                   height: 45 * fem,
//                   child: Stack(
//                     children: [
//                       Positioned(
//                         // rectangle17RT1 (11:1257)
//                         left: 0 * fem,
//                         top: 5 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 328 * fem,
//                             height: 40 * fem,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(4 * fem),
//                                 border: Border.all(color: Color(0xff9c9c9c)),
//                                 color: Color(0xffe0e0e0),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // rectangle18JWo (11:1258)
//                         left: 11 * fem,
//                         top: 0 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 105 * fem,
//                             height: 11 * fem,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Color(0xffffffff),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // materialdescriptionZhd (11:1259)
//                         left: 12 * fem,
//                         top: 0 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: 99 * fem,
//                             height: 13 * fem,
//                             child: Text(
//                               'Material Description',
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 11 * ffem,
//                                 fontWeight: FontWeight.w400,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff000000),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         // vitasoylemonteadrink250mlEHy (11:1260)
//                         left: 10 * fem,
//                         top: 15 * fem,
//                         child: Align(
//                           child: SizedBox(
//                             width: GlobalVar.width,
//                             height: 19 * fem,
//                             child: Text(
//                               outdetail.itemName,
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 16 * ffem,
//                                 fontWeight: FontWeight.w400,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff2d2d2d),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 Visibility(
//                   visible: widget.choice == "WO",
//                   child: Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       7 * fem,
//                     ),
//                     width: double.infinity,
//                     height: 45 * fem,
//                     child: Stack(
//                       children: [
//                         Positioned(
//                           // rectangle17GPm (11:1252)
//                           left: 0 * fem,
//                           top: 5 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 328 * fem,
//                               height: 40 * fem,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(4 * fem),
//                                   border: Border.all(color: Color(0xff9c9c9c)),
//                                   color: Color(0xffe0e0e0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           // rectangle187fH (11:1253)
//                           left: 11 * fem,
//                           top: 0 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 46 * fem,
//                               height: 11 * fem,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Color(0xffffffff),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           // materialDCX (11:1254)
//                           left: 11.7142333984 * fem,
//                           top: 0 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 41 * fem,
//                               height: 13 * fem,
//                               child: Text(
//                                 'UOM',
//                                 style: safeGoogleFont(
//                                   'Roboto',
//                                   fontSize: 11 * ffem,
//                                   fontWeight: FontWeight.w400,
//                                   height: 1.1725 * ffem / fem,
//                                   color: Color(0xff000000),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           // 4iw (11:1255)
//                           left: 10 * fem,
//                           top: 15 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: GlobalVar.width,
//                               height: 19 * fem,
//                               child: Text(
//                                 outdetail.uom[0].uom,
//                                 style: safeGoogleFont(
//                                   'Roboto',
//                                   fontSize: 16 * ffem,
//                                   fontWeight: FontWeight.w400,
//                                   height: 1.1725 * ffem / fem,
//                                   color: Color(0xff000000),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice == "WO",
//                   child: Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       12 * fem,
//                     ),
//                     width: double.infinity,
//                     height: 46 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Container(
//                           margin: EdgeInsets.fromLTRB(
//                             0 * fem,
//                             0 * fem,
//                             12 * fem,
//                             0 * fem,
//                           ),
//                           width: 162 * fem,
//                           height: double.infinity,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 // rectangle178ec (594:1003)
//                                 left: 0 * fem,
//                                 top: 6 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 162 * fem,
//                                     height: 40 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           4 * fem,
//                                         ),
//                                         border: Border.all(
//                                           color: Color(0xff9c9c9c),
//                                         ),
//                                         color: Color(0xffe0e0e0),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // rectangle18SQQ (594:1004)
//                                 left: 10 * fem,
//                                 top: 1 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 103 * fem,
//                                     height: 13 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Color(0xffffffff),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // requireditemqtyy9S (594:1005)
//                                 left: 11 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 100 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Required Item QTY',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff272727),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // HA8 (594:1006)
//                                 left: 10 * fem,
//                                 top: 16 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 100 * fem,
//                                     height: 19 * fem,
//                                     child: Text(
//                                       outdetail.uom[0].totalItem,
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 16 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           width: 150 * fem,
//                           height: double.infinity,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0 * fem,
//                                 top: 6 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 150 * fem,
//                                     height: 40 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           4 * fem,
//                                         ),
//                                         border: Border.all(
//                                           color: Color(0xff9c9c9c),
//                                         ),
//                                         color: Color(0xffe0e0e0),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 10 * fem,
//                                 top: 1 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 64 * fem,
//                                     height: 13 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Color(0xffffffff),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 10 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 62 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Compatible',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 10 * fem,
//                                 top: 16 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 36 * fem,
//                                     height: 19 * fem,
//                                     child: Text(
//                                       outdetail.compatible,
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 16 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice == "WO",
//                   child: GestureDetector(
//                     child: Container(
//                       // materialinputy9m (11:1251)
//                       margin: EdgeInsets.fromLTRB(
//                         0 * fem,
//                         0 * fem,
//                         0 * fem,
//                         7 * fem,
//                       ),
//                       width: double.infinity,
//                       height: 45 * fem,
//                       child: Stack(
//                         children: [
//                           Positioned(
//                             // rectangle17GPm (11:1252)
//                             left: 0 * fem,
//                             top: 5 * fem,
//                             child: Align(
//                               child: SizedBox(
//                                 width: 328 * fem,
//                                 height: 40 * fem,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(
//                                       4 * fem,
//                                     ),
//                                     border: Border.all(
//                                       color: Color(0xff9c9c9c),
//                                     ),
//                                     // color: Color(0xffe0e0e0),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             // rectangle187fH (11:1253)
//                             left: 11 * fem,
//                             top: 0 * fem,
//                             child: Align(
//                               child: SizedBox(
//                                 width: 80 * fem,
//                                 height: 11 * fem,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: Color(0xffffffff),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             // materialDCX (11:1254)
//                             left: 11.7142333984 * fem,
//                             top: 0 * fem,
//                             child: Align(
//                               child: SizedBox(
//                                 width: 150 * fem,
//                                 height: 13 * fem,
//                                 child: Text(
//                                   'Picked Item QTY',
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 11 * ffem,
//                                     fontWeight: FontWeight.w400,
//                                     height: 1.1725 * ffem / fem,
//                                     color: Color(0xff000000),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             // 4iw (11:1255)
//                             left: 10 * fem,
//                             top: 15 * fem,
//                             child: Align(
//                               child: SizedBox(
//                                 width: GlobalVar.width,
//                                 height: 19 * fem,
//                                 child: ValueListenableBuilder<int>(
//                                   valueListenable: pickedpcs,
//                                   builder: (context, value, child) {
//                                     return Text(
//                                       '$value',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 16 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: const Color(0xff000000),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     onTap: () {
//                       setState(() {
//                         _controllerpcs = TextEditingController(
//                           text: outdetail.uom[0].totalPicked,
//                         );
//                         typeIndexpcs = int.parse(_controllerpcs!.text);
//                       });
//                     },
//                   ),
//                 ),

//                 Visibility(
//                   visible: widget.choice == "SR",

//                   child: Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       7 * fem,
//                     ),
//                     width: double.infinity,
//                     height: 45 * fem,
//                     child: Stack(
//                       children: [
//                         Positioned(
//                           left: 0 * fem,
//                           top: 5 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 328 * fem,
//                               height: 40 * fem,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(4 * fem),
//                                   border: Border.all(color: Color(0xff9c9c9c)),
//                                   color: Color(0xffe0e0e0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 11 * fem,
//                           top: 0 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 60 * fem,
//                               height: 11 * fem,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Color(0xffffffff),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 11.7142333984 * fem,
//                           top: 0 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: 60 * fem,
//                               height: 13 * fem,
//                               child: Text(
//                                 'Compatible',
//                                 style: safeGoogleFont(
//                                   'Roboto',
//                                   fontSize: 11 * ffem,
//                                   fontWeight: FontWeight.w400,
//                                   height: 1.1725 * ffem / fem,
//                                   color: Color(0xff000000),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 10 * fem,
//                           top: 15 * fem,
//                           child: Align(
//                             child: SizedBox(
//                               width: GlobalVar.width,
//                               height: 19 * fem,
//                               child: Text(
//                                 outdetail.compatible,
//                                 style: safeGoogleFont(
//                                   'Roboto',
//                                   fontSize: 16 * ffem,
//                                   fontWeight: FontWeight.w400,
//                                   height: 1.1725 * ffem / fem,
//                                   color: Color(0xff000000),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice == "SR",
//                   child: Container(
//                     // autogroupo4gxU9e (184gc6gbsm3LZWBCTQo4Gx)
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       10 * fem,
//                     ),
//                     width: double.infinity,
//                     height: 46 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Container(
//                           // unitofmeasurementinputoSp (18:833)
//                           margin: EdgeInsets.fromLTRB(
//                             0 * fem,
//                             0 * fem,
//                             12 * fem,
//                             0 * fem,
//                           ),
//                           width: 162 * fem,
//                           height: double.infinity,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 // rectangle17iZn (18:834)
//                                 left: 0 * fem,
//                                 top: 6 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 162 * fem,
//                                     height: 40 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           4 * fem,
//                                         ),
//                                         border: Border.all(color: Colors.red),
//                                         color: Color(0xffe0e0e0),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Align(
//                                 alignment: Alignment.centerRight,
//                                 child: SizedBox(
//                                   width: (() {
//                                     final ctnItem = outdetail.uom.where(
//                                       (e) => e.uom == "CTN",
//                                     );
//                                     if (ctnItem.isEmpty) {
//                                       return GlobalVar.width * 0.15;
//                                     }

//                                     final length =
//                                         ctnItem.first.totalPicked.length;
//                                     return (length == 1 || length == 2)
//                                         ? GlobalVar.width * 0.08
//                                         : GlobalVar.width * 0.15;
//                                   })(),
//                                   height: 19 * fem,
//                                   child: Text(
//                                     (() {
//                                       final ctnItem = outdetail.uom.where(
//                                         (e) => e.uom == "CTN",
//                                       );
//                                       return ctnItem.isNotEmpty
//                                           ? ctnItem.first.totalItem
//                                           : "0";
//                                     })(),
//                                     style: safeGoogleFont(
//                                       'Roboto',
//                                       fontSize: 16 * ffem,
//                                       fontWeight: FontWeight.w400,
//                                       height: 1.1725 * ffem / fem,
//                                       color: const Color(0xff000000),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // rectangle18jUt (596:1050)
//                                 left: 10 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 110 * fem,
//                                     height: 14 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Color(0xffffffff),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // requireditemqtyctnGDv (596:1051)
//                                 left: 11 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 110 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Qty Required (CTN)',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Colors.red,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           width: 153 * fem,
//                           height: double.infinity,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0 * fem,
//                                 top: 6 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 153 * fem,
//                                     height: 40 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           4 * fem,
//                                         ),
//                                         border: Border.all(color: Colors.blue),
//                                         color: Color(0xffe0e0e0),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 10 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 110 * fem,
//                                     height: 14 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Color(0xffffffff),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 11 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 110 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Qty Required (PCS)',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Colors.blue,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Align(
//                                 alignment: Alignment.centerRight,
//                                 child: SizedBox(
//                                   width: (() {
//                                     final pcsItem = outdetail.uom.where(
//                                       (e) => e.uom == "PCS",
//                                     );
//                                     if (pcsItem.isEmpty) {
//                                       return GlobalVar.width * 0.15;
//                                     }

//                                     final length =
//                                         pcsItem.first.totalItem.length;
//                                     return (length == 1 || length == 2)
//                                         ? GlobalVar.width * 0.08
//                                         : GlobalVar.width * 0.15;
//                                   })(),
//                                   height: 19 * fem,
//                                   child: Text(
//                                     (() {
//                                       final pcsItem = outdetail.uom.where(
//                                         (e) => e.uom == "PCS",
//                                       );
//                                       return pcsItem.isNotEmpty
//                                           ? pcsItem.first.totalItem
//                                           : "0";
//                                     })(),
//                                     style: safeGoogleFont(
//                                       'Roboto',
//                                       fontSize: 16 * ffem,
//                                       fontWeight: FontWeight.w400,
//                                       height: 1.1725 * ffem / fem,
//                                       color: const Color(0xff000000),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice == "SR",
//                   child: Container(
//                     margin: EdgeInsets.only(bottom: 10 * fem),
//                     width: double.infinity,
//                     height: 46 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             if (anyctn) {
//                               backupctn = pickedctn.value;
//                               tabs = 0;
//                               _controllerctn = TextEditingController(
//                                 text: pickedctn.value.toString(),
//                               );
//                               typeIndexctn = int.parse(_controllerctn!.text);

//                               if (!anypcs) {
//                                 backuppcs = pickedpcs.value;
//                                 _controllerpcs = TextEditingController(
//                                   text: "0",
//                                 );
//                                 typeIndexpcs = int.parse(_controllerpcs!.text);
//                               } else {
//                                 _controllerpcs = TextEditingController(
//                                   text: pickedpcs.value.toString(),
//                                 );
//                                 typeIndexpcs = int.parse(_controllerpcs!.text);
//                                 backuppcs = pickedpcs.value;
//                               }

//                               _showMyDialog(
//                                 outdetail,
//                                 "ctn",
//                                 backupctn!,
//                                 backuppcs!,
//                               );
//                             } else {
//                               tabs = 0;
//                             }
//                           },
//                           child: Container(
//                             margin: EdgeInsets.only(right: 12 * fem),
//                             width: 162 * fem,
//                             height: double.infinity,
//                             child: Stack(
//                               children: [
//                                 Positioned(
//                                   left: 0,
//                                   top: 6 * fem,
//                                   child: Container(
//                                     width: 162 * fem,
//                                     height: 40 * fem,
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(
//                                         4 * fem,
//                                       ),
//                                       border: Border.all(color: Colors.red),
//                                       color: anyctn
//                                           ? Colors.white
//                                           : Color(0xffe0e0e0),
//                                     ),
//                                   ),
//                                 ),
//                                 Align(
//                                   alignment: Alignment.centerRight,
//                                   child: SizedBox(
//                                     width:
//                                         pickedctn.value.toString().length <= 2
//                                         ? GlobalVar.width * 0.08
//                                         : GlobalVar.width * 0.15,
//                                     height: 19 * fem,
//                                     child: ValueListenableBuilder<int>(
//                                       valueListenable: pickedctn,
//                                       builder: (context, value, child) {
//                                         return Text(
//                                           '$value',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 16 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: const Color(0xff000000),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   left: 10 * fem,
//                                   top: 0,
//                                   child: Container(
//                                     width: 100 * fem,
//                                     height: 14 * fem,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 Positioned(
//                                   left: 11 * fem,
//                                   top: 0,
//                                   child: SizedBox(
//                                     width: 100 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Qty Picked (CTN)',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Colors.red,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             if (anypcs) {
//                               backupctn = pickedctn.value;
//                               backuppcs = pickedpcs.value;
//                               tabs = 1;
//                               _controllerpcs = TextEditingController(
//                                 text: pickedpcs.value.toString(),
//                               );
//                               typeIndexpcs = int.parse(_controllerpcs!.text);

//                               if (!anyctn) {
//                                 backupctn = pickedctn.value;
//                                 _controllerctn = TextEditingController(
//                                   text: "0",
//                                 );
//                                 typeIndexctn = int.parse(_controllerctn!.text);
//                               } else {
//                                 _controllerctn = TextEditingController(
//                                   text: pickedctn.value.toString(),
//                                 );
//                                 typeIndexctn = int.parse(_controllerctn!.text);
//                                 backupctn = pickedctn.value;
//                               }
//                               _showMyDialog(
//                                 outdetail,
//                                 "pcs",
//                                 backupctn!,
//                                 backuppcs!,
//                               );
//                             } else {
//                               tabs = 1;
//                             }
//                           },
//                           child: SizedBox(
//                             width: 153 * fem,
//                             height: double.infinity,
//                             child: Stack(
//                               children: [
//                                 Positioned(
//                                   left: 0,
//                                   top: 6 * fem,
//                                   child: Container(
//                                     width: 153 * fem,
//                                     height: 40 * fem,
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(
//                                         4 * fem,
//                                       ),
//                                       border: Border.all(color: Colors.blue),
//                                       color: anypcs
//                                           ? Colors.white
//                                           : Color(0xffe0e0e0),
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   left: 10 * fem,
//                                   top: 0,
//                                   child: Container(
//                                     width: 110 * fem,
//                                     height: 14 * fem,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 Positioned(
//                                   left: 11 * fem,
//                                   top: 0,
//                                   child: SizedBox(
//                                     width: 110 * fem,
//                                     height: 15 * fem,
//                                     child: Text(
//                                       'Qty Picked (PCS)',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Colors.blue,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 Align(
//                                   alignment: Alignment.centerRight,
//                                   child: SizedBox(
//                                     width:
//                                         pickedpcs.value.toString().length <= 2
//                                         ? GlobalVar.width * 0.08
//                                         : GlobalVar.width * 0.15,
//                                     height: 19 * fem,
//                                     child: ValueListenableBuilder<int>(
//                                       valueListenable: pickedpcs,
//                                       builder: (context, value, child) {
//                                         return Text(
//                                           '$value',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 16 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: const Color(0xff000000),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Visibility(
//                   visible: widget.choice == "SR",
//                   child: Container(
//                     // autogroupf5ebdRu (UM6eDoseJp3PyzDupvF5EB)
//                     margin: EdgeInsets.fromLTRB(
//                       150 * fem,
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                     ),
//                     width: double.infinity,
//                     height: 40 * fem,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           child: Container(
//                             // cancelbutton8Nf (11:1273)
//                             margin: EdgeInsets.fromLTRB(
//                               0 * fem,
//                               0 * fem,
//                               16 * fem,
//                               0 * fem,
//                             ),
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Color(0xfff44236)),
//                               color: Color(0xffffffff),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                             ),
//                             child: Center(
//                               // cancelnCK (11:1275)
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/cancel-viF.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             scanforbarcode = false;

//                             final ctnItem = outdetail.uom.where(
//                               (e) => e.uom == "CTN",
//                             );
//                             if (ctnItem.isNotEmpty) {
//                               pickedctn.value = int.parse(
//                                 ctnItem.first.totalPicked,
//                               );
//                             }

//                             final pcsItem = outdetail.uom.where(
//                               (e) => e.uom == "PCS",
//                             );
//                             if (pcsItem.isNotEmpty) {
//                               pickedpcs.value = int.parse(
//                                 pcsItem.first.totalPicked,
//                               );
//                             }

//                             Get.back();
//                           },
//                         ),
//                         GestureDetector(
//                           child: Container(
//                             padding: EdgeInsets.fromLTRB(
//                               24 * fem,
//                               5 * fem,
//                               25 * fem,
//                               5 * fem,
//                             ),
//                             height: double.infinity,
//                             decoration: BoxDecoration(
//                               color: Color(0xff2cab0c),
//                               borderRadius: BorderRadius.circular(12 * fem),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Color(0x3f000000),
//                                   offset: Offset(0 * fem, 4 * fem),
//                                   blurRadius: 2 * fem,
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               child: SizedBox(
//                                 width: 30 * fem,
//                                 height: 30 * fem,
//                                 child: Image.asset(
//                                   'data/images/check-circle-fg7.png',
//                                   width: 30 * fem,
//                                   height: 30 * fem,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             setState(() {
//                               scanforbarcode = false;

//                               final now = DateTime.now();
//                               final formattedDate = DateFormat(
//                                 'yyyy-MM-dd kk:mm:ss',
//                               ).format(now);

//                               final ctnIndex = outdetail.uom.indexWhere(
//                                 (e) => e.uom == "CTN",
//                               );
//                               if (ctnIndex != -1) {
//                                 final updatedUom = List<DetailDouble>.from(
//                                   outdetail.uom,
//                                 );
//                                 updatedUom[ctnIndex] = updatedUom[ctnIndex]
//                                     .copyWith(
//                                       totalPicked: pickedctn.value.toString(),
//                                     );

//                                 outdetail = outdetail.copyWith(
//                                   uom: updatedUom,
//                                   approveName: globalVM.username.value,
//                                   updatedAt: formattedDate,
//                                 );
//                               }

//                               final pcsIndex = outdetail.uom.indexWhere(
//                                 (e) => e.uom == "PCS",
//                               );
//                               if (pcsIndex != -1) {
//                                 final updatedUom = List<DetailDouble>.from(
//                                   outdetail.uom,
//                                 );
//                                 updatedUom[pcsIndex] = updatedUom[pcsIndex]
//                                     .copyWith(
//                                       totalPicked: pickedpcs.value.toString(),
//                                     );

//                                 outdetail = outdetail.copyWith(
//                                   uom: updatedUom,
//                                   approveName: globalVM.username.value,
//                                   updatedAt: formattedDate,
//                                 );
//                               }

//                               Get.back();
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 //bates
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _calculateCtn(String flag) {
//     try {
//       List<DetailItem> listByInventoryGroup = [];

//       if (stockrequestVM.srOutList.isEmpty) return "0";

//       final srOut = stockrequestVM.srOutList.firstWhere(
//         (element) => element.documentNo == widget.documentno,
//         orElse: () => OutModel(documentNo: "", detail: []),
//       );

//       if (srOut.detail == null) return "0";

//       if (GlobalVar.choicecategory == "ALL" || widget.from == "history") {
//         listByInventoryGroup = srOut.detail!.toList();
//       } else {
//         listByInventoryGroup = srOut.detail!
//             .where(
//               (element) => element.inventoryGroup == GlobalVar.choicecategory,
//             )
//             .toList();
//       }

//       double total = 0;

//       for (var item in listByInventoryGroup) {
//         final ctnUom = item.uom.where((e) => e.uom == "CTN");
//         for (var u in ctnUom) {
//           total += (flag == "required")
//               ? double.tryParse(u.totalItem) ?? 0
//               : double.tryParse(u.totalPicked) ?? 0;
//         }
//       }

//       return total.toInt().toString();
//     } catch (e) {
//       Logger().e(e);
//       return "0";
//     }
//   }

//   String _calculatePcs(String flag) {
//     try {
//       if (stockrequestVM.srOutList.isEmpty) return "0";

//       final srOut = stockrequestVM.srOutList.firstWhere(
//         (element) => element.documentNo == widget.documentno,
//         orElse: () => OutModel(documentNo: "", detail: []),
//       );

//       if (srOut.detail == null) return "0";

//       List<DetailItem> listByInventoryGroup = [];

//       if (GlobalVar.choicecategory == "ALL" || widget.from == "history") {
//         listByInventoryGroup = srOut.detail!.toList();
//       } else {
//         listByInventoryGroup = srOut.detail!
//             .where(
//               (element) => element.inventoryGroup == GlobalVar.choicecategory,
//             )
//             .toList();
//       }

//       double total = 0;

//       for (var item in listByInventoryGroup) {
//         final pcsUom = item.uom.where((e) => e.uom == "PCS");
//         for (var u in pcsUom) {
//           total += (flag == "required")
//               ? double.tryParse(u.totalItem) ?? 0
//               : double.tryParse(u.totalPicked) ?? 0;
//         }
//       }

//       return total.toInt().toString();
//     } catch (e) {
//       Logger().e(e);
//       return "0";
//     }
//   }

//   String calculateTotal(String flag) {
//     try {
//       final ctn = _calculateCtn(flag);
//       final pcs = _calculatePcs(flag);

//       return "$ctn CTN + $pcs PCS";
//     } catch (e) {
//       Logger().e(e);
//       return "0 CTN + 0 PCS";
//     }
//   }

//   String calculateTotalPcs(String flag) {
//     try {
//       final pcs = _calculatePcs(flag);
//       return "+ $pcs PCS";
//     } catch (e) {
//       Logger().e(e);
//       return "+ 0 PCS";
//     }
//   }

//   Widget headerCard2(DetailItem outdetail, int index) {
//     double baseWidth = 360;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;
//     return Container(
//       padding: EdgeInsets.fromLTRB(5 * fem, 6 * fem, 5 * fem, 6 * fem),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 16 * fem, 3 * fem),
//             width: double.infinity,
//             height: outdetail.approveName == "" ? 102 * fem : 130 * fem,
//             decoration: BoxDecoration(
//               color: Color(0xffffffff),
//               borderRadius: BorderRadius.circular(8 * fem),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color(0x3f000000),
//                   offset: Offset(0 * fem, 4 * fem),
//                   blurRadius: 5 * fem,
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   margin: EdgeInsets.fromLTRB(
//                     0 * fem,
//                     0 * fem,
//                     32 * fem,
//                     0 * fem,
//                   ),
//                   height: double.infinity,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         margin: EdgeInsets.fromLTRB(
//                           0 * fem,
//                           0 * fem,
//                           0 * fem,
//                           2 * fem,
//                         ),
//                         constraints: BoxConstraints(maxWidth: 137 * fem),
//                         child: Text(
//                           outdetail.itemName,
//                           style: safeGoogleFont(
//                             'Roboto',
//                             fontSize: 16 * ffem,
//                             fontWeight: FontWeight.w600,
//                             height: 1.1725 * ffem / fem,
//                             color: () {
//                               final ctnList = outdetail.uom
//                                   .where((e) => e.uom == "CTN")
//                                   .toList();
//                               final pcsList = outdetail.uom
//                                   .where((e) => e.uom == "PCS")
//                                   .toList();

//                               if (ctnList.isNotEmpty &&
//                                   pcsList.isNotEmpty &&
//                                   ctnList.first.totalPicked == "0" &&
//                                   pcsList.first.totalPicked == "0") {
//                                 return Colors.red;
//                               }

//                               if (pcsList.isNotEmpty &&
//                                   pcsList.first.totalPicked == "0") {
//                                 return Colors.red;
//                               }

//                               if (ctnList.isNotEmpty &&
//                                   ctnList.first.totalPicked == "0") {
//                                 return Colors.red;
//                               }

//                               if ((outdetail.approveName).isNotEmpty) {
//                                 return Colors.green;
//                               }

//                               return const Color(0xff2d2d2d);
//                             }(),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(
//                           0 * fem,
//                           0 * fem,
//                           0 * fem,
//                           1 * fem,
//                         ),
//                         child: Text(
//                           'SKU: ${outdetail.itemCode}',
//                           style: safeGoogleFont(
//                             'Roboto',
//                             fontSize: 12 * ffem,
//                             fontWeight: FontWeight.w600,
//                             height: 1.1725 * ffem / fem,
//                             color: Color(0xff9a9a9a),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         constraints: BoxConstraints(maxWidth: 140 * fem),
//                         child: RichText(
//                           text: TextSpan(
//                             style: safeGoogleFont(
//                               'Roboto',
//                               fontSize: 12 * ffem,
//                               fontWeight: FontWeight.w600,
//                               height: 1.1725 * ffem / fem,
//                               color: Color(0xff9a9a9a),
//                             ),
//                             children: [
//                               TextSpan(text: 'Required: '),
//                               TextSpan(
//                                 text: outdetail.requiredString,
//                                 style: safeGoogleFont(
//                                   'Roboto',
//                                   fontSize: 12 * ffem,
//                                   fontWeight: FontWeight.w600,
//                                   height: 1.1725 * ffem / fem,
//                                   color: Color(0xff9a9a9a),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Visibility(
//                         visible: outdetail.approveName != "",
//                         child: Container(
//                           constraints: BoxConstraints(maxWidth: 140 * fem),
//                           child: RichText(
//                             text: TextSpan(
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 12 * ffem,
//                                 fontWeight: FontWeight.w600,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff9a9a9a),
//                               ),
//                               children: [
//                                 TextSpan(text: 'Update By: '),
//                                 TextSpan(
//                                   text: outdetail.approveName,
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 12 * ffem,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.1725 * ffem / fem,
//                                     color: Color(0xff9a9a9a),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       Visibility(
//                         visible: outdetail.updatedAt != "",
//                         child: Container(
//                           // required6ctn6pcs3cU (530:1254)
//                           constraints: BoxConstraints(maxWidth: 140 * fem),
//                           child: RichText(
//                             text: TextSpan(
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 12 * ffem,
//                                 fontWeight: FontWeight.w600,
//                                 height: 1.1725 * ffem / fem,
//                                 color: Color(0xff9a9a9a),
//                               ),
//                               children: [
//                                 TextSpan(text: 'Updated: '),
//                                 TextSpan(
//                                   text: outdetail.updatedAt != ""
//                                       ? '${globalVM.stringToDateWithTime(outdetail.updatedAt)}'
//                                       : outdetail.updatedAt,
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 12 * ffem,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.1725 * ffem / fem,
//                                     color: Color(0xff9a9a9a),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice != "WO",
//                   child: Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       19 * fem,
//                       16 * fem,
//                       23 * fem,
//                     ),
//                     width: 50 * fem,
//                     height: double.infinity,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Container(
//                           // autogroupnyzgJdE (184HNmPbYsGtwFKbBpnyzg)
//                           margin: EdgeInsets.fromLTRB(
//                             0 * fem,
//                             0 * fem,
//                             0 * fem,
//                             4 * fem,
//                           ),
//                           width: double.infinity,
//                           height: 28 * fem,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Color(0xffa8a8a8)),
//                             color: Color(0xffffffff),
//                             borderRadius: BorderRadius.circular(8 * fem),
//                           ),
//                           child: Center(
//                             child: Text(
//                               () {
//                                 final ctnList = outdetail.uom
//                                     .where((e) => e.uom == "CTN")
//                                     .toList();
//                                 return ctnList.isEmpty
//                                     ? "0"
//                                     : ctnList.first.totalPicked;
//                               }(),
//                               textAlign: TextAlign.center,
//                               style: safeGoogleFont(
//                                 'Roboto',
//                                 fontSize: 14 * ffem,
//                                 fontWeight: FontWeight.w600,
//                                 height: 1.1725 * ffem / fem,
//                                 color: const Color(0xff2d2d2d),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Text(
//                           // pcsmFv (526:1214)
//                           "CTN",
//                           textAlign: TextAlign.center,
//                           style: safeGoogleFont(
//                             'Roboto',
//                             fontSize: 14 * ffem,
//                             fontWeight: FontWeight.w600,
//                             height: 1.1725 * ffem / fem,
//                             color: Color(0xff272727),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 Container(
//                   margin: EdgeInsets.fromLTRB(
//                     0 * fem,
//                     19 * fem,
//                     16 * fem,
//                     23 * fem,
//                   ),
//                   width: 50 * fem,
//                   height: double.infinity,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         margin: EdgeInsets.fromLTRB(
//                           0 * fem,
//                           0 * fem,
//                           0 * fem,
//                           4 * fem,
//                         ),
//                         width: double.infinity,
//                         height: 28 * fem,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Color(0xffa8a8a8)),
//                           color: Color(0xffffffff),
//                           borderRadius: BorderRadius.circular(8 * fem),
//                         ),
//                         child: Center(
//                           child: Text(
//                             () {
//                               final pcsList = outdetail.uom
//                                   .where((e) => e.uom == "PCS")
//                                   .toList();
//                               return pcsList.isEmpty
//                                   ? "0"
//                                   : pcsList.first.totalPicked;
//                             }(),
//                             textAlign: TextAlign.center,
//                             style: safeGoogleFont(
//                               'Roboto',
//                               fontSize: 14 * ffem,
//                               fontWeight: FontWeight.w600,
//                               height: 1.1725 * ffem / fem,
//                               color: const Color(0xff2d2d2d),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Text(
//                         widget.choice == "SR" ? 'PCS' : outdetail.uom[0].uom,
//                         textAlign: TextAlign.center,
//                         style: safeGoogleFont(
//                           'Roboto',
//                           fontSize: 14 * ffem,
//                           fontWeight: FontWeight.w600,
//                           height: 1.1725 * ffem / fem,
//                           color: Color(0xff272727),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.choice == "SR" && widget.from != "history",
//                   child: Container(
//                     margin: EdgeInsets.fromLTRB(
//                       0 * fem,
//                       0 * fem,
//                       0 * fem,
//                       5 * fem,
//                     ),
//                     width: 12 * fem,
//                     height: 16 * fem,
//                     child: Image.asset(
//                       'data/images/vector-YCb.png',
//                       width: 12 * fem,
//                       height: 16 * fem,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildActions() {
//     if (_isSearching) {
//       return <Widget>[
//         IconButton(
//           icon: const Icon(Icons.clear),
//           onPressed: () {
//             if (_searchQuery.text.isEmpty) {
//               setState(() {
//                 _stopSearching();
//               });
//               return;
//             }
//             _clearSearchQuery();
//           },
//         ),
//       ];
//     }
//     return <Widget>[
//       Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.qr_code),
//             onPressed: () {
//               scanBarcode(); // Ini akan memanggil method baru kita
//             },
//           ),
//           IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
//         ],
//       ),
//     ];
//   }

//   Future<void> scanBarcode() async {
//     // HAPUS implementation lama:
//     /*
//   barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
//     "#ff6666",
//     "Cancel",
//     true,
//     ScanMode.BARCODE,
//   );
//   */

//     // GANTI dengan mobile_scanner:
//     setState(() {
//       isScanning = true;
//     });

//     // Tampilkan dialog scanning
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Scan Barcode'),
//           content: SizedBox(
//             height: 300,
//             child: Column(
//               children: [
//                 Expanded(
//                   child: MobileScanner(
//                     controller: cameraController,
//                     onDetect: (capture) {
//                       final List<Barcode> barcodes = capture.barcodes;
//                       if (barcodes.isNotEmpty) {
//                         final String barcode = barcodes.first.rawValue ?? '';

//                         // Tutup dialog
//                         Navigator.of(context).pop();

//                         // Proses barcode
//                         _processScannedBarcode(barcode);
//                       }
//                     },
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.flash_on),
//                       onPressed: () {
//                         cameraController.toggleTorch();
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.camera_rear),
//                       onPressed: () {
//                         cameraController.switchCamera();
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 setState(() {
//                   isScanning = false;
//                 });
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Method baru untuk memproses barcode yang discan
//   void _processScannedBarcode(String barcode) {
//     setState(() {
//       isScanning = false;
//       barcodeScanRes = barcode;
//     });

//     if (barcodeScanRes == null || barcodeScanRes!.isEmpty) return;

//     final srOut = stockrequestVM.srOutList.firstWhere(
//       (e) => e.documentNo == widget.documentno,
//       orElse: () => OutModel(documentNo: "", detail: []),
//     );

//     if (srOut.detail == null || srOut.detail!.isEmpty) return;

//     final barcodeItems = srOut.detail!
//         .where(
//           (item) => item.uom.any((u) => u.barcode.contains(barcodeScanRes!)),
//         )
//         .toList();

//     if (barcodeItems.isEmpty) return;
//     final barcodeItem = barcodeItems.first;

//     final ctnList = barcodeItem.uom.where((u) => u.uom == "CTN").toList();
//     if (ctnList.isEmpty) {
//       pickedctn.value = 0;
//       anyctn = false;
//     } else {
//       pickedctn.value = int.tryParse(ctnList.first.totalPicked) ?? 0;
//       anyctn = true;
//     }

//     final pcsList = barcodeItem.uom.where((u) => u.uom == "PCS").toList();
//     if (pcsList.isEmpty) {
//       pickedpcs.value = 0;
//       anypcs = false;
//     } else {
//       pickedpcs.value = int.tryParse(pcsList.first.totalPicked) ?? 0;
//       anypcs = true;
//     }

//     scanforbarcode = true;

//     if (!mounted) return;

//     showModalBottomSheet(
//       context: context,
//       builder: (context) =>
//           PopScope(canPop: true, child: modalBottomSheet(barcodeItem, "sr")),
//     );
//   }

//   Widget _buildSearchField() {
//     Logger().e("masuk");
//     return TextField(
//       controller: _searchQuery,
//       autofocus: true,
//       decoration: const InputDecoration(
//         hintText: 'Search...',
//         border: InputBorder.none,
//         hintStyle: TextStyle(color: Colors.white30),
//       ),
//       style: const TextStyle(color: Colors.white, fontSize: 16.0),
//       onChanged: updateSearchQuery,
//     );
//   }

//   void updateSearchQuery(String newQuery) {
//     setState(() {
//       searchQuery = newQuery;
//       searchWF(newQuery);
//     });
//   }

//   void searchWF(String search) async {
//     final srOut = stockrequestVM.srOutList
//         .where((element) => element.documentNo == widget.documentno)
//         .firstOrNull;

//     if (srOut?.detail != null) {
//       srOut!.detail!.clear();
//     }

//     var locallist2 = listdetailitem
//         .where(
//           (element) =>
//               element.itemCode.toLowerCase().contains(search.toLowerCase()),
//         )
//         .toList();

//     var localsku = listdetailitem
//         .where(
//           (element) =>
//               element.itemName.toLowerCase().contains(search.toLowerCase()),
//         )
//         .toList();

//     if (locallist2.isNotEmpty) {
//       for (var i = 0; i < locallist2.length; i++) {
//         final srOut = stockrequestVM.srOutList
//             .where((element) => element.documentNo == widget.documentno)
//             .firstOrNull;

//         if (srOut?.detail != null) {
//           srOut!.detail!.add(locallist2[i]);
//         }
//       }
//     } else if (localsku.isNotEmpty) {
//       for (var i = 0; i < localsku.length; i++) {
//         final srOut = stockrequestVM.srOutList
//             .where((element) => element.documentNo == widget.documentno)
//             .firstOrNull;

//         if (srOut?.detail != null) {
//           srOut!.detail!.add(localsku[i]);
//         }
//       }
//     }
//   }

//   void _startSearch() {
//     setState(() {
//       listdetailitem.clear();
//       final srOut = stockrequestVM.srOutList
//           .where((element) => element.documentNo == widget.documentno)
//           .firstOrNull;

//       if (srOut?.detail != null) {
//         for (var i = 0; i < srOut!.detail!.length; i++) {
//           listdetailitem.add(srOut.detail![i]);
//         }
//       }
//       _isSearching = true;
//     });
//   }

//   void _stopSearching() {
//     _clearSearchQuery();

//     setState(() {
//       _isSearching = false;
//     });
//   }

//   void _clearSearchQuery() {
//     setState(() {
//       _isSearching = false;
//       _searchQuery.clear();
//       _isSearching = false;

//       final srOut = stockrequestVM.srOutList
//           .where((element) => element.documentNo == widget.documentno)
//           .firstOrNull;

//       if (srOut?.detail != null) {
//         srOut!.detail!.clear();
//       }

//       if (srOut?.detail != null) {
//         for (var item in listdetailitem) {
//           srOut!.detail!.add(item);
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     double baseWidth = 360.0028076172;
//     double fem = MediaQuery.of(context).size.width / baseWidth;
//     double ffem = fem * 0.97;
//     return PopScope(
//       canPop: false,
//       child: SafeArea(
//         child: Scaffold(
//           appBar: AppBar(
//             actions: widget.choice == "SR" && widget.from != "history"
//                 ? _buildActions()
//                 : null,
//             automaticallyImplyLeading: false,
//             leading: IconButton(
//               icon: Icon(Icons.arrow_back_ios),
//               iconSize: 20.0,
//               onPressed: () {
//                 if (widget.from != "history") {
//                   _showMyDialogReject(
//                     stockrequestVM.srOutList
//                         .where(
//                           (element) => element.documentNo == widget.documentno,
//                         )
//                         .toList()[0],
//                   );
//                 } else {
//                   Get.back();
//                 }

//                 // Get.back();
//               },
//             ),
//             backgroundColor: Colors.red,
//             title: _isSearching
//                 ? _buildSearchField()
//                 : TextWidget(
//                     text: widget.choice == "WO"
//                         ? "${weborderVM.tolistwoout[widget.index].recordId}"
//                         : "${stockrequestVM.srOutList.where((element) => element.documentNo == widget.documentno).toList()[0].documentNo} ",
//                     maxLines: 2,
//                     fontSize: 20,
//                     color: Colors.white,
//                   ),
//           ),
//           backgroundColor: kWhiteColor,
//           body: Container(
//             height: GlobalVar.height,
//             padding: EdgeInsets.only(top: 10),
//             width: double.infinity,
//             decoration: BoxDecoration(color: Color(0xffffffff)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: Column(
//                     children: [
//                       Container(
//                         margin: EdgeInsets.fromLTRB(
//                           12 * fem,
//                           0 * fem,
//                           12 * fem,
//                           8 * fem,
//                         ),
//                         width: double.infinity,
//                         height: 46 * fem,
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Container(
//                               margin: EdgeInsets.fromLTRB(
//                                 0 * fem,
//                                 0 * fem,
//                                 16 * fem,
//                                 0 * fem,
//                               ),
//                               width: 160 * fem,
//                               height: double.infinity,
//                               child: Stack(
//                                 children: [
//                                   Positioned(
//                                     left: 0 * fem,
//                                     top: 6 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 160 * fem,
//                                         height: 40 * fem,
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(
//                                               4 * fem,
//                                             ),
//                                             border: Border.all(
//                                               color: Color(0xff9c9c9c),
//                                             ),
//                                             color: Color(0xffe0e0e0),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 15.5844726562 * fem,
//                                     top: 0 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 73.77 * fem,
//                                         height: 11 * fem,
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             color: Color(0xffffffff),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 15.5844726562 * fem,
//                                     top: 0 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 66 * fem,
//                                         height: 13 * fem,
//                                         child: Text(
//                                           widget.choice == "WO"
//                                               ? 'Delivery Date'
//                                               : 'Request Date',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 11 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: Color(0xff000000),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 10.8754882812 * fem,
//                                     top: 15 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 81 * fem,
//                                         height: 19 * fem,
//                                         child: Text(
//                                           widget.choice == "WO"
//                                               ? '${weborderVM.tolistWO[widget.index].deliveryDate}'
//                                               : '${globalVM.dateToString(stockrequestVM.srOutList.where((element) => element.documentNo == widget.documentno).toList()[0].deliveryDate ?? "")}',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 16 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: Color(0xff000000),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             SizedBox(
//                               width: 160 * fem,
//                               height: 45 * fem,
//                               child: Stack(
//                                 children: [
//                                   Positioned(
//                                     left: 0 * fem,
//                                     top: 5 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 160 * fem,
//                                         height: 40 * fem,
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(
//                                               4 * fem,
//                                             ),
//                                             border: Border.all(
//                                               color: Color(0xff9c9c9c),
//                                             ),
//                                             color: Color(0xffe0e0e0),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 16 * fem,
//                                     top: 0 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 50 * fem,
//                                         height: 11 * fem,
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             color: Color(0xffffffff),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 16.6667480469 * fem,
//                                     top: 0 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 71 * fem,
//                                         height: 13 * fem,
//                                         child: Text(
//                                           'Location',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 11 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: Color(0xff000000),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     left: 12.2221679688 * fem,
//                                     top: 15 * fem,
//                                     child: Align(
//                                       child: SizedBox(
//                                         width: 95 * fem,
//                                         height: 19 * fem,
//                                         child: Text(
//                                           widget.choice == "WO"
//                                               ? '${weborderVM.tolistWO[widget.index].location}-${weborderVM.tolistWO[widget.index].locationName}'
//                                               : '${stockrequestVM.srOutList.firstWhere((element) => element.documentNo == widget.documentno).locationName}',
//                                           style: safeGoogleFont(
//                                             'Roboto',
//                                             fontSize: 16 * ffem,
//                                             fontWeight: FontWeight.w400,
//                                             height: 1.1725 * ffem / fem,
//                                             color: Color(0xff000000),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Visibility(
//                         visible:
//                             widget.from == "history" &&
//                             stockrequestVM.srOutList
//                                     .where(
//                                       (element) =>
//                                           element.documentNo ==
//                                           widget.documentno,
//                                     )
//                                     .toList()[0]
//                                     .matDoc !=
//                                 null,
//                         child: Container(
//                           // vendorC7u (I11:786;11:390)
//                           margin: EdgeInsets.fromLTRB(
//                             12 * fem,
//                             0 * fem,
//                             12 * fem,
//                             8 * fem,
//                           ),
//                           width: double.infinity,
//                           height: 45 * fem,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 // rectangle17uo1 (I11:786;11:391)
//                                 left: 0 * fem,
//                                 top: 5 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 336 * fem,
//                                     height: 40 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           4 * fem,
//                                         ),
//                                         border: Border.all(
//                                           color: Color(0xff9c9c9c),
//                                         ),
//                                         color: Color(0xffe0e0e0),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // rectangle18Cn7 (I11:786;11:392)
//                                 left: 14 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 50 * fem,
//                                     height: 11 * fem,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Color(0xffffffff),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 // vendor6Mh (I11:786;11:393)
//                                 left: 15 * fem,
//                                 top: 0 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 50 * fem,
//                                     height: 13 * fem,
//                                     child: Text(
//                                       'Doc No SAP',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 11 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 11 * fem,
//                                 top: 15 * fem,
//                                 child: Align(
//                                   child: SizedBox(
//                                     width: 279 * fem,
//                                     height: 19 * fem,
//                                     child: Text(
//                                       '${stockrequestVM.srOutList.where((element) => element.documentNo == widget.documentno).toList()[0].matDoc}',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 16 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(
//                           0 * fem,
//                           0 * fem,
//                           0 * fem,
//                           7 * fem,
//                         ),
//                         width: double.infinity,
//                         height: 1 * fem,
//                         decoration: BoxDecoration(color: Color(0xff9c9c9c)),
//                       ),
//                       //listview
//                       SizedBox(
//                         child: Obx(() {
//                           return Expanded(
//                             child: ListView.builder(
//                               controller: controller,
//                               shrinkWrap: true,
//                               scrollDirection: Axis.vertical,
//                               itemCount: widget.choice == "WO"
//                                   ? weborderVM
//                                             .tolistwoout[widget.index]
//                                             .detail
//                                             ?.length ??
//                                         0
//                                   : widget.choice == "SR" &&
//                                         GlobalVar.choicecategory.contains("ALL")
//                                   ? stockrequestVM.srOutList
//                                             .where(
//                                               (element) =>
//                                                   element.documentNo ==
//                                                   widget.documentno,
//                                             )
//                                             .firstOrNull
//                                             ?.detail
//                                             ?.length ??
//                                         0
//                                   : widget.choice == "SR" &&
//                                         widget.from == "history"
//                                   ? stockrequestVM.srOutList
//                                             .where(
//                                               (element) =>
//                                                   element.documentNo ==
//                                                   widget.documentno,
//                                             )
//                                             .firstOrNull
//                                             ?.detail
//                                             ?.length ??
//                                         0
//                                   : stockrequestVM.srOutList
//                                             .where(
//                                               (element) =>
//                                                   element.documentNo ==
//                                                   widget.documentno,
//                                             )
//                                             .firstOrNull
//                                             ?.detail
//                                             ?.where(
//                                               (element) => element
//                                                   .inventoryGroup
//                                                   .contains(
//                                                     GlobalVar.choicecategory,
//                                                   ),
//                                             )
//                                             .length ??
//                                         0,
//                               itemBuilder: (BuildContext context, int index) {
//                                 listpcsinput.add(TextEditingController());
//                                 listctninput.add(TextEditingController());
//                                 return GestureDetector(
//                                   child: widget.choice == "WO"
//                                       ? headerCard2(
//                                           weborderVM
//                                               .tolistwoout[widget.index]
//                                               .detail![index],
//                                           index,
//                                         )
//                                       : widget.choice == "SR" &&
//                                             GlobalVar.choicecategory == "ALL"
//                                       ? (() {
//                                           var filtered = stockrequestVM
//                                               .srOutList
//                                               .where(
//                                                 (element) =>
//                                                     element.documentNo ==
//                                                     widget.documentno,
//                                               )
//                                               .toList();
//                                           return filtered.isNotEmpty
//                                               ? headerCard2(
//                                                   filtered[0].detail![index],
//                                                   index,
//                                                 )
//                                               : SizedBox();
//                                         })()
//                                       : widget.choice == "SR" &&
//                                             widget.from == "history"
//                                       ? (() {
//                                           var filtered = stockrequestVM
//                                               .srOutList
//                                               .where(
//                                                 (element) =>
//                                                     element.documentNo ==
//                                                     widget.documentno,
//                                               )
//                                               .toList();
//                                           return filtered.isNotEmpty
//                                               ? headerCard2(
//                                                   filtered[0].detail![index],
//                                                   index,
//                                                 )
//                                               : SizedBox();
//                                         })()
//                                       : (() {
//                                           var filtered = stockrequestVM
//                                               .srOutList
//                                               .where(
//                                                 (element) =>
//                                                     element.documentNo ==
//                                                     widget.documentno,
//                                               )
//                                               .toList();
//                                           if (filtered.isEmpty) {
//                                             return SizedBox();
//                                           }
//                                           var detailFiltered = filtered[0]
//                                               .detail!
//                                               .where(
//                                                 (d) =>
//                                                     d.inventoryGroup.contains(
//                                                       GlobalVar.choicecategory,
//                                                     ),
//                                               )
//                                               .toList();
//                                           return detailFiltered.isNotEmpty
//                                               ? headerCard2(
//                                                   detailFiltered[index],
//                                                   index,
//                                                 )
//                                               : SizedBox();
//                                         })(),

//                                   onTap: () async {
//                                     if (widget.choice == "WO") {
//                                       return;
//                                     }
//                                     if (widget.from == "history") {
//                                       return;
//                                     }

//                                     final srIndex = stockrequestVM.srOutList
//                                         .indexWhere(
//                                           (e) =>
//                                               e.documentNo == widget.documentno,
//                                         );
//                                     if (srIndex == -1) {
//                                       return;
//                                     }

//                                     final srItem =
//                                         stockrequestVM.srOutList[srIndex];

//                                     final List detailList =
//                                         (GlobalVar.choicecategory != "ALL")
//                                         ? (srItem.detail
//                                                   ?.where(
//                                                     (d) => d.inventoryGroup
//                                                         .contains(
//                                                           GlobalVar
//                                                               .choicecategory,
//                                                         ),
//                                                   )
//                                                   .toList() ??
//                                               [])
//                                         : (srItem.detail ?? []);

//                                     if (index < 0 ||
//                                         index >= detailList.length) {
//                                       return;
//                                     }

//                                     final detail = detailList[index];
//                                     final List uomList = detail.uom ?? [];

//                                     final List ctnUomList = uomList
//                                         .where(
//                                           (u) => (u.uom ?? '').contains('CTN'),
//                                         )
//                                         .toList();
//                                     if (ctnUomList.isEmpty) {
//                                       pickedctn.value = 0;
//                                       anyctn = false;
//                                     } else {
//                                       anyctn = true;
//                                       final ctnExact = ctnUomList.firstWhere(
//                                         (u) => (u.uom ?? '') == 'CTN',
//                                         orElse: () => ctnUomList.first,
//                                       );
//                                       pickedctn.value =
//                                           int.tryParse(
//                                             '${ctnExact.totalPicked}',
//                                           ) ??
//                                           0;
//                                     }
//                                     final List pcsUomList = uomList
//                                         .where(
//                                           (u) => (u.uom ?? '').contains('PCS'),
//                                         )
//                                         .toList();
//                                     if (pcsUomList.isEmpty) {
//                                       pickedpcs.value = 0;
//                                       anypcs = false;
//                                     } else {
//                                       anypcs = true;
//                                       final pcsExact = pcsUomList.firstWhere(
//                                         (u) => (u.uom ?? '') == 'PCS',
//                                         orElse: () => pcsUomList.first,
//                                       );
//                                       pickedpcs.value =
//                                           int.tryParse(
//                                             '${pcsExact.totalPicked}',
//                                           ) ??
//                                           0;
//                                     }
//                                     showModalBottomSheet(
//                                       context: context,
//                                       builder: (context) {
//                                         return modalBottomSheet(detail, "sr");
//                                       },
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                           );
//                         }),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   // buttonvalidationT3h (11:802)
//                   margin: EdgeInsets.fromLTRB(
//                     0 * fem,
//                     0 * fem,
//                     0 * fem,
//                     0 * fem,
//                   ),
//                   padding: EdgeInsets.fromLTRB(
//                     22.5 * fem,
//                     6 * fem,
//                     22.5 * fem,
//                     6 * fem,
//                   ),
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Color(0xffffffff),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(8 * fem),
//                       topRight: Radius.circular(8 * fem),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Color(0x3f000000),
//                         offset: Offset(0 * fem, 4 * fem),
//                         blurRadius: 2 * fem,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         // frame10dsH (I11:802;11:382)
//                         margin: EdgeInsets.fromLTRB(
//                           0 * fem,
//                           0 * fem,
//                           0 * fem,
//                           5 * fem,
//                         ),
//                         width: double.infinity,
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                               // numberofitems5YUT (I11:802;11:383)
//                               constraints: BoxConstraints(maxWidth: 94 * fem),
//                               child: RichText(
//                                 textAlign: TextAlign.center,
//                                 text: TextSpan(
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 12 * ffem,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.1725 * ffem / fem,
//                                     color: Color(0xff000000),
//                                   ),
//                                   children: [
//                                     TextSpan(text: 'Number of Items:\n'),
//                                     TextSpan(
//                                       text: widget.choice == "WO"
//                                           ? '${weborderVM.tolistwoout.where((element) => element.documentNo == widget.documentno).toList()[0].detail!.length}'
//                                           : widget.choice == "SR" &&
//                                                 GlobalVar.choicecategory !=
//                                                     "ALL"
//                                           ? '${stockrequestVM.srOutList.where((element) => element.documentNo == widget.documentno).toList()[0].detail!.where((element) => element.inventoryGroup.contains(GlobalVar.choicecategory)).toList().length}'
//                                           : '${stockrequestVM.srOutList.where((element) => element.documentNo == widget.documentno).toList()[0].detail!.length}',
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 23 * fem),
//                             Container(
//                               // totalgrinpcs120PNb (I11:802;11:384)
//                               constraints: BoxConstraints(maxWidth: 87 * fem),
//                               child: RichText(
//                                 textAlign: TextAlign.center,
//                                 text: TextSpan(
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 12 * ffem,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.1725 * ffem / fem,
//                                     color: Color(0xff000000),
//                                   ),
//                                   children: [
//                                     TextSpan(text: 'Total Required QTY :\n'),
//                                     TextSpan(
//                                       text: widget.choice == "WO"
//                                           ? weborderVM
//                                                 .tolistwoout[widget.index]
//                                                 .item
//                                           : calculateTotal("required"),
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color: Color(0xff000000),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 23 * fem),
//                             Container(
//                               // totalgrinctn0fzK (I11:802;11:385)
//                               constraints: BoxConstraints(maxWidth: 88 * fem),
//                               child: RichText(
//                                 textAlign: TextAlign.center,
//                                 text: TextSpan(
//                                   style: safeGoogleFont(
//                                     'Roboto',
//                                     fontSize: 12 * ffem,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.1725 * ffem / fem,
//                                     color:
//                                         calculateTotal("pick") !=
//                                             calculateTotal("required")
//                                         ? Colors.red
//                                         : Color(0xff000000),
//                                   ),
//                                   children: [
//                                     TextSpan(text: 'Total Pick QTY :\n'),
//                                     TextSpan(
//                                       text: calculateTotal("pick"),
//                                       style: safeGoogleFont(
//                                         'Roboto',
//                                         fontSize: 12 * ffem,
//                                         fontWeight: FontWeight.w400,
//                                         height: 1.1725 * ffem / fem,
//                                         color:
//                                             calculateTotal("pick") !=
//                                                 calculateTotal("required")
//                                             ? Colors.red
//                                             : Color(0xff000000),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Visibility(
//                         visible:
//                             widget.choice == "SR" &&
//                             widget.from != "history" &&
//                             _isSearching != true,
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: 40 * fem,
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 margin: EdgeInsets.fromLTRB(
//                                   0 * fem,
//                                   0 * fem,
//                                   30 * fem,
//                                   0 * fem,
//                                 ),
//                                 child: TextButton(
//                                   onPressed: () {
//                                     _showMyDialogReject(
//                                       stockrequestVM.srOutList
//                                           .where(
//                                             (element) =>
//                                                 element.documentNo ==
//                                                 widget.documentno,
//                                           )
//                                           .toList()[0],
//                                     );
//                                   },
//                                   style: TextButton.styleFrom(
//                                     padding: EdgeInsets.zero,
//                                   ),
//                                   child: Container(
//                                     padding: EdgeInsets.fromLTRB(
//                                       52 * fem,
//                                       5 * fem,
//                                       53 * fem,
//                                       5 * fem,
//                                     ),
//                                     height: double.infinity,
//                                     decoration: BoxDecoration(
//                                       border: Border.all(
//                                         color: Color(0xfff44236),
//                                       ),
//                                       color: Color(0xffffffff),
//                                       borderRadius: BorderRadius.circular(
//                                         12 * fem,
//                                       ),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Color(0x3f000000),
//                                           offset: Offset(0 * fem, 4 * fem),
//                                           blurRadius: 2 * fem,
//                                         ),
//                                       ],
//                                     ),
//                                     child: Center(
//                                       // cancelUyh (I11:802;11:374)
//                                       child: SizedBox(
//                                         width: 30 * fem,
//                                         height: 30 * fem,
//                                         child: Image.asset(
//                                           'data/images/cancel-ecb.png',
//                                           width: 30 * fem,
//                                           height: 30 * fem,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               TextButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     if (GlobalVar.choicecategory == "ALL") {
//                                       if (stockrequestVM.srOutList
//                                           .where(
//                                             (element) =>
//                                                 element.documentNo ==
//                                                 widget.documentno,
//                                           )
//                                           .toList()[0]
//                                           .detail!
//                                           .any(
//                                             (element) =>
//                                                 element.updatedAt == "",
//                                           )) {
//                                         var product = stockrequestVM.srOutList
//                                             .where(
//                                               (element) =>
//                                                   element.documentNo ==
//                                                   widget.documentno,
//                                             )
//                                             .toList()[0]
//                                             .detail!
//                                             .singleWhere(
//                                               (element) =>
//                                                   element.updatedAt == "",
//                                             );
//                                         _showDialogCheckProduct(product);
//                                       } else {
//                                         _showMyDialogApprove(
//                                           stockrequestVM.srOutList
//                                               .where(
//                                                 (element) =>
//                                                     element.documentNo ==
//                                                     widget.documentno,
//                                               )
//                                               .toList()[0],
//                                         );
//                                       }
//                                     } else {
//                                       if (stockrequestVM.srOutList
//                                           .where(
//                                             (element) =>
//                                                 element.documentNo ==
//                                                 widget.documentno,
//                                           )
//                                           .toList()[0]
//                                           .detail!
//                                           .where(
//                                             (element) =>
//                                                 element.inventoryGroup ==
//                                                 GlobalVar.choicecategory,
//                                           )
//                                           .any(
//                                             (element) =>
//                                                 element.updatedAt == "",
//                                           )) {
//                                         var product = stockrequestVM.srOutList
//                                             .where(
//                                               (element) =>
//                                                   element.documentNo ==
//                                                   widget.documentno,
//                                             )
//                                             .toList()[0]
//                                             .detail!
//                                             .where(
//                                               (element) =>
//                                                   element.updatedAt == "" &&
//                                                   element.inventoryGroup ==
//                                                       GlobalVar.choicecategory,
//                                             )
//                                             .toList();
//                                         _showDialogCheckProduct(product[0]);
//                                       } else {
//                                         _showMyDialogApprove(
//                                           stockrequestVM.srOutList
//                                               .where(
//                                                 (element) =>
//                                                     element.documentNo ==
//                                                     widget.documentno,
//                                               )
//                                               .toList()[0],
//                                         );
//                                       }
//                                     }
//                                   });
//                                 },
//                                 style: TextButton.styleFrom(
//                                   padding: EdgeInsets.zero,
//                                 ),
//                                 child: Container(
//                                   padding: EdgeInsets.fromLTRB(
//                                     52 * fem,
//                                     5 * fem,
//                                     53 * fem,
//                                     5 * fem,
//                                   ),
//                                   height: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: Color(0xff2cab0c),
//                                     borderRadius: BorderRadius.circular(
//                                       12 * fem,
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Color(0x3f000000),
//                                         offset: Offset(0 * fem, 4 * fem),
//                                         blurRadius: 2 * fem,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Center(
//                                     child: SizedBox(
//                                       width: 30 * fem,
//                                       height: 30 * fem,
//                                       child: Image.asset(
//                                         'data/images/check-circle-LCb.png',
//                                         width: 30 * fem,
//                                         height: 30 * fem,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
