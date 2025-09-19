import 'package:flutter/material.dart';

/// Defines thresholds for electricity usage notifications.
/// 
/// Each threshold has a percentage level, color name, channel ID for notifications,
/// and a color for visual representation.
class UsageThreshold {
  /// Percentage of budget at which notification should trigger
  final int percent;
  
  /// Human-readable name of the alert color
  final String colorName;
  
  /// Android notification channel ID
  final String channelId;
  
  /// Color to use for the notification and UI elements
  final Color color;

  /// Creates a new usage threshold with the specified parameters
  UsageThreshold(this.percent, this.colorName, this.channelId, this.color);
  
  /// Converts threshold to a map for storage in Firestore
  Map<String, dynamic> toMap() {
    return {
      'percent': percent,
      'colorName': colorName,
      'channelId': channelId,
      // Color can't be directly stored, but we could store the value
      'colorValue': color.value,
    };
  }
  
  /// Creates a threshold from a Firestore map
  factory UsageThreshold.fromMap(Map<String, dynamic> map) {
    return UsageThreshold(
      map['percent'] as int,
      map['colorName'] as String,
      map['channelId'] as String,
      Color(map['colorValue'] as int),
    );
  }
}