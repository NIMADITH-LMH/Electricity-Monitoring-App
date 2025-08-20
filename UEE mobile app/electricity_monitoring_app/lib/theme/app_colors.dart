import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF4CAF50); // Green
  static const Color primaryLight = Color(0xFF80E27E);
  static const Color primaryDark = Color(0xFF087F23);

  // Accent colors
  static const Color accent = Color(0xFF03A9F4); // Light Blue
  static const Color accentLight = Color(0xFF67DAFF);
  static const Color accentDark = Color(0xFF007AC1);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF03A9F4), // Light Blue
    Color(0xFFFFC107), // Amber
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
  ];

  // Usage level colors (from good to bad)
  static const Color usageLow = Color(0xFF4CAF50); // Green
  static const Color usageModerate = Color(0xFFFFEB3B); // Yellow
  static const Color usageHigh = Color(0xFFFF9800); // Orange
  static const Color usageCritical = Color(0xFFF44336); // Red
}
