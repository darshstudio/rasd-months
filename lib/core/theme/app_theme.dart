import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String fontFamily = 'IBMPlexSansArabic';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: const [fontFamily, 'sans-serif'],
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.lightSurface,
        error: AppColors.errorRed,
        onPrimary: AppColors.lightSurface,
        onSecondary: AppColors.lightSurface,
        onSurface: AppColors.primaryDark,
        onError: AppColors.white,
        outline: AppColors.mutedBorder,
      ),
      scaffoldBackgroundColor: AppColors.neutralBackground,
      
      // Cards merge seamlessly with white background (0 elevation, no border lines)
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
        ),
      ),
      
      // Seamless AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutralBackground,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      // Dialog Theme merging with surface
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.mutedBorder, width: 1),
        ),
      ),

      // Input Fields with clean subtle border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mutedBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mutedBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.secondaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),

      // Material 3 Dropdown & Popup Menu Themes
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.lightSurface),
          elevation: const WidgetStatePropertyAll(2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.mutedBorder, width: 1),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.mutedBorder, width: 1),
        ),
      ),

      // Buttons with distinct styling, borders & colors (height 48dp)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.lightSurface,
          enabledMouseCursor: SystemMouseCursors.click,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          foregroundColor: AppColors.primaryDark,
          enabledMouseCursor: SystemMouseCursors.click,
          side: const BorderSide(color: AppColors.secondaryDark, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          foregroundColor: AppColors.primaryDark,
          enabledMouseCursor: SystemMouseCursors.click,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
    );
  }
}
