import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/appliance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rounded_button.dart';

class AddApplianceScreen extends StatefulWidget {
  static const routeName = '/add-appliance';

  const AddApplianceScreen({super.key});

  @override
  State<AddApplianceScreen> createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wattageController = TextEditingController();
  final TextEditingController _dailyUsageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedApplianceType;
  bool _isLoading = false;

  // Common household appliances with average wattage
  final List<Map<String, dynamic>> _commonAppliances = [
    {'type': 'Refrigerator', 'wattage': 150},
    {'type': 'Television', 'wattage': 100},
    {'type': 'Air Conditioner', 'wattage': 1500},
    {'type': 'Washing Machine', 'wattage': 500},
    {'type': 'Ceiling Fan', 'wattage': 75},
    {'type': 'Light Bulb (LED)', 'wattage': 10},
    {'type': 'Light Bulb (CFL)', 'wattage': 14},
    {'type': 'Microwave Oven', 'wattage': 1000},
    {'type': 'Water Heater', 'wattage': 3000},
    {'type': 'Computer/Laptop', 'wattage': 150},
    {'type': 'Other', 'wattage': 0},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _dailyUsageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onApplianceTypeSelected(String? type) {
    setState(() {
      _selectedApplianceType = type;
      if (type != 'Other') {
        // Pre-fill name and wattage based on selected type
        final selectedAppliance = _commonAppliances.firstWhere(
          (appliance) => appliance['type'] == type,
          orElse: () => {'type': 'Other', 'wattage': 0},
        );

        _nameController.text = selectedAppliance['type'];
        _wattageController.text = selectedAppliance['wattage'].toString();
      }
    });
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

        final newAppliance = await applianceService.addAppliance(
          name: _nameController.text.trim(),
          wattage: double.parse(_wattageController.text.trim()),
          dailyUsageHrs: double.parse(_dailyUsageController.text.trim()),
          location: _locationController.text.trim(),
        );

        if (newAppliance != null) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appliance added successfully!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add appliance. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Add New Appliance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appliance selection section
                    _buildApplianceTypeSection(),

                    const SizedBox(height: 24),

                    // Appliance details section
                    _buildApplianceDetailsSection(),

                    const SizedBox(height: 32),

                    // Submit button
                    RoundedButton(
                      label: 'Save Appliance',
                      onPressed: _saveAppliance,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildApplianceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Appliance Type',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Choose from common household appliances or add a custom one',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextColor),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedApplianceType,
              hint: const Text('Select appliance type'),
              items: _commonAppliances.map((appliance) {
                return DropdownMenuItem<String>(
                  value: appliance['type'],
                  child: Text(appliance['type']),
                );
              }).toList(),
              onChanged: _onApplianceTypeSelected,
            ),
          ),
        ),
      ],
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
