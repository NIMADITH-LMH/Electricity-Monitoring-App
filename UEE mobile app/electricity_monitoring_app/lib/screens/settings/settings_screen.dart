import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/budget_service.dart';
import '../../models/user_model.dart';
import '../../utils/card_theme_helper.dart';
import '../../widgets/background_container.dart';
import '../budget/budget_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  UserModel? _user;
  bool _usageAlertsEnabled = true;
  bool _tipsNotificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _appUpdatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationPreferences();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      await Provider.of<BudgetService>(context, listen: false).fetchBudgets();
    } catch (e) {
      // Handle errors silently, as this is just for display purposes
      debugPrint('Error loading budget data: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final user = await profileService.getUserProfile();
      setState(() {
        _user = user;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading profile')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final usageAlerts = await profileService.getUsageAlertsEnabled();
      final tipsNotifications = await profileService
          .getTipsNotificationsEnabled();
      final budgetAlerts = await profileService.getBudgetAlertsEnabled();
      final appUpdates = await profileService.getAppUpdatesEnabled();

      setState(() {
        _usageAlertsEnabled = usageAlerts;
        _tipsNotificationsEnabled = tipsNotifications;
        _budgetAlertsEnabled = budgetAlerts;
        _appUpdatesEnabled = appUpdates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading preferences')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BackgroundContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                child: Text(
                                  _user?.name.isNotEmpty == true
                                      ? _user!.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user?.name ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _user?.email ?? 'email@example.com',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Notifications section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: 'Usage Alerts',
                        subtitle:
                            'Get notified about unusual energy consumption',
                        value: _usageAlertsEnabled,
                        onChanged: (value) {
                          setState(() => _usageAlertsEnabled = value);
                          final profileService =
                              Provider.of<UserProfileService>(
                                context,
                                listen: false,
                              );
                          profileService.setUsageAlertsEnabled(value);
                        },
                        icon: Icons.bolt,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Energy Saving Tips',
                        subtitle:
                            'Receive tips to reduce electricity consumption',
                        value: _tipsNotificationsEnabled,
                        onChanged: (value) {
                          setState(() => _tipsNotificationsEnabled = value);
                          final profileService =
                              Provider.of<UserProfileService>(
                                context,
                                listen: false,
                              );
                          profileService.setTipsNotificationsEnabled(value);
                        },
                        icon: Icons.tips_and_updates,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Budget Alerts',
                        subtitle: 'Get notified when approaching budget limits',
                        value: _budgetAlertsEnabled,
                        onChanged: (value) {
                          setState(() => _budgetAlertsEnabled = value);
                          final profileService =
                              Provider.of<UserProfileService>(
                                context,
                                listen: false,
                              );
                          profileService.setBudgetAlertsEnabled(value);
                        },
                        icon: Icons.account_balance_wallet,
                      ),
                      const Divider(height: 1),
                      _buildBudgetTile(),
                      const Divider(height: 1),
                      _buildBudgetPlanTile(),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune, color: Colors.blue),
                        title: const Text('Advanced Notification Settings'),
                        subtitle: const Text(
                          'Configure personalized notification preferences',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed('/notification-preferences');
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'App Updates',
                        subtitle:
                            'Receive notifications about new app features',
                        value: _appUpdatesEnabled,
                        onChanged: (value) {
                          setState(() => _appUpdatesEnabled = value);
                          final profileService =
                              Provider.of<UserProfileService>(
                                context,
                                listen: false,
                              );
                          profileService.setAppUpdatesEnabled(value);
                        },
                        icon: Icons.system_update,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App info section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('About'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showHelpSupportDialog(context);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showPrivacyPolicyDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('About'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Electricity Monitoring App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Electricity Monitoring App helps you track your electricity usage, manage your power consumption, and save money on your energy bills.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Key Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Real-time electricity usage monitoring'),
              const Text('• Usage history and analytics'),
              const Text('• Bill prediction and budgeting'),
              const Text('• Energy-saving tips and recommendations'),
              const Text('• Customizable alerts and notifications'),
              const SizedBox(height: 16),
              const Text(
                'Developed by UEE Team',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const Text(
                '© 2025 All Rights Reserved',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const ExpansionTile(
                title: Text('How do I set up my account?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'To set up your account, go to the Profile section and tap on "Edit Profile". Fill in your personal details and save the changes.',
                    ),
                  ),
                ],
              ),
              const ExpansionTile(
                title: Text('How to connect my electricity meter?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Go to the Dashboard and tap on "Add Device". Follow the on-screen instructions to connect your electricity meter to the app.',
                    ),
                  ),
                ],
              ),
              const ExpansionTile(
                title: Text('How to set budget alerts?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Navigate to the Budget section and tap on "Set Budget". Enter your monthly budget amount and the app will automatically send alerts when you approach your limit.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.email),
                title: Text('Email Support'),
                subtitle: Text('support@electricityapp.com'),
              ),
              const ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone Support'),
                subtitle: Text('+1 (555) 123-4567'),
              ),
              const ListTile(
                leading: Icon(Icons.chat),
                title: Text('Live Chat'),
                subtitle: Text('Available 9 AM - 5 PM, Monday to Friday'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTile() {
    return Consumer<BudgetService>(
      builder: (context, budgetService, child) {
        final currentBudget = budgetService.budgets.isNotEmpty
            ? budgetService
                  .budgets
                  .first // Assume the first budget is the current one
            : null;

        return ListTile(
          leading: Icon(
            Icons.bolt,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Monthly kWh Budget'),
          subtitle: Text(
            currentBudget != null
                ? '${currentBudget.maxKwh.toStringAsFixed(1)} kWh (LKR ${currentBudget.maxCost.toStringAsFixed(2)})'
                : 'No budget set for this month',
          ),
          onTap: () {
            // Navigate to the budget screen
            Navigator.pushNamed(context, BudgetScreen.routeName);
          },
        );
      },
    );
  }
  
  Widget _buildBudgetPlanTile() {
    return ListTile(
      leading: Icon(
        Icons.shopping_bag_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Budget Plans'),
      subtitle: const Text('Select or customize your budget plan'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pushNamed(context, '/budget-plan-selection');
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Last updated: August 1, 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'This Privacy Policy describes how we collect, use, and disclose your information when you use our Electricity Monitoring App.',
              ),
              const SizedBox(height: 12),
              Text(
                '1. Information We Collect',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We collect information that you provide directly to us, such as your name, email address, and electricity consumption data. We also collect technical information about your device and how you use our app.',
              ),
              const SizedBox(height: 12),
              Text(
                '2. How We Use Your Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We use the information we collect to provide, maintain, and improve our services, process your requests, and send you notifications about your electricity usage and billing.',
              ),
              const SizedBox(height: 12),
              Text(
                '3. Data Security',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
              ),
              const SizedBox(height: 12),
              Text(
                '4. Data Sharing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We do not sell your personal information. We may share your information with third-party service providers who help us operate our app, but they are bound by confidentiality obligations.',
              ),
              const SizedBox(height: 12),
              Text(
                '5. Your Rights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have the right to access, update, or delete your personal information. You can do this through your account settings or by contacting our support team.',
              ),
              const SizedBox(height: 16),
              const Text(
                'For more information about our privacy practices, please contact us at privacy@electricityapp.com.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final user = await profileService.getUserProfile();
      setState(() {
        _user = user;
        if (user != null) {
          _nameController.text = user.name;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading profile')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final success = await profileService.updateUserProfile(
        name: _nameController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final success = await profileService.updateUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update password')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating password: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            _user?.name.isNotEmpty == true
                                ? _user!.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profile info section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _user?.email ?? '',
                              enabled: false, // Email is not editable
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isLoading ? 'Updating...' : 'Update Profile',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Change password section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm New Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updatePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isLoading ? 'Updating...' : 'Update Password',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
