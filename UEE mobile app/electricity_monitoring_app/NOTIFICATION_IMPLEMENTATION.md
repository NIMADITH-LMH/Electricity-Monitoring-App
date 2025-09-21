# Notification System Implementation Guide

This document explains the implementation of the multi-level notification system in the Electricity Monitoring App.

## Overview

The app features a comprehensive notification system that monitors electricity usage and alerts users when their consumption approaches or exceeds predefined thresholds. The system works even when the app is not actively running.

## Key Components

### 1. Usage Threshold Model

The `UsageThreshold` model defines different alert levels:

```dart
class UsageThreshold {
  final double percent;  // Percentage of budget/limit
  final String color;    // Alert color (yellow, orange, red)
  final String channel;  // Notification channel ID

  // Methods for Firestore serialization/deserialization
  Map<String, dynamic> toMap() { ... }
  static UsageThreshold fromMap(Map<String, dynamic> map) { ... }
}
```

### 2. Usage Notifier Service

The `UsageNotifierService` handles monitoring and notification logic:

- Checks current usage against thresholds
- Creates and shows appropriate notifications
- Integrates with Firestore for user-specific thresholds
- Updates notification status in real-time

```dart
class UsageNotifierService {
  // Core methods
  Future<void> initialize() { ... }
  Future<void> updateUsage(double currentUsage, double limit) { ... }
  Future<void> checkAndNotify() { ... }
  
  // Notification methods
  Future<void> showUsageNotification(UsageThreshold threshold, double currentUsage, double limit) { ... }
}
```

### 3. Background Worker

The `BackgroundWorker` class uses the Workmanager package to schedule periodic background tasks:

```dart
class BackgroundWorker {
  static Future<void> initializeWorkManager() async { ... }
  static void callbackDispatcher() { ... }
  static Future<void> performBackgroundUsageCheck() { ... }
}
```

## Implementation Details

### Notification Levels

The system includes three notification levels:

1. **Yellow Alert (70%)**: Early warning when usage reaches 70% of the limit
2. **Orange Alert (85%)**: Warning when usage reaches 85% of the limit
3. **Red Alert (95%)**: Critical alert when usage reaches 95% of the limit

### Background Processing

The app uses the Workmanager package to schedule periodic tasks:

1. Background tasks run every 15 minutes to check usage
2. Each task fetches current usage data from Firestore
3. If thresholds are exceeded, notifications are triggered

### User Configuration

Users can customize notification settings via the Settings screen:

- Enable/disable notifications
- Adjust threshold percentages
- Set quiet hours

## Testing

The app includes a developer tool section with a notification test screen that allows:

- Simulating different usage levels
- Triggering test notifications
- Verifying background worker functionality

## Integration with Other Features

The notification system integrates with:

- Budget planning feature to determine usage limits
- Usage monitoring to get current consumption data
- User preferences for personalized settings

## Technical Requirements

- Flutter Local Notifications plugin
- Workmanager for background processing
- Firebase Firestore for data storage
- Android-specific setup for background processing