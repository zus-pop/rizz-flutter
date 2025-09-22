import 'package:flutter/material.dart';

/// Helper class to access theme colors easily throughout the app
class AppTheme {
  /// Get the current theme colors based on context
  static ColorScheme colors(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Check if current theme is dark mode
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get primary color
  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Get surface color
  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get background color
  static Color background(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get text color for surface
  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Get secondary color
  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// Get outline/border color
  static Color outline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  /// Get error color
  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// Get success color (using tertiary)
  static Color success(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  /// Get warning color
  static Color warning(BuildContext context) {
    return const Color(0xFFFF9800);
  }

  /// Get info color
  static Color info(BuildContext context) {
    return const Color(0xFF2196F3);
  }

  /// Get on primary color
  static Color onPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  /// Get on secondary color
  static Color onSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  /// Get on tertiary color
  static Color onTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiary;
  }

  /// Get on error color
  static Color onError(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

  /// Get card color
  static Color card(BuildContext context) {
    return Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// Common text styles
  static TextStyle get headline1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static TextStyle get headline2 => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static TextStyle get headline3 =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w600);

  static TextStyle get headline4 =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get body1 =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.normal);

  static TextStyle get body2 =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.normal);

  static TextStyle get caption =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

  static TextStyle get button =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}

/// Extension to add theme-aware colors to BuildContext
extension ThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Quick access to common colors
  Color get primary => colors.primary;
  Color get surface => colors.surface;
  Color get onSurface => colors.onSurface;
  Color get outline => colors.outline;
  Color get error => colors.error;
  Color get onPrimary => colors.onPrimary;
  Color get onSecondary => colors.onSecondary;
  Color get onTertiary => colors.onTertiary;
  Color get onError => colors.onError;
}
