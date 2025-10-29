import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/grin/grin_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/grin/grin_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_model.dart';
import 'package:wms_bctech/models/in/in_model.dart';
import 'package:wms_bctech/pages/grin/grin_detail_page.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:wms_bctech/pages/in/in_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:logger/logger.dart';

class GrinPageCopy extends StatefulWidget {
  const GrinPageCopy({super.key});

  @override
  State<GrinPageCopy> createState() => _GrinPageCopyState();
}

class _GrinPageCopyState extends State<GrinPageCopy> {
  final GrinController _grinController = Get.find<GrinController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();

  bool _isSearching = false;
  String _selectedSort = 'Created Date';
  final List<String> _sortList = ['Created Date', 'GR ID', 'PO Number'];
  final poData = InModel();

  @override
  void initState() {
    super.initState();
    _grinController.loadGrinData();
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

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _grinController.clearSearch();
    });
  }

  void _updateSearchQuery(String newQuery) {
    _grinController.searchGrin(newQuery);
  }

  Future<void> _handleRefresh() async {
    await _grinController.refreshData();
  }

  void _handleSortChange(String? value) {
    setState(() {
      _selectedSort = value ?? 'Created Date';
      _grinController.sortGrin(_selectedSort);
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
        hintText: 'Search GR ID, PO Number...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  Widget _buildHeader() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GrinConstants.cardColor,
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
              '${_grinController.grinList.length} data shown',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: GrinConstants.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: GrinConstants.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, color: GrinConstants.primaryColor, size: 18),
                  const SizedBox(width: 6),
                  DropdownButtonHideUnderline(
                    child: DropdownButton(
                      dropdownColor: Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: GrinConstants.primaryColor,
                      ),
                      hint: Text(
                        'Sort By',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          color: GrinConstants.textSecondaryColor,
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
                                  color: GrinConstants.textPrimaryColor,
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

  void _handleAddGrin() {
    _logger.d('🔄 Navigate to InPage without generating GR ID');
    Get.to(
      () => InPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildAddGrinButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: _handleAddGrin,
        style: ElevatedButton.styleFrom(
          backgroundColor: GrinConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah GRIN',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (_grinController.isLoading.value) {
        return _buildShimmerLoader();
      }

      if (_grinController.grinList.isEmpty) {
        return _buildEmptyState();
      }

      return _buildGrinList();
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
                color: GrinConstants.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_outlined,
                size: 60,
                color: GrinConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No GRIN Data Found",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GrinConstants.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No good receive serial numbers available",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: GrinConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: GrinConstants.primaryColor,
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

  Widget _buildGrinList() {
    return Obx(
      () => Expanded(
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          clipBehavior: Clip.hardEdge,
          itemCount: _grinController.grinList.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              final grin = _grinController.grinList[index];
              _logger.d('Tapped on GRIN: ${grin.grId}');
            },
            child: _buildGrinCard(_grinController.grinList[index], index),
          ),
        ),
      ),
    );
  }

  Widget _buildGrinCard(GoodReceiveSerialNumberModel grinData, int index) {
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
          color: GrinConstants.cardColor,
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
                  color: GrinConstants.primaryColor,
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
                  // Header dengan GR ID dan Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: GrinConstants.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GrinConstants.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          grinData.grId,
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GrinConstants.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        grinData.createdAt != null
                            ? DateHelper.formatDate(
                                grinData.createdAt!.toIso8601String(),
                              )
                            : 'No Date',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GrinConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.receipt_long,
                    'PO Number',
                    grinData.poNumber,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person,
                    'Created By',
                    TextHelper.formatUserName(grinData.createdBy ?? 'Unknown'),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.inventory_2,
                    'Total Items',
                    '${grinData.details.length} items',
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.to(
                            () => GrinDetailPage(grId: grinData.grId),
                            transition: Transition.rightToLeft,
                          );
                        },
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GrinConstants.primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InDetailPage(
                                index,
                                'In Detail',
                                poData,
                                grinData.grId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: GrinConstants.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: GrinConstants.primaryColor,
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
            color: GrinConstants.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: GrinConstants.primaryColor),
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
                  color: GrinConstants.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 14,
                  color: GrinConstants.textPrimaryColor,
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
          statusBarColor: hijauGojek,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
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
              backgroundColor: GrinConstants.primaryColor,
              elevation: 0,
              title: _isSearching
                  ? _buildSearchField()
                  : Text(
                      "Good Receive IN",
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
            ),
            backgroundColor: GrinConstants.backgroundColor,
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: GrinConstants.primaryColor,
              onRefresh: _handleRefresh,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Button Tambah GRIN
                    _buildAddGrinButton(),
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
      ),
    );
  }
}
