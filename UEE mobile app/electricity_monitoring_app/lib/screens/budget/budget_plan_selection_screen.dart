import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/budget_plan.dart';
import '../../services/budget_plan_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_card.dart';

class BudgetPlanSelectionScreen extends StatefulWidget {
  static const routeName = '/budget-plan-selection';

  const BudgetPlanSelectionScreen({super.key});

  @override
  _BudgetPlanSelectionScreenState createState() => _BudgetPlanSelectionScreenState();
}

class _BudgetPlanSelectionScreenState extends State<BudgetPlanSelectionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Select Budget Plan',
        showBackButton: true,
      ),
      body: Consumer<BudgetPlanService>(
        builder: (context, budgetPlanService, child) {
          if (budgetPlanService.isLoading || _isLoading) {
            return const LoadingIndicator(message: 'Loading budget plans...');
          }

          final plans = budgetPlanService.availablePlans;
          final selectedPlan = budgetPlanService.selectedPlan;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your budget plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a plan that matches your household electricity needs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                ...plans.map((plan) => _buildPlanCard(plan, plan.id == selectedPlan?.id)),
                const SizedBox(height: 24),
                _buildCreateCustomPlanButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(BudgetPlan plan, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectPlan(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildPlanDetailsRow('Maximum kWh', '${plan.maxKwh.toStringAsFixed(1)} kWh'),
              const SizedBox(height: 8),
              _buildPlanDetailsRow('Maximum Cost', 'LKR ${plan.maxCost.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...plan.recommendations.map((recommendation) => _buildRecommendationItem(recommendation)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetailsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCustomPlanButton() {
    return GestureDetector(
      onTap: _showCreateCustomPlanDialog,
      child: CustomCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Custom Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Set your own kWh and cost limits.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPlan(BudgetPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    final success = await Provider.of<BudgetPlanService>(context, listen: false).selectBudgetPlan(plan.id);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plan.name} selected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select plan. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateCustomPlanDialog() {
    final formKey = GlobalKey<FormState>();
    String name = 'Custom Plan';
    double maxKwh = 200;
    double maxCost = 500;
    String description = 'My custom budget plan';
    List<String> recommendations = ['Add energy saving recommendations here'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Plan'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Plan Name'),
                  validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                  onChanged: (value) => name = value,
                ),
                TextFormField(
                  initialValue: maxKwh.toString(),
                  decoration: const InputDecoration(labelText: 'Maximum kWh'),
                  keyboardType: TextInputType.number,
                  validator: (value) => double.tryParse(value!) == null ? 'Please enter a valid number' : null,
                  onChanged: (value) => maxKwh = double.tryParse(value) ?? maxKwh,
                ),
                TextFormField(
                  initialValue: maxCost.toString(),
                  decoration: const InputDecoration(labelText: 'Maximum Cost (LKR)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => double.tryParse(value!) == null ? 'Please enter a valid number' : null,
                  onChanged: (value) => maxCost = double.tryParse(value) ?? maxCost,
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 16),
                const Text('Recommendations:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextFormField(
                    initialValue: recommendations.join('\n'),
                    decoration: const InputDecoration(
                      hintText: 'Enter recommendations, one per line',
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                    onChanged: (value) {
                      recommendations = value.split('\n').where((line) => line.trim().isNotEmpty).toList();
                    },
                  ),
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });
                
                final success = await Provider.of<BudgetPlanService>(context, listen: false)
                    .createCustomBudgetPlan(
                      name: name,
                      maxKwh: maxKwh,
                      maxCost: maxCost,
                      description: description,
                      recommendations: recommendations,
                    );
                
                setState(() {
                  _isLoading = false;
                });
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom plan created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create custom plan. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
