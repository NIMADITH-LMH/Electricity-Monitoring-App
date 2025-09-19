import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:electricity_monitoring_app/models/usage_threshold_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to monitor electricity usage and trigger notifications when
/// usage thresholds are crossed.
class UsageNotifier extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Define usage thresholds with their notification properties
  static final List<UsageThreshold> thresholds = [
    UsageThreshold(50, "Yellow", "yellow_channel", Colors.yellow),
    UsageThreshold(80, "Orange", "orange_channel", Colors.orange),
    UsageThreshold(100, "Red", "red_channel", Colors.red),
  ];

  UsageNotifier() {
    _initializeNotifications();
  }

  /// Initialize the local notifications plugin
  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// Show a notification with the specified details
  Future<void> _showNotification(
      String title, String body, String channelId, Color color) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Usage Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: color,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  /// Update a user's usage and trigger appropriate notifications
  /// 
  /// - Updates the usage in Firestore
  /// - Checks if the user has crossed any notification thresholds
  /// - Handles daily reset and usage drop reset logic
  Future<void> updateUsage(String userId, int newUsed) async {
    // If no user ID provided, try to get the current authenticated user
    if (userId.isEmpty) {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user to update usage');
        return;
      }
      userId = currentUser.uid;
    }

    final userRef = _firestore.collection('users').doc(userId);
    final userSnap = await userRef.get();
    final data = userSnap.data() ?? {};

    // Get the user's budget (default to 100 if not set)
    int budget = data['budget'] ?? 100;
    double percent = (newUsed / budget) * 100;

    // Save the updated usage
    await userRef.set({'used': newUsed}, SetOptions(merge: true));

    // Daily reset logic
    DateTime today = DateTime.now();
    String todayStr = "${today.year}-${today.month}-${today.day}";
    String lastNotifiedDate = data['lastNotifiedDate'] ?? '';
    int lastNotified = data['lastNotified'] ?? 0;

    // Reset notification status if it's a new day
    if (lastNotifiedDate != todayStr) {
      await userRef.update({
        'lastNotified': 0,
        'lastNotifiedDate': todayStr,
      });
      lastNotified = 0;
    }

    // Reset if usage drops below 50%
    if (percent < 50 && lastNotified != 0) {
      await userRef.update({'lastNotified': 0});
      lastNotified = 0;
    }

    // Trigger notification for highest new threshold crossed
    // We check thresholds in reverse order to find the highest one
    for (var threshold in thresholds.reversed) {
      if (percent >= threshold.percent && lastNotified < threshold.percent) {
        // Show local notification
        await _showNotification(
          "${threshold.colorName} Usage Alert ⚠️",
          "You've used ${percent.toStringAsFixed(0)}% of your budget.",
          threshold.channelId,
          threshold.color,
        );

        // Also create a notification in Firestore for the app's notification center
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
              'title': "${threshold.colorName} Usage Alert",
              'message': "You've used ${percent.toStringAsFixed(0)}% of your electricity budget.",
              'read': false,
              'createdAt': Timestamp.fromDate(today),
              'type': 'usage',
            });

        // Update last notified threshold
        await userRef.update({'lastNotified': threshold.percent});
        
        // Only trigger one notification (the highest threshold crossed)
        break;
      }
    }

    // Notify listeners if this class is used with Provider
    notifyListeners();
  }

  /// Check and update usage for all users
  /// This method is used by the background task
  Future<void> checkAllUsers() async {
    try {
      // Get all users with usage data
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        if (data.containsKey('used')) {
          final userId = userDoc.id;
          final usage = data['used'] as int;
          
          // Update usage to trigger notification checks
          // This doesn't change the actual usage value
          await updateUsage(userId, usage);
        }
      }
    } catch (e) {
      debugPrint('Error checking all users: $e');
    }
  }
}