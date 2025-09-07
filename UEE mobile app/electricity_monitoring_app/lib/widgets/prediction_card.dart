import 'package:flutter/material.dart';
import '../models/usage_analytics_model.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class PredictionCard extends StatelessWidget {
  final UsagePredictionModel prediction;

  const PredictionCard({
    Key? key,
    required this.prediction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(prediction.date);
    
    // Determine confidence level color
    Color confidenceColor;
    if (prediction.confidencePercentage >= 90) {
      confidenceColor = AppTheme.successColor;
    } else if (prediction.confidencePercentage >= 70) {
      confidenceColor = AppTheme.accentColor;
    } else {
      confidenceColor = AppTheme.warningColor;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: confidenceColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: confidenceColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${prediction.confidencePercentage.toInt()}% confidence',
                        style: TextStyle(
                          color: confidenceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Usage and Cost Cards in a Row
            Row(
              children: [
                // Usage Card
                Expanded(
                  child: _buildMetricCard(
                    title: 'Predicted Usage',
                    value: '${prediction.predictedKwh.toStringAsFixed(1)}',
                    unit: 'kWh',
                    icon: Icons.bolt,
                    iconColor: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Cost Card
                Expanded(
                  child: _buildMetricCard(
                    title: 'Predicted Cost',
                    value: 'LKR ${prediction.predictedCost.toStringAsFixed(2)}',
                    unit: '',
                    icon: Icons.account_balance_wallet,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom info or actions could go here
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    // Calculate how many days from today
    final today = DateTime.now();
    final differenceInDays = prediction.date.difference(today).inDays;
    
    String dayText = differenceInDays == 0 
        ? "Today" 
        : differenceInDays == 1 
            ? "Tomorrow" 
            : "In $differenceInDays days";
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            "Prediction for $dayText",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
