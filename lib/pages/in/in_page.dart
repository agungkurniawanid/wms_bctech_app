import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/models/in/in_model.dart';
import 'package:wms_bctech/pages/good_receipt/good_receipt_page.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

class InPage extends StatefulWidget {
  const InPage({super.key});

  @override
  State<InPage> createState() => _InPageState();
}

class _InPageState extends State<InPage> {
  final Color _primaryColor = hijauGojek;
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF2D2D2D);
  final Color _textSecondaryColor = const Color(0xFF6B7280);

  // Inisialisasi controller
  late final InVM _inController;
  final _logger = Logger();

  final List<String> _sortList = ['All', 'PO Date', 'Vendor'];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _selectedSort = 'All';
  String choiceInValue = 'ALL';
  Timer? _searchDebounce;
  bool _isLiveSearching = false;

  // Pagination variables
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  final List<InModel> _displayedItems = [];

  // Worker untuk reactive updates
  Worker? _filterWorker;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller dengan error handling
    try {
      _inController = Get.find<InVM>();
    } catch (e) {
      _logger.e('Error finding InVM controller: $e');
      // Jika controller belum ada, buat instance baru
      _inController = Get.put(InVM());
    }

    // Setup listeners
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Setup reactive worker untuk filtered list changes
    _setupReactiveWorker();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _setupReactiveWorker() {
    // Gunakan ever hanya sekali di initState
    _filterWorker = ever(_inController.filteredPOList, (List<InModel> newList) {
      if (mounted && !_isLoadingMore) {
        _resetPagination();
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      await _inController.refreshData(type: RefreshType.listPOData);
      if (mounted) {
        _resetPagination();
      }
    } catch (e) {
      _logger.e('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose workers
    _filterWorker?.dispose();

    // Dispose controllers and timers
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  // Handle scroll untuk pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  // Load more data untuk pagination
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _isSearching) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Simulasi delay untuk loading
      await Future.delayed(const Duration(milliseconds: 500));

      final sourceList = _inController.filteredPOList;
      final startIndex = (_currentPage + 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;

      if (startIndex >= sourceList.length) {
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
        });
        return;
      }

      if (endIndex < sourceList.length) {
        setState(() {
          _displayedItems.addAll(sourceList.sublist(startIndex, endIndex));
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        final remainingItems = sourceList.sublist(startIndex);
        setState(() {
          _displayedItems.addAll(remainingItems);
          _currentPage++;
          _hasMoreData = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading more data: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Reset pagination ketika filter/search berubah
  void _resetPagination() {
    if (!mounted) return;

    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
      _isLoadingMore = false;
      _displayedItems.clear();

      final sourceList = _inController.filteredPOList;
      if (sourceList.isNotEmpty) {
        final itemsToShow = sourceList.length > _itemsPerPage
            ? _itemsPerPage
            : sourceList.length;
        _displayedItems.addAll(sourceList.take(itemsToShow).toList());
        _hasMoreData = sourceList.length > _itemsPerPage;
      }
    });
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_isLiveSearching && mounted) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _inController.clearFilters();
    } else {
      _inController.searchPOData(query);
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _isLiveSearching = true;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _isLiveSearching = false;
      _searchController.clear();
    });
    _inController.clearFilters();
  }

  Future<void> _handleRefresh() async {
    try {
      await _inController.refreshData(type: RefreshType.listPOData);
      if (mounted) {
        _showSyncDialog();
      }
    } catch (e) {
      _logger.e('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    try {
      final result = await _inController.getPoWithDoc(documentNumber);
      if (result != "0") {
        await _inController.refreshData(type: RefreshType.listPOData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document $documentNumber synced successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document $documentNumber not found'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error syncing document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSortChange(String? value) {
    if (value == null) return;

    setState(() {
      _selectedSort = value;
    });
    _inController.sortPOData(_selectedSort);
  }

  // Shimmer untuk load more
  Widget _buildLoadMoreShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: List.generate(
                _itemsPerPage,
                (index) => _buildShimmerCard(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(hijauGojek),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading more items...',
            style: TextStyle(color: _textSecondaryColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                color: Colors.grey.shade300,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Indicator untuk akhir list
  Widget _buildEndOfListIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.08),
              blurRadius: 12.0,
              offset: const Offset(0, 4.0),
              spreadRadius: 1.0,
            ),
          ],
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14.0,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All data loaded',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: _textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${_inController.filteredPOList.length} items total',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w400,
                      color: _textSecondaryColor.withValues(alpha: 0.8),
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

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: _stopSearching,
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.refresh_outlined, color: Colors.white),
        onPressed: _handleRefresh,
      ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: _startSearch,
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
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        // Search is handled by live listener
      },
    );
  }

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
              '${_displayedItems.length} of ${_inController.filteredPOList.length} items shown',
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
      if (_inController.isLoading.value && _displayedItems.isEmpty) {
        return _buildShimmerLoader();
      }

      if (_inController.filteredPOList.isEmpty) {
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
                _isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                size: 60,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isSearching ? "No Results Found" : "No Data Found",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? "Try different search terms"
                  : "No purchase orders available",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: _textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              OutlinedButton(
                onPressed: _stopSearching,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: BorderSide(color: _primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
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
                  child: const Text(
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
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        clipBehavior: Clip.hardEdge,
        itemCount:
            _displayedItems.length +
            (_isLoadingMore ? 1 : 0) +
            (!_hasMoreData && _displayedItems.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator untuk load more
          if (_isLoadingMore && index == _displayedItems.length) {
            return _buildLoadMoreShimmer();
          }

          // End of list indicator
          if (!_hasMoreData &&
              _displayedItems.isNotEmpty &&
              index == _displayedItems.length) {
            return _buildEndOfListIndicator();
          }

          // Item data
          return GestureDetector(
            onTap: () {
              final po = _displayedItems[index];
              _logger.d('Tapped on PO: ${po.documentno}');
            },
            child: _buildPoCard(_displayedItems[index], index),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackPress();
      },
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
                : const Text(
                    "Purchase Order",
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
              await _inController.refreshData(type: RefreshType.listPOData);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoCard(InModel poData, int index) {
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
                    'Vendor',
                    poData.cBpartnerName ?? 'No Vendor',
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          try {
                            final result = await Get.to(
                              () => InDetailPage(
                                index,
                                'In Detail',
                                poData,
                                null,
                              ),
                            );

                            if (result == true && mounted) {
                              await _inController.refreshData(
                                type: RefreshType.listPOData,
                              );
                            }
                          } catch (e) {
                            _logger.e('Error navigating to detail: $e');
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
                          try {
                            final result = await Get.to(
                              () => InDetailPage(
                                index,
                                'In Detail',
                                poData,
                                null,
                              ),
                            );

                            if (result == true && mounted) {
                              await _inController.refreshData(
                                type: RefreshType.listPOData,
                              );
                            }
                          } catch (e) {
                            _logger.e('Error navigating to detail: $e');
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

  Future<void> _handleBackPress() async {
    try {
      _logger.d('🔄 Navigate back to GrinPage from InPage');
      Get.offAll(() => const GoodReceiptPage());
    } catch (e) {
      _logger.e('Error handling back press: $e');
      Get.offAll(() => const GoodReceiptPage());
    }
  }
}
