import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData buildTheme(Brightness brightness, Color primaryAccent) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: brightness,
        primary: primaryAccent,
        secondary: AppColors.secondary,
        surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        error: Colors.redAccent,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        bodyLarge: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        bodyMedium: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceLow,
        selectedItemColor: primaryAccent,
        unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        inactiveTrackColor: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3),
        thumbColor: primaryAccent,
        overlayColor: primaryAccent.withValues(alpha: 0.2),
      ),
    );
  }
}
