import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  TargetPlatform getPlatform(BuildContext context) {
    return Theme.of(context).platform;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}

TextStyle safeGoogleFont(
  String fontFamily, {
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) {
  try {
    return GoogleFonts.getFont(
      fontFamily,
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  } catch (exception, stackTrace) {
    debugPrint('Error loading font $fontFamily: $exception');
    debugPrint('Stack trace: $stackTrace');
    return GoogleFonts.roboto(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}

class AppTextStyles {
  static TextStyle displayLarge(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle displayMedium(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle headlineLarge(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle headlineMedium(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle titleLarge(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle titleMedium(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodyLarge(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodyMedium(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodySmall(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle labelLarge(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle labelMedium(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle labelSmall(BuildContext context) => safeGoogleFont(
    'Roboto',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

class AppUtils {
  static void hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  static Future<void> copyToClipboard({
    required BuildContext context,
    required String text,
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? 'Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static String formatNumber(num value, {String locale = 'en_US'}) {
    final formatter = NumberFormat('#,###', locale);
    return formatter.format(value);
  }

  static String formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getAdaptiveColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : Colors.black;
  }
}

extension ContextExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  void hideKeyboard() => AppUtils.hideKeyboard(this);
}

extension StringExtensions on String {
  bool get isNullOrEmpty => isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String truncate(int maxLength, {bool showEllipsis = true}) {
    if (length <= maxLength) return this;
    return showEllipsis
        ? '${substring(0, maxLength)}...'
        : substring(0, maxLength);
  }
}

// checked
