import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electricity_monitoring_app/services/auth_service.dart';
import 'package:electricity_monitoring_app/models/user_model.dart';
import 'package:electricity_monitoring_app/widgets/custom_app_bar.dart';
import 'package:electricity_monitoring_app/widgets/custom_button.dart';
import 'package:electricity_monitoring_app/theme/app_colors.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  static const routeName = '/notification-preferences';

  const NotificationPreferencesScreen({super.key});

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  NotificationPreferences _preferences = NotificationPreferences();
  final TextEditingController _dailyThresholdController =
      TextEditingController();
  final TextEditingController _weeklyThresholdController =
      TextEditingController();
  final TextEditingController _monthlyThresholdController =
      TextEditingController();
  TimeOfDay _reminderTime = TimeOfDay(hour: 20, minute: 0); // Default 8 PM

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _dailyThresholdController.dispose();
    _weeklyThresholdController.dispose();
    _monthlyThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userDoc = await authService.getUserDoc();

      if (userDoc != null) {
        final user = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
        _preferences = user.notificationPreferences;

        // Set text field values
        _dailyThresholdController.text = _preferences.usageThresholds['daily']
            .toString();
        _weeklyThresholdController.text = _preferences.usageThresholds['weekly']
            .toString();
        _monthlyThresholdController.text = _preferences
            .usageThresholds['monthly']
            .toString();

        // Parse reminder time
        final timeParts = _preferences.reminderTime.split(':');
        if (timeParts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading preferences: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Create updated preferences
      final updatedPreferences = NotificationPreferences(
        reminderEnabled: _preferences.reminderEnabled,
        tipsEnabled: _preferences.tipsEnabled,
        weeklyReportEnabled: _preferences.weeklyReportEnabled,
        monthlyReportEnabled: _preferences.monthlyReportEnabled,
        enableUsageAlerts: _preferences.enableUsageAlerts,
        enableTipNotifications: _preferences.enableTipNotifications,
        enableDailyReminders: _preferences.enableDailyReminders,
        reminderTime:
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        maxTipsPerWeek: _preferences.maxTipsPerWeek,
        maxAlertsPerDay: _preferences.maxAlertsPerDay,
        usageThresholds: {
          'daily': double.parse(_dailyThresholdController.text),
          'weekly': double.parse(_weeklyThresholdController.text),
          'monthly': double.parse(_monthlyThresholdController.text),
        },
      );

      // Update in Firestore
      await authService.updateUserField(
        'notificationPreferences',
        updatedPreferences.toMap(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preferences saved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notification Preferences',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalize Your Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 20),

                  _buildSectionTitle('General Preferences'),
                  _buildSwitchTile(
                    'Enable Reminders',
                    _preferences.reminderEnabled,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: value,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Energy Saving Tips',
                    _preferences.tipsEnabled,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: value,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Weekly Report',
                    _preferences.weeklyReportEnabled,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: value,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Monthly Report',
                    _preferences.monthlyReportEnabled,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled: value,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  _buildSectionTitle('Enhanced Notifications'),
                  _buildSwitchTile(
                    'Usage Alerts',
                    _preferences.enableUsageAlerts,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: value,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Energy Tip Notifications',
                    _preferences.enableTipNotifications,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications: value,
                          enableDailyReminders:
                              _preferences.enableDailyReminders,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Daily Usage Reminders',
                    _preferences.enableDailyReminders,
                    (value) {
                      setState(() {
                        _preferences = NotificationPreferences(
                          reminderEnabled: _preferences.reminderEnabled,
                          tipsEnabled: _preferences.tipsEnabled,
                          weeklyReportEnabled: _preferences.weeklyReportEnabled,
                          monthlyReportEnabled:
                              _preferences.monthlyReportEnabled,
                          enableUsageAlerts: _preferences.enableUsageAlerts,
                          enableTipNotifications:
                              _preferences.enableTipNotifications,
                          enableDailyReminders: value,
                          reminderTime: _preferences.reminderTime,
                          maxTipsPerWeek: _preferences.maxTipsPerWeek,
                          maxAlertsPerDay: _preferences.maxAlertsPerDay,
                          usageThresholds: _preferences.usageThresholds,
                        );
                      });
                    },
                  ),

                  // Time picker for daily reminder
                  if (_preferences.enableDailyReminders)
                    ListTile(
                      title: Text('Reminder Time'),
                      subtitle: Text(
                        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),

                  SizedBox(height: 20),

                  _buildSectionTitle('Usage Thresholds'),
                  _buildTextField(
                    'Daily Threshold (kWh)',
                    _dailyThresholdController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    'Weekly Threshold (kWh)',
                    _weeklyThresholdController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    'Monthly Threshold (kWh)',
                    _monthlyThresholdController,
                    keyboardType: TextInputType.number,
                  ),

                  SizedBox(height: 30),

                  Center(
                    child: CustomButton(
                      text: 'Save Preferences',
                      onPressed: _savePreferences,
                      width: 200,
                      isLoading: _isLoading,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
