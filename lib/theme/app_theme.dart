import 'package:flutter/material.dart';

class AppColors {
  // Primary Gold Colors (from logo)
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFE6C54A);
  static const Color darkGold = Color(0xFFB8941F);
  static const Color deepGold = Color(0xFF9C7E15);

  // Background Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color surfaceColor = Color(0xFF3A3A3A);

  // Text Colors
  static const Color goldText = Color(0xFFD4AF37);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFFB0B0B0);
  static const Color lightGreyText = Color(0xFF808080);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);

  // Wallet Currency Colors
  static const Color usdColor = Color(0xFF4CAF50);
  static const Color euroColor = Color(0xFF2196F3);
  static const Color srdColor = Color(0xFFFF9800);

  // Gradient Colors
  static const LinearGradient goldGradient = LinearGradient(
    colors: [lightGold, primaryGold, darkGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, cardBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGold,
        secondary: AppColors.lightGold,
        surface: AppColors.cardBackground,
        background: AppColors.darkBackground,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.whiteText,
        onBackground: AppColors.whiteText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.goldText,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          side: const BorderSide(color: AppColors.primaryGold),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.cardBackground,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.greyText),
        hintStyle: const TextStyle(color: AppColors.lightGreyText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class AppConstants {
  // Currency Types
  static const String usdCurrency = 'USD';
  static const String euroCurrency = 'EUR';
  static const String srdCurrency = 'SRD';

  // Gold Units
  static const String goldUnit = 'grams';
  static const double kgToGrams = 1000.0;

  // Default Values
  static const double defaultWalletAmount = 0.0;
  static const double defaultGoldPoints = 0.0;

  // App Strings
  static const String appName = 'OUROPAY';
  static const String appTagline = 'DIGITAL GOLD, REAL VALUE.';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
}
