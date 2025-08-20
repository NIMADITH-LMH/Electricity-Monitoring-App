import 'package:flutter/material.dart';

// Represents usage analytics data for a specific time period
class UsageAnalyticsModel {
  final DateTime startDate;
  final DateTime endDate;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final double totalKwh;
  final double totalCost;
  final double avgKwhPerDay;
  final double avgCostPerDay;
  final double percentChangeKwh; // Compared to previous period
  final double percentChangeCost; // Compared to previous period

  UsageAnalyticsModel({
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.totalKwh,
    required this.totalCost,
    required this.avgKwhPerDay,
    required this.avgCostPerDay,
    this.percentChangeKwh = 0,
    this.percentChangeCost = 0,
  });

  // Helper method to determine if usage has increased or decreased
  bool get isKwhIncreased => percentChangeKwh > 0;
  bool get isCostIncreased => percentChangeCost > 0;

  // Helper method to get appropriate color based on trends
  // Red for increase, green for decrease (since we want to reduce consumption)
  Color getKwhTrendColor() {
    if (percentChangeKwh == 0) return Colors.grey;
    return isKwhIncreased ? Colors.red : Colors.green;
  }

  Color getCostTrendColor() {
    if (percentChangeCost == 0) return Colors.grey;
    return isCostIncreased ? Colors.red : Colors.green;
  }

  // Helper method to get a formatted string for the percent change
  String getFormattedKwhChange() {
    if (percentChangeKwh == 0) return "No change";
    String direction = isKwhIncreased ? "↑" : "↓";
    return "$direction ${percentChangeKwh.abs().toStringAsFixed(1)}%";
  }

  String getFormattedCostChange() {
    if (percentChangeCost == 0) return "No change";
    String direction = isCostIncreased ? "↑" : "↓";
    return "$direction ${percentChangeCost.abs().toStringAsFixed(1)}%";
  }
}

// Model for usage prediction
class UsagePredictionModel {
  final DateTime date;
  final double predictedKwh;
  final double predictedCost;
  final double confidencePercentage;

  UsagePredictionModel({
    required this.date,
    required this.predictedKwh,
    required this.predictedCost,
    this.confidencePercentage = 70.0, // Default confidence level
  });
}

// Model for time-based usage data point (for charts)
class UsageDataPoint {
  final DateTime date;
  final double kwh;
  final double cost;

  UsageDataPoint({required this.date, required this.kwh, required this.cost});
}

// Model for usage breakdown by time of day
class DailyUsageBreakdown {
  final double morningUsage; // 6 AM - 12 PM
  final double afternoonUsage; // 12 PM - 6 PM
  final double eveningUsage; // 6 PM - 12 AM
  final double nightUsage; // 12 AM - 6 AM

  DailyUsageBreakdown({
    required this.morningUsage,
    required this.afternoonUsage,
    required this.eveningUsage,
    required this.nightUsage,
  });

  // Get total usage
  double get totalUsage =>
      morningUsage + afternoonUsage + eveningUsage + nightUsage;

  // Get percentages
  double get morningPercentage =>
      totalUsage > 0 ? (morningUsage / totalUsage) * 100 : 0;
  double get afternoonPercentage =>
      totalUsage > 0 ? (afternoonUsage / totalUsage) * 100 : 0;
  double get eveningPercentage =>
      totalUsage > 0 ? (eveningUsage / totalUsage) * 100 : 0;
  double get nightPercentage =>
      totalUsage > 0 ? (nightUsage / totalUsage) * 100 : 0;

  // Identify peak usage time
  String get peakUsageTime {
    final values = [morningUsage, afternoonUsage, eveningUsage, nightUsage];
    final maxValue = values.reduce((curr, next) => curr > next ? curr : next);

    if (maxValue == morningUsage) return "Morning";
    if (maxValue == afternoonUsage) return "Afternoon";
    if (maxValue == eveningUsage) return "Evening";
    return "Night";
  }
}
