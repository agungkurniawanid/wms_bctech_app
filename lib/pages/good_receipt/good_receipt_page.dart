import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/web.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wms_bctech/constants/good_receipt/good_receipt_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/good_receipt/good_receipt_controller.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_model.dart';
import 'package:wms_bctech/models/in/in_model.dart';
import 'package:wms_bctech/pages/app_bottom_navigation_page.dart';
import 'package:wms_bctech/pages/good_receipt/good_receipt_detail_page.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:wms_bctech/pages/in/in_page.dart';
import 'package:wms_bctech/components/good_receipt/good_receipt_add_button_widget.dart';
import 'package:wms_bctech/components/good_receipt/good_receipt_appbar_widget.dart';
import 'package:wms_bctech/components/good_receipt/good_receipt_empty_widget.dart';
import 'package:wms_bctech/components/good_receipt/good_receipt_header_widget.dart';
import 'package:wms_bctech/components/good_receipt/good_receipt_shimmer_widget.dart';

class GoodReceiptPage extends StatefulWidget {
  const GoodReceiptPage({super.key});

  @override
  State<GoodReceiptPage> createState() => _GoodReceiptPageState();
}

class _GoodReceiptPageState extends State<GoodReceiptPage> {
  final GoodReceiptController _goodReceiptController =
      Get.find<GoodReceiptController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();
  final _inController = Get.find<InVM>();

  final Color _primaryColor = hijauGojek;
  final Color _textPrimaryColor = const Color(0xFF2D2D2D);
  final Color _textSecondaryColor = const Color(0xFF6B7280);

  Timer? _searchDebounce;
  late final StreamSubscription<bool> _searchStateSubscription;
  late final StreamSubscription<String> _searchQuerySubscription;

  @override
  void initState() {
    super.initState();
    _logger.d('🎯 GoodReceiptPage initState');

    // Setup scroll controller untuk pagination
    _scrollController.addListener(_onScroll);

    _searchStateSubscription = _goodReceiptController.isSearching.listen((
      searching,
    ) {
      _logger.d('🔄 Search state changed in UI: $searching');
      if (mounted) {
        setState(() {});
      }
    });

    _searchQuerySubscription = _goodReceiptController.searchQuery.listen((
      query,
    ) {
      _logger.d('📝 Search query in UI: "$query"');
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
  }

  // Handle scroll untuk pagination
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    // Jangan load more jika sedang search mode
    if (_goodReceiptController.isSearching.value) {
      return;
    }

    await _goodReceiptController.loadMoreGrinData();
  }

  @override
  void dispose() {
    _logger.d('🧹 GoodReceiptPage dispose');
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchStateSubscription.cancel();
    _searchQuerySubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _logger.d('🔍 _onSearchChanged: "$query"');

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      try {
        final trimmedQuery = query.trim();
        _logger.d('🎯 Executing search for: "$trimmedQuery"');

        // Delegate to controller
        _goodReceiptController.updateSearchQuery(trimmedQuery);
      } catch (e, stackTrace) {
        _logger.e('❌ Search error: $e\n$stackTrace');
      }
    });
  }

  void _startSearch() {
    _logger.d('🔍 _startSearch called');
    try {
      _goodReceiptController.setSearchMode(true);
    } catch (e, stackTrace) {
      _logger.e('❌ Error in _startSearch: $e\n$stackTrace');
    }
  }

  void _clearSearchQuery() {
    _logger.d('🧹 _clearSearchQuery dipanggil');
    try {
      _searchController.clear();
      _goodReceiptController.clearSearch();
      _logger.d('✅ Search cleared dan mode dinonaktifkan');
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _clearSearchQuery: $e\n$stackTrace');
    }
  }

  Widget _buildContent() {
    return Obx(() {
      final isSearching = _goodReceiptController.isSearching.value;
      final searchQuery = _goodReceiptController.searchQuery.value;
      final hasSearchResults = _goodReceiptController.grinList.isNotEmpty;
      final isLoading = _goodReceiptController.isLoading.value;
      // final isLoadingMore = _goodReceiptController.isLoadingMoreData; // <-- Dihapus
      // final hasMoreData = _goodReceiptController.hasMoreData; // <-- Dihapus

      _logger.d(
        '📊 _buildContent - isSearching: $isSearching, searchQuery: "$searchQuery", hasResults: $hasSearchResults',
      );

      // Jika sedang loading awal
      if (isLoading && _goodReceiptController.grinList.isEmpty) {
        return const GoodReceiptShimmerWidget();
      }

      // Jika sedang search mode dan ada query
      if (isSearching && searchQuery.isNotEmpty) {
        if (!hasSearchResults) {
          return _buildEmptySearchState();
        }
        return _buildSearchResults();
      }

      // Jika tidak ada data sama sekali
      if (_goodReceiptController.grinList.isEmpty) {
        return GoodReceiptEmptyWidget(
          onRefresh: _goodReceiptController.refreshData,
        );
      }

      // ✅ FIX: Hapus Column dan kembalikan _buildGroupedGrinList secara langsung
      // Logika indikator sekarang ada di dalam _buildGroupedGrinList
      return _buildGroupedGrinList();
    });
  }

  Widget _buildLoadMoreShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 14, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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
                    'All items loaded',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: _textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${_goodReceiptController.totalLoaded} items total',
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

  // Update juga method search results untuk handle scroll
  Widget _buildSearchResults() {
    return Obx(() {
      final searchQuery = _goodReceiptController.searchQuery.value
          .trim()
          .toLowerCase();
      final grinList = _goodReceiptController.grinList;

      if (searchQuery.isEmpty) {
        return const Center(child: Text('Start typing to search...'));
      }

      return ListView.builder(
        controller: _scrollController,
        itemCount: grinList.length,
        itemBuilder: (context, index) {
          final grin = grinList[index];
          return _buildSearchResultCard(grin);
        },
      );
    });
  }

  // Empty state dengan ilustrasi modern
  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated search icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GoodReceiptConstant.primaryColor.withValues(alpha: 0.1),
                    GoodReceiptConstant.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'No Results Found',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: GoodReceiptConstant.textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'We couldn\'t find any matches for your search.\nTry adjusting your search terms.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: GoodReceiptConstant.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Optional: Add clear search button
            OutlinedButton.icon(
              onPressed: () {
                _clearSearchQuery();
              },
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GoodReceiptConstant.primaryColor,
                side: BorderSide(color: GoodReceiptConstant.primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(GoodReceiptModel grin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(
              () => GoodReceiptDetailPage(grId: grin.grId),
              transition: Transition.rightToLeft,
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: GoodReceiptConstant.primaryColor.withValues(alpha: 0.1),
          highlightColor: GoodReceiptConstant.primaryColor.withValues(
            alpha: 0.05,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: GR ID dan Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GoodReceiptConstant.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        grin.grId,
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GoodReceiptConstant.primaryColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          grin.createdAt != null
                              ? DateHelper.formatDate(
                                  grin.createdAt!.toIso8601String(),
                                )
                              : 'No Date',
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GoodReceiptConstant.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PO Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GoodReceiptConstant.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            GoodReceiptConstant.primaryColor.withValues(
                              alpha: 0.06,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: GoodReceiptConstant.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PO Number',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: GoodReceiptConstant.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            grin.poNumber,
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 15,
                              color: GoodReceiptConstant.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Created By
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GoodReceiptConstant.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            GoodReceiptConstant.primaryColor.withValues(
                              alpha: 0.06,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: GoodReceiptConstant.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created By',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: GoodReceiptConstant.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            TextHelper.formatUserName(
                              grin.createdBy ?? 'Unknown',
                            ),
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 15,
                              color: GoodReceiptConstant.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total Items dan Kafka Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  GoodReceiptConstant.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  GoodReceiptConstant.primaryColor.withValues(
                                    alpha: 0.06,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 18,
                              color: GoodReceiptConstant.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Items',
                                  style: TextStyle(
                                    fontFamily: 'MonaSans',
                                    fontSize: 12,
                                    color:
                                        GoodReceiptConstant.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${grin.details.length} items',
                                  style: TextStyle(
                                    fontFamily: 'MonaSans',
                                    fontSize: 15,
                                    color: GoodReceiptConstant.textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusAndKafkaButton(grin.grId, grin),
                  ],
                ),

                // Divider dan Arrow indicator
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.shade300,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // View Details Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 12,
                        color: GoodReceiptConstant.primaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: GoodReceiptConstant.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAndKafkaButton(String grId, GoodReceiptModel grinData) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('good_receipt')
          .doc(grId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildAddButton(grinData);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final kafkaStatus = data['status'];

        Color badgeColor;
        String statusLabel;
        Widget actionButton;

        if (kafkaStatus == 'completed') {
          badgeColor = Colors.green;
          statusLabel = 'Completed';
          actionButton = _buildCheckIcon();
        } else if (kafkaStatus == 'error') {
          badgeColor = Colors.red;
          statusLabel = 'Error';
          actionButton = _buildResendButton(grId);
        } else {
          badgeColor = Colors.orange;
          statusLabel = 'Belum Submit';
          actionButton = _buildAddButton(grinData);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusBadge(statusLabel, badgeColor),
            const SizedBox(width: 8),
            actionButton,
          ],
        );
      },
    );
  }

  Widget _buildAddButton(GoodReceiptModel grinData) {
    return InkWell(
      onTap: () => _handleAddDataToGrin(grinData),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 18,
          color: GoodReceiptConstant.primaryColor,
        ),
      ),
    );
  }

  Widget _buildResendButton(String grId) {
    return InkWell(
      onTap: () => _inController.sendToKafkaForGR(grId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Icon(Icons.refresh_rounded, size: 18, color: Colors.green),
      ),
    );
  }

  Widget _buildCheckIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Icon(Icons.check_circle, size: 18, color: Colors.green),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
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

  Map<String, List<GoodReceiptModel>> _groupGrinByPoNumber(
    List<GoodReceiptModel> grinList,
  ) {
    final Map<String, List<GoodReceiptModel>> groupedData = {};

    for (final grin in grinList) {
      final poNumber = grin.poNumber;
      if (!groupedData.containsKey(poNumber)) {
        groupedData[poNumber] = [];
      }
      groupedData[poNumber]!.add(grin);
    }

    return groupedData;
  }

  Widget _buildGroupedGrinList() {
    return Obx(() {
      final groupedData = _groupGrinByPoNumber(_goodReceiptController.grinList);
      final groupedDataCount = groupedData.length;

      // Ambil status dari controller
      final isLoadingMore = _goodReceiptController.isLoadingMoreData;
      final hasMoreData = _goodReceiptController.hasMoreData;
      final isListNotEmpty = _goodReceiptController.grinList.isNotEmpty;

      // ✅ FIX: Tentukan itemCount
      int itemCount = groupedDataCount;
      if (isLoadingMore) {
        itemCount += 1; // Tambah 1 untuk shimmer
      } else if (!hasMoreData && isListNotEmpty) {
        itemCount += 1; // Tambah 1 untuk end indicator
      }

      return ListView.builder(
        controller: _scrollController,
        clipBehavior: Clip.hardEdge,
        // ✅ Tambahkan padding di bawah agar item terakhir tidak terpotong
        padding: const EdgeInsets.only(bottom: 80.0),
        itemCount: itemCount, // Gunakan itemCount yang baru
        itemBuilder: (context, index) {
          // ✅ FIX: Logic untuk menampilkan indicator di item terakhir
          if (index == groupedDataCount) {
            if (isLoadingMore) {
              return _buildLoadMoreShimmer();
            } else if (!hasMoreData && isListNotEmpty) {
              return _buildEndOfListIndicator();
            }
            // Jika tidak ada kondisi di atas, return box kosong
            return const SizedBox.shrink();
          }

          // Ini adalah item data normal
          final poNumber = groupedData.keys.elementAt(index);
          final grinList = groupedData[poNumber]!;

          return _buildPoGroupContainer(poNumber, grinList);
        },
      );
    });
  }

  Widget _buildPoGroupContainer(
    String poNumber,
    List<GoodReceiptModel> grinList,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                GoodReceiptConstant.primaryColor.withValues(alpha: 0.05),
                GoodReceiptConstant.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      GoodReceiptConstant.primaryColor.withValues(alpha: 0.08),
                      GoodReceiptConstant.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GoodReceiptConstant.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: GoodReceiptConstant.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PO Number',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: GoodReceiptConstant.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            poNumber,
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 16,
                              color: GoodReceiptConstant.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: GoodReceiptConstant.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${grinList.length} GR',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 12,
                          color: GoodReceiptConstant.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...grinList.asMap().entries.map((entry) {
                final index = entry.key;
                final grinData = entry.value;
                final isLast = index == grinList.length - 1;

                return Container(
                  decoration: !isLast
                      ? BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: GoodReceiptConstant.primaryColor
                                  .withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        )
                      : null,
                  child: _buildGrinCardInGroup(grinData, index),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrinCardInGroup(GoodReceiptModel grinData, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(
              () => GoodReceiptDetailPage(grId: grinData.grId),
              transition: Transition.rightToLeft,
            );
          },
          splashColor: GoodReceiptConstant.primaryColor.withValues(alpha: 0.1),
          highlightColor: GoodReceiptConstant.primaryColor.withValues(
            alpha: 0.05,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GoodReceiptConstant.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        grinData.grId,
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GoodReceiptConstant.primaryColor,
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
                        color: GoodReceiptConstant.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: GoodReceiptConstant.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created By',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: GoodReceiptConstant.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TextHelper.formatUserName(
                              grinData.createdBy ?? 'Unknown',
                            ),
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 14,
                              color: GoodReceiptConstant.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GoodReceiptConstant.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: GoodReceiptConstant.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Items',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: GoodReceiptConstant.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${grinData.details.length} items',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 14,
                              color: GoodReceiptConstant.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusAndKafkaButton(grinData.grId, grinData),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildGrinCard(
  //   GoodReceiptModel grinData,
  //   int index, {
  //   required bool showPoNumber,
  //   bool isSearchResult = false,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     child: Material(
  //       borderRadius: BorderRadius.circular(16),
  //       color: Colors.transparent,
  //       child: Container(
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(16),
  //           gradient: LinearGradient(
  //             begin: Alignment.centerLeft,
  //             end: Alignment.centerRight,
  //             colors: [
  //               GoodReceiptConstant.primaryColor.withValues(alpha: 0.05),
  //               GoodReceiptConstant.primaryColor.withValues(alpha: 0.02),
  //             ],
  //           ),
  //           border: Border.all(
  //             color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.3),
  //             width: 1.5,
  //           ),
  //         ),
  //         child: Material(
  //           color: Colors.transparent,
  //           child: InkWell(
  //             onTap: () {
  //               Get.to(
  //                 () => GoodReceiptDetailPage(grId: grinData.grId),
  //                 transition: Transition.rightToLeft,
  //               );
  //             },
  //             borderRadius: BorderRadius.circular(16),
  //             splashColor: GoodReceiptConstant.primaryColor.withValues(
  //               alpha: 0.1,
  //             ),
  //             highlightColor: GoodReceiptConstant.primaryColor.withValues(
  //               alpha: 0.05,
  //             ),
  //             child: Container(
  //               padding: const EdgeInsets.all(20),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 12,
  //                           vertical: 6,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: GoodReceiptConstant.primaryColor.withValues(
  //                             alpha: 0.1,
  //                           ),
  //                           borderRadius: BorderRadius.circular(8),
  //                           border: Border.all(
  //                             color: GoodReceiptConstant.primaryColor
  //                                 .withValues(alpha: 0.3),
  //                             width: 1,
  //                           ),
  //                         ),
  //                         child: Text(
  //                           grinData.grId,
  //                           style: TextStyle(
  //                             fontFamily: 'MonaSans',
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.w600,
  //                             color: GoodReceiptConstant.primaryColor,
  //                           ),
  //                         ),
  //                       ),
  //                       Text(
  //                         grinData.createdAt != null
  //                             ? DateHelper.formatDate(
  //                                 grinData.createdAt!.toIso8601String(),
  //                               )
  //                             : 'No Date',
  //                         style: TextStyle(
  //                           fontFamily: 'MonaSans',
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.w500,
  //                           color: GoodReceiptConstant.textSecondaryColor,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 16),
  //                   if (showPoNumber) ...[
  //                     _buildInfoRow(
  //                       Icons.receipt_long,
  //                       'PO Number',
  //                       grinData.poNumber,
  //                     ),
  //                     const SizedBox(height: 12),
  //                   ],
  //                   _buildInfoRow(
  //                     Icons.person,
  //                     'Created By',
  //                     TextHelper.formatUserName(
  //                       grinData.createdBy ?? 'Unknown',
  //                     ),
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Expanded(
  //                         child: _buildInfoRow(
  //                           Icons.inventory_2,
  //                           'Total Items',
  //                           '${grinData.details.length} items',
  //                         ),
  //                       ),
  //                       if (isSearchResult)
  //                         _buildStatusAndKafkaButton(grinData.grId, grinData)
  //                       else
  //                         _buildAddButton(grinData),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _handleAddDataToGrin(GoodReceiptModel grinData) async {
    _logger.d('➕ Adding data to GR ID: ${grinData.grId}');
    _logger.d('📦 PO Number: ${grinData.poNumber}');

    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: hijauGojek),
              const SizedBox(height: 16),
              const Text('Loading PO data...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final inVM = Get.find<InVM>();

      InModel? poData = inVM.tolistPO.firstWhereOrNull(
        (po) => po.documentno == grinData.poNumber,
      );

      if (poData == null) {
        _logger.d('🔍 PO not found in local list, fetching from Firestore...');

        final snapshot = await FirebaseFirestore.instance
            .collection('purchase_orders')
            .where('documentno', isEqualTo: grinData.poNumber)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          poData = InModel.fromJson(data);
          _logger.d('✅ PO data loaded from Firestore');
        }
      } else {
        _logger.d('✅ PO data found in local list');
      }

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (poData != null) {
        _logger.d('✅ Navigating to InDetailPage with valid PO data');
        _logger.d('   - Document No: ${poData.documentno}');
        _logger.d('   - Vendor: ${poData.cBpartnerId}');
        _logger.d('   - Total Details: ${poData.details?.length ?? 0}');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InDetailPage(0, 'sync', poData!, grinData.grId),
            ),
          );
        }
      } else {
        _logger.e('❌ PO data not found for: ${grinData.poNumber}');

        Get.snackbar(
          'Error',
          'PO data tidak ditemukan untuk PO Number: ${grinData.poNumber}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading PO data: $e');
      _logger.e('📋 Stack trace: $stackTrace');

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Gagal memuat data PO: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Widget _buildInfoRow(IconData icon, String label, String value) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         width: 32,
  //         height: 32,
  //         decoration: BoxDecoration(
  //           color: GoodReceiptConstant.primaryColor.withValues(alpha: 0.1),
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(icon, size: 16, color: GoodReceiptConstant.primaryColor),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               label,
  //               style: TextStyle(
  //                 fontFamily: 'MonaSans',
  //                 fontSize: 12,
  //                 color: GoodReceiptConstant.textSecondaryColor,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             const SizedBox(height: 2),
  //             Text(
  //               value,
  //               style: TextStyle(
  //                 fontFamily: 'MonaSans',
  //                 fontSize: 14,
  //                 color: GoodReceiptConstant.textPrimaryColor,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //               maxLines: 2,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _handleBackPress() {
    // Jika sedang search mode, clear search dulu
    if (_goodReceiptController.isSearching.value) {
      _clearSearchQuery();
    } else {
      Get.offAll(() => const AppBottomNavigation());
    }
  }

  void _handleSortChange(String? value) {
    _logger.d('🔄 _handleSortChange dipanggil dengan value: $value');
    try {
      if (value != null) {
        setState(() {
          GoodReceiptConstant.defaultSort = value;
        });
        _goodReceiptController.sortGrin(value);
        _logger.d('✅ Sorting diubah ke: $value');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _handleSortChange: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInSearchMode = _goodReceiptController.isSearching.value;
    _logger.d('🎨 Build - isInSearchMode: $isInSearchMode');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: hijauGojek,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          appBar: GoodReceiptAppbarWidget(
            isSearching: isInSearchMode,
            onBackPressed: _handleBackPress,
            onClearSearch: _clearSearchQuery,
            onRefresh: _goodReceiptController.handleRefreshGoodReceiptPage,
            onStartSearch: _startSearch,
            grinController: _goodReceiptController,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
          backgroundColor: GoodReceiptConstant.backgroundColor,
          body: RefreshIndicator(
            backgroundColor: Colors.white,
            color: GoodReceiptConstant.primaryColor,
            onRefresh: _goodReceiptController.handleRefreshGoodReceiptPage,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isInSearchMode)
                    GoodReceiptAddButtonWidget(onPressed: _handleAddGrin),
                  if (!isInSearchMode)
                    GoodReceiptHeaderWidget.fromReactiveList(
                      reactiveList: _goodReceiptController.grinList,
                      selectedSort: GoodReceiptConstant.defaultSort,
                      sortList: GoodReceiptConstant.sortOptions,
                      onSortChanged: _handleSortChange,
                    ),
                  if (!isInSearchMode) const SizedBox(height: 16),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
