// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/home/home_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/controllers/auth_controller.dart';
import 'package:wms_bctech/controllers/out_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/number_helper.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/pages/grin/grin_page.dart';
import 'package:wms_bctech/pages/out/out_page.dart';
import 'package:wms_bctech/components/home/clipper.dart';
import 'package:wms_bctech/components/home/home_appbar_widget.dart';
import 'package:wms_bctech/components/home/home_menu_card_widget.dart';
import 'package:wms_bctech/components/home/home_more_options_bottom_sheet_widget.dart';
import 'package:wms_bctech/components/home/home_recent_order_carousel_widget.dart';
import 'package:wms_bctech/components/home/home_shimmer_loading_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  String selectedCategory = 'FZ';

  final authController = Get.find<NewAuthController>();
  final inController = Get.find<InVM>();
  final outController = Get.find<OutController>();

  int idPeriodSelected = 1;

  int getTotalItems(dynamic details) {
    if (details == null) return 0;
    if (details is List) return details.length;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupInControllerListeners();
    _setupOutControllerListeners();
    _loadDataAfterBuild();
    authController.loadUserId();
  }

  void _setupInControllerListeners() {
    ever(inController.isLoading, (loading) {
      debugPrint('[InController] Loading state: $loading');
    });

    // GUNAKAN tolistPORecent BUKAN tolistPO
    ever(inController.tolistPORecent, (list) {
      _logListUpdate('PO Recent', list);
    });
  }

  void _setupOutControllerListeners() {
    ever(outController.isLoading, (loading) {
      debugPrint('[OutController] Loading state: $loading');
    });

    ever(outController.tolistSOapprove, (list) {
      _logListUpdate('SO', list);
    });
  }

  void _logListUpdate(String type, List<dynamic> list) {
    debugPrint('$type list updated with ${list.length} items');
    if (list.isNotEmpty) {
      for (var item in list.take(3)) {
        debugPrint(
          '$type: ${item.documentno}, TotalLines: ${item.totallines}, Details: ${item.details?.length}',
        );
      }
    }
  }

  void _loadDataAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        inController.onRecent();
        outController.onRecent();
      });
    });
  }

  void _initializeData() {
    setState(() {
      selectedCategory = HomeDataConstant.listChoice[0]['label'];
    });
  }

  void _handleMenuTap(String title) {
    if (title == 'More') {
      _showMoreOptions();
    } else if (title == 'In') {
      // PERBAIKAN: Gunakan Get.to() untuk konsistensi navigasi
      Get.to(
        () => const GrinPage(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } else if (title == 'Out') {
      // PERBAIKAN: Gunakan Get.to() untuk konsistensi navigasi
      Get.to(
        () => const OutPage(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigating to $title page')));
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => HomeMoreOptionsBottomSheetWidget(),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: HomeDataConstant.menuItems.length,
      itemBuilder: (_, index) {
        final menuItem = HomeDataConstant.menuItems[index];
        return HomeMenuCardWidget(
          icon: menuItem['icon'],
          title: menuItem['title'],
          color: menuItem['color'],
          onTap: () => _handleMenuTap(menuItem['title']),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: hijauGojek,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              inController.refreshData(type: RefreshType.listRecentData),
              outController.refreshDataSO(type: RefreshTypeSO.listRecentData),
            ]);
          },
          color: hijauGojek,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: CurveClipper(),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              hijauGojek,
                              hijauGojek.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SafeArea(
                            child: Column(
                              children: [
                                HomeAppbarWidget(),
                                const SizedBox(height: 20),
                                _buildMenuGrid(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Positioned(
                    //   bottom: 0,
                    //   left: 0,
                    //   right: 0,
                    //   child: HomeCategorySectionWidget(),
                    // ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSectionHeader('Recent Sales Order'),
                      const SizedBox(height: 10),
                      Obx(() {
                        if (outController.isLoading.value) {
                          return HomeShimmerLoadingWidget();
                        }

                        final data = outController.tolistSO;
                        debugPrint('Rendering SO data length: ${data.length}');

                        if (data.isEmpty) {
                          return SizedBox(
                            height: 140,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No Sales Orders Found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () =>
                                        outController.refreshDataSO(
                                          type: RefreshTypeSO.listRecentData,
                                        ),
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final List<Map<String, dynamic>>
                        mappedSO = data.take(10).map((so) {
                          final totalLines = so.totallines ?? 0.0;
                          final totalItems = so.details?.length ?? 0;
                          final totalQty =
                              so.details
                                  ?.fold<num>(
                                    0,
                                    (sum, detail) =>
                                        sum + (detail.qtyordered ?? 0),
                                  )
                                  .toString() ??
                              '0';

                          debugPrint(
                            'Mapping SO: ${so.documentno}, TotalLines: $totalLines, '
                            'Items: $totalItems, TotalQty: $totalQty',
                          );

                          return {
                            'documentNo': so.documentno ?? '-',
                            'customer': TextHelper.capitalize(
                              so.cBpartnerName ?? "",
                            ),
                            'date': DateHelper.formatDate(so.dateordered),
                            'totalItems': totalItems.toString(),
                            'totalQty': NumberHelper.formatNumber(
                              double.parse(totalQty),
                            ),
                          };
                        }).toList();

                        return HomeRecentOrderCarouselWidget(
                          data: mappedSO,
                          contextType: 'SO',
                        );
                      }),

                      const SizedBox(height: 20),
                      _buildSectionHeader('Recent Purchase Orders'),

                      const SizedBox(height: 10),
                      Obx(() {
                        if (inController.isLoading.value) {
                          return HomeShimmerLoadingWidget();
                        }

                        try {
                          // GUNAKAN tolistPORecent
                          final data = inController.tolistPORecent;
                          debugPrint(
                            'Rendering PO data length: ${data.length}',
                          );

                          if (data.isEmpty) {
                            return SizedBox(
                              height: 140,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No Active Purchase Orders Found',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'All POs have been fully delivered or no recent orders',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => inController.refreshData(
                                        type: RefreshType.listRecentData,
                                      ),
                                      child: Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final List<Map<String, dynamic>>
                          mappedPO = data.take(10).map((po) {
                            final totalLines = po.totallines ?? 0.0;
                            final totalItems = po.details?.length ?? 0;

                            debugPrint(
                              'Mapping PO: ${po.documentno}, TotalLines: $totalLines, Items: $totalItems, FullyDelivered: ${po.isFullyDelivered}',
                            );

                            return {
                              'documentNo': po.documentno ?? '-',
                              'supplier': TextHelper.capitalize(
                                po.cBpartnerName,
                              ),
                              'status': po.docstatus ?? '-',
                              'date': DateHelper.formatDate(po.dateordered),
                              'items': NumberHelper.formatNumber(
                                double.parse(totalItems.toString()),
                              ),
                            };
                          }).toList();

                          return HomeRecentOrderCarouselWidget(
                            data: mappedPO,
                            contextType: 'PO',
                          );
                        } catch (e) {
                          debugPrint('Error rendering PO data: $e');
                          return SizedBox(
                            height: 140,
                            child: Center(
                              child: Text('Error loading data: $e'),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
