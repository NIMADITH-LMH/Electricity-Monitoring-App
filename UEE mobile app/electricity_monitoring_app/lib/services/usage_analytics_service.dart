import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/usage_record_model.dart';
import '../models/usage_analytics_model.dart';

class UsageAnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for analytics results
  Map<String, UsageAnalyticsModel> _analyticsCache = {};
  List<UsageDataPoint> _dataPoints = [];
  List<UsagePredictionModel> _predictions = [];

  // Getters
  List<UsageDataPoint> get dataPoints => _dataPoints;
  List<UsagePredictionModel> get predictions => _predictions;

  // Get analytics for a specific period
  Future<UsageAnalyticsModel> getUsageAnalytics({
    required String period, // 'daily', 'weekly', 'monthly', 'yearly'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Set default dates if not provided
      startDate ??= _getDefaultStartDate(period);
      endDate ??= DateTime.now();

      // Create a cache key
      final cacheKey =
          '${period}_${startDate.toIso8601String()}_${endDate.toIso8601String()}';

      // Check if we already have this analytics data cached
      if (_analyticsCache.containsKey(cacheKey)) {
        return _analyticsCache[cacheKey]!;
      }

      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get usage records for the given date range
      final currentRecords = await _getUsageRecordsForPeriod(
        startDate,
        endDate,
      );

      // Calculate the date range for the previous period (for comparison)
      final durationDays = endDate.difference(startDate).inDays + 1;
      final previousStartDate = startDate.subtract(
        Duration(days: durationDays),
      );
      final previousEndDate = startDate.subtract(const Duration(days: 1));

      // Get usage records for the previous period
      final previousRecords = await _getUsageRecordsForPeriod(
        previousStartDate,
        previousEndDate,
      );

      // Calculate analytics
      final currentTotalKwh = currentRecords.fold(
        0.0,
        (sum, record) => sum + record.totalKwh,
      );
      final currentTotalCost = currentRecords.fold(
        0.0,
        (sum, record) => sum + record.totalCost,
      );

      final previousTotalKwh = previousRecords.fold(
        0.0,
        (sum, record) => sum + record.totalKwh,
      );
      final previousTotalCost = previousRecords.fold(
        0.0,
        (sum, record) => sum + record.totalCost,
      );

      // Calculate daily averages
      final avgKwhPerDay = currentTotalKwh / durationDays;
      final avgCostPerDay = currentTotalCost / durationDays;

      // Calculate percentage changes
      double percentChangeKwh = 0;
      double percentChangeCost = 0;

      if (previousTotalKwh > 0) {
        percentChangeKwh =
            ((currentTotalKwh - previousTotalKwh) / previousTotalKwh) * 100;
      }

      if (previousTotalCost > 0) {
        percentChangeCost =
            ((currentTotalCost - previousTotalCost) / previousTotalCost) * 100;
      }

      // Create analytics model
      final analytics = UsageAnalyticsModel(
        startDate: startDate,
        endDate: endDate,
        period: period,
        totalKwh: currentTotalKwh,
        totalCost: currentTotalCost,
        avgKwhPerDay: avgKwhPerDay,
        avgCostPerDay: avgCostPerDay,
        percentChangeKwh: percentChangeKwh,
        percentChangeCost: percentChangeCost,
      );

      // Cache the results
      _analyticsCache[cacheKey] = analytics;

      return analytics;
    } catch (e) {
      debugPrint('Error getting usage analytics: $e');
      rethrow;
    }
  }

  // Get historical usage data for charts
  Future<List<UsageDataPoint>> getHistoricalUsageData({
    required String period, // 'daily', 'weekly', 'monthly', 'yearly'
    int limit = 12, // How many data points to return
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      final now = DateTime.now();
      DateTime startDate;

      // Determine start date based on period and limit
      switch (period) {
        case 'daily':
          startDate = now.subtract(Duration(days: limit));
          break;
        case 'weekly':
          startDate = now.subtract(Duration(days: limit * 7));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month - limit, now.day);
          break;
        case 'yearly':
          startDate = DateTime(now.year - limit, now.month, now.day);
          break;
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }

      // Get all usage records since the start date
      final records = await _getUsageRecordsForPeriod(startDate, now);

      // Group records by period and aggregate data
      _dataPoints = _aggregateDataByPeriod(records, period, limit);
      notifyListeners();

      return _dataPoints;
    } catch (e) {
      debugPrint('Error getting historical usage data: $e');
      return [];
    }
  }

  // Get daily usage breakdown (morning, afternoon, evening, night)
  Future<DailyUsageBreakdown> getDailyUsageBreakdown({DateTime? date}) async {
    try {
      date ??= DateTime.now();

      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // For this to work properly, we would need hourly usage data
      // As a placeholder, we'll return some mock data based on date
      // In a real implementation, you would query hourly usage records

      // Mock implementation - would be replaced with actual data query
      final totalDailyUsage = await _getTotalUsageForDay(date);

      // Distribute usage across different times of day
      // This is a mock implementation - in reality would be based on actual hourly data
      final morningUsage = totalDailyUsage * 0.25;
      final afternoonUsage = totalDailyUsage * 0.30;
      final eveningUsage = totalDailyUsage * 0.35;
      final nightUsage = totalDailyUsage * 0.10;

      return DailyUsageBreakdown(
        morningUsage: morningUsage,
        afternoonUsage: afternoonUsage,
        eveningUsage: eveningUsage,
        nightUsage: nightUsage,
      );
    } catch (e) {
      debugPrint('Error getting daily usage breakdown: $e');
      return DailyUsageBreakdown(
        morningUsage: 0,
        afternoonUsage: 0,
        eveningUsage: 0,
        nightUsage: 0,
      );
    }
  }

  // Predict future usage based on historical patterns
  Future<List<UsagePredictionModel>> predictFutureUsage({
    int daysToPredict = 7,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get historical data for the last 30 days to base our predictions on
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final historicalRecords = await _getUsageRecordsForPeriod(
        thirtyDaysAgo,
        now,
      );

      // Simple prediction algorithm - in a real app, this would use more sophisticated ML
      // Here we're calculating average daily increase/decrease and projecting forward

      if (historicalRecords.isEmpty) {
        return [];
      }

      // Sort records by date
      historicalRecords.sort((a, b) => a.date.compareTo(b.date));

      // Calculate average daily changes
      List<double> dailyKwhChanges = [];
      List<double> dailyCostChanges = [];

      for (int i = 1; i < historicalRecords.length; i++) {
        dailyKwhChanges.add(
          historicalRecords[i].totalKwh - historicalRecords[i - 1].totalKwh,
        );
        dailyCostChanges.add(
          historicalRecords[i].totalCost - historicalRecords[i - 1].totalCost,
        );
      }

      // Calculate average change
      final avgKwhChange = dailyKwhChanges.isNotEmpty
          ? dailyKwhChanges.reduce((a, b) => a + b) / dailyKwhChanges.length
          : 0.0;
      final avgCostChange = dailyCostChanges.isNotEmpty
          ? dailyCostChanges.reduce((a, b) => a + b) / dailyCostChanges.length
          : 0.0;

      // Start prediction from the last known record
      final lastRecord = historicalRecords.last;
      double lastKwh = lastRecord.totalKwh;
      double lastCost = lastRecord.totalCost;

      _predictions = [];

      // Generate predictions for the specified number of days
      for (int i = 1; i <= daysToPredict; i++) {
        final predictedDate = now.add(Duration(days: i));
        final predictedKwh = lastKwh + (avgKwhChange * i);
        final predictedCost = lastCost + (avgCostChange * i);

        // Ensure we don't predict negative usage
        final adjustedKwh = predictedKwh < 0 ? 0.0 : predictedKwh;
        final adjustedCost = predictedCost < 0 ? 0.0 : predictedCost;

        _predictions.add(
          UsagePredictionModel(
            date: predictedDate,
            predictedKwh: adjustedKwh,
            predictedCost: adjustedCost,
            // Lower confidence as we predict further into the future
            confidencePercentage: 90 - (i * 5),
          ),
        );
      }

      notifyListeners();
      return _predictions;
    } catch (e) {
      debugPrint('Error predicting future usage: $e');
      return [];
    }
  }

  // Helper function to get usage records for a specific date range
  Future<List<UsageRecordModel>> _getUsageRecordsForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_auth.currentUser == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('usageRecords')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs
          .map((doc) => UsageRecordModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting usage records for period: $e');
      return [];
    }
  }

  // Helper function to determine the default start date based on period
  DateTime _getDefaultStartDate(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        // Start from the beginning of the week (Sunday)
        return now.subtract(Duration(days: now.weekday));
      case 'monthly':
        // Start from the beginning of the month
        return DateTime(now.year, now.month, 1);
      case 'yearly':
        // Start from the beginning of the year
        return DateTime(now.year, 1, 1);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  // Helper function to aggregate data by period for charts
  List<UsageDataPoint> _aggregateDataByPeriod(
    List<UsageRecordModel> records,
    String period,
    int limit,
  ) {
    final Map<String, List<UsageRecordModel>> groupedRecords = {};

    // Group records by period
    for (final record in records) {
      String key;

      switch (period) {
        case 'daily':
          key = DateFormat('yyyy-MM-dd').format(record.date);
          break;
        case 'weekly':
          // Get the week start date (Sunday)
          final weekStart = record.date.subtract(
            Duration(days: record.date.weekday),
          );
          key = DateFormat('yyyy-MM-dd').format(weekStart);
          break;
        case 'monthly':
          key = DateFormat('yyyy-MM').format(record.date);
          break;
        case 'yearly':
          key = DateFormat('yyyy').format(record.date);
          break;
        default:
          key = DateFormat('yyyy-MM-dd').format(record.date);
          break;
      }

      if (!groupedRecords.containsKey(key)) {
        groupedRecords[key] = [];
      }

      groupedRecords[key]!.add(record);
    }

    // Calculate aggregated values for each period
    List<UsageDataPoint> dataPoints = [];

    groupedRecords.forEach((key, periodRecords) {
      final totalKwh = periodRecords.fold(
        0.0,
        (sum, record) => sum + record.totalKwh,
      );
      final totalCost = periodRecords.fold(
        0.0,
        (sum, record) => sum + record.totalCost,
      );

      // Use the first date in the period as the reference
      final date = periodRecords.first.date;

      dataPoints.add(
        UsageDataPoint(date: date, kwh: totalKwh, cost: totalCost),
      );
    });

    // Sort by date
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    // Take only the most recent 'limit' data points
    if (dataPoints.length > limit) {
      dataPoints = dataPoints.sublist(dataPoints.length - limit);
    }

    return dataPoints;
  }

  // Helper function to get total usage for a specific day
  Future<double> _getTotalUsageForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final records = await _getUsageRecordsForPeriod(startOfDay, endOfDay);

      if (records.isEmpty) {
        return 0.0;
      }

      double total = 0.0;
      for (var record in records) {
        total += record.totalKwh;
      }
      return total;
    } catch (e) {
      debugPrint('Error getting total usage for day: $e');
      return 0.0;
    }
  }

  // Clear cache when user signs out or data gets refreshed
  void clearCache() {
    _analyticsCache.clear();
    _dataPoints = [];
    _predictions = [];
    notifyListeners();
  }
}
