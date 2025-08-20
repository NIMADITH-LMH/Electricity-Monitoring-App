import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:electricity_monitoring_app/models/notification_model.dart';
import 'package:electricity_monitoring_app/models/user_model.dart';
import 'package:electricity_monitoring_app/models/tip_model.dart';
import 'package:electricity_monitoring_app/models/user_tip_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Collection references
  final CollectionReference _notificationsCollection = FirebaseFirestore
      .instance
      .collection('notifications');
  final CollectionReference _userTipsCollection = FirebaseFirestore.instance
      .collection('user_tips');

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission for push notifications
    await _requestPermissions();

    // Configure Firebase Messaging
    await _configureFirebaseMessaging();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  // Request permissions for notifications
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User notification settings: ${settings.authorizationStatus}');
  }

  // Configure Firebase Cloud Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    // Handle when user taps on notification from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint('App opened from terminated state via notification');
        // Handle notification tap - can navigate to specific screen based on data
      }
    });

    // Handle when user taps on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background state via notification');
      // Handle notification tap - can navigate to specific screen based on data
    });
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
        // Handle notification click - can navigate to specific screen based on payload
      },
    );
  }

  // Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'electricity_monitor_channel',
          'Electricity Monitoring',
          channelDescription:
              'Notifications for the Electricity Monitoring App',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          showWhen: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(title: title, body: body, payload: payload);
  }

  // Send auth notification
  Future<void> sendAuthNotification({
    required bool isSignIn,
    String? email,
  }) async {
    final title = isSignIn ? 'Signed In Successfully' : 'Signed Out';
    final body = isSignIn
        ? 'You have been signed in${email != null ? ' as $email' : ''}.'
        : 'You have been signed out of your account.';

    await sendLocalNotification(
      title: title,
      body: body,
      payload: 'auth_${isSignIn ? 'signin' : 'signout'}',
    );
  }

  // Send budget notification
  Future<void> sendBudgetNotification({
    required double percentage,
    required String month,
  }) async {
    final warningLevel = percentage >= 100
        ? 'exceeded'
        : percentage >= 90
        ? 'at 90% of'
        : percentage >= 75
        ? 'at 75% of'
        : 'approaching';

    await sendLocalNotification(
      title: 'Budget Alert',
      body:
          'Your electricity usage for $month is $warningLevel your monthly budget.',
      payload: 'budget_alert',
    );
  }

  // Send appliance added notification
  Future<void> sendApplianceNotification({
    required String action, // 'added', 'updated', 'deleted'
    required String applianceName,
  }) async {
    String title, body;

    switch (action) {
      case 'added':
        title = 'New Appliance Added';
        body = 'You have added $applianceName to your appliances list.';
        break;
      case 'updated':
        title = 'Appliance Updated';
        body = 'You have updated information for $applianceName.';
        break;
      case 'deleted':
        title = 'Appliance Removed';
        body = 'You have removed $applianceName from your appliances.';
        break;
      default:
        title = 'Appliance Update';
        body = 'Your appliances list has been updated.';
    }

    await sendLocalNotification(
      title: title,
      body: body,
      payload: 'appliance_$action',
    );
  }

  // Send usage record notification
  Future<void> sendUsageRecordNotification({
    required String action, // 'added', 'updated', 'deleted'
    required DateTime date,
    double? kWh,
  }) async {
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    String title, body;

    switch (action) {
      case 'added':
        title = 'New Usage Record';
        body =
            'You have added a new usage record for $formattedDate${kWh != null ? ' with $kWh kWh' : ''}.';
        break;
      case 'updated':
        title = 'Usage Record Updated';
        body = 'You have updated the usage record for $formattedDate.';
        break;
      case 'deleted':
        title = 'Usage Record Deleted';
        body = 'You have deleted the usage record for $formattedDate.';
        break;
      default:
        title = 'Usage Update';
        body = 'Your usage records have been updated.';
    }

    await sendLocalNotification(
      title: title,
      body: body,
      payload: 'usage_$action',
    );
  }

  // Send energy saving tip notification
  Future<void> sendTipNotification({
    required String action, // 'added', 'updated', 'deleted'
    required String tipTitle,
  }) async {
    String title, body;

    switch (action) {
      case 'added':
        title = 'New Energy Saving Tip';
        body = 'You have added a new tip: $tipTitle';
        break;
      case 'updated':
        title = 'Tip Updated';
        body = 'You have updated the tip: $tipTitle';
        break;
      case 'deleted':
        title = 'Tip Deleted';
        body = 'You have deleted the tip: $tipTitle';
        break;
      default:
        title = 'Tip Update';
        body = 'Your energy saving tips have been updated.';
    }

    await sendLocalNotification(
      title: title,
      body: body,
      payload: 'tip_$action',
    );
  }

  // PERSONALIZED NOTIFICATIONS FEATURE METHODS

  // Store notification in Firestore
  Future<String> storeNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    final notificationData = {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'metadata': metadata ?? {},
    };

    // Add to Firestore
    final docRef = await _notificationsCollection.add(notificationData);
    return docRef.id;
  }

  // Send personalized tip notification based on user preferences
  Future<void> sendPersonalizedTipNotification({
    required String userId,
    required TipModel tip,
    required NotificationPreferences preferences,
  }) async {
    // Check if user has notification preferences enabled for tips
    if (!preferences.enableTipNotifications) {
      debugPrint('Tip notifications are disabled for user $userId');
      return;
    }

    // Store in Firestore for history
    final notificationId = await storeNotification(
      userId: userId,
      title: 'Energy Saving Tip: ${tip.title}',
      message: tip.description,
      type: NotificationType.tip,
      metadata: {
        'tipId': tip.id,
        'potentialSavings': tip.potentialSavingsKwh,
        'difficulty': tip.difficulty,
      },
    );

    // Track user-tip relationship
    await _userTipsCollection.add({
      'userId': userId,
      'tipId': tip.id,
      'shown': true,
      'dismissed': false,
      'implemented': false,
      'effectivenessRating': null,
      'shownAt': FieldValue.serverTimestamp(),
    });

    // Send local notification
    await sendLocalNotification(
      title: 'Energy Saving Tip: ${tip.title}',
      body: tip.description,
      payload: 'personalized_tip:$notificationId',
    );
  }

  // Send usage threshold alert
  Future<void> sendUsageThresholdAlert({
    required String userId,
    required double currentUsage,
    required double threshold,
    required NotificationPreferences preferences,
  }) async {
    // Check if user has notification preferences enabled for usage alerts
    if (!preferences.enableUsageAlerts) {
      debugPrint('Usage alerts are disabled for user $userId');
      return;
    }

    final title = 'Usage Alert';
    final message =
        'Your current electricity usage ($currentUsage kWh) has exceeded your threshold ($threshold kWh).';

    // Store in Firestore for history
    final notificationId = await storeNotification(
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.usageAlert,
      metadata: {'currentUsage': currentUsage, 'threshold': threshold},
    );

    // Send local notification
    await sendLocalNotification(
      title: title,
      body: message,
      payload: 'usage_alert:$notificationId',
    );
  }

  // Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      // Try the query with ordering that requires a composite index
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error in getUserNotifications with index: $e');
      // Fall back to a simpler query that doesn't require a composite index
      try {
        // Just fetch by userId without ordering
        final querySnapshot = await _notificationsCollection
            .where('userId', isEqualTo: userId)
            .get();

        // Sort the results in memory instead
        final notifications = querySnapshot.docs
            .map(
              (doc) => NotificationModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Sort by createdAt manually (newest first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      } catch (fallbackError) {
        debugPrint('Error in getUserNotifications fallback: $fallbackError');
        // If all else fails, return an empty list rather than crashing
        return [];
      }
    }
  }

  // Get unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error in getUnreadNotificationsCount: $e');

      try {
        // Fallback to fetching all user notifications and filtering in memory
        final querySnapshot = await _notificationsCollection
            .where('userId', isEqualTo: userId)
            .get();

        // Count unread notifications manually
        final unreadCount = querySnapshot.docs
            .where(
              (doc) => (doc.data() as Map<String, dynamic>)['isRead'] == false,
            )
            .length;

        return unreadCount;
      } catch (fallbackError) {
        debugPrint(
          'Error in getUnreadNotificationsCount fallback: $fallbackError',
        );
        // Return 0 as default to avoid crashing the UI
        return 0;
      }
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in markAllNotificationsAsRead: $e');

      try {
        // Fallback to fetching all user notifications and updating them individually
        final querySnapshot = await _notificationsCollection
            .where('userId', isEqualTo: userId)
            .get();

        // Filter unread notifications and update them one by one
        for (var doc in querySnapshot.docs) {
          if ((doc.data() as Map<String, dynamic>)['isRead'] == false) {
            await doc.reference.update({'isRead': true});
          }
        }
      } catch (fallbackError) {
        debugPrint(
          'Error in markAllNotificationsAsRead fallback: $fallbackError',
        );
        rethrow; // Rethrow to let the UI handle the error
      }
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  // Schedule daily usage reminder based on user preferences
  Future<void> scheduleUsageReminder({
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    // This would typically use a platform-specific scheduling mechanism
    // For now, we'll just log that it would be scheduled
    if (preferences.enableDailyReminders) {
      debugPrint(
        'Would schedule daily reminder for user $userId at ${preferences.reminderTime}',
      );
      // In a real implementation, we would set up a periodic notification using
      // the platform's scheduling capabilities
    }
  }
}
