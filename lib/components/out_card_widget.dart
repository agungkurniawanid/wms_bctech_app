import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OutCard extends StatelessWidget {
  final int index;
  final IconData? icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final NumberFormat currency = NumberFormat("#,###", "en_US");
  final double height;
  final String? choice;
  final String? category;

  final Map<String, dynamic> dummyWOData = {
    'location': 'Warehouse A',
    'deliveryDate': '2023-12-01',
    'item': '5 CTN\n3 PCS',
  };

  final Map<String, dynamic> dummySRData = {
    'documentNo': 'SR-001',
    'deliveryDate': '2023-12-01 14:30:00',
  };

  OutCard({
    super.key,
    required this.index,
    this.icon,
    this.elevation = 9,
    this.iconSize = 0.10,
    this.fontSize = 14.0,
    this.height = 40,
    this.choice,
    this.category,
  });

  String _calcuCTN() {
    try {
      return '10';
    } catch (e) {
      debugPrint('Error in _calcuCTN: $e');
      return '0';
    }
  }

  int calcuforcolour() {
    return 2;
  }

  String _calcuPCS() {
    try {
      return '25';
    } catch (e) {
      debugPrint('Error in _calcuPCS: $e');
      return '0';
    }
  }

  String _calculTotal() {
    try {
      final calcuCTN = _calcuCTN();
      return '$calcuCTN CTN';
    } catch (e) {
      debugPrint('Error in _CalculTotal: $e');
      return '0 CTN';
    }
  }

  String _calcutotalpcs() {
    try {
      final calcuPCS = _calcuPCS();
      return '$calcuPCS PCS';
    } catch (e) {
      debugPrint('Error in _calcutotalpcs: $e');
      return '0 PCS';
    }
  }

  InlineSpan getInlineSpan(int index) {
    return const WidgetSpan(
      child: CircleAvatar(backgroundColor: Colors.red, radius: 5.5),
    );
  }

  InlineSpan getInlineSpanCH(int index) {
    return const WidgetSpan(
      child: CircleAvatar(backgroundColor: Colors.green, radius: 5.5),
    );
  }

  InlineSpan getInlineSpanFZ(int index) {
    return const WidgetSpan(
      child: CircleAvatar(backgroundColor: Colors.blue, radius: 5.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    final isWO = choice == "WO";
    final currentItem = isWO ? dummyWOData : dummySRData;

    return Container(
      width: double.infinity,
      height: 200 * fem,
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
                isWO
                    ? currentItem['location'] ?? 'Unknown Location'
                    : currentItem['documentNo'] ?? 'Unknown Document',
                textAlign: TextAlign.center,
                style: _getHeaderTextStyle(ffem, fem),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(4 * fem, 8 * fem, 0, 4 * fem),
            child: RichText(
              text: TextSpan(
                style: _getTextStyle(ffem, fem),
                children: [
                  TextSpan(
                    text: isWO ? 'Delivery Date:   ' : 'Request Date:   ',
                  ),
                  TextSpan(
                    text: _getDateText(isWO, currentItem),
                    style: _getTextStyle(ffem, fem, isBold: false),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 0),
            constraints: BoxConstraints(maxWidth: 150 * fem),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12 * fem),
                  child: RichText(
                    text: TextSpan(
                      text: 'Total Quantity:  ',
                      style: _getTextStyle(ffem, fem),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWO ? currentItem['item'] ?? '' : _calculTotal(),
                      style: _getTextStyle(ffem, fem, isBold: false),
                    ),
                    if (!isWO) ...[
                      SizedBox(height: 2 * fem),
                      Text(
                        _calcutotalpcs(),
                        style: _getTextStyle(ffem, fem, isBold: false),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (choice != "WO") ...[
            SizedBox(height: 8 * fem),
            Container(
              margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 0),
              constraints: BoxConstraints(maxWidth: 150 * fem),
              child: RichText(
                text: TextSpan(
                  style: _getTextStyle(ffem, fem),
                  children: [
                    getInlineSpan(index),
                    const TextSpan(text: ' '),
                    getInlineSpanCH(index),
                    const TextSpan(text: ' '),
                    getInlineSpanFZ(index),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getHeaderColor() {
    if (category == "FZ") return Colors.blue;
    if (category == "CH") return Colors.green;
    return Colors.orange;
  }

  TextStyle _getHeaderTextStyle(double ffem, double fem) {
    return TextStyle(
      fontSize: 16 * ffem,
      fontWeight: FontWeight.w600,
      height: 1.1725 * ffem / fem,
      color: Colors.white,
    );
  }

  TextStyle _getTextStyle(double ffem, double fem, {bool isBold = true}) {
    return TextStyle(
      fontSize: 12 * ffem,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      height: 1.1725 * ffem / fem,
      color: const Color(0xff3d3d3d),
    );
  }

  String _getDateText(bool isWO, Map<String, dynamic> currentItem) {
    if (isWO) {
      return _formatDate(currentItem['deliveryDate'] ?? '');
    } else {
      final dateString = _formatDate(currentItem['deliveryDate'] ?? '');
      final timeString = (currentItem['deliveryDate']?.length ?? 0) > 11
          ? currentItem['deliveryDate']!.substring(11)
          : '';
      return timeString.isNotEmpty
          ? '$dateString\n                            $timeString'
          : dateString;
    }
  }

  String _formatDate(String dateString) {
    try {
      return dateString.split(' ')[0];
    } catch (e) {
      return dateString;
    }
  }
}

TextStyle safeGoogleFont(
  String fontFamily, {
  required double fontSize,
  required FontWeight fontWeight,
  required double height,
  required Color color,
}) {
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );
}

//checked
