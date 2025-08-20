import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appliance_model.dart';
import '../../services/appliance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rounded_button.dart';

class EditApplianceScreen extends StatefulWidget {
  final ApplianceModel appliance;

  const EditApplianceScreen({super.key, required this.appliance});

  @override
  State<EditApplianceScreen> createState() => _EditApplianceScreenState();
}

class _EditApplianceScreenState extends State<EditApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _wattageController;
  late TextEditingController _dailyUsageController;
  late TextEditingController _locationController;

  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing appliance data
    _nameController = TextEditingController(text: widget.appliance.name);
    _wattageController = TextEditingController(
      text: widget.appliance.wattage.toString(),
    );
    _dailyUsageController = TextEditingController(
      text: widget.appliance.dailyUsageHrs.toString(),
    );
    _locationController = TextEditingController(
      text: widget.appliance.location,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _dailyUsageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateAppliance() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final applianceService = Provider.of<ApplianceService>(
          context,
          listen: false,
        );

        final success = await applianceService.updateAppliance(
          id: widget.appliance.id,
          name: _nameController.text.trim(),
          wattage: double.parse(_wattageController.text.trim()),
          dailyUsageHrs: double.parse(_dailyUsageController.text.trim()),
          location: _locationController.text.trim(),
        );

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appliance updated successfully!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update appliance. Please try again.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteAppliance() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appliance'),
        content: Text(
          'Are you sure you want to delete "${widget.appliance.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final applianceService = Provider.of<ApplianceService>(
          context,
          listen: false,
        );

        final success = await applianceService.deleteAppliance(
          widget.appliance.id,
        );

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appliance deleted successfully!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _isDeleting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete appliance. Please try again.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Edit Appliance',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading || _isDeleting ? null : _deleteAppliance,
            color: Colors.red,
          ),
        ],
      ),
      body: _isLoading || _isDeleting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isDeleting
                        ? 'Deleting appliance...'
                        : 'Updating appliance...',
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appliance details section
                    _buildApplianceDetailsSection(),

                    const SizedBox(height: 32),

                    // Submit button
                    RoundedButton(
                      label: 'Update Appliance',
                      onPressed: _updateAppliance,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildApplianceDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appliance Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Name field
        CustomTextField(
          controller: _nameController,
          label: 'Appliance Name',
          hintText: 'e.g., Living Room TV',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an appliance name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Wattage field
        CustomTextField(
          controller: _wattageController,
          label: 'Wattage (W)',
          hintText: 'e.g., 100',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter wattage';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid wattage value';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Daily usage field
        CustomTextField(
          controller: _dailyUsageController,
          label: 'Daily Usage (hours)',
          hintText: 'e.g., 4',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter daily usage hours';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid usage value';
            }
            if (double.parse(value) > 24) {
              return 'Daily usage cannot exceed 24 hours';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Location field
        CustomTextField(
          controller: _locationController,
          label: 'Location (optional)',
          hintText: 'e.g., Living Room',
        ),

        const SizedBox(height: 16),

        // Consumption preview
        if (_wattageController.text.isNotEmpty &&
            _dailyUsageController.text.isNotEmpty &&
            double.tryParse(_wattageController.text) != null &&
            double.tryParse(_dailyUsageController.text) != null)
          _buildConsumptionPreview(
            double.parse(_wattageController.text),
            double.parse(_dailyUsageController.text),
          ),
      ],
    );
  }

  Widget _buildConsumptionPreview(double wattage, double hoursPerDay) {
    // Calculate consumption
    final dailyConsumptionKWh = (wattage * hoursPerDay) / 1000;
    final monthlyConsumptionKWh = dailyConsumptionKWh * 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated Consumption',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily:',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${dailyConsumptionKWh.toStringAsFixed(2)} kWh',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly:',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${monthlyConsumptionKWh.toStringAsFixed(2)} kWh',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
