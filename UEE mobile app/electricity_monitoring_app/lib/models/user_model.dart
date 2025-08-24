import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final NotificationPreferences notificationPreferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    NotificationPreferences? notificationPreferences,
  }) : notificationPreferences =
           notificationPreferences ?? NotificationPreferences();

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notificationPreferences: map['notificationPreferences'] != null
          ? NotificationPreferences.fromMap(map['notificationPreferences'])
          : NotificationPreferences(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }
}

class NotificationPreferences {
  // General notification settings
  final bool reminderEnabled;
  final bool tipsEnabled;
  final bool weeklyReportEnabled;
  final bool monthlyReportEnabled;

  // Enhanced notification settings for personalization
  final bool enableUsageAlerts;
  final bool enableTipNotifications;
  final bool enableDailyReminders;
  final String reminderTime; // Format: "HH:MM" in 24-hour format

  // Usage thresholds for different time periods
  final Map<String, double> usageThresholds;

  // Notification frequency settings
  final int maxTipsPerWeek; // Maximum number of tips to show per week
  final int maxAlertsPerDay; // Maximum number of usage alerts per day

  NotificationPreferences({
    // Original settings
    this.reminderEnabled = true,
    this.tipsEnabled = true,
    this.weeklyReportEnabled = true,
    this.monthlyReportEnabled = true,

    // Enhanced settings
    this.enableUsageAlerts = true,
    this.enableTipNotifications = true,
    this.enableDailyReminders = true,
    this.reminderTime = "20:00", // Default reminder at 8 PM
    this.maxTipsPerWeek = 3,
    this.maxAlertsPerDay = 2,

    // Thresholds
    Map<String, double>? usageThresholds,
  }) : usageThresholds =
           usageThresholds ??
           {
             'daily': 10.0, // Default 10 kWh daily threshold
             'weekly': 70.0, // Default 70 kWh weekly threshold
             'monthly': 300.0, // Default 300 kWh monthly threshold
           };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      // Original settings
      reminderEnabled: map['reminderEnabled'] ?? true,
      tipsEnabled: map['tipsEnabled'] ?? true,
      weeklyReportEnabled: map['weeklyReportEnabled'] ?? true,
      monthlyReportEnabled: map['monthlyReportEnabled'] ?? true,

      // Enhanced settings
      enableUsageAlerts: map['enableUsageAlerts'] ?? true,
      enableTipNotifications: map['enableTipNotifications'] ?? true,
      enableDailyReminders: map['enableDailyReminders'] ?? true,
      reminderTime: map['reminderTime'] ?? "20:00",
      maxTipsPerWeek: map['maxTipsPerWeek'] ?? 3,
      maxAlertsPerDay: map['maxAlertsPerDay'] ?? 2,

      // Thresholds
      usageThresholds: Map<String, double>.from(
        map['usageThresholds'] ??
            {'daily': 10.0, 'weekly': 70.0, 'monthly': 300.0},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Original settings
      'reminderEnabled': reminderEnabled,
      'tipsEnabled': tipsEnabled,
      'weeklyReportEnabled': weeklyReportEnabled,
      'monthlyReportEnabled': monthlyReportEnabled,

      // Enhanced settings
      'enableUsageAlerts': enableUsageAlerts,
      'enableTipNotifications': enableTipNotifications,
      'enableDailyReminders': enableDailyReminders,
      'reminderTime': reminderTime,
      'maxTipsPerWeek': maxTipsPerWeek,
      'maxAlertsPerDay': maxAlertsPerDay,

      // Thresholds
      'usageThresholds': usageThresholds,
    };
  }
}
