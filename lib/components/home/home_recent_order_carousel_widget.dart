// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:wms_bctech/components/home/home_recent_order_card_widget.dart';

class HomeRecentOrderCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String contextType;

  const HomeRecentOrderCarouselWidget({
    super.key,
    required this.data,
    required this.contextType,
  });

  @override
  State<HomeRecentOrderCarouselWidget> createState() =>
      _HomeRecentOrderCarouselWidgetState();
}

class _HomeRecentOrderCarouselWidgetState
    extends State<HomeRecentOrderCarouselWidget> {
  final InVM inController = Get.find<InVM>();

  void _navigateToPOReadOnly(Map<String, dynamic> item) {
    try {
      final String documentNo = item['documentNo'] ?? '';

      if (documentNo.isEmpty) {
        _showErrorSnackbar('Document number not found');
        return;
      }

      // ✅ CARI PO YANG SESUAI DARI CONTROLLER DENGAN ERROR HANDLING
      final poList = inController.tolistPORecent;
      final matchingPO = poList.firstWhere(
        (po) => po.documentno == documentNo,
        orElse: () {
          throw Exception('PO not found for documentNo: $documentNo');
        },
      );

      // ✅ NAVIGASI KE IN_DETAIL_PAGE DENGAN MODE READ-ONLY
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InDetailPage(
            0, // index tidak penting di mode read-only
            "recent", // from - gunakan nilai khusus untuk mode recent
            matchingPO, // flag - data PO yang akan ditampilkan
            null, // grId - tidak perlu GR ID di mode read-only
            isReadOnlyMode: false, // ✅ PARAMETER READ-ONLY
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to PO details: $e');
      _showErrorSnackbar(
        'Failed to open purchase order details: ${e.toString()}',
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: widget.data.map((item) {
          if (widget.contextType == 'PO') {
            return GestureDetector(
              onTap: () => _navigateToPOReadOnly(item),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: HomeRecentOrderCardWidget(
                  documentNo: item['documentNo'] ?? '-',
                  title1: 'PO Date',
                  value1: item['date'] ?? '-',
                  title2: 'Supplier',
                  value2: item['supplier'] ?? '-',
                  title3: 'Total Items',
                  value3: item['items']?.toString() ?? '0',
                  contextType: 'PO',
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: HomeRecentOrderCardWidget(
                documentNo: item['documentNo'] ?? '-',
                title1: 'SO Date',
                value1: item['date'] ?? '-',
                title2: 'Total Items',
                value2: item['totalItems']?.toString() ?? '0',
                title3: 'Total QTY',
                value3: item['totalQty']?.toString() ?? '0',
                contextType: 'SO',
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}
