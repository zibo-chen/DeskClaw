import 'package:flutter/material.dart';

/// DeskClaw design system constants
class AppColors {
  AppColors._();

  // Primary brand color (blue-purple like the reference)
  static const primary = Color(0xFF5B6ABF);
  static const primaryLight = Color(0xFF7C8ADB);
  static const primaryDark = Color(0xFF3D4A9E);

  // Sidebar
  static const sidebarBg = Color(0xFFF8F9FC);
  static const sidebarText = Color(0xFF4A4D5C);
  static const sidebarActiveText = Color(0xFF5B6ABF);
  static const sidebarActiveBg = Color(0xFFEEF0FA);
  static const sidebarSection = Color(0xFF9498A8);

  // Chat panel
  static const chatListBg = Color(0xFFFFFFFF);
  static const chatListBorder = Color(0xFFE8EAF0);

  // Main content
  static const mainBg = Color(0xFFF5F6FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF5F6FA);
  static const inputBorder = Color(0xFFE0E3EB);

  // Text
  static const textPrimary = Color(0xFF1A1D2E);
  static const textSecondary = Color(0xFF6B7080);
  static const textHint = Color(0xFFA0A5B5);

  // Accents
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);

  // Dark theme
  static const darkBg = Color(0xFF1E1E2E);
  static const darkSidebarBg = Color(0xFF252536);
  static const darkCardBg = Color(0xFF2A2A3C);
  static const darkTextPrimary = Color(0xFFE0E0E8);
  static const darkTextSecondary = Color(0xFF9498A8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.mainBg,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.chatListBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.chatListBorder,
      thickness: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCardBg,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
    ),
  );
}
