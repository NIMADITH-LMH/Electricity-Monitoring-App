import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/appliance/appliance_list_screen.dart';
import 'screens/appliance/add_appliance_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/notification_preferences_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/usage/usage_analytics_screen.dart';
import 'screens/budget/budget_plan_selection_screen.dart';
import 'utils/app_theme.dart';
import 'services/auth_service.dart';
import 'services/tip_service.dart';
import 'services/usage_record_service.dart';
import 'services/appliance_service.dart';
import 'services/budget_service.dart';
import 'services/budget_plan_service.dart';
import 'services/user_profile_service.dart';
import 'services/usage_reminder_service.dart';
import 'services/usage_analytics_service.dart';
import 'providers/budget_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TipService()),
        ChangeNotifierProvider(create: (_) => UsageRecordService()),
        ChangeNotifierProvider(create: (_) => ApplianceService()),
        ChangeNotifierProvider(create: (_) => BudgetService()),
        ChangeNotifierProvider(create: (_) => BudgetPlanService()), // Add new BudgetPlanService
        ChangeNotifierProvider(create: (_) => UserProfileService()),
        ChangeNotifierProvider(create: (_) => UsageReminderService()),
        ChangeNotifierProvider(create: (_) => UsageAnalyticsService()),
        // Create BudgetProvider with dependency on BudgetService
        ChangeNotifierProxyProvider<BudgetService, BudgetProvider>(
          create: (_) => BudgetProvider(BudgetService()),
          update: (_, budgetService, previous) => 
            previous ?? BudgetProvider(budgetService),
        ),
      ],
      child: MaterialApp(
        title: 'Electricity Monitoring',
        theme: AppTheme.lightTheme,
        // Use light theme since dark theme is not defined
        themeMode: ThemeMode.light,
        home: const SplashScreen(nextScreen: LoginScreen()),
        routes: {
          '/appliances': (context) => const ApplianceListScreen(),
          '/add-appliance': (context) => const AddApplianceScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notification-preferences': (context) =>
              NotificationPreferencesScreen(),
          '/notifications': (context) => NotificationsScreen(),
          '/usage-analytics': (context) => UsageAnalyticsScreen(),
          '/budget-plan-selection': (context) => const BudgetPlanSelectionScreen(),
          // We can't use routes for EditApplianceScreen because it needs an appliance parameter
        },
      ),
    );
  }
}
