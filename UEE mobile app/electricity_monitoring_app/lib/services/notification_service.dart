import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
}
