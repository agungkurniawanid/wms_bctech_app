import 'package:flutter/material.dart';

const Color kBlueColor = Color(0xFF2196F3);
const Color kWhiteColor = Color(0xFFFFFFFF);
const Color kBlackColor = Color(0xFF000000);
const Color kGreyColor = Color(0xFF9E9E9E);
const Color kGrey100Color = Color(0xFFF5F5F5);
const Color kBlackThemeColor = Color(0xFF121212);
const Color kBlack45Color = Color(0x73000000);
const Color kGreenColor = Color(0xFF4CAF50);
const Color kRedColor = Color(0xFFF44336);
const Color kRedAccentColor = Color(0xFFFF5252);
const Color kAmberColor = Color(0xFFFDA50F);
const Color kDarkBlueColor = Color(0xFF64B5F6);
const Color kDarkSurfaceColor = Color(0xFF1E1E1E);
const Color kDarkGreyColor = Color(0xFF616161);
const Color kSuccessColor = kGreenColor;
const Color kErrorColor = kRedColor;
const Color kWarningColor = kAmberColor;
const Color kInfoColor = kBlueColor;
const Color kPrimaryTextColor = kBlackColor;
const Color kSecondaryTextColor = kBlack45Color;
const Color kInverseTextColor = kWhiteColor;
const Color kPrimaryBackgroundColor = kWhiteColor;
const Color kSecondaryBackgroundColor = kGrey100Color;
const Color kScaffoldBackgroundColor = kWhiteColor;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kDividerColor = Color(0xFFEEEEEE);
const Color hijauGojekSecond = Color(0xFF058134);
const Color hijauGojek = Color(0xFF00AA13);
const String kSetPinTxt =
    "Looks like you haven't set a pin for your account. Please set it first to continue";

class AppTextTheme {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: kPrimaryTextColor,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: kPrimaryTextColor,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: kPrimaryTextColor,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: kPrimaryTextColor,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: kPrimaryTextColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: kPrimaryTextColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: kPrimaryTextColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: kPrimaryTextColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: kSecondaryTextColor,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kInverseTextColor,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: kInverseTextColor,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: kBlueColor,
      scaffoldBackgroundColor: kScaffoldBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: kWhiteColor,
        foregroundColor: kBlackColor,
        elevation: 0,
        centerTitle: true,
      ),

      colorScheme: const ColorScheme.light(
        primary: kBlueColor,
        secondary: kAmberColor,
        surface: kWhiteColor,
        error: kErrorColor,
        onPrimary: kWhiteColor,
        onSecondary: kBlackColor,
        onSurface: kBlackColor,
        onError: kWhiteColor,
      ),

      textTheme: const TextTheme(
        displayLarge: AppTextTheme.displayLarge,
        displayMedium: AppTextTheme.displayMedium,
        headlineLarge: AppTextTheme.headlineLarge,
        headlineMedium: AppTextTheme.headlineMedium,
        titleLarge: AppTextTheme.titleLarge,
        titleMedium: AppTextTheme.titleMedium,
        bodyLarge: AppTextTheme.bodyLarge,
        bodyMedium: AppTextTheme.bodyMedium,
        bodySmall: AppTextTheme.bodySmall,
        labelLarge: AppTextTheme.labelLarge,
        labelMedium: AppTextTheme.labelMedium,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          foregroundColor: kWhiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorderColor),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBlueColor),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: kDarkBlueColor,
      scaffoldBackgroundColor: kBlackThemeColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: kBlackThemeColor,
        elevation: 0,
        centerTitle: true,
      ),

      colorScheme: const ColorScheme.dark(
        primary: kDarkBlueColor,
        secondary: kAmberColor,
        surface: kDarkSurfaceColor,
        error: kRedAccentColor,
        onPrimary: kWhiteColor,
        onSecondary: kWhiteColor,
        onSurface: kWhiteColor,
        onError: kWhiteColor,
      ),
    );
  }
}

extension ThemeExtensions on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
