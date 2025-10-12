import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PermissionErrorHelp extends StatelessWidget {
  final String feature;
  final VoidCallback? onContactSupport;

  const PermissionErrorHelp({
    super.key,
    required this.feature,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: AppTheme.errorColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Permission Error',
            style: const TextStyle(
              color: AppTheme.errorColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to access $feature due to database permission restrictions. '
            'This is a configuration issue that needs to be resolved by updating '
            'the Firebase security rules.',
            style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Fix for Developers:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Go to Firebase Console\n'
                  '2. Navigate to Firestore Database\n'
                  '3. Update Security Rules\n'
                  '4. Allow authenticated users to read/write their own data',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundColor,
                    foregroundColor: AppTheme.textColor,
                    side: BorderSide(
                      color: AppTheme.textColor.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              if (onContactSupport != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static void showPermissionDialog(BuildContext context, String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        contentPadding: EdgeInsets.zero,
        content: PermissionErrorHelp(
          feature: feature,
          onContactSupport: () {
            Navigator.of(context).pop();
            // You can add actual contact support functionality here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Contact support functionality not implemented yet',
                ),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          },
        ),
      ),
    );
  }
}
