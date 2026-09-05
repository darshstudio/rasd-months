import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const String fontFamily = 'IBMPlexSansArabic';
  static const String fallbackFontFamily = 'IBMPlexSansArabic';

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.rubikTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
        displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.secondaryText),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondaryText),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.secondaryText),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightSurface,
        error: AppColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
        outline: AppColors.mutedBorder,
      ),
      scaffoldBackgroundColor: AppColors.neutralBackground,
      canvasColor: AppColors.lightSurface,
      cardColor: AppColors.lightSurface,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: AppColors.primaryDark.withValues(alpha: 0.05),
      
      // Card Theme (Clean white surface with 12px radius & slate border)
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.mutedBorder, width: 1),
        ),
      ),
      
      // Minimal Clean TabBar Theme
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.secondaryDark,
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.mutedBorder,
        space: 1,
        thickness: 1,
      ),

      // Seamless AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutralBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.mutedBorder, width: 1),
        ),
      ),

      // Input Fields with Dark Slate Focus Ring
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mutedBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mutedBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),

      // Material 3 Dropdown & Popup Menu Themes (Clean Pure White Surface & Slate Borders)
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.lightSurface),
          elevation: const WidgetStatePropertyAll(6),
          shadowColor: const WidgetStatePropertyAll(Color(0x0C000000)),
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
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.mutedBorder, width: 1),
        ),
      ),

      // Primary Button (Slate 900 Dark Container, 10px radius)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          minimumSize: const Size(0, 44),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          enabledMouseCursor: SystemMouseCursors.click,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),

      // Secondary Button (Outlined Dark Slate, 10px radius)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.primaryDark,
          enabledMouseCursor: SystemMouseCursors.click,
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.primaryDark,
          enabledMouseCursor: SystemMouseCursors.click,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
