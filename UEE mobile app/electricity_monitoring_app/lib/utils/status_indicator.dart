import 'package:flutter/material.dart';

class StatusIndicator {
  // Get the appropriate color based on usage percentage
  static Color getStatusColor(double percentage) {
    if (percentage <= 70) return Colors.green;
    if (percentage <= 90) return Colors.orange;
    return Colors.red;
  }
  
  // Get status message based on usage percentage
  static String getStatusMessage(double percentage) {
    if (percentage <= 70) return "On track";
    if (percentage <= 90) return "Caution";
    return "Over budget";
  }
  
  // Get icon based on usage percentage
  static IconData getStatusIcon(double percentage) {
    if (percentage <= 70) return Icons.check_circle;
    if (percentage <= 90) return Icons.warning;
    return Icons.error;
  }
  
  // Get background color with reduced opacity for cards/containers
  static Color getBackgroundColor(double percentage) {
    if (percentage <= 70) return Colors.green.withOpacity(0.15);
    if (percentage <= 90) return Colors.orange.withOpacity(0.15);
    return Colors.red.withOpacity(0.15);
  }
  
  // Get status for a specific metric (kWh or cost)
  static Map<String, dynamic> getMetricStatus({
    required double current,
    required double max,
    String unit = '',
  }) {
    final double percentage = max > 0 ? (current / max) * 100 : 0.0;
    return {
      'percentage': percentage,
      'color': getStatusColor(percentage),
      'message': getStatusMessage(percentage),
      'icon': getStatusIcon(percentage),
      'background': getBackgroundColor(percentage),
      'remaining': max - current,
      'formattedRemaining': '${(max - current).toStringAsFixed(1)} $unit',
      'formattedPercentage': '${percentage.toStringAsFixed(1)}%',
    };
  }
}
