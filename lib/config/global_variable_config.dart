// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class GlobalVar {
  static int newDataCount = 0;
  static bool isGoingToLogout = false;
  static bool isDark = false;
  static String versionApps = '';
  static bool newVersion = false;
  static double width = 0.0;
  static double height = 0.0;
  static String email = '';
  static String pass = '';
  static bool smartLogin = false;
  static bool autoUpdate = false;
  static bool usePin = true;
  static String calendar = "N";
  static String dir = '';

  static const String urlIos =
      'https://apps.apple.com/id/app/cpma/id1550720257';
  static const String urlAndroid =
      'https://play.google.com/store/apps/details?id=id.co.cp.cpma';

  static final ValueNotifier<int> discountfeedNotifier = ValueNotifier(0);
  static final ValueNotifier<int> discountOtherNotifier = ValueNotifier(0);
  static final ValueNotifier<bool> widgetDetailNoLineCard = ValueNotifier(true);
  static final ValueNotifier<bool> widgetdiscountFeed2 = ValueNotifier(true);
  static final ValueNotifier<bool> widgetdiscountOther = ValueNotifier(true);
  static final TextEditingController myController = TextEditingController();
  static String discountFeed2 = "";
  static String flagcheckbox = "";
  static String choicecategory = "";
  static String forchoice = "";
  static String validationdocumentno = "";

  static bool isNumeric(String s) {
    if (s.isEmpty) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  static void darkChecker(BuildContext context) {
    try {
      final Brightness brightnessValue = MediaQuery.platformBrightnessOf(
        context,
      );
      isDark = brightnessValue == Brightness.dark;
      _setStatusBarColor(Theme.of(context).primaryColor, isDark);
    } catch (e) {
      Logger().e(e);
    }
  }

  static void _setStatusBarColor(Color color, bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  static void setStatusBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: theme.primaryColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  static void setTransparentStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
    );
  }

  static void setColoredStatusBar(Color color, {bool darkIcons = true}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
      ),
    );
  }

  static void configLoading(bool isDark) {
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..loadingStyle = isDark ? EasyLoadingStyle.light : EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..maskColor = Colors.blue.withValues(alpha: 0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  static void dispose() {
    myController.dispose();
    discountfeedNotifier.dispose();
    discountOtherNotifier.dispose();
    widgetDetailNoLineCard.dispose();
    widgetdiscountFeed2.dispose();
    widgetdiscountOther.dispose();
  }
}
