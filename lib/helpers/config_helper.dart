// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ConfigHelper {
  static void configLoading() {
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..maskColor = Colors.blue.withValues(alpha: 0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }
}
