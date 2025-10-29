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
import 'package:wms_bctech/widgets/grin/grin_add_button_widget.dart';
import 'package:wms_bctech/widgets/grin/grin_appbar_widget.dart';
import 'package:wms_bctech/widgets/grin/grin_empty_widget.dart';
import 'package:wms_bctech/widgets/grin/grin_header_widget.dart';
import 'package:wms_bctech/widgets/grin/grin_shimmer_widget.dart';
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
  final poData = InModel();
  final _inController = Get.find<InVM>();

  bool _isSearching = false;

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

  void _handleSortChange(String? value) {
    setState(() {
      GrinConstants.defaultSort = value ?? 'Created Date';
      _grinController.sortGrin(GrinConstants.defaultSort);
    });
  }

  Widget _buildStatusAndKafkaButton(
    String grId,
    GoodReceiveSerialNumberModel grinData,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('gr_in').doc(grId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Status: Belum Dikirim - hanya tombol plus
          return _buildAddButton(grinData);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final kafkaStatus = data['lastSentToKafkaLogStatus'];

        Color badgeColor;
        String statusLabel;
        Widget actionButton;

        if (kafkaStatus == 'success') {
          // Status: Terkirim - hanya icon centang
          badgeColor = Colors.green;
          statusLabel = 'Terkirim';
          actionButton = _buildCheckIcon();
        } else if (kafkaStatus == 'error') {
          // Status: Error - hanya tombol resend
          badgeColor = Colors.red;
          statusLabel = 'Error';
          actionButton = _buildResendButton(grId);
        } else {
          // Status: Belum Dikirim - hanya tombol plus
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

  // Fungsi untuk mengelompokkan data berdasarkan PO Number
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

  Widget _buildContent() {
    return Obx(() {
      if (_grinController.isLoading.value) {
        return GrinShimmerWidget();
      }

      if (_grinController.grinList.isEmpty) {
        return GrinEmptyWidget(
          onRefresh: _grinController.handleRefreshGrinPage,
        );
      }

      return _buildGroupedGrinList();
    });
  }

  Widget _buildGroupedGrinList() {
    return Obx(() {
      final groupedData = _groupGrinByPoNumber(_grinController.grinList);
      // final hasMultipleGroups = groupedData.length > 1;

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

            // Jika hanya ada satu grup, tampilkan tanpa container induk
            if (isSingleGroup) {
              return Column(
                children: grinList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final grinData = entry.value;
                  return _buildGrinCard(grinData, index, showPoNumber: true);
                }).toList(),
              );
            }

            // Jika multiple groups, tampilkan dengan container induk
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
              // Header Container Induk - PO Number
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

              // List GR dalam grup
              ...grinList.asMap().entries.map((entry) {
                final index = entry.key;
                final grinData = entry.value;
                final isLast = index == grinList.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(
                              color: GrinConstants.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
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

                // Info Created By
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

                // Info Total Items
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

                    // Tampilkan PO Number hanya jika showPoNumber = true
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
                        InkWell(
                          onTap: () => _handleAddDataToGrin(grinData),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: GrinConstants.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GrinConstants.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
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

    // Show loading indicator
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
      // ✅ GET IN CONTROLLER
      final inVM = Get.find<InVM>();

      // ✅ CARI DATA PO BERDASARKAN PO NUMBER
      // Pertama cek di local list
      InModel? poData = inVM.tolistPO.firstWhereOrNull(
        (po) => po.documentno == grinData.poNumber,
      );

      // Jika tidak ada di local, ambil dari Firestore
      if (poData == null) {
        _logger.d('🔍 PO not found in local list, fetching from Firestore...');

        final snapshot = await FirebaseFirestore.instance
            .collection('purchase_orders')
            .where('documentno', isEqualTo: grinData.poNumber)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // ✅ GUNAKAN fromMap atau fromJson (sesuaikan dengan yang ada di InModel)
          final data = snapshot.docs.first.data();
          poData = InModel.fromJson(data); // atau InModel.fromJson(data)
          _logger.d('✅ PO data loaded from Firestore');
        }
      } else {
        _logger.d('✅ PO data found in local list');
      }

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (poData != null) {
        _logger.d('✅ Navigating to InDetailPage with valid PO data');
        _logger.d('   - Document No: ${poData.documentno}');
        _logger.d('   - Vendor: ${poData.cBpartnerId}');
        _logger.d('   - Total Details: ${poData.details?.length ?? 0}');

        // ✅ NAVIGASI DENGAN DATA PO YANG VALID

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

      // Close loading dialog if still open
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
    // Kembali ke HomePage yang ada di dalam AppBottomNavigation
    Get.offAll(() => const AppBottomNavigation());
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
            appBar: GrinAppbarWidget(
              isSearching: _isSearching,
              onBackPressed: _handleBackPress,
              onClearSearch: _clearSearchQuery,
              onRefresh: _grinController.handleRefreshGrinPage,
              onStartSearch: _startSearch,
              grinController: _grinController,
              searchController: _searchController,
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
                    GrinAddButtonWidget(onPressed: _handleAddGrin),
                    GrinHeaderWidget.fromReactiveList(
                      reactiveList: _grinController.grinList,
                      selectedSort: GrinConstants.defaultSort,
                      sortList: GrinConstants.sortOptions,
                      onSortChanged: _handleSortChange,
                    ),
                    const SizedBox(height: 16),
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
