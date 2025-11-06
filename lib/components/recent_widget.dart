import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentWidget extends StatelessWidget {
  final int index;
  final IconData? icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final double height;
  final NumberFormat currency = NumberFormat("#,###", "en_US");

  final List<Map<String, dynamic>> dummyWOList = [
    {
      'inventoryGroup': 'FZ',
      'deliveryDate': '2023-12-01',
      'totalItem': '15',
      'item': '10 CTN\n5 PCS',
    },
    {
      'inventoryGroup': 'CH',
      'deliveryDate': '2023-12-02',
      'totalItem': '20',
      'item': '12 CTN\n8 PCS',
    },
    {
      'inventoryGroup': 'AB',
      'deliveryDate': '2023-12-03',
      'totalItem': '8',
      'item': '5 CTN\n3 PCS',
    },
  ];

  final String dummyChoiceWO = 'ALL';

  RecentWidget({
    super.key,
    required this.index,
    this.icon,
    this.elevation = 9,
    this.iconSize = 0.10,
    this.fontSize = 14.0,
    this.height = 40,
  });

  Color _getHeaderColor() {
    final currentItem = dummyWOList[index % dummyWOList.length];
    final group = currentItem['inventoryGroup'];

    switch (group) {
      case "FZ":
        return Colors.blue;
      case "CH":
        return Colors.green;
      default:
        return const Color(0xfff44236);
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '-';
      return dateString.split(' ')[0];
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    if (index < 0 || index >= dummyWOList.length) {
      return _buildEmptyCard(fem, ffem);
    }

    final currentItem = dummyWOList[index];

    return Container(
      width: 155 * fem,
      height: 100 * fem,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * fem),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 31 * fem,
            decoration: BoxDecoration(
              color: _getHeaderColor(),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8 * fem),
                topRight: Radius.circular(8 * fem),
              ),
            ),
            child: Center(
              child: Text(
                currentItem['inventoryGroup'] ?? '',
                textAlign: TextAlign.center,
                style: _getTextStyle(ffem, fem, isHeader: true),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(4 * fem, 4 * fem, 0, 2 * fem),
            child: RichText(
              text: TextSpan(
                style: _getTextStyle(ffem, fem),
                children: [
                  const TextSpan(text: 'Delivery Date:   '),
                  TextSpan(
                    text: _formatDate(currentItem['deliveryDate'] ?? ''),
                    style: _getTextStyle(ffem, fem, isBold: false),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 2 * fem),
            child: RichText(
              text: TextSpan(
                style: _getTextStyle(ffem, fem),
                children: [
                  const TextSpan(text: 'Total Item:         '),
                  TextSpan(
                    text: '${currentItem['totalItem']}',
                    style: _getTextStyle(ffem, fem, isBold: false),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 4 * fem),
            constraints: BoxConstraints(maxWidth: 130 * fem),
            child: RichText(
              text: TextSpan(
                style: _getTextStyle(ffem, fem),
                children: [
                  const TextSpan(text: 'Total Quantity:  '),
                  TextSpan(
                    text: currentItem['item'] ?? '',
                    style: _getTextStyle(ffem, fem, isBold: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(double fem, double ffem) {
    return Container(
      width: 155 * fem,
      height: 100 * fem,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8 * fem),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: Offset(0 * fem, 2 * fem),
            blurRadius: 3 * fem,
          ),
        ],
      ),
      child: Center(
        child: Text('No Data', style: _getTextStyle(ffem, fem, isBold: true)),
      ),
    );
  }

  TextStyle _getTextStyle(
    double ffem,
    double fem, {
    bool isBold = true,
    bool isHeader = false,
  }) {
    if (isHeader) {
      return TextStyle(
        fontSize: 16 * ffem,
        fontWeight: FontWeight.w600,
        height: 1.1725 * ffem / fem,
        color: Colors.white,
      );
    }

    return TextStyle(
      fontSize: 12 * ffem,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      height: 1.1725 * ffem / fem,
      color: const Color(0xff3d3d3d),
    );
  }
}

// checked
