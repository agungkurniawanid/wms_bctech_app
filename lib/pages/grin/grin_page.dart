import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
import 'package:logger/logger.dart';

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

  bool _isInSearchMode = false; // LOCAL STATE untuk UI search mode
  // ✅ TAMBAHKAN STREAM SUBSCRIPTION UNTUK SYNCHRONIZE STATE
  late final StreamSubscription<bool> _searchStateSubscription;

  @override
  void initState() {
    super.initState();
    // Stream subscription tetap untuk trigger setState
    _searchStateSubscription = _grinController.isSearching.listen((searching) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchStateSubscription.cancel(); // ✅ JANGAN LUPA DISPOSE
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      try {
        final trimmedQuery = query.trim();

        // ✅ FIXED: Jika query kosong, nonaktifkan search mode
        if (trimmedQuery.isEmpty) {
          _grinController.setSearchMode(false);
        } else {
          _grinController.setSearchMode(true);
          _grinController.searchGrin(trimmedQuery);
        }
      } catch (e, stackTrace) {
        _logger.e('❌ Search error: $e\n$stackTrace');
      }
    });
  }

  void _startSearch() {
    _logger.d('🔍 _startSearch dipanggil');
    try {
      // ✅ FIXED: Update controller state
      _grinController.setSearchMode(true);

      // Trigger UI rebuild
      if (mounted) setState(() {});

      _logger.d('✅ Search mode diaktifkan');
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _startSearch: $e\n$stackTrace');
    }
  }

  void _clearSearchQuery() {
    _logger.d('🧹 _clearSearchQuery dipanggil');
    try {
      _searchController.clear();
      _grinController.setSearchMode(false); // ✅ Nonaktifkan search mode
      _logger.d('✅ Search cleared dan mode dinonaktifkan');
    } catch (e, stackTrace) {
      _logger.e('❌ Error di _clearSearchQuery: $e\n$stackTrace');
    }
  }

  // ✅ PERBAIKI _buildContent UNTUK LEBIH ROBUST
  Widget _buildContent() {
    return Obx(() {
      final isSearching = _grinController.isSearching.value;
      final searchQuery = _grinController.searchQuery.value;
      final hasResults = _grinController.grinList.isNotEmpty;

      // ✅ FIXED: Logic yang lebih sederhana dan aman
      if (searchQuery.isNotEmpty) {
        return _buildSearchResults();
      }

      // Default view (bukan search mode)
      if (isSearching && !hasResults) {
        return const GrinShimmerWidget();
      }

      if (!isSearching && !hasResults) {
        return GrinEmptyWidget(
          onRefresh: _grinController.handleRefreshGrinPage,
        );
      }

      return _buildGroupedGrinList();
    });
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final searchQuery = _grinController.searchQuery.value
          .trim()
          .toLowerCase();
      final isSearching = _grinController.isSearching.value;
      final grinList = _grinController.grinList;

      // Jika belum mulai mengetik
      if (searchQuery.isEmpty) {
        return const Center(child: Text('Start typing to search...'));
      }

      // Jika sedang loading
      if (isSearching) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filter data berdasarkan query di field tertentu
      final filteredList = grinList.where((grin) {
        final createdBy = grin.createdBy?.toLowerCase() ?? '';
        final grId = grin.grId.toLowerCase();
        final poId = grin.poNumber.toLowerCase();
        final poNumber = grin.poNumber.toLowerCase();

        return createdBy.contains(searchQuery) ||
            grId.contains(searchQuery) ||
            poId.contains(searchQuery) ||
            poNumber.contains(searchQuery);
      }).toList();

      if (filteredList.isEmpty) {
        return const Center(child: Text('No results found.'));
      }

      // Tampilkan hasil tanpa grouping (langsung per card)
      return ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final grin = filteredList[index];
          return _buildSearchResultCard(grin);
        },
      );
    });
  }

  // Card tampilan hasil pencarian
  Widget _buildSearchResultCard(GoodReceiveSerialNumberModel grin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        title: Text(grin.poNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GR ID: ${grin.grId}'),
            Text('PO ID: ${grin.poNumber}'),
            Text('Created by: ${grin.createdBy ?? '-'}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Get.to(() => GrinDetailPage(grId: grin.grId));
        },
      ),
    );
  }

  // ✅ PERBAIKAN: Method untuk membangun baris info di hasil pencarian
  Widget _buildSearchInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: GrinConstants.primaryColor.withOpacity(0.1),
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

  // ... (method-method lainnya tetap sama seperti sebelumnya: _buildStatusAndKafkaButton, _buildAddButton, dll.)

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
        final kafkaStatus = data['lastSentToKafkaLogStatus'];

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
          color: GrinConstants.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: GrinConstants.primaryColor.withOpacity(0.3),
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
          color: Colors.green.withOpacity(0.1),
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
        color: Colors.green.withOpacity(0.1),
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
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
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

      return Expanded(
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          clipBehavior: Clip.hardEdge,
          itemCount: groupedData.length,
          itemBuilder: (context, groupIndex) {
            final poNumber = groupedData.keys.elementAt(groupIndex);
            final grinList = groupedData[poNumber]!;
            final isSingleGroup = groupedData.length == 1;

            if (isSingleGroup) {
              return Column(
                children: grinList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final grinData = entry.value;
                  return _buildGrinCard(grinData, index, showPoNumber: true);
                }).toList(),
              );
            }

            return _buildPoGroupContainer(poNumber, grinList);
          },
        ),
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
                GrinConstants.primaryColor.withOpacity(0.05),
                GrinConstants.primaryColor.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: GrinConstants.primaryColor.withOpacity(0.3),
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
                      GrinConstants.primaryColor.withOpacity(0.08),
                      GrinConstants.primaryColor.withOpacity(0.04),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GrinConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GrinConstants.primaryColor.withOpacity(0.3),
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
                        color: GrinConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: GrinConstants.primaryColor.withOpacity(0.3),
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
                              color: GrinConstants.primaryColor.withOpacity(
                                0.1,
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
          splashColor: GrinConstants.primaryColor.withOpacity(0.1),
          highlightColor: GrinConstants.primaryColor.withOpacity(0.05),
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
                        color: GrinConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GrinConstants.primaryColor.withOpacity(0.3),
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
                        color: GrinConstants.primaryColor.withOpacity(0.1),
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
                        color: GrinConstants.primaryColor.withOpacity(0.1),
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
                GrinConstants.primaryColor.withOpacity(0.05),
                GrinConstants.primaryColor.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: GrinConstants.primaryColor.withOpacity(0.3),
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
              splashColor: GrinConstants.primaryColor.withOpacity(0.1),
              highlightColor: GrinConstants.primaryColor.withOpacity(0.05),
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
                            color: GrinConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GrinConstants.primaryColor.withOpacity(
                                0.3,
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
                        _buildInfoRow(
                          Icons.inventory_2,
                          'Total Items',
                          '${grinData.details.length} items',
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
      _logger.e('Stack trace: $stackTrace');

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
            color: GrinConstants.primaryColor.withOpacity(0.1),
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
    Get.offAll(() => const AppBottomNavigation());
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
        // Handle back button - jika sedang search mode, clear search dulu
        if (_isInSearchMode) {
          _clearSearchQuery();
        } else {
          _handleBackPress();
        }
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
              isSearching: _isInSearchMode, // Gunakan LOCAL STATE
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
                    if (!_isInSearchMode)
                      GrinAddButtonWidget(onPressed: _handleAddGrin),
                    if (!_isInSearchMode)
                      GrinHeaderWidget.fromReactiveList(
                        reactiveList: _grinController.grinList,
                        selectedSort: GrinConstants.defaultSort,
                        sortList: GrinConstants.sortOptions,
                        onSortChanged: _handleSortChange,
                      ),
                    if (!_isInSearchMode) const SizedBox(height: 16),
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
