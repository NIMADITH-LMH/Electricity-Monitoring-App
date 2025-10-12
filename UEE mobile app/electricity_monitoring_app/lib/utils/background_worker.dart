import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/usage_notifier_service.dart';

/// The entry point for the background worker process.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Initialize the worker and register the task callback
  Workmanager().executeTask((task, inputData) async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    try {
      debugPrint('Executing background task: $task');

      // Initialize Firebase in background context
      await Firebase.initializeApp();
      debugPrint('Firebase initialized in background task');

      // Check what task we're executing
      if (task == 'checkUsage') {
        debugPrint('Starting usage check for all users');

        // Create an instance of the usage notifier
        final notifier = UsageNotifier();

        // Give Firebase a moment to fully initialize
        await Future.delayed(const Duration(seconds: 2));

        // Check usage for all users
        await notifier.checkAllUsers();

        debugPrint('Usage check completed successfully');
      }

      // Always return true for work completion
      return Future.value(true);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error in background task: ${e.message}');
      return Future.value(false);
    } catch (e) {
      debugPrint('Error in background task: $e');
      // Return false to indicate task failure
      return Future.value(false);
    }
  });
}

/// Initialize the workmanager and register tasks
Future<void> initializeWorkManager() async {
  try {
    // Initialize the workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode:
          false, // Set to false in production to avoid excessive logging
    );

    // Register the periodic task to check usage
    await Workmanager().registerPeriodicTask(
      "usageCheckTask", // Unique task name
      "checkUsage", // Task type
      frequency: const Duration(
        hours: 1,
      ), // Check every hour instead of 15 minutes
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint('Workmanager initialized and tasks registered successfully');
  } catch (e) {
    debugPrint('Error initializing Workmanager: $e');
  }
}
