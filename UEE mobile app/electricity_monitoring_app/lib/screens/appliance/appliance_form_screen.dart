import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appliance_model.dart';
import '../../services/appliance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class ApplianceFormScreen extends StatefulWidget {
  final ApplianceModel? appliance;

  const ApplianceFormScreen({super.key, this.appliance});

  @override
  State<ApplianceFormScreen> createState() => _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends State<ApplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _wattageController;
  late final TextEditingController _hoursController;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.appliance != null;

    _nameController = TextEditingController(text: widget.appliance?.name ?? '');
    _locationController = TextEditingController(
      text: widget.appliance?.location ?? '',
    );
    _wattageController = TextEditingController(
      text: widget.appliance != null
          ? widget.appliance!.wattage.toString()
          : '',
    );
    _hoursController = TextEditingController(
      text: widget.appliance != null
          ? widget.appliance!.dailyUsageHrs.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _wattageController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _saveAppliance() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final applianceService = Provider.of<ApplianceService>(
          context,
          listen: false,
        );

        if (_isEditing && widget.appliance != null) {
          // Update existing appliance
          final success = await applianceService.updateAppliance(
            id: widget.appliance!.id,
            name: _nameController.text,
            wattage: double.parse(_wattageController.text),
            dailyUsageHrs: double.parse(_hoursController.text),
            location: _locationController.text,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appliance updated successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Add new appliance
          final newAppliance = await applianceService.addAppliance(
            name: _nameController.text,
            wattage: double.parse(_wattageController.text),
            dailyUsageHrs: double.parse(_hoursController.text),
            location: _locationController.text,
          );

          if (newAppliance != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appliance added successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        debugPrint('Error saving appliance: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving appliance. Please try again.'),
              backgroundColor: AppTheme.errorColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Appliance' : 'Add Appliance',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Saving appliance data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form title
                    const Text(
                      'Appliance Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    _buildFormField(
                      controller: _nameController,
                      labelText: 'Appliance Name',
                      hintText: 'e.g., Refrigerator, TV, Air Conditioner',
                      prefixIcon: Icons.devices,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the appliance name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Location field
                    _buildFormField(
                      controller: _locationController,
                      labelText: 'Location',
                      hintText: 'e.g., Kitchen, Living Room, Bedroom',
                      prefixIcon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Power information section
                    const Text(
                      'Power Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Wattage field
                    _buildFormField(
                      controller: _wattageController,
                      labelText: 'Wattage (W)',
                      hintText: 'e.g., 100',
                      prefixIcon: Icons.electric_bolt,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the wattage';
                        }
                        final wattage = double.tryParse(value);
                        if (wattage == null || wattage <= 0) {
                          return 'Please enter a valid wattage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Information note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can find wattage information on the appliance label or manual',
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Daily usage hours
                    _buildFormField(
                      controller: _hoursController,
                      labelText: 'Daily Usage (hours)',
                      hintText: 'e.g., 5',
                      prefixIcon: Icons.access_time,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter daily usage hours';
                        }
                        final hours = double.tryParse(value);
                        if (hours == null || hours <= 0) {
                          return 'Please enter a valid value';
                        }
                        if (hours > 24) {
                          return 'Value cannot exceed 24 hours';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveAppliance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Update Appliance' : 'Add Appliance',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Cancel button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          side: const BorderSide(
                            color: AppTheme.secondaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.primaryColor)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightTextColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTextColor.withOpacity(0.5),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
