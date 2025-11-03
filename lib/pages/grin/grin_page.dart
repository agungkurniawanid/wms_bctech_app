import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/web.dart';
import 'package:wms_bctech/constants/grin/grin_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/grin/grin_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_model.dart';
import 'package:wms_bctech/models/in/in_model.dart';
import 'package:wms_bctech/pages/app_bottom_navigation_page.dart';
import 'package:wms_bctech/pages/grin/grin_detail_page.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:wms_bctech/pages/in/in_page.dart';
import 'package:wms_bctech/components/grin/grin_add_button_widget.dart';
import 'package:wms_bctech/components/grin/grin_appbar_widget.dart';
import 'package:wms_bctech/components/grin/grin_empty_widget.dart';
import 'package:wms_bctech/components/grin/grin_header_widget.dart';
import 'package:wms_bctech/components/grin/grin_shimmer_widget.dart';

class GrinPage extends StatefulWidget {
  const GrinPage({super.key});

  @override
  State<GrinPage> createState() => _GrinPageState();
}

class _GrinPageState extends State<GrinPage> {
  final GrinController _grinController = Get.find<GrinController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();
  final _inController = Get.find<InVM>();

  Timer? _searchDebounce;
  late final StreamSubscription<bool> _searchStateSubscription;
  late final StreamSubscription<String> _searchQuerySubscription;

  @override
  void initState() {
    super.initState();
    _logger.d('🎯 GrinPage initState');

    _searchStateSubscription = _grinController.isSearching.listen((searching) {
      _logger.d('🔄 Search state changed in UI: $searching');
      if (mounted) {
        setState(() {});
      }
    });

    _searchQuerySubscription = _grinController.searchQuery.listen((query) {
      _logger.d('📝 Search query in UI: "$query"');
      // Sync search controller text
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
  }

  @override
  void dispose() {
    _logger.d('🧹 GrinPage dispose');
    _searchDebounce?.cancel();
    _searchStateSubscription.cancel();
    _searchQuerySubscription.cancel();
    _scrollController.dispose();
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
        _grinController.updateSearchQuery(trimmedQuery);
      } catch (e, stackTrace) {
        _logger.e('❌ Search error: $e\n$stackTrace');
      }
    });
  }

  void _startSearch() {
    _logger.d('🔍 _startSearch called');
    try {
      _grinController.setSearchMode(true);
    } catch (e, stackTrace) {
      _logger.e('❌ Error in _startSearch: $e\n$stackTrace');
    }
  }

  void _clearSearchQuery() {
    _logger.d('🧹 _clearSearchQuery dipanggil');
    try {
      _searchController.clear();
      _grinController.clearSearch();
      _logger.d('✅ Search cleared dan mode dinonaktifkan');
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _clearSearchQuery: $e\n$stackTrace');
    }
  }

  Widget _buildContent() {
    return Obx(() {
      final isSearching = _grinController.isSearching.value;
      final searchQuery = _grinController.searchQuery.value;
      final hasSearchResults = _grinController.grinList.isNotEmpty;
      final isLoading = _grinController.isLoading.value;

      _logger.d(
        '📊 _buildContent - isSearching: $isSearching, searchQuery: "$searchQuery", hasResults: $hasSearchResults',
      );

      // Jika sedang loading
      if (isLoading) {
        return const GrinShimmerWidget();
      }

      // Jika sedang search mode dan ada query
      if (isSearching && searchQuery.isNotEmpty) {
        if (!hasSearchResults) {
          return _buildEmptySearchState();
        }
        return _buildSearchResults();
      }

      // Jika tidak ada data sama sekali
      if (_grinController.grinList.isEmpty) {
        return GrinEmptyWidget(
          onRefresh: _grinController.handleRefreshGrinPage,
        );
      }

      // Default view - grouped list
      return _buildGroupedGrinList();
    });
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final searchQuery = _grinController.searchQuery.value
          .trim()
          .toLowerCase();
      final grinList = _grinController.grinList;

      if (searchQuery.isEmpty) {
        return const Center(child: Text('Start typing to search...'));
      }

      // Tampilkan hasil search secara langsung (tanpa grouping)
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
                    GrinConstants.primaryColor.withValues(alpha: 0.1),
                    GrinConstants.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: GrinConstants.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'No Results Found',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: GrinConstants.textPrimaryColor,
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
                color: GrinConstants.textSecondaryColor,
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
                foregroundColor: GrinConstants.primaryColor,
                side: BorderSide(color: GrinConstants.primaryColor),
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

  Widget _buildSearchResultCard(GoodReceiveSerialNumberModel grin) {
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
            color: GrinConstants.primaryColor.withValues(alpha: 0.08),
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
              () => GrinDetailPage(grId: grin.grId),
              transition: Transition.rightToLeft,
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: GrinConstants.primaryColor.withValues(alpha: 0.1),
          highlightColor: GrinConstants.primaryColor.withValues(alpha: 0.05),
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
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GrinConstants.primaryColor.withValues(
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
                          color: GrinConstants.primaryColor,
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
                            color: GrinConstants.textSecondaryColor,
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
                            GrinConstants.primaryColor.withValues(alpha: 0.12),
                            GrinConstants.primaryColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: GrinConstants.primaryColor,
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
                              color: GrinConstants.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            grin.poNumber,
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 15,
                              color: GrinConstants.textPrimaryColor,
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
                            GrinConstants.primaryColor.withValues(alpha: 0.12),
                            GrinConstants.primaryColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: GrinConstants.primaryColor,
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
                              color: GrinConstants.textSecondaryColor,
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
                              color: GrinConstants.textPrimaryColor,
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
                                  GrinConstants.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  GrinConstants.primaryColor.withValues(
                                    alpha: 0.06,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 18,
                              color: GrinConstants.primaryColor,
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
                                    color: GrinConstants.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${grin.details.length} items',
                                  style: TextStyle(
                                    fontFamily: 'MonaSans',
                                    fontSize: 15,
                                    color: GrinConstants.textPrimaryColor,
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
                        color: GrinConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: GrinConstants.primaryColor,
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

  Widget _buildStatusAndKafkaButton(
    String grId,
    GoodReceiveSerialNumberModel grinData,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('gr_in').doc(grId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildAddButton(grinData);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final kafkaStatus = data['status'];

        Color badgeColor;
        String statusLabel;
        Widget actionButton;

        if (kafkaStatus == 'success') {
          badgeColor = Colors.green;
          statusLabel = 'Terkirim';
          actionButton = _buildCheckIcon();
        } else if (kafkaStatus == 'error') {
          badgeColor = Colors.red;
          statusLabel = 'Error';
          actionButton = _buildResendButton(grId);
        } else {
          badgeColor = Colors.orange;
          statusLabel = 'Belum Dikirim';
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

  Widget _buildAddButton(GoodReceiveSerialNumberModel grinData) {
    return InkWell(
      onTap: () => _handleAddDataToGrin(grinData),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: GrinConstants.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: GrinConstants.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(Icons.add, size: 18, color: GrinConstants.primaryColor),
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

  Map<String, List<GoodReceiveSerialNumberModel>> _groupGrinByPoNumber(
    List<GoodReceiveSerialNumberModel> grinList,
  ) {
    final Map<String, List<GoodReceiveSerialNumberModel>> groupedData = {};

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
      final groupedData = _groupGrinByPoNumber(_grinController.grinList);

      return ListView.builder(
        controller: _scrollController,
        // shrinkWrap: true, // <-- REKOMENDASI: Sebaiknya dihapus
        clipBehavior: Clip.hardEdge,
        itemCount: groupedData.length,
        itemBuilder: (context, groupIndex) {
          final poNumber = groupedData.keys.elementAt(groupIndex);
          final grinList = groupedData[poNumber]!;

          return _buildPoGroupContainer(poNumber, grinList);
        },
      );
    });
  }

  Widget _buildPoGroupContainer(
    String poNumber,
    List<GoodReceiveSerialNumberModel> grinList,
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
                GrinConstants.primaryColor.withValues(alpha: 0.05),
                GrinConstants.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: GrinConstants.primaryColor.withValues(alpha: 0.3),
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
                      GrinConstants.primaryColor.withValues(alpha: 0.08),
                      GrinConstants.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GrinConstants.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: GrinConstants.primaryColor,
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
                              color: GrinConstants.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            poNumber,
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 16,
                              color: GrinConstants.textPrimaryColor,
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
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: GrinConstants.primaryColor.withValues(
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
                          color: GrinConstants.primaryColor,
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
                              color: GrinConstants.primaryColor.withValues(
                                alpha: 0.1,
                              ),
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

  Widget _buildGrinCardInGroup(
    GoodReceiveSerialNumberModel grinData,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(
              () => GrinDetailPage(grId: grinData.grId),
              transition: Transition.rightToLeft,
            );
          },
          splashColor: GrinConstants.primaryColor.withValues(alpha: 0.1),
          highlightColor: GrinConstants.primaryColor.withValues(alpha: 0.05),
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
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GrinConstants.primaryColor.withValues(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: GrinConstants.primaryColor,
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
                              color: GrinConstants.textSecondaryColor,
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
                              color: GrinConstants.textPrimaryColor,
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
                        color: GrinConstants.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: GrinConstants.primaryColor,
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
                              color: GrinConstants.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${grinData.details.length} items',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 14,
                              color: GrinConstants.textPrimaryColor,
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

  Widget _buildGrinCard(
    GoodReceiveSerialNumberModel grinData,
    int index, {
    required bool showPoNumber,
    bool isSearchResult = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                GrinConstants.primaryColor.withValues(alpha: 0.05),
                GrinConstants.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: GrinConstants.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.to(
                  () => GrinDetailPage(grId: grinData.grId),
                  transition: Transition.rightToLeft,
                );
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: GrinConstants.primaryColor.withValues(alpha: 0.1),
              highlightColor: GrinConstants.primaryColor.withValues(
                alpha: 0.05,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                            color: GrinConstants.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GrinConstants.primaryColor.withValues(
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
                    if (showPoNumber) ...[
                      _buildInfoRow(
                        Icons.receipt_long,
                        'PO Number',
                        grinData.poNumber,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildInfoRow(
                      Icons.person,
                      'Created By',
                      TextHelper.formatUserName(
                        grinData.createdBy ?? 'Unknown',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.inventory_2,
                            'Total Items',
                            '${grinData.details.length} items',
                          ),
                        ),
                        if (isSearchResult)
                          _buildStatusAndKafkaButton(grinData.grId, grinData)
                        else
                          _buildAddButton(grinData),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddDataToGrin(
    GoodReceiveSerialNumberModel grinData,
  ) async {
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
    // Jika sedang search mode, clear search dulu
    if (_grinController.isSearching.value) {
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
          GrinConstants.defaultSort = value;
        });
        _grinController.sortGrin(value);
        _logger.d('✅ Sorting diubah ke: $value');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _handleSortChange: $e');
      _logger.e('📋 Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInSearchMode = _grinController.isSearching.value;
    _logger.d('🎨 Build - isInSearchMode: $isInSearchMode');

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
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
        child: SafeArea(
          child: Scaffold(
            appBar: GrinAppbarWidget(
              isSearching: isInSearchMode, // GUNAKAN STATE DARI CONTROLLER
              onBackPressed: _handleBackPress,
              onClearSearch: _clearSearchQuery,
              onRefresh: _grinController.handleRefreshGrinPage,
              onStartSearch: _startSearch,
              grinController: _grinController,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
            ),
            backgroundColor: GrinConstants.backgroundColor,
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: GrinConstants.primaryColor,
              onRefresh: _grinController.handleRefreshGrinPage,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isInSearchMode)
                      GrinAddButtonWidget(onPressed: _handleAddGrin),
                    if (!isInSearchMode)
                      GrinHeaderWidget.fromReactiveList(
                        reactiveList: _grinController.grinList,
                        selectedSort: GrinConstants.defaultSort,
                        sortList: GrinConstants.sortOptions,
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
      ),
    );
  }
}
