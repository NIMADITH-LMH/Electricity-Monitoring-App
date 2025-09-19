import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../services/usage_notifier_service.dart';

/// The entry point for the background worker process.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Initialize the worker and register the task callback
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Executing background task: $task');
      
      // Check what task we're executing
      if (task == 'checkUsage') {
        // Create an instance of the usage notifier
        final notifier = UsageNotifier();
        
        // Check usage for all users
        await notifier.checkAllUsers();
        
        debugPrint('Usage check completed successfully');
      }
      
      // Always return true for work completion
      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      // Return false to indicate task failure
      return Future.value(false);
    }
  });
}

/// Initialize the workmanager and register tasks
Future<void> initializeWorkManager() async {
  // Initialize the workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );
  
  // Register the periodic task to check usage
  await Workmanager().registerPeriodicTask(
    "usageCheckTask", // Unique task name
    "checkUsage",     // Task type
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
  
  debugPrint('Workmanager initialized and tasks registered');
}