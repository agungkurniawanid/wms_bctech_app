import 'package:get/get.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/stock_check_controlller.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class RecentStockCheck extends StatelessWidget {
  final int index;
  final IconData icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final currency = NumberFormat("#,###", "en_US");
  final double height;

  final StockCheckVM stockCheckVM = Get.find();
  final GlobalVM globalVM = Get.find();

  RecentStockCheck({
    super.key,
    this.index = 0,
    this.icon = Icons.check,
    this.elevation = 9,
    this.iconSize = 0.10,
    this.fontSize = 14.0,
    this.height = 40,
  });

  String _formatLastTransaction(String formattedUpdatedAt) {
    if (formattedUpdatedAt.contains("Today") ||
        formattedUpdatedAt.contains("Yesterday")) {
      return formattedUpdatedAt;
    }
    return globalVM.stringToDateWithTime(formattedUpdatedAt);
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    if (stockCheckVM.toliststock.length <= index) {
      return SizedBox();
    }

    final stockItem = stockCheckVM.toliststock[index];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 155 * fem,
          height: 100 * fem,
          decoration: BoxDecoration(
            color: Color(0xffffffff),
            borderRadius: BorderRadius.circular(8 * fem),
            boxShadow: [
              BoxShadow(
                color: Color(0x3f000000),
                offset: Offset(0 * fem, 4 * fem),
                blurRadius: 5 * fem,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 6 * fem),
                width: double.infinity,
                height: 31 * fem,
                decoration: BoxDecoration(
                  color: Color(0xfff44236),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8 * fem),
                    topRight: Radius.circular(8 * fem),
                  ),
                ),
                child: Center(
                  child: Text(
                    stockItem.location ?? 'Unknown Location',
                    textAlign: TextAlign.center,
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 16 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xffffffff),
                    ),
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.fromLTRB(4 * fem, 0 * fem, 0 * fem, 4 * fem),
                child: RichText(
                  text: TextSpan(
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 12 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff3d3d3d),
                    ),
                    children: [
                      TextSpan(text: 'Last Transaction:'),
                      TextSpan(
                        text:
                            '\n${_formatLastTransaction(stockItem.formattedUpdatedAt ?? '')}',
                        style: safeGoogleFont(
                          'Roboto',
                          fontSize: 12 * ffem,
                          fontWeight: FontWeight.w400,
                          height: 1.1725 * ffem / fem,
                          color: Color(0xff3d3d3d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.fromLTRB(4 * fem, 0 * fem, 0 * fem, 4 * fem),
                child: RichText(
                  text: TextSpan(
                    style: safeGoogleFont(
                      'Roboto',
                      fontSize: 12 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff3d3d3d),
                    ),
                    children: [
                      TextSpan(text: 'Total Item: '),
                      TextSpan(
                        text: '${stockItem.detail?.length ?? 0}',
                        style: safeGoogleFont(
                          'Roboto',
                          fontSize: 12 * ffem,
                          fontWeight: FontWeight.w400,
                          height: 1.1725 * ffem / fem,
                          color: Color(0xff3d3d3d),
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
}
