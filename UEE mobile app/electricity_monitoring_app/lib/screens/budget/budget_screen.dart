import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class BudgetScreen extends StatefulWidget {
  static const routeName = '/budget';

  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isLoading = false;
  final List<BudgetModel> _budgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<BudgetService>(context, listen: false).fetchBudgets();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Budget Management',
        showBackButton: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryColor,
        onPressed: () => _showAddEditBudgetDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<BudgetService>(
      builder: (context, budgetService, child) {
        if (_isLoading) {
          return const LoadingIndicator(message: 'Loading budget data...');
        }

        final budgets = budgetService.budgets;
        final currentBudget = budgetService.getCurrentMonthBudget();
        final previousBudgets = budgets
            .where((b) => b.id != (currentBudget?.id ?? ''))
            .toList();

        if (budgets.isEmpty) {
          return EmptyState(
            icon: Icons.account_balance_wallet,
            message:
                'No budget set yet. Create your first budget to start tracking electricity expenses.',
            buttonText: 'Create Budget',
            onButtonPressed: _showAddEditBudgetDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadBudgets,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentBudget != null) ...[
                  _buildCurrentBudgetCard(currentBudget),
                  const SizedBox(height: 24),
                  _buildUsageChart(currentBudget),
                  const SizedBox(height: 24),
                ],
                if (previousBudgets.isNotEmpty) ...[
                  const Text(
                    'Previous Budgets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: previousBudgets.length,
                    itemBuilder: (context, index) {
                      return _buildPreviousBudgetCard(previousBudgets[index]);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentBudgetCard(BudgetModel budget) {
    // Parse month and get month name
    final dateParts = budget.month.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    // Mock usage data for now - in a real app this would be calculated
    final double usedAmount =
        78.50; // This would be calculated based on actual usage
    final double percentUsed = usedAmount / budget.maxCost;
    final bool isOverBudget = percentUsed > 1.0;

    // Determine status color
    Color statusColor;
    if (percentUsed >= 1.0) {
      statusColor = AppTheme.errorColor;
    } else if (percentUsed >= 0.8) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        'LKR ${budget.maxCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Used Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        'LKR ${usedAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Budget Usage',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed > 1 ? 1 : percentUsed,
              backgroundColor: AppTheme.lightTextColor.withOpacity(0.2),
              color: statusColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percentUsed * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'Over by LKR ${(usedAmount - budget.maxCost).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isOverBudget)
                  Text(
                    'Remaining: LKR ${(budget.maxCost - usedAmount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditBudgetDialog(budget: budget),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart(BudgetModel budget) {
    // Mock daily usage data - in a real app, this would come from the service
    final List<Map<String, dynamic>> dailyUsage = [
      {'day': 'Week 1', 'amount': 18.5},
      {'day': 'Week 2', 'amount': 22.1},
      {'day': 'Week 3', 'amount': 19.8},
      {'day': 'Week 4', 'amount': 18.1},
    ];

    // Calculate max Y to ensure proper scaling
    final double maxY =
        dailyUsage
            .map((data) => data['amount'] as double)
            .reduce((max, value) => max > value ? max : value) *
        1.2;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'LKR ${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                      getTooltipColor: (group) {
                        return const Color(0xFF505050);
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < dailyUsage.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dailyUsage[value.toInt()]['day'],
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: dailyUsage.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['amount'],
                          color: AppTheme.primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousBudgetCard(BudgetModel budget) {
    // Parse month
    final dateParts = budget.month.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    // Mock usage for now - in a real app this would come from a calculation
    final double usedAmount =
        82.50; // This would be calculated based on actual usage
    final double percentUsed = usedAmount / budget.maxCost;

    // Determine status color
    Color statusColor;
    if (percentUsed >= 1.0) {
      statusColor = AppTheme.errorColor;
    } else if (percentUsed >= 0.8) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  percentUsed >= 1.0 ? 'Over Budget' : 'Under Budget',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        'LKR ${budget.maxCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Used',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        'LKR ${usedAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Difference',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        percentUsed >= 1.0
                            ? '+LKR ${(usedAmount - budget.maxCost).toStringAsFixed(2)}'
                            : '-LKR ${(budget.maxCost - usedAmount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditBudgetDialog({BudgetModel? budget}) async {
    final kwhController = TextEditingController(
      text: budget != null ? budget.maxKwh.toString() : '',
    );
    final costController = TextEditingController(
      text: budget != null ? budget.maxCost.toString() : '',
    );

    // Get current month in format YYYY-MM
    final now = DateTime.now();
    String selectedMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (budget != null) {
      selectedMonth = budget.month;
    }

    // Parse month for display
    final dateParts = selectedMonth.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    String displayMonth = DateFormat('MMMM yyyy').format(DateTime(year, month));

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          budget == null ? 'Create New Budget' : 'Edit Budget',
          style: const TextStyle(color: AppTheme.secondaryColor),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                budget == null
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Budget Month'),
                        subtitle: Text(displayMonth),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(year, month),
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                            initialDatePickerMode: DatePickerMode.year,
                          );

                          if (pickedDate != null && mounted) {
                            setState(() {
                              selectedMonth =
                                  '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                              displayMonth = DateFormat(
                                'MMMM yyyy',
                              ).format(pickedDate);
                            });
                          }
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Budget for $displayMonth',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kwhController,
                  decoration: const InputDecoration(
                    labelText: 'Max kWh',
                    border: OutlineInputBorder(),
                    suffixText: 'kWh',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maximum kWh';
                    }
                    final kwh = double.tryParse(value);
                    if (kwh == null || kwh <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Max Cost (LKR)',
                    border: OutlineInputBorder(),
                    prefixText: 'LKR ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maximum cost';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final maxKwh = double.parse(kwhController.text);
                final maxCost = double.parse(costController.text);

                if (budget == null) {
                  // Create new budget
                  await _createBudget(
                    month: selectedMonth,
                    maxKwh: maxKwh,
                    maxCost: maxCost,
                  );
                } else {
                  // Update existing budget
                  await _updateBudget(
                    id: budget.id,
                    month: selectedMonth,
                    maxKwh: maxKwh,
                    maxCost: maxCost,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(budget == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBudget({
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<BudgetService>(
        context,
        listen: false,
      ).addBudget(month: month, maxKwh: maxKwh, maxCost: maxCost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already exists')
                  ? 'A budget already exists for this month'
                  : 'Failed to create budget. Please try again.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _loadBudgets();
      }
    }
  }

  Future<void> _updateBudget({
    required String id,
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<BudgetService>(
        context,
        listen: false,
      ).updateBudget(id: id, month: month, maxKwh: maxKwh, maxCost: maxCost);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update budget. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update budget. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _loadBudgets();
      }
    }
  }
}
