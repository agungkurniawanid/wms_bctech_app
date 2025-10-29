import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';

class GrinConstants {
  static const Color primaryColor = hijauGojek;
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2D2D2D);
  static const Color textSecondaryColor = Color(0xFF6B7280);

  static const List<String> sortOptions = [
    'Created Date',
    'GR ID',
    'PO Number',
  ];
  static String defaultSort = 'Created Date';
}
