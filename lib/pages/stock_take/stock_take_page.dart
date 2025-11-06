import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';
import 'package:wms_bctech/pages/stock_take/stock_take_header_page.dart';
import 'package:wms_bctech/controllers/stock_take_controller.dart';

class StockTakePage extends StatefulWidget {
  const StockTakePage({super.key});

  @override
  State<StockTakePage> createState() => _StockTakePageState();
}

class _StockTakePageState extends State<StockTakePage> {
  final TextEditingController _searchController = TextEditingController();
  final StockTakeController _stockTakeController =
      Get.find<StockTakeController>();

  bool _isSearching = false;
  bool allowBack = true;
  String searchQuery = '';

  final Color hijauGojekLight = const Color(0xFF4CAF50);
  final Color hijauGojekDark = const Color(0xFF008A0E);

  @override
  void initState() {
    super.initState();

    // Listen to real-time updates
    _setupListeners();
  }

  void _setupListeners() {
    // Listen untuk perubahan data real-time
    ever(_stockTakeController.documentListUnique, (
      List<StockTakeModel> documents,
    ) {
      if (mounted) {
        setState(() {
          // UI akan otomatis update ketika data berubah
          Logger().d("UI Updated with ${documents.length} documents");
        });
      }
    });

    // Listen untuk loading state
    ever(_stockTakeController.isLoading, (bool loading) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _stockTakeController.searchValue.value = newQuery;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      searchQuery = '';
      _stockTakeController.searchValue.value = '';
    });
  }

  void _clearSearchQuery() {
    if (_searchController.text.isEmpty) {
      _stopSearching();
      return;
    }
    _searchController.clear();
    _updateSearchQuery('');
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Cari lokasi warehouse...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        onChanged: _updateSearchQuery,
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear_rounded, size: 24, color: Colors.white),
          onPressed: _clearSearchQuery,
          tooltip: 'Clear',
        ),
        const SizedBox(width: 4),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search_rounded, size: 24, color: Colors.white),
        onPressed: _startSearch,
        tooltip: 'Search',
      ),
      IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 24, color: Colors.white),
        onPressed: _refreshData,
        tooltip: 'Refresh',
      ),
      const SizedBox(width: 4),
    ];
  }

  void _refreshData() {
    _stockTakeController.refreshData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Refreshing data...',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: hijauGojek,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStockItem(StockTakeModel stock, int index) {
    final isActive =
        stock.whValue.isNotEmpty; // Adjust based on your active logic

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hijauGojek.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _onStockItemTap(stock),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [hijauGojek, hijauGojekDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: hijauGojek.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warehouse_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stock.whName.isNotEmpty
                                  ? stock.whName
                                  : 'Unknown Warehouse',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hijauGojekDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Indicator
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? hijauGojek : Colors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: isActive
                                      ? hijauGojek.withValues(alpha: 0.3)
                                      : Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Items Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hijauGojek.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 14,
                              color: hijauGojekDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stock.countDetail} Items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hijauGojekDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Last Transaction
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Last Transaction: ${_stockTakeController.formatDate(stock.lastQuery)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hijauGojek.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: hijauGojek,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hijauGojek.withValues(alpha: 0.1),
                  hijauGojekLight.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Data Tidak Ditemukan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada warehouse yang sesuai\ndengan pencarian Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hijauGojek,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalItems = _stockTakeController.documentListUnique.length;
    final activeItems = _stockTakeController.documentListUnique
        .where((item) => item.whValue.isNotEmpty)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hijauGojek, hijauGojekDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hijauGojek.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.warehouse_rounded,
              label: 'Total Warehouse',
              value: totalItems.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_rounded,
              label: 'Active',
              value: activeItems.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.pause_circle_rounded,
              label: 'Inactive',
              value: (totalItems - activeItems).toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _onStockItemTap(StockTakeModel stock) {
    Logger().d('Selected stock: ${stock.whName}');

    // Set documentNo untuk detail streaming
    _stockTakeController.documentNo.value = stock.documentid;
    _stockTakeController.bindDocumentDetailsStream(stock.documentid);

    // Tampilkan snackbar modern
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Opening ${stock.whName}...',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: hijauGojek,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    Get.to(() => StockTakeHeader());
  }

  List<StockTakeModel> _getFilteredStocks() {
    if (searchQuery.isEmpty) {
      return _stockTakeController.documentListUnique;
    }

    final query = searchQuery.toLowerCase();
    return _stockTakeController.documentListUnique
        .where(
          (stock) =>
              stock.whName.toLowerCase().contains(query) ||
              stock.locatorValue.toLowerCase().contains(query) ||
              stock.whValue.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white,
            ),
          ),
          actions: _buildAppBarActions(),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hijauGojek, hijauGojekDark],
              ),
            ),
          ),
          title: _isSearching
              ? _buildSearchField()
              : const Text(
                  "Stock Take",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
          centerTitle: true,
        ),
        body: Obx(() {
          final filteredStocks = _getFilteredStocks();

          return Column(
            children: [
              // Stats Bar
              _buildStatsBar(),

              // Loading Indicator
              if (_stockTakeController.isLoading.value)
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(hijauGojek),
                ),

              // List
              Expanded(
                child: filteredStocks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _stockTakeController.refreshData();
                        },
                        backgroundColor: Colors.white,
                        color: hijauGojek,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filteredStocks.length,
                          itemBuilder: (BuildContext context, int index) {
                            final stock = filteredStocks[index];
                            return _buildStockItem(stock, index);
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
