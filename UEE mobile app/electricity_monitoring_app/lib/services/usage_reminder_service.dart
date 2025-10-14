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

  // Check if user has exceeded usage thresholds - WITH BETTER ERROR HANDLING
  Future<void> checkUsageThresholds() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get user's notification preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final notificationPreferences =
          userData['notificationPreferences'] as Map<String, dynamic>? ?? {};

      final usageThresholds = notificationPreferences['usageThresholds']
              as Map<String, dynamic>? ??
          {
            'daily': 15.0,
            'weekly': 100.0,
            'monthly': 300.0,
          };

      // Get today's usage
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final usageRecords = await _firestore
          .collection('users')
          .doc(userId)
          .collection('usageRecords')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      double dailyUsage = 0;
      for (var doc in usageRecords.docs) {
        dailyUsage += (doc.data()['totalKwh'] as num?)?.toDouble() ?? 0;
      }

      // Check if threshold exceeded
      final dailyThreshold = (usageThresholds['daily'] as num?)?.toDouble() ?? 15.0;
      if (dailyUsage > dailyThreshold) {
        // Send notification about high usage using existing notification service
        await _notificationService.storeNotification(
          userId: userId,
          title: 'High Daily Usage Alert',
          message: 'Your electricity usage today (${dailyUsage.toStringAsFixed(1)} kWh) has exceeded your daily threshold.',
          type: NotificationType.usageAlert,
          metadata: {'dailyUsage': dailyUsage, 'threshold': dailyThreshold},
        );

        await _notificationService.sendLocalNotification(
          title: 'High Daily Usage Alert',
          body: 'Your electricity usage today (${dailyUsage.toStringAsFixed(1)} kWh) has exceeded your daily threshold.',
        );
      }
    } catch (e) {
      // Handle network issues gracefully
      if (e.toString().contains('permission-denied')) {
        debugPrint('Permission denied checking usage thresholds: $e');
        // This might be expected for some users, don't log as error
      } else if (e.toString().contains('unavailable') || 
                 e.toString().contains('network') ||
                 e.toString().contains('Failed to get service')) {
        debugPrint('Network issue checking usage thresholds, skipping: $e');
        // Network issues are temporary, skip for now
      } else {
        debugPrint('Error checking usage thresholds: $e');
      }
    }
  }

  // Send a personalized energy-saving tip to the user - WITH BETTER ERROR HANDLING
  Future<void> sendPersonalizedTip() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get a random tip from admin tips
      final tipSnapshot = await _firestore
          .collection('admin_tips')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (tipSnapshot.docs.isEmpty) return;

      final tipData = tipSnapshot.docs.first.data();
      
      // Use the notification service to properly store the notification
      // This ensures proper security rules are followed
      await _notificationService.storeNotification(
        userId: userId,
        title: '💡 Energy Saving Tip',
        message: tipData['title'] ?? 'Check out this energy saving tip!',
        type: NotificationType.tip, // Assuming there's a tip type, or use general
        metadata: {
          'tipId': tipSnapshot.docs.first.id,
          'tipTitle': tipData['title'],
        },
      );

      // Also send local notification
      await _notificationService.sendLocalNotification(
        title: '💡 Energy Saving Tip',
        body: tipData['title'] ?? 'Check out this energy saving tip!',
      );
    } catch (e) {
      // Handle network issues gracefully
      if (e.toString().contains('permission-denied')) {
        debugPrint('Permission denied sending personalized tip: $e');
        // This might be expected for some operations, don't log as error
      } else if (e.toString().contains('unavailable') || 
                 e.toString().contains('network') ||
                 e.toString().contains('Failed to get service')) {
        debugPrint('Network issue sending personalized tip, skipping: $e');
        // Network issues are temporary, skip for now
      } else {
        debugPrint('Error sending personalized tip: $e');
      }
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
