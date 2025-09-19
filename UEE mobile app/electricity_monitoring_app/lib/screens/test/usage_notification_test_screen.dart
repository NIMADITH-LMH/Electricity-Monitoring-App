import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/usage_notifier_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/background_container.dart';

class UsageNotificationTestScreen extends StatefulWidget {
  static const routeName = '/usage-notification-test';
  
  const UsageNotificationTestScreen({super.key});

  @override
  State<UsageNotificationTestScreen> createState() => _UsageNotificationTestScreenState();
}

class _UsageNotificationTestScreenState extends State<UsageNotificationTestScreen> {
  final TextEditingController _usageController = TextEditingController(text: '0');
  int _selectedUsage = 0;
  
  @override
  void dispose() {
    _usageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Usage Notification Test'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage Notification System',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This tool lets you test the multi-level notification system for electricity usage alerts. '
                        'The system will trigger notifications at different thresholds:',
                      ),
                      SizedBox(height: 12),
                      _buildThresholdRow('Yellow Alert', '50% of budget', Colors.yellow),
                      _buildThresholdRow('Orange Alert', '80% of budget', Colors.orange),
                      _buildThresholdRow('Red Alert', '100% of budget', Colors.red),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Usage Simulator
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulate Usage Level',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Budget: 100 kWh (Fixed for testing)',
                      ),
                      SizedBox(height: 16),
                      
                      // Usage Slider
                      Row(
                        children: [
                          Text('Usage:'),
                          SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: _selectedUsage.toDouble(),
                              min: 0,
                              max: 120,
                              divisions: 120,
                              label: '$_selectedUsage kWh',
                              onChanged: (value) {
                                setState(() {
                                  _selectedUsage = value.toInt();
                                  _usageController.text = _selectedUsage.toString();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _usageController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                suffix: Text('kWh'),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                final usage = int.tryParse(value) ?? 0;
                                if (usage >= 0 && usage <= 120) {
                                  setState(() {
                                    _selectedUsage = usage;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Usage Percentage
                      _buildUsagePercentageIndicator(),
                      
                      SizedBox(height: 24),
                      
                      // Test Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _triggerUsageUpdate(),
                          child: Text('Test Notification'),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Reset Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _resetNotificationState(),
                          child: Text('Reset Notification State'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Notifications Work',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Notifications trigger when crossing a threshold\n'
                        '• Each threshold triggers only once per day\n'
                        '• Notifications reset daily at midnight\n'
                        '• When usage drops below 50%, notifications reset\n'
                        '• Background checks run every 15 minutes\n'
                        '• Only the highest threshold crossed will notify',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildThresholdRow(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(subtitle),
        ],
      ),
    );
  }
  
  Widget _buildUsagePercentageIndicator() {
    double percentage = _selectedUsage.toDouble();
    Color barColor;
    
    if (percentage >= 100) {
      barColor = Colors.red;
    } else if (percentage >= 80) {
      barColor = Colors.orange;
    } else if (percentage >= 50) {
      barColor = Colors.yellow;
    } else {
      barColor = Colors.green;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage: $_selectedUsage% of budget',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
  
  void _triggerUsageUpdate() {
    final notifier = Provider.of<UsageNotifier>(context, listen: false);
    
    // Get current user ID or use a placeholder for testing
    String userId = '';  // Empty string will use current authenticated user
    
    // Trigger the usage update with the selected usage value
    notifier.updateUsage(userId, _selectedUsage).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usage updated and notification check triggered'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
  
  void _resetNotificationState() async {
    try {
      // Get the current authenticated user
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Reset the notification state in Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'lastNotified': 0,
          'lastNotifiedDate': '',
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification state has been reset'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}