import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ElegantUsageCard extends StatelessWidget {
  final String month;
  final String year;
  final double totalKwh;
  final double maxKwh;
  final double kwhPercentage;
  final double totalCost;
  final double maxCost;
  final double costPercentage;
  final VoidCallback onViewDetails;

  const ElegantUsageCard({
    super.key,
    required this.month,
    required this.year,
    required this.totalKwh,
    required this.maxKwh,
    required this.kwhPercentage,
    required this.totalCost,
    required this.maxCost,
    required this.costPercentage,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "$month $year",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  _buildBudgetStatus(),
                ],
              ),
              const SizedBox(height: 20),

              // Main Content - Consumption and Cost
              Row(
                children: [
                  // Consumption Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bolt,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Consumption',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Value
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${totalKwh.toStringAsFixed(1)} ',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const TextSpan(
                                text: 'kWh',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Budget Total
                        Text(
                          '/ ${maxKwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress Bar
                        _buildProgressBar(
                          kwhPercentage, 
                          _getProgressColor(kwhPercentage)
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Percentage Text
                        Text(
                          '${kwhPercentage.toStringAsFixed(0)}% of budget',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getProgressTextColor(kwhPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Container(
                    height: 100,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  
                  // Cost Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.attach_money,
                                color: AppTheme.accentColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cost',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Value
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'LKR ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              TextSpan(
                                text: totalCost.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Budget Total
                        Text(
                          '/ LKR ${maxCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress Bar
                        _buildProgressBar(
                          costPercentage, 
                          _getProgressColor(costPercentage)
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Percentage Text
                        Text(
                          '${costPercentage.toStringAsFixed(0)}% of budget',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getProgressTextColor(costPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // View Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('View Budget Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetStatus() {
    Color backgroundColor;
    Color textColor;
    String text;
    
    if (costPercentage < 80) {
      backgroundColor = AppTheme.successColor.withOpacity(0.1);
      textColor = AppTheme.successColor;
      text = 'Within Budget';
    } else if (costPercentage < 100) {
      backgroundColor = AppTheme.warningColor.withOpacity(0.1);
      textColor = AppTheme.warningColor;
      text = 'Approaching Limit';
    } else {
      backgroundColor = AppTheme.errorColor.withOpacity(0.1);
      textColor = AppTheme.errorColor;
      text = 'Over Budget';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double percentage, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: percentage / 100 > 1 ? 1 : percentage / 100,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 8,
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) {
      return AppTheme.errorColor;
    } else if (percentage >= 80) {
      return AppTheme.warningColor;
    } else if (percentage >= 60) {
      return AppTheme.accentColor;
    } else {
      return AppTheme.successColor;
    }
  }

  Color _getProgressTextColor(double percentage) {
    if (percentage >= 100) {
      return AppTheme.errorColor;
    } else if (percentage >= 80) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.lightTextColor;
    }
  }
}
