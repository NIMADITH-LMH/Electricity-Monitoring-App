import 'package:flutter/material.dart';

class CardThemeHelper {
  static CardTheme getCardThemeForBackground() {
    return CardTheme(
      elevation: 4,
      color: Colors.white.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
  
  static TextStyle getTextStyleForBackground({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      shadows: [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  }
  
  static TextStyle getHeadingStyle() {
    return getTextStyleForBackground(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle getSubheadingStyle() {
    return getTextStyleForBackground(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle getBodyTextStyle() {
    return getTextStyleForBackground(
      fontSize: 14,
      color: Colors.black87,
    );
  }
}
