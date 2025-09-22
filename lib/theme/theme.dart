import 'package:flutter/material.dart';

// Define your brand colors
class AppColors {
  // Primary brand colors
  static const Color primaryPurple = Color(0xFFfa5eff); // Your main purple
  static const Color darkNavy = Color(0xFF080026); // Your dark color

  // Light mode colors - Purple palette
  static const Color lightBackground = Color.fromARGB(
    255,
    230,
    225,
    245,
  ); // Very light purple tint
  static const Color lightSurface = Color(0xFFF4F1FF); // Light purple tint
  static const Color lightSurfaceVariant = Color(0xFFEEE9FF); // Purple tint
  static const Color lightOnBackground = Color(0xFF2A1B3D); // Dark purple
  static const Color lightOnSurface = Color(0xFF3D2C5A); // Purple-tinted dark
  static const Color lightOutline = Color(0xFFD6C6E7); // Purple-tinted border
  static const Color lightSecondary = Color(0xFF6B46C1);

  // Dark mode colors - Purple palette
  static const Color darkBackground = Color.fromARGB(
    255,
    26,
    26,
    39,
  ); // Very dark purple tint
  static const Color darkSurface = Color.fromARGB(
    255,
    23,
    18,
    29,
  ); // Dark purple tint
  static const Color darkSurfaceVariant = Color(
    0xFF1E1724,
  ); // Purple-tinted dark
  static const Color darkOnBackground = Color(0xFFEFEBFF); // Light purple tint
  static const Color darkOnSurface = Color(0xFFE0D9FF); // Purple-tinted light
  static const Color darkOutline = Color(0xFF3D3247); // Purple-tinted border
  static const Color darkSecondary = Color(0xFF9F7AEA);
}

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Color Scheme
  colorScheme: const ColorScheme.light(
    // Primary colors
    primary: AppColors.primaryPurple,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFF0E6FF),
    onPrimaryContainer: AppColors.darkNavy,

    // Secondary colors
    secondary: AppColors.lightSecondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8DDFF),
    onSecondaryContainer: Color(0xFF2A1B5A),

    // Background colors
    surface: AppColors.lightBackground,
    onSurface: AppColors.lightOnBackground,
    surfaceContainerHighest: AppColors.lightSurface,
    surfaceContainerHigh: AppColors.lightSurfaceVariant,
    surfaceContainer: Color(0xFFF7F4FF), // Light purple tint
    surfaceContainerLow: Color(0xFFFCFAFF), // Very light purple tint
    // Outline and borders
    outline: AppColors.lightOutline,
    outlineVariant: Color(0xFFF0F0F0),

    // Error colors
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEF2F2),
    onErrorContainer: Color(0xFF7F1D1D),

    // Success colors (custom)
    tertiary: Color(0xFF059669),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFECFDF5),
    onTertiaryContainer: Color(0xFF064E3B),
  ),

  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.lightOnBackground,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.lightOnBackground,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.lightSurface,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: .1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryPurple,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppColors.primaryPurple.withValues(alpha: .3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),

  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  // Outlined Button Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryPurple,
      side: const BorderSide(color: AppColors.lightOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.lightBackground,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color.fromARGB(255, 226, 220, 230),
    selectedItemColor: AppColors.primaryPurple,
    unselectedItemColor: Color(0xFF9CA3AF),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // Color Scheme
  colorScheme: const ColorScheme.dark(
    // Primary colors
    primary: AppColors.primaryPurple,
    onPrimary: Colors.white,
    primaryContainer: AppColors.darkNavy,
    onPrimaryContainer: AppColors.primaryPurple,

    // Secondary colors
    secondary: AppColors.darkSecondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF3D2D6B),
    onSecondaryContainer: Color(0xFFE8DDFF),

    // Background colors
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkOnBackground,
    surfaceContainerHighest: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceVariant,
    surfaceContainer: Color(0xFF1B1520), // Dark purple tint
    surfaceContainerLow: Color(0xFF120E17), // Very dark purple tint
    // Outline and borders
    outline: AppColors.darkOutline,
    outlineVariant: Color(0xFF303030),

    // Error colors
    error: Color(0xFFEF4444),
    onError: Colors.white,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),

    // Success colors (custom)
    tertiary: Color(0xFF10B981),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF064E3B),
    onTertiaryContainer: Color(0xFFA7F3D0),
  ),

  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.darkOnBackground,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.darkOnBackground,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: .3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: AppColors.primaryPurple.withValues(alpha: .4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),

  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  // Outlined Button Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryPurple,
      side: const BorderSide(color: AppColors.darkOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primaryPurple,
    unselectedItemColor: Color(0xFF6B7280),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);
