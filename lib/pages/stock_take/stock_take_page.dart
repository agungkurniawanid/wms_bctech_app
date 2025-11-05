import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/pages/stock_take/stock_take_header_page.dart';

class StockTakePage extends StatefulWidget {
  const StockTakePage({super.key});

  @override
  State<StockTakePage> createState() => _StockTakePageState();
}

class _StockTakePageState extends State<StockTakePage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool allowBack = true;
  String searchQuery = '';

  final Color hijauGojekLight = const Color(0xFF4CAF50);
  final Color hijauGojekDark = const Color(0xFF008A0E);

  // Data dummy untuk menggantikan data dari Firestore
  final List<Map<String, dynamic>> _stockList = [
    {
      'lGORT': ['WH-A01', 'SHELF-01'],
      'updated': '2024-01-15 14:30:25',
      'items': 125,
      'status': 'active',
    },
    {
      'lGORT': ['WH-B02', 'SHELF-02'],
      'updated': '2024-01-15 13:45:10',
      'items': 89,
      'status': 'active',
    },
    {
      'lGORT': ['WH-C03', 'SHELF-03'],
      'updated': '2024-01-15 12:20:35',
      'items': 234,
      'status': 'inactive',
    },
    {
      'lGORT': ['WH-D04', 'SHELF-04'],
      'updated': '2024-01-15 11:15:50',
      'items': 156,
      'status': 'active',
    },
    {
      'lGORT': ['WH-E05', 'SHELF-05'],
      'updated': '2024-01-15 10:05:15',
      'items': 67,
      'status': 'inactive',
    },
  ];

  List<Map<String, dynamic>> _filteredStockList = [];

  @override
  void initState() {
    super.initState();
    _filteredStockList = List.from(_stockList);
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _filterStocks(newQuery);
    });
  }

  void _filterStocks(String search) {
    if (search.isEmpty) {
      _filteredStockList = List.from(_stockList);
    } else {
      final query = search.toUpperCase();
      _filteredStockList = _stockList
          .where((element) => element['lGORT'].join(', ').contains(query))
          .toList();
    }
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
      _filteredStockList = List.from(_stockList);
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
      const SizedBox(width: 4),
    ];
  }

  Widget _buildStockItem(Map<String, dynamic> stock, int index) {
    final isActive = stock['status'] == 'active';

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
                              stock['lGORT'].isNotEmpty
                                  ? stock['lGORT'].join(', ')
                                  : '-',
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
                              '${stock['items']} Items',
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
                              'Last: ${stock['updated']}',
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
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalItems = _filteredStockList.length;
    final activeItems = _filteredStockList
        .where((item) => item['status'] == 'active')
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

  void _onStockItemTap(Map<String, dynamic> stock) {
    // Navigasi ke halaman detail dengan animasi
    Logger().d('Selected stock: ${stock['lGORT']}');

    // Tampilkan snackbar modern
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Opening ${stock['lGORT'].join(', ')}...',
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

    Get.to(() => StockTakeHeader()); // Uncomment when ready
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
        body: Column(
          children: [
            // Stats Bar
            _buildStatsBar(),

            // List
            Expanded(
              child: _filteredStockList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredStockList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final stock = _filteredStockList[index];
                        return _buildStockItem(stock, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Fungsi safeGoogleFont dummy untuk menghindari error
TextStyle safeGoogleFont(
  String fontFamily, {
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  double height = 1.0,
  Color color = Colors.black,
}) {
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );
}
