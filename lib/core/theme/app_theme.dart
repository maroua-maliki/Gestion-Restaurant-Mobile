import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary colors - Restaurant Warm Theme
  static const Color primary = Color(0xFFE85D04); // Warm Orange
  static const Color primaryLight = Color(0xFFFB923C);
  static const Color primaryDark = Color(0xFFD4500A);

  // Secondary colors - Brown/Gold
  static const Color secondary = Color(0xFF3D2914); // Deep Brown
  static const Color secondaryLight = Color(0xFFD4A574); // Gold
  static const Color secondaryDark = Color(0xFF2A1D0E);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral colors
  static const Color background = Color(0xFFFFF8F0); // Cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF5E6);
  static const Color textPrimary = Color(0xFF3D2914); // Deep Brown text
  static const Color textSecondary = Color(0xFF8B7E74);
  static const Color textTertiary = Color(0xFFA99C91);
  static const Color border = Color(0xFFE6DCCF);
  static const Color divider = Color(0xFFE6DCCF);

  // Role-based accent colors (adjusted for warm theme)
  static const Color adminAccent = Color(0xFFE85D04);    // Warm Orange
  static const Color chefAccent = Color(0xFFD4A574);     // Gold
  static const Color serveurAccent = Color(0xFF8B5E3C); // Bronze/Brown

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE85D04), Color(0xFFC2410C)],
  );

  static const LinearGradient chefGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A574), Color(0xFFB58B5D)],
  );

  static const LinearGradient serveurGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5E3C), Color(0xFF6D4C41)],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.secondary, // Deep Brown for AppBar
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: AppColors.primary), // Orange accents
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.secondaryLight.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.secondaryLight.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
