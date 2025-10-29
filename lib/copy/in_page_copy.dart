// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shimmer/shimmer.dart';

// class InPage extends StatefulWidget {
//   const InPage({super.key});

//   @override
//   State<InPage> createState() => _InPageState();
// }

// class _InPageState extends State<InPage> {
//   // Data dummy untuk kategori
//   final List<Map<String, String>> _listChoice = [
//     {'id': '1', 'label': 'FZ', 'labelName': 'Frozen'},
//     {'id': '2', 'label': 'CH', 'labelName': 'Chemical'},
//     {'id': '3', 'label': 'ALL', 'labelName': 'All'},
//   ];

//   // Data dummy untuk PO
//   final List<Map<String, dynamic>> _dummyPoData = [
//     {
//       'ebeln': '4500000011',
//       'aedat': '2024-01-15',
//       'lifnr': 'Vendor ABC Company',
//       'invoiceno': 'INV-001',
//       'created': '2024-01-16',
//     },
//     {
//       'ebeln': '4500000012',
//       'aedat': '2024-01-14',
//       'lifnr': 'XYZ Supplier Corp',
//       'invoiceno': 'INV-002',
//       'created': '2024-01-15',
//     },
//     {
//       'ebeln': '4500000013',
//       'aedat': '2024-01-13',
//       'lifnr': 'Global Trading Ltd',
//       'invoiceno': 'INV-003',
//       'created': '2024-01-14',
//     },
//     {
//       'ebeln': '4500000014',
//       'aedat': '2024-01-12',
//       'lifnr': 'Best Materials Inc',
//       'invoiceno': 'INV-004',
//       'created': '2024-01-13',
//     },
//   ];

//   final List<String> _sortList = ['PO Date', 'Vendor'];
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _searchController = TextEditingController();

//   bool _isSearching = false;
//   bool _isLoading = false;
//   String _selectedChoiceId = '1';
//   String _selectedSort = 'PO Date';
//   String _choiceInValue = 'FZ';
//   String? searchQuery;
//   List<Map<String, dynamic>> _displayedPoData = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _initializeData() {
//     setState(() {
//       _displayedPoData = List.from(_dummyPoData);
//     });
//   }

//   void _startSearch() {
//     setState(() {
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
//       _searchController.clear();
//       searchQuery = null;
//       _isSearching = false;
//       _displayedPoData = List.from(_dummyPoData);
//     });
//   }

//   void _updateSearchQuery(String newQuery) {
//     setState(() {
//       searchQuery = newQuery;
//       _searchWorkflow(newQuery);
//     });
//   }

//   void _searchWorkflow(String search) {
//     if (search.isEmpty) {
//       _displayedPoData = List.from(_dummyPoData);
//       return;
//     }

//     final filteredList = _dummyPoData.where((element) {
//       return (element['ebeln']?.toString().contains(search) ?? false) ||
//           (element['invoiceno']?.toString().contains(search) ?? false) ||
//           (element['vendorpo']?.toString().contains(search) ?? false);
//     }).toList();

//     setState(() {
//       _displayedPoData = filteredList;
//     });
//   }

//   Future<void> _handleRefresh() async {
//     setState(() {
//       _isLoading = true;
//     });

//     // Simulasi loading
//     await Future.delayed(const Duration(seconds: 2));

//     setState(() {
//       _isLoading = false;
//       _displayedPoData = List.from(_dummyPoData);
//     });

//     _showSyncDialog();
//   }

//   void _showSyncDialog() {
//     final textFieldController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: Text('Sync By Document Number', style: _getTextStyle()),
//         content: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: textFieldController,
//                 decoration: _getInputDecoration('Document Number'),
//                 textAlign: TextAlign.left,
//                 style: const TextStyle(color: Colors.black),
//               ),
//             ],
//           ),
//         ),
//         contentPadding: const EdgeInsets.all(20.0),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               _syncDocument(textFieldController.text);
//               Navigator.of(context).pop();
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _getInputDecoration(String hintText) {
//     return InputDecoration(
//       hintText: hintText,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
//       focusedBorder: const OutlineInputBorder(
//         borderSide: BorderSide(color: Colors.black),
//       ),
//       enabledBorder: const OutlineInputBorder(
//         borderSide: BorderSide(color: Colors.black),
//       ),
//       hintStyle: const TextStyle(color: Colors.black),
//     );
//   }

//   void _syncDocument(String documentNumber) {
//     // Simulasi sync document
//     print('Syncing document: $documentNumber');
//   }

//   void _handleChoiceSelection(Map<String, String> choice) {
//     setState(() {
//       _selectedChoiceId = choice['id']!;
//       _stopSearching();
//       _choiceInValue = choice['labelName']!;

//       // Simulasi filter data berdasarkan kategori
//       if (choice['label'] == 'ALL') {
//         _displayedPoData = List.from(_dummyPoData);
//       } else {
//         _displayedPoData = _dummyPoData
//             .where(
//               (element) => element['ebeln']!.endsWith(
//                 choice['label'] == 'FZ' ? '1' : '2',
//               ),
//             )
//             .toList();
//       }
//     });
//   }

//   void _handleSortChange(String? value) {
//     setState(() {
//       _selectedSort = value ?? 'PO Date';

//       if (value == "PO Date") {
//         _displayedPoData.sort((a, b) {
//           final aDate = a['aedat'] ?? '';
//           final bDate = b['aedat'] ?? '';
//           return bDate.compareTo(aDate);
//         });
//       } else {
//         _displayedPoData.sort((a, b) {
//           final aLifnr = a['lifnr'] ?? '';
//           final bLifnr = b['lifnr'] ?? '';
//           return aLifnr.compareTo(bLifnr);
//         });
//       }
//     });
//   }

//   List<Widget> _buildAppBarActions() {
//     if (_isSearching) {
//       return [
//         IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearchQuery),
//       ];
//     }

//     return [
//       Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.refresh_outlined),
//             onPressed: _handleRefresh,
//           ),
//           IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
//         ],
//       ),
//     ];
//   }

//   Widget _buildSearchField() {
//     return TextField(
//       controller: _searchController,
//       autofocus: true,
//       decoration: const InputDecoration(
//         hintText: 'Search...',
//         border: InputBorder.none,
//         hintStyle: TextStyle(color: Colors.white30),
//       ),
//       style: const TextStyle(color: Colors.white, fontSize: 16.0),
//       onChanged: _updateSearchQuery,
//     );
//   }

//   Widget _buildChoiceChips() {
//     return Wrap(
//       spacing: 25,
//       children: _listChoice.map((choice) {
//         final isSelected = _selectedChoiceId == choice['id'];
//         final labelText = choice['labelName']!;

//         return ChoiceChip(
//           padding: const EdgeInsets.symmetric(horizontal: 5),
//           label: Text(labelText),
//           labelStyle: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//           ),
//           backgroundColor: Colors.grey,
//           selected: isSelected,
//           selectedColor: _getChoiceChipColor(choice['label']!),
//           elevation: 10,
//           onSelected: (_) => _handleChoiceSelection(choice),
//         );
//       }).toList(),
//     );
//   }

//   Color _getChoiceChipColor(String choice) {
//     switch (choice) {
//       case "ALL":
//         return Colors.orange;
//       case "FZ":
//         return Colors.blue;
//       case "CH":
//         return Colors.green;
//       default:
//         return const Color(0xfff44236);
//     }
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           '${_displayedPoData.length} of ${_dummyPoData.length} data shown',
//           style: _getTextStyle(),
//           maxLines: 2,
//         ),
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: const BoxDecoration(color: Colors.white),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               const Icon(Icons.sort, color: Colors.black),
//               DropdownButton(
//                 dropdownColor: Colors.white,
//                 icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
//                 hint: const Text('Sort By '),
//                 value: _selectedSort,
//                 items: _sortList
//                     .map(
//                       (value) =>
//                           DropdownMenuItem(value: value, child: Text(value)),
//                     )
//                     .toList(),
//                 onChanged: _handleSortChange,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildContent() {
//     if (_isLoading) {
//       return _buildShimmerLoader();
//     }

//     if (_displayedPoData.isEmpty) {
//       return _buildEmptyState();
//     }

//     return _buildPoList();
//   }

//   Widget _buildShimmerLoader() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[500]!,
//       highlightColor: Colors.white12,
//       period: const Duration(milliseconds: 1500),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: _buildDummyCard(),
//       ),
//     );
//   }

//   Widget _buildDummyCard() {
//     return Container(
//       height: 150,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.25),
//             offset: const Offset(0, 4),
//             blurRadius: 5,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: SizedBox(
//         width: 250,
//         height: 250,
//         child: Column(
//           children: [
//             Icon(
//               Icons.inventory_2_outlined,
//               size: 100,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "No Data",
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "No purchase orders found",
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPoList() {
//     return Expanded(
//       child: ListView.builder(
//         controller: _scrollController,
//         shrinkWrap: true,
//         scrollDirection: Axis.vertical,
//         itemCount: _displayedPoData.length,
//         itemBuilder: (context, index) => GestureDetector(
//           onTap: () {
//             // Navigate to detail page
//             print('Tapped on PO: ${_displayedPoData[index]['ebeln']}');
//           },
//           child: _buildPoCard(_displayedPoData[index]),
//         ),
//       ),
//     );
//   }

//   Widget _buildPoCard(Map<String, dynamic> poData) {
//     final double fem = MediaQuery.of(context).size.width / 360;
//     final double ffem = fem * 0.97;

//     return Container(
//       margin: EdgeInsets.fromLTRB(5 * fem, 0, 10 * fem, 10 * fem),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.fromLTRB(0, 0, 0, 13 * fem),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8 * fem),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.25),
//                   offset: Offset(0, 4 * fem),
//                   blurRadius: 5 * fem,
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildCardHeader(poData, fem, ffem),
//                 _buildCardInfo(
//                   'Vendor:',
//                   _formatVendorText(poData['lifnr'] ?? ''),
//                   12 * fem,
//                 ),
//                 _buildCardInfo(
//                   'Invoice No:',
//                   poData['invoiceno'] ?? '',
//                   12 * fem,
//                 ),
//                 _buildCardInfo(
//                   'Last Updated:',
//                   _formatDate(poData['created'] ?? ''),
//                   12 * fem,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCardHeader(
//     Map<String, dynamic> poData,
//     double fem,
//     double ffem,
//   ) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 1.66 * fem),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             width: 130 * fem,
//             height: 38 * fem,
//             margin: EdgeInsets.only(right: 12 * fem, bottom: 13.34 * fem),
//             decoration: BoxDecoration(
//               color: _getChoiceChipColor(
//                 _choiceInValue == 'All' ? 'ALL' : _choiceInValue,
//               ),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(8 * fem),
//                 bottomRight: Radius.circular(8 * fem),
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 poData['ebeln'] ?? '',
//                 style: _getTextStyle(
//                   fontSize: 16 * ffem,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               'PO Date: ${_formatDate(poData['aedat'])}',
//               style: _getTextStyle(
//                 fontSize: 16 * ffem,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           Container(
//             margin: EdgeInsets.only(top: 31.94 * fem),
//             width: 11 * fem,
//             height: 19.39 * fem,
//             child: const Icon(Icons.arrow_forward_ios, size: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCardInfo(String label, String value, double leftMargin) {
//     return Container(
//       margin: EdgeInsets.only(left: leftMargin),
//       child: Text(
//         '$label $value',
//         style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   String _formatVendorText(String vendor) {
//     if (vendor.length > 42) {
//       return '${vendor.substring(0, 7)}\n${vendor.substring(8, 43)}';
//     }

//     if (vendor.contains("Crown Pacific Investments") ||
//         vendor.contains("Australian Fruit Juice")) {
//       return '${vendor.substring(0, 7)}\n${vendor.substring(8)}';
//     }

//     return vendor;
//   }

//   String _formatDate(String date) {
//     // Simple date formatting for demo
//     if (date.length >= 10) {
//       return date.substring(0, 10);
//     }
//     return date;
//   }

//   TextStyle _getTextStyle({
//     double fontSize = 16,
//     FontWeight fontWeight = FontWeight.normal,
//     Color color = const Color(0xff2d2d2d),
//   }) {
//     return GoogleFonts.roboto(
//       fontSize: fontSize,
//       fontWeight: fontWeight,
//       height: 1.1725,
//       color: color,
//     );
//   }

//   void _handleBackPress() {
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: true,
//       child: SafeArea(
//         child: Scaffold(
//           appBar: AppBar(
//             actions: _buildAppBarActions(),
//             automaticallyImplyLeading: false,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back_ios, size: 20.0),
//               onPressed: _handleBackPress,
//             ),
//             backgroundColor: Colors.red,
//             title: _isSearching
//                 ? _buildSearchField()
//                 : const Padding(
//                     padding: EdgeInsets.only(right: 5),
//                     child: Text(
//                       "GR In Purchase Order",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       maxLines: 2,
//                     ),
//                   ),
//             centerTitle: true,
//           ),
//           backgroundColor: Colors.white,
//           body: Container(
//             padding: const EdgeInsets.only(bottom: 25, left: 5),
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     _buildHeader(),
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 10),
//                       child: _buildChoiceChips(),
//                     ),
//                   ],
//                 ),
//                 _buildContent(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
