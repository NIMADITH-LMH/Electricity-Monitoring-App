import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/appliance_service.dart';
import '../../services/usage_record_service.dart';
import '../../services/tip_service.dart';
import '../../services/notification_service.dart';
import '../../services/usage_reminder_service.dart';
import '../../services/admin_tip_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/elegant_usage_card.dart';
import '../../widgets/loading_indicator.dart';
import '../appliance/appliance_list_screen.dart';
import '../budget/budget_screen.dart';
import '../usage/usage_records_screen.dart';
import '../tips/tips_list_screen.dart';
import '../badges/streak_and_badges_page.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../providers/budget_provider.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _userName = '';
  Timer? _debounceTimer;
  bool _isAdmin = false;
  final AdminTipService _adminTipService = AdminTipService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    setState(() {
      _isLoading = true;
    });

    // Use debounce to prevent excessive loading
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        // Get user info
        final user = await authService.getCurrentUserData();
        if (user != null && mounted) {
          setState(() {
            _userName = user.name;
          });
        }

        // Preload appliances data
        await Provider.of<ApplianceService>(
          context,
          listen: false,
        ).fetchAppliances();

        // No need to explicitly load budget data here anymore
        // The BudgetService stream will handle this automatically        // Preload usage records
        await Provider.of<UsageRecordService>(
          context,
          listen: false,
        ).fetchUsageRecords();

        // Preload energy saving tips
        await Provider.of<TipService>(context, listen: false).fetchTips();

        // Initialize notifications
        await NotificationService().initialize();

        // Initialize usage reminders
        await _initializeUsageReminders();
      } catch (e) {
        debugPrint('Error loading data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    // Only proceed with sign out if user confirmed
    if (shouldSignOut == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        // Navigation is handled by AuthService state change listener
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  Future<void> _initializeUsageReminders() async {
    try {
      final reminderService = Provider.of<UsageReminderService>(
        context,
        listen: false,
      );

      // Schedule daily usage reminders based on user preferences
      await reminderService.scheduleDailyReminders();

      // Check if user has exceeded usage thresholds
      await reminderService.checkUsageThresholds();

      // Check weekly usage threshold
      await reminderService.checkWeeklyUsageThreshold();

      // Send a personalized energy-saving tip
      await reminderService.sendPersonalizedTip();

      debugPrint('Usage reminders initialized successfully');
    } catch (e) {
      debugPrint('Error initializing usage reminders: $e');
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      bool isAdmin = await _adminTipService.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  void _navigateToAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  Widget _buildNotificationButton() {
    return FutureBuilder<int>(
      future: _getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data! > 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
              tooltip: 'Notifications',
            ),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    snapshot.data! > 9 ? '9+' : '${snapshot.data}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<int> _getUnreadNotificationsCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return 0;

    try {
      final notificationService = NotificationService();
      return await notificationService.getUnreadNotificationsCount(user.uid);
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Electricity Monitor'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _navigateToAdminDashboard,
              tooltip: 'Admin Dashboard',
            ),
          _buildNotificationButton(),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/electricity managing mobile app background image.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading your data...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    Text(
                      'Hello, $_userName!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Welcome to your electricity monitoring dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current month usage
                    _buildCurrentUsageSection(),
                    const SizedBox(height: 24),

                    // Quick actions grid
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 24),

                    // Recent tips
                    _buildRecentTipsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  // Optimized using StreamBuilder to prevent multiple budget fetches
  Widget _buildCurrentUsageSection() {
    final usageService = Provider.of<UsageRecordService>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    final month = _getMonthName(now.month);
    final year = now.year.toString();

    // Get current usage data - can be cached
    final totalKwh = usageService.getTotalKwhForMonth(now.year, now.month);
    final totalCost = usageService.getTotalCostForMonth(now.year, now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Month Usage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get the current budget from the provider
            final currentBudget = provider.currentBudget;

            // Calculate usage percentages with null safety
            double kwhPercentage = 0;
            double costPercentage = 0;
            double maxKwh = currentBudget?.maxKwh ?? 160.0; // Default if null
            double maxCost =
                currentBudget?.maxCost ?? 1000.0; // Default if null

            if (currentBudget != null && maxKwh > 0) {
              kwhPercentage = (totalKwh / maxKwh) * 100;
            }

            if (currentBudget != null && maxCost > 0) {
              costPercentage = (totalCost / maxCost) * 100;
            }

            return ElegantUsageCard(
              month: month,
              year: year,
              totalKwh: totalKwh,
              maxKwh: maxKwh,
              kwhPercentage: kwhPercentage,
              totalCost: totalCost,
              maxCost: maxCost,
              costPercentage: costPercentage,
              onViewDetails: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, // Reduced from 16
          crossAxisSpacing: 12, // Reduced from 16
          childAspectRatio: 2.5, // Further increased to make cards even shorter
          children: [
            _buildActionCard(
              title: 'Appliances',
              icon: Icons.device_hub,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ApplianceListScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              title: 'Budgets',
              icon: Icons.account_balance_wallet,
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                );
              },
            ),
            _buildActionCard(
              title: 'Usage Records',
              icon: Icons.insert_chart,
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UsageRecordsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              title: 'Saving Tips',
              icon: Icons.lightbulb,
              color: AppTheme.successColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TipsListScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              title: 'Analytics',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).pushNamed('/usage-analytics');
              },
            ),
            _buildActionCard(
              title: 'Streaks & Badges',
              icon: Icons.emoji_events,
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StreakAndBadgesPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      // Remove padding to save space
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 40, // Further reduced from 50
            height: 40, // Further reduced from 50
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20), // Reduced from 24
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13, // Reduced from 14
                fontWeight: FontWeight.w500, // Lighter weight
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTipsSection() {
    final tipService = Provider.of<TipService>(context);
    final tips = tipService.tips;

    // Get the first 3 tips
    final recentTips = tips.isNotEmpty ? tips.take(3).toList() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Energy Saving Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TipsListScreen(),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentTips.isEmpty) ...[
          CustomCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 48,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tips available yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add custom tips or check back later for system recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.lightTextColor),
                ),
              ],
            ),
          ),
        ] else ...[
          ...recentTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomCard(
                padding: const EdgeInsets.all(10),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TipsListScreen(),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            color: AppTheme.successColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (tip.category != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tip.category!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.description.length > 80
                          ? '${tip.description.substring(0, 80)}...'
                          : tip.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                    if (tip.estimatedSavings != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.savings,
                            color: AppTheme.accentColor,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Saves: LKR ${tip.estimatedSavings!.toStringAsFixed(0)}/year',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}
