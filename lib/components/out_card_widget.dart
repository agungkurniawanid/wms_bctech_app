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

  // Data dummy untuk simulasi UI
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

  // Method untuk simulasi perhitungan CTN
  String _calcuCTN() {
    try {
      // Data dummy - dalam implementasi nyata ini akan diisi dari controller
      return '10'; // Contoh nilai dummy
    } catch (e) {
      debugPrint('Error in _calcuCTN: $e');
      return '0';
    }
  }

  // Method untuk simulasi perhitungan warna
  int calcuforcolour() {
    // Data dummy - return nilai acak untuk simulasi
    return 2; // Contoh nilai dummy
  }

  // Method untuk simulasi perhitungan PCS
  String _calcuPCS() {
    try {
      // Data dummy - dalam implementasi nyata ini akan diisi dari controller
      return '25'; // Contoh nilai dummy
    } catch (e) {
      debugPrint('Error in _calcuPCS: $e');
      return '0';
    }
  }

  // Method untuk simulasi total CTN
  String _calculTotal() {
    try {
      final calcuCTN = _calcuCTN();
      return '$calcuCTN CTN';
    } catch (e) {
      debugPrint('Error in _CalculTotal: $e');
      return '0 CTN';
    }
  }

  // Method untuk simulasi total PCS
  String _calcutotalpcs() {
    try {
      final calcuPCS = _calcuPCS();
      return '$calcuPCS PCS';
    } catch (e) {
      debugPrint('Error in _calcutotalpcs: $e');
      return '0 PCS';
    }
  }

  // Widget untuk simulasi status AB
  InlineSpan getInlineSpan(int index) {
    // Data dummy - dalam implementasi nyata ini akan berdasarkan kondisi tertentu
    return const WidgetSpan(
      child: CircleAvatar(backgroundColor: Colors.red, radius: 5.5),
    );
  }

  // Widget untuk simulasi status CH
  InlineSpan getInlineSpanCH(int index) {
    // Data dummy - dalam implementasi nyata ini akan berdasarkan kondisi tertentu
    return const WidgetSpan(
      child: CircleAvatar(backgroundColor: Colors.green, radius: 5.5),
    );
  }

  // Widget untuk simulasi status FZ
  InlineSpan getInlineSpanFZ(int index) {
    // Data dummy - dalam implementasi nyata ini akan berdasarkan kondisi tertentu
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
          // Header Section
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

          // Date Section
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

          // Quantity Section
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
    // Simulasi kondisi choiceout.value == "ALL"
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

  // Helper method untuk format tanggal sederhana
  String _formatDate(String dateString) {
    try {
      // Format tanggal sederhana untuk simulasi
      return dateString.split(' ')[0]; // Ambil hanya bagian tanggal
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
