import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:electricity_monitoring_app/models/user_model.dart';
import 'package:electricity_monitoring_app/models/notification_model.dart';
import 'package:electricity_monitoring_app/services/notification_service.dart';
import 'package:electricity_monitoring_app/services/usage_record_service.dart';
import 'package:electricity_monitoring_app/services/tip_service.dart';

class UsageReminderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final UsageRecordService _usageRecordService = UsageRecordService();

  // Schedule daily usage reminders for the current user
  Future<void> scheduleDailyReminders() async {
    try {
      if (_auth.currentUser == null) return;

      // Get user data to check notification preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );

      // Check if daily reminders are enabled
      if (!user.notificationPreferences.enableDailyReminders) return;

      // Schedule the reminder using the NotificationService
      _notificationService.scheduleUsageReminder(
        userId: user.id,
        preferences: user.notificationPreferences,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminders: $e');
    }
  }

  // Check if user has exceeded their usage threshold and send notification if needed
  Future<void> checkUsageThresholds() async {
    try {
      if (_auth.currentUser == null) return;

      // Get user data to check notification preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );

      // Skip if usage alerts are disabled
      if (!user.notificationPreferences.enableUsageAlerts) return;

      // Get current usage
      final recentUsage = await _usageRecordService.getRecentUsage(user.id);

      // Check against daily threshold
      final dailyThreshold =
          user.notificationPreferences.usageThresholds['daily'] ?? 10.0;

      if (recentUsage > dailyThreshold) {
        // User has exceeded their daily threshold, send notification
        await _notificationService.sendUsageThresholdAlert(
          userId: user.id,
          currentUsage: recentUsage,
          threshold: dailyThreshold,
          preferences: user.notificationPreferences,
        );
      }
    } catch (e) {
      debugPrint('Error checking usage thresholds: $e');
    }
  }

  // Generate a personalized energy-saving tip and send it as a notification
  Future<void> sendPersonalizedTip() async {
    try {
      if (_auth.currentUser == null) return;

      // Get user data to check notification preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );

      // Skip if tip notifications are disabled
      if (!user.notificationPreferences.enableTipNotifications) return;

      // Get tip service to fetch personalized tip
      final tipService = TipService();
      final personalizedTips = await tipService.getPersonalizedTips(user);

      // If we have a tip to show, send it as a notification
      if (personalizedTips.isNotEmpty) {
        final tip = personalizedTips.first;

        await _notificationService.sendPersonalizedTipNotification(
          userId: user.id,
          tip: tip,
          preferences: user.notificationPreferences,
        );
      }
    } catch (e) {
      debugPrint('Error sending personalized tip: $e');
    }
  }

  // Check if weekly usage exceeded threshold
  Future<void> checkWeeklyUsageThreshold() async {
    try {
      if (_auth.currentUser == null) return;

      // Get user data to check notification preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );

      // Skip if usage alerts are disabled
      if (!user.notificationPreferences.enableUsageAlerts) return;

      // Calculate date range for current week (Sunday to Saturday)
      final now = DateTime.now();
      final currentWeekStart = now.subtract(Duration(days: now.weekday));
      final currentWeekEnd = currentWeekStart.add(Duration(days: 6));

      // Get total kWh for the current week
      final weeklyUsage = _usageRecordService.getTotalKwhForDateRange(
        currentWeekStart,
        currentWeekEnd,
      );

      // Check against weekly threshold
      final weeklyThreshold =
          user.notificationPreferences.usageThresholds['weekly'] ?? 70.0;

      if (weeklyUsage > weeklyThreshold) {
        // Send notification about weekly usage threshold
        final title = 'Weekly Usage Alert';
        final message =
            'Your electricity usage this week ($weeklyUsage kWh) has exceeded your weekly threshold ($weeklyThreshold kWh).';

        await _notificationService.storeNotification(
          userId: user.id,
          title: title,
          message: message,
          type: NotificationType.usageAlert,
          metadata: {'weeklyUsage': weeklyUsage, 'threshold': weeklyThreshold},
        );

        await _notificationService.sendLocalNotification(
          title: title,
          body: message,
        );
      }
    } catch (e) {
      debugPrint('Error checking weekly usage threshold: $e');
    }
  }
}
