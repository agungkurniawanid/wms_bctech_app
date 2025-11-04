import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';

class RecentIn extends StatelessWidget {
  RecentIn({
    super.key,
    required this.index,
    this.icon,
    this.elevation = 9,
    this.iconSize = 0.10,
    this.fontSize = 14.0,
    this.height = 40,
  });

  final int index;
  final IconData? icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final double height;

  final InVM inVM = Get.find();
  final GlobalVM globalVM = Get.find();

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;
    final poItem = inVM.tolistPO[index];

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
              // Header Section
              Container(
                width: double.infinity,
                height: 31 * fem,
                margin: EdgeInsets.only(bottom: 6 * fem),
                decoration: BoxDecoration(
                  color: _getHeaderColor(globalVM.choicecategory.value),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8 * fem),
                    topRight: Radius.circular(8 * fem),
                  ),
                ),
                child: Center(
                  child: Text(
                    poItem.ebeln ?? '',
                    textAlign: TextAlign.center,
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 16 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 4 * fem),
                child: RichText(
                  text: TextSpan(
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 12 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: const Color(0xff3d3d3d),
                    ),
                    children: [
                      TextSpan(
                        text: _getVendorText(poItem.lifnr ?? ''),
                        style: safeGoogleFont(
                          'Roboto',
                          fontSize: 12 * ffem,
                          fontWeight: FontWeight.w600,
                          height: 1.2175 * ffem / fem,
                          color: const Color(0xff202020),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.fromLTRB(4 * fem, 0, 0, 0),
                constraints: BoxConstraints(maxWidth: 130 * fem),
                child: RichText(
                  text: TextSpan(
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 12 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: const Color(0xff3d3d3d),
                    ),
                    children: [
                      const TextSpan(text: 'Last Updated:  '),
                      TextSpan(
                        text: globalVM.stringToDateWithTime(
                          poItem.created ?? '',
                        ),
                        style: safeGoogleFont(
                          'Roboto',
                          fontSize: 12 * ffem,
                          fontWeight: FontWeight.w400,
                          height: 1.1725 * ffem / fem,
                          color: const Color(0xff3d3d3d),
                        ),
                      ),
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

  Color _getHeaderColor(String category) {
    switch (category) {
      case 'FZ':
        return Colors.blue;
      case 'CH':
        return Colors.green;
      case 'ALL':
        return Colors.orange;
      default:
        return const Color(0xfff44236);
    }
  }

  String _getVendorText(String lifnr) {
    if (lifnr.length > 42) {
      return 'Vendor:   ${lifnr.substring(0, 7)}\n${lifnr.substring(8, 43)}';
    } else if (lifnr.contains('Crown Pacific Investments') ||
        lifnr.contains('Australian Fruit Juice')) {
      return 'Vendor:   ${lifnr.substring(0, 7)}\n${lifnr.substring(8)}';
    } else {
      return 'Vendor:   $lifnr';
    }
  }
}
