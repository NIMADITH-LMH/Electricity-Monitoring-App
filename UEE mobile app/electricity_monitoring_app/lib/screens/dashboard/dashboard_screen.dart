import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/appliance_service.dart';
import '../../services/budget_service.dart';
import '../../services/usage_record_service.dart';
import '../../services/tip_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import '../appliance/appliance_list_screen.dart';
import '../budget/budget_screen.dart';
import '../usage/usage_records_screen.dart';
import '../tips/tips_list_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Get user info
      final user = await authService.getCurrentUserData();
      if (user != null) {
        setState(() {
          _userName = user.name;
        });
      }

      // Preload appliances data
      await Provider.of<ApplianceService>(
        context,
        listen: false,
      ).fetchAppliances();

      // Preload budget data
      await Provider.of<BudgetService>(context, listen: false).fetchBudgets();

      // Preload usage records
      await Provider.of<UsageRecordService>(
        context,
        listen: false,
      ).fetchUsageRecords();

      // Preload energy saving tips
      await Provider.of<TipService>(context, listen: false).fetchTips();

      // Initialize notifications
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Send notification before signing out
      await NotificationService().sendAuthNotification(isSignIn: false);

      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading your data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Text(
                    'Hello, $_userName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Text(
                    'Welcome to your electricity monitoring dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightTextColor,
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
    );
  }

  Widget _buildCurrentUsageSection() {
    final budgetService = Provider.of<BudgetService>(context);
    final usageService = Provider.of<UsageRecordService>(context);
    final now = DateTime.now();

    // Get current month's budget
    final currentBudget = budgetService.getCurrentMonthBudget();
    // Debug print to see what's happening
    debugPrint('CurrentBudget: ${currentBudget?.toMap()}');
    debugPrint('CurrentBudget maxKwh: ${currentBudget?.maxKwh}');
    debugPrint('CurrentBudget maxCost: ${currentBudget?.maxCost}');

    // Get current month's usage
    final totalKwh = usageService.getTotalKwhForMonth(now.year, now.month);
    final totalCost = usageService.getTotalCostForMonth(now.year, now.month);
    debugPrint('Total kWh: $totalKwh');
    debugPrint('Total cost: $totalCost');

    // Calculate budget usage percentages
    double kwhPercentage = 0;
    double costPercentage = 0;

    if (currentBudget != null) {
      debugPrint(
        'Calculating percentages with maxKwh: ${currentBudget.maxKwh}',
      );
      kwhPercentage = currentBudget.maxKwh > 0
          ? (totalKwh / currentBudget.maxKwh) * 100
          : 0;
      costPercentage = currentBudget.maxCost > 0
          ? (totalCost / currentBudget.maxCost) * 100
          : 0;
      debugPrint('kWh percentage: $kwhPercentage');
      debugPrint('Cost percentage: $costPercentage');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Month Usage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month and Year
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getMonthName(now.month)} ${now.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  if (currentBudget != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: costPercentage < 90
                            ? AppTheme.successColor.withOpacity(0.1)
                            : costPercentage < 100
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        costPercentage < 90
                            ? 'Within Budget'
                            : costPercentage < 100
                            ? 'Approaching Limit'
                            : 'Over Budget',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: costPercentage < 90
                              ? AppTheme.successColor
                              : costPercentage < 100
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Usage stats
              Row(
                children: [
                  Expanded(
                    child: _buildUsageStat(
                      'Consumption',
                      '$totalKwh kWh${currentBudget != null ? ' / ${currentBudget.maxKwh} kWh' : ''}',
                      currentBudget != null
                          ? '${kwhPercentage.toStringAsFixed(0)}% of budget'
                          : null,
                      kwhPercentage,
                      icon: Icons.bolt,
                      iconColor: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUsageStat(
                      'Cost',
                      'LKR ${totalCost.toStringAsFixed(2)}',
                      currentBudget != null
                          ? '${costPercentage.toStringAsFixed(0)}% of budget'
                          : null,
                      costPercentage,
                      icon: Icons.attach_money,
                      iconColor: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // View details button
              if (currentBudget != null) ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text('View Budget Details'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set a Budget'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageStat(
    String title,
    String value,
    String? subvalue,
    double percentage, {
    required IconData icon,
    required Color iconColor,
  }) {
    Color progressColor = AppTheme.successColor;

    if (percentage >= 100) {
      progressColor = AppTheme.errorColor;
    } else if (percentage >= 90) {
      progressColor = AppTheme.warningColor;
    } else if (percentage >= 75) {
      progressColor = AppTheme.accentColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        if (subvalue != null) ...[
          const SizedBox(height: 4),
          Text(
            subvalue,
            style: TextStyle(
              fontSize: 12,
              color: percentage < 90
                  ? AppTheme.lightTextColor
                  : percentage < 100
                  ? AppTheme.warningColor
                  : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100 > 1 ? 1 : percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
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
            const Text(
              'Energy Saving Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
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
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomCard(
                padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            color: AppTheme.successColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              if (tip.category != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
                    const SizedBox(height: 12),
                    Text(
                      tip.description.length > 100
                          ? '${tip.description.substring(0, 100)}...'
                          : tip.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                    if (tip.estimatedSavings != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.savings,
                            color: AppTheme.accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Est. savings: LKR ${tip.estimatedSavings!.toStringAsFixed(2)}/year',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.accentColor,
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
