import 'package:flutter/material.dart';

class AppColors {
  // Professional Administrative Unified Color System
  
  // 1. Unified Background Everywhere (Sidebar, Title Bar, Canvas, Lists)
  static const Color neutralBackground = Color(0xFFF8FAFC); // Pure Slate (#F8FAFC)
  static const Color sidebarBackground = Color(0xFFF8FAFC); // Unified with neutralBackground
  static const Color lightSurface = Colors.white;            // Pure White (#FFFFFF)
  static const Color filterPillBackground = Color(0xFFF1F5F9);

  // 2. Sidebar Active/Inactive Items
  static const Color sidebarActiveBackground = Color(0xFF0F172A); // Slate 900 Dark Container
  static const Color sidebarActiveText = Colors.white;
  static const Color sidebarInactiveText = Color(0xFF475569);     // Slate 600 Text

  // 3. Professional Administrative Accents & Card Backgrounds (0 clown colors)
  static const Color primaryPurple = Color(0xFF1E293B);      // Slate 800 Dark Administrative
  static const Color primaryDark = Color(0xFF0F172A);        // Slate 900 Text & Headings
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);      // Slate 500 Subtitles & Muted
  static const Color secondaryDark = Color(0xFF64748B);
  static const Color buttonHoverDark = Color(0xFF334155);

  // 4. Clean Monochromatic Card Surfaces
  static const Color cardLavender = Color(0xFFF8FAFC);       // Slate 50 Clean Surface
  static const Color cardRose = Color(0xFFF1F5F9);           // Slate 100 Soft Surface
  static const Color cardCyanTint = Color(0xFFF8FAFC);

  // 5. Action Buttons & Administrative Accents
  static const Color accentPurple = Color(0xFF2563EB);       // Royal Administrative Blue
  static const Color accentPink = Color(0xFF3B82F6);         // Clean Blue
  static const Color digitalCyan = Color(0xFF2563EB);
  static const Color secondaryAccent = Color(0xFF2563EB);
  static const Color cyanHover = Color(0xFF1D4ED8);
  static const Color cyanContainer = Color(0xFFEFF6FF);
  static const Color cyanGlow = Color(0x1F2563EB);

  // 6. Borders & Subtle Shadows
  static const Color mutedBorder = Color(0xFFE2E8F0);       // Slate 200 Border
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  static const BoxShadow floatingShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  // 7. Utility & Status
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
}



