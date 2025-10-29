import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentSR extends StatelessWidget {
  final int index;
  final IconData? icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final double height;
  final NumberFormat currency = NumberFormat("#,###", "en_US");

  // Data dummy untuk simulasi UI
  final List<Map<String, dynamic>> dummySRList = [
    {
      'documentNo': 'SR-001',
      'deliveryDate': '2023-12-01',
      'totalItem': '15',
      'detail': [],
    },
    {
      'documentNo': 'SR-002',
      'deliveryDate': '2023-12-02',
      'totalItem': '20',
      'detail': [],
    },
    {
      'documentNo': 'SR-003',
      'deliveryDate': '2023-12-03',
      'totalItem': '8',
      'detail': [],
    },
  ];

  // Variabel global dummy
  final String dummyChoiceCategory = 'ALL';

  RecentSR({
    super.key,
    required this.index,
    this.icon,
    this.elevation = 9,
    this.iconSize = 0.10,
    this.fontSize = 14.0,
    this.height = 40,
  });

  // Method untuk simulasi perhitungan CTN
  String _calculateCTN() {
    try {
      // Data dummy - return nilai acak untuk simulasi
      return (10 + index).toString();
    } catch (e) {
      debugPrint('Error calculating CTN: $e');
      return "0";
    }
  }

  // Method untuk simulasi perhitungan PCS
  String _calculatePCS() {
    try {
      // Data dummy - return nilai acak untuk simulasi
      return (25 + index * 5).toString();
    } catch (e) {
      debugPrint('Error calculating PCS: $e');
      return "0";
    }
  }

  // Method untuk simulasi total CTN
  String _calculateTotalCTN() {
    try {
      final calcuCTN = _calculateCTN();
      return '$calcuCTN CTN';
    } catch (e) {
      debugPrint('Error calculating total CTN: $e');
      return '0 CTN';
    }
  }

  // Method untuk simulasi total PCS
  String _calculateTotalPCS() {
    try {
      final calcuPCS = _calculatePCS();
      return '$calcuPCS PCS';
    } catch (e) {
      debugPrint('Error calculating total PCS: $e');
      return '0 PCS';
    }
  }

  // Widget untuk simulasi status AB
  InlineSpan _buildInlineSpanAB(int index) {
    // Data dummy - simulasi kondisi berdasarkan index
    if (dummyChoiceCategory == "ALL") {
      if (index % 3 == 0) {
        return WidgetSpan(
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        );
      } else if (index % 3 == 1) {
        return WidgetSpan(
          child: Image.asset(
            'data/images/stars_red.png',
            width: 13,
            height: 13,
          ),
        );
      }
    }
    return const TextSpan(text: '');
  }

  // Widget untuk simulasi status CH
  InlineSpan _buildInlineSpanCH(int index) {
    // Data dummy - simulasi kondisi berdasarkan index
    if (dummyChoiceCategory == "ALL") {
      if (index % 3 == 1) {
        return WidgetSpan(
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
        );
      } else if (index % 3 == 2) {
        return WidgetSpan(
          child: Image.asset(
            'data/images/stars_green.png',
            width: 13,
            height: 13,
          ),
        );
      }
    }
    return const TextSpan(text: '');
  }

  // Widget untuk simulasi status FZ
  InlineSpan _buildInlineSpanFZ(int index) {
    // Data dummy - simulasi kondisi berdasarkan index
    if (dummyChoiceCategory == "ALL") {
      if (index % 3 == 2) {
        return WidgetSpan(
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
        );
      } else if (index % 3 == 0) {
        return WidgetSpan(
          child: Image.asset(
            'data/images/stars_blue.png',
            width: 13,
            height: 13,
          ),
        );
      }
    }
    return const TextSpan(text: '');
  }

  Color _getHeaderColor() {
    // Data dummy - warna berdasarkan kategori
    switch (dummyChoiceCategory) {
      case "FZ":
        return Colors.blue;
      case "CH":
        return Colors.green;
      case "ALL":
        return Colors.orange;
      default:
        return const Color(0xfff44236);
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '-';

      // Format tanggal sederhana untuk simulasi
      // Dalam implementasi nyata, gunakan DateFormat
      return dateString.split(' ')[0]; // Ambil hanya bagian tanggal
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    // Safety check untuk index
    if (index < 0 || index >= dummySRList.length) {
      return Container(
        width: 155 * fem,
        height: 110 * fem,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8 * fem),
        ),
        child: Center(
          child: Text(
            'No Data',
            style: _buildTextStyle(
              ffem: ffem,
              fem: fem,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final outModel = dummySRList[index];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 155 * fem,
          height: 110 * fem,
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
              // Header
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
                    outModel['documentNo'] ?? '-',
                    textAlign: TextAlign.center,
                    style: _buildTextStyle(
                      ffem: ffem,
                      fem: fem,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              _buildInfoRow(
                fem: fem,
                ffem: ffem,
                label: 'Request Date:',
                value: _formatDate(outModel['deliveryDate'] ?? ''),
              ),

              _buildInfoRow(
                fem: fem,
                ffem: ffem,
                label: 'Total Item:',
                value: outModel['totalItem']?.toString() ?? '0',
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
                          style: _buildTextStyle(
                            ffem: ffem,
                            fem: fem,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff3d3d3d),
                          ),
                          children: const [TextSpan(text: 'Total Quantity:  ')],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _calculateTotalCTN(),
                          style: _buildTextStyle(
                            ffem: ffem,
                            fem: fem,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff3d3d3d),
                          ),
                        ),
                        Text(
                          _calculateTotalPCS(),
                          style: _buildTextStyle(
                            ffem: ffem,
                            fem: fem,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff3d3d3d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 0),
                constraints: BoxConstraints(maxWidth: 150 * fem),
                child: RichText(
                  text: TextSpan(
                    style: _buildTextStyle(
                      ffem: ffem,
                      fem: fem,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff3d3d3d),
                    ),
                    children: [
                      _buildInlineSpanAB(index),
                      const TextSpan(text: ' '),
                      _buildInlineSpanCH(index),
                      const TextSpan(text: ' '),
                      _buildInlineSpanFZ(index),
                      const TextSpan(text: ''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required double fem,
    required double ffem,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 4 * fem),
      child: RichText(
        text: TextSpan(
          style: _buildTextStyle(
            ffem: ffem,
            fem: fem,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xff3d3d3d),
          ),
          children: [
            TextSpan(text: '$label   '),
            TextSpan(
              text: value,
              style: _buildTextStyle(
                ffem: ffem,
                fem: fem,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xff3d3d3d),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _buildTextStyle({
    required double ffem,
    required double fem,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: fontSize * ffem,
      fontWeight: fontWeight,
      height: 1.1725 * ffem / fem,
      color: color,
    );
  }
}
