import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/controllers/out/out_controller.dart';
import 'package:wms_bctech/pages/in/in_detail_page.dart';
import 'package:wms_bctech/components/home/home_recent_order_card_widget.dart';
import 'package:wms_bctech/pages/out/out_detail_page.dart';

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
  final OutController outController = Get.find<OutController>();

  void _navigateToDetail(Map<String, dynamic> item) {
    try {
      final String documentNo = item['documentNo'] ?? '';
      final String type = widget.contextType;

      if (documentNo.isEmpty) {
        _showErrorSnackbar('Document number not found');
        return;
      }

      if (type == 'PO') {
        final poList = inController.tolistPORecent;
        final matchingPO = poList.firstWhere(
          (po) => po.documentno == documentNo,
          orElse: () {
            throw Exception('PO not found for documentNo: $documentNo');
          },
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InDetailPage(
              0,
              "recent",
              matchingPO,
              null,
              isReadOnlyMode: false,
            ),
          ),
        );
      } else if (type == 'SO') {
        final soList = outController.tolistSalesOrderRecent;
        final matchingSO = soList.firstWhere(
          (so) => so.documentno == documentNo,
          orElse: () {
            throw Exception('SO not found for documentNo: $documentNo');
          },
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutDetailPage(
              0,
              "recent",
              matchingSO,
              null,
              isReadOnlyMode: false,
            ),
          ),
        );
      } else {
        throw Exception('Unknown context type: $type');
      }
    } catch (e) {
      debugPrint('Error navigating to detail: $e');
      _showErrorSnackbar('Failed to open details: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
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
              onTap: () => _navigateToDetail(item),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: HomeRecentOrderCardWidget(
                  documentNo: item['documentNo'] ?? '-',
                  partnerName: item['supplier'] ?? '-',
                  title1: 'Document No',
                  value1: item['documentNo'] ?? '-',
                  title2: 'PO Date',
                  value2: item['date'] ?? '-',
                  title3: 'Total Items',
                  value3: item['items']?.toString() ?? '0',
                  contextType: 'PO',
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () => _navigateToDetail(item),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: HomeRecentOrderCardWidget(
                  documentNo: item['documentNo'] ?? '-',
                  partnerName: item['customer'] ?? '-', //
                  title1: 'Document No',
                  value1: item['documentNo'] ?? '-',
                  title2: 'SO Date',
                  value2: item['date'] ?? '-',
                  title3: 'Total Items',
                  value3: item['totalItems']?.toString() ?? '0',
                  contextType: 'SO',
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}

// checked
