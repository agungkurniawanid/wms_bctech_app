import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';

class HomeRecentOrderCardWidget extends StatelessWidget {
  final String documentNo;
  final String partnerName;
  final String title1;
  final String value1;
  final String title2;
  final String value2;
  final String title3;
  final String value3;
  final String contextType;

  const HomeRecentOrderCardWidget({
    super.key,
    required this.documentNo,
    required this.partnerName,
    required this.title1,
    required this.value1,
    required this.title2,
    required this.value2,
    required this.title3,
    required this.value3,
    required this.contextType,
  });

  Color get _primaryColor {
    return contextType == 'PO'
        ? Colors
              .blueAccent // Indigo untuk PO
        : hijauGojek; // Emerald untuk SO
  }

  IconData get _headerIcon {
    return contextType == 'PO'
        ? Icons.shopping_cart_rounded
        : Icons.local_shipping_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // ✅ Dikurangi dari 320 ke 280
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16), // ✅ Dikurangi dari 20 ke 16
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ COMPACT HEADER - Type Badge & Partner Name Combined
            Container(
              padding: const EdgeInsets.all(16), // ✅ Dikurangi dari 20 ke 16
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor.withValues(alpha: 0.08),
                    _primaryColor.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // ✅ Dikurangi
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _headerIcon,
                          color: Colors.white,
                          size: 16, // ✅ Dikurangi dari 20 ke 16
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          contextType == 'PO' ? 'PO' : 'SO',
                          style: const TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Partner Name
                  Row(
                    children: [
                      Icon(
                        contextType == 'PO'
                            ? Icons.business_rounded
                            : Icons.person_rounded,
                        color: _primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contextType == 'PO' ? 'Vendor' : 'Customer',
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              partnerName,
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ COMPACT DETAILS SECTION
            Padding(
              padding: const EdgeInsets.all(16), // ✅ Dikurangi dari 20 ke 16
              child: Column(
                children: [
                  _buildCompactDetailRow(Icons.tag_rounded, title1, value1),
                  const SizedBox(height: 10), // ✅ Dikurangi dari 14 ke 10
                  _buildCompactDetailRow(
                    Icons.calendar_today_rounded,
                    title2,
                    value2,
                  ),
                  const SizedBox(height: 10),
                  _buildCompactDetailRow(
                    Icons.inventory_2_rounded,
                    title3,
                    value3,
                  ),
                ],
              ),
            ),

            // ✅ COMPACT FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ), // ✅ Dikurangi dari 14 ke 10
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.04),
                border: Border(
                  top: BorderSide(
                    color: _primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 11, // ✅ Dikurangi dari 12 ke 11
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12, // ✅ Dikurangi dari 14 ke 12
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // ✅ Dikurangi dari 8 ke 6
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14, // ✅ Dikurangi dari 16 ke 14
            color: _primaryColor,
          ),
        ),
        const SizedBox(width: 10), // ✅ Dikurangi dari 12 ke 10
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 10, // ✅ Dikurangi dari 11 ke 10
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 13, // ✅ Dikurangi dari 14 ke 13
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
