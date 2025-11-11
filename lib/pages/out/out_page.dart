import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/out/out_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/pages/out/out_detail_page.dart';

class OutPage extends StatefulWidget {
  const OutPage({super.key});

  @override
  State<OutPage> createState() => _OutPageState();
}

class _OutPageState extends State<OutPage> {
  // Warna utama - Hijau Gojek
  final Color _primaryColor = hijauGojek;
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF2D2D2D);
  final Color _textSecondaryColor = const Color(0xFF6B7280);

  // Inisialisasi controller
  final OutController _outController = Get.find<OutController>();

  // // Data dummy untuk kategori (dinonaktifkan sementara)
  // final List<Map<String, String>> _listChoice = [
  //   {'id': '1', 'label': 'FZ', 'labelName': 'Frozen'},
  //   {'id': '2', 'label': 'CH', 'labelName': 'Chemical'},
  //   {'id': '3', 'label': 'ALL', 'labelName': 'All'},
  // ];

  final List<String> _sortList = ['All', 'SO Date', 'Vendor'];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  // String _selectedChoiceId = '3';
  String _selectedSort = 'SO Date';
  String choiceInValue = 'ALL';

  @override
  void initState() {
    super.initState();
    _outController.refreshDataSO(
      type: RefreshTypeSalesOrder.listSalesOrderData,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  // void _stopSearching() {
  //   _clearSearchQuery();
  //   setState(() {
  //     _isSearching = false;
  //   });
  // }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _outController.clearFilters();
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      if (newQuery.isEmpty) {
        _outController.clearFilters();
      } else {
        // Implement search logic jika diperlukan
        _searchWorkflow(newQuery);
      }
    });
  }

  void _searchWorkflow(String search) {
    // Search logic bisa diimplementasikan di controller jika diperlukan
    // Untuk sekarang, kita clear filter saja
    _outController.clearFilters();
  }

  Future<void> _handleRefresh() async {
    await _outController.refreshDataSO(
      type: RefreshTypeSalesOrder.listSalesOrderData,
    );
    _showSyncDialog();
  }

  void _showSyncDialog() {
    final textFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync By Document Number',
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textFieldController,
                decoration: InputDecoration(
                  hintText: 'Document Number',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _primaryColor,
                    ),
                    child: TextButton(
                      onPressed: () {
                        _syncDocument(textFieldController.text);
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncDocument(String documentNumber) async {
    if (documentNumber.isEmpty) return;
    final result = await _outController.getSoWithDoc(documentNumber);
    if (result != "0") {
      _outController.refreshDataSO(
        type: RefreshTypeSalesOrder.listSalesOrderData,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document $documentNumber synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document $documentNumber not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // void _handleChoiceSelection(Map<String, String> choice) {
  //   setState(() {
  //     _selectedChoiceId = choice['id']!;
  //     _stopSearching();
  //     choiceInValue = choice['labelName']!;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Filter ${choice['labelName']} sedang dinonaktifkan'),
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //   });
  // }

  void _handleSortChange(String? value) {
    setState(() {
      _selectedSort = value ?? 'SO Date';

      // Sort logic - bisa diimplementasikan di controller jika diperlukan
      if (value == "SO Date") {
        _outController.tolistSalesOrder.sort((a, b) {
          final aDate = a.dateordered ?? '';
          final bDate = b.dateordered ?? '';
          return bDate.compareTo(aDate);
        });
      } else {
        _outController.tolistSalesOrder.sort((a, b) {
          final aLifnr = a.cBpartnerId ?? '';
          final bLifnr = b.cBpartnerId ?? '';
          return aLifnr.compareTo(bLifnr);
        });
      }
    });
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: _clearSearchQuery,
        ),
      ];
    }

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _handleRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _startSearch,
          ),
        ],
      ),
    ];
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search PO Number, Vendor...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  // Widget _buildChoiceChips() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: _listChoice.map((choice) {
  //       final isSelected = _selectedChoiceId == choice['id'];
  //       final labelText = choice['labelName']!;

  //       return Container(
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: isSelected
  //               ? [
  //                   BoxShadow(
  //                     color: _getChoiceChipColor(
  //                       choice['label']!,
  //                     ).withValues(alpha: 0.3),
  //                     blurRadius: 8,
  //                     offset: const Offset(0, 2),
  //                   ),
  //                 ]
  //               : null,
  //         ),
  //         child: ChoiceChip(
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //           label: Text(
  //             labelText,
  //             style: TextStyle(
  //               color: isSelected ? Colors.white : _textSecondaryColor,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //           backgroundColor: Colors.grey.shade100,
  //           selected: isSelected,
  //           selectedColor: _getChoiceChipColor(choice['label']!),
  //           elevation: 0,
  //           checkmarkColor: Colors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           onSelected: (_) => _handleChoiceSelection(choice),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Color _getChoiceChipColor(String choice) {
  //   switch (choice) {
  //     case "ALL":
  //       return const Color(0xFFFF6B35);
  //     case "FZ":
  //       return const Color(0xFF00AA13);
  //     case "CH":
  //       return const Color(0xFF8B5FBF);
  //     default:
  //       return const Color(0xfff44236);
  //   }
  // }

  Widget _buildHeader() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_outController.tolistSalesOrder.length} data shown',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: _textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, color: _primaryColor, size: 18),
                  const SizedBox(width: 6),
                  DropdownButtonHideUnderline(
                    child: DropdownButton(
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                      hint: Text(
                        'Sort By',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          color: _textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      value: _selectedSort,
                      items: _sortList
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontFamily: 'MonaSans',
                                  color: _textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _handleSortChange,
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

  Widget _buildContent() {
    return Obx(() {
      if (_outController.isLoading.value) {
        return _buildShimmerLoader();
      }

      if (_outController.tolistSalesOrder.isEmpty) {
        return _buildEmptyState();
      }

      return _buildPoList();
    });
  }

  Widget _buildShimmerLoader() {
    return Expanded(
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            period: const Duration(milliseconds: 1500),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Data Found",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No purchase orders available",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: _textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _primaryColor,
              ),
              child: TextButton(
                onPressed: _handleRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Refresh',
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoList() {
    return Obx(
      () => Expanded(
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          clipBehavior: Clip.hardEdge,
          itemCount: _outController.tolistSalesOrder.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              // Navigate to detail page
              final po = _outController.tolistSalesOrder[index];
              Logger().d('Tapped on PO: ${po.documentno}');
            },
            child: _buildPoCard(_outController.tolistSalesOrder[index], index),
          ),
        ),
      ),
    );
  }

  Widget _buildPoCard(OutModel poData, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan PO Number dan Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          poData.documentno ?? 'No Document No',
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        DateHelper.formatDate(
                          poData.dateordered ?? 'No Date Ordered',
                        ),
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.business_center,
                    'Location',
                    poData.mWarehouseId ?? 'No Vendor',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.shopping_bag,
                    'Total Items',
                    '${poData.details?.length ?? 0} items', // Format lebih deskriptif
                  ),

                  // const SizedBox(height: 12),
                  // _buildInfoRow(
                  //   Icons.update,
                  //   'Last Updated',
                  //   _outController.dateToString(poData.updated, '') ??
                  //       'No Update Date',
                  // ),
                  const SizedBox(height: 8),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          final result = await Get.to(
                            () =>
                                OutDetailPage(index, 'In Detail', poData, null),
                          );

                          // Refresh data jika kembali dari detail page
                          if (result == true) {
                            await _outController.refreshDataSO(
                              type: RefreshTypeSalesOrder.listSalesOrderData,
                            );
                          }
                        },
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final result = await Get.to(
                            () =>
                                OutDetailPage(index, 'In Detail', poData, null),
                          );

                          // Refresh data jika kembali dari detail page
                          if (result == true) {
                            await _outController.refreshDataSO(
                              type: RefreshTypeSalesOrder.listSalesOrderData,
                            );
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 12,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 14,
                  color: _textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleBackPress() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF00AA13),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          appBar: AppBar(
            actions: _buildAppBarActions(),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20.0,
                color: Colors.white,
              ),
              onPressed: _handleBackPress,
            ),
            backgroundColor: _primaryColor,
            elevation: 0,
            title: _isSearching
                ? _buildSearchField()
                : Text(
                    "DO Sales Order",
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          backgroundColor: _backgroundColor,
          body: RefreshIndicator(
            backgroundColor: Colors.white,
            color: hijauGojek,
            onRefresh: () async {
              await _outController.refreshDataSO(
                type: RefreshTypeSalesOrder.listSalesOrderData,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips (tetap ditampilkan tapi fungsinya dinonaktifkan)
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 16),
                  //   child: _buildChoiceChips(),
                  // ),
                  // Header dengan info dan sort
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Content
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
