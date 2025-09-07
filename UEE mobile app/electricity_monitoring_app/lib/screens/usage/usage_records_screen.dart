import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/usage_record_model.dart';
import '../../services/usage_record_service.dart';
import '../../services/appliance_service.dart';
import '../../services/budget_service.dart';
import '../../services/report_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
// import '../../widgets/custom_card.dart'; // Not used

class UsageRecordsScreen extends StatefulWidget {
  static const routeName = '/usage-records';

  const UsageRecordsScreen({super.key});

  @override
  State<UsageRecordsScreen> createState() => _UsageRecordsScreenState();
}

class _UsageRecordsScreenState extends State<UsageRecordsScreen> {
  bool _isLoading = false;
  String _selectedMonth = "all";
  // Removed _selectedAppliance variable since it's not currently used

  @override
  void initState() {
    super.initState();
    // We now use "all" as the default for both month and appliance
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Usage Records', showBackButton: true),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryColor,
        onPressed: () => _showAddRecordDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer2<UsageRecordService, ApplianceService>(
      builder: (context, usageService, applianceService, child) {
        if (_isLoading) {
          return const LoadingIndicator(message: 'Please wait...');
        }

        final allRecords = usageService.usageRecords;
        // Removed the unused appliances variable

        if (allRecords.isEmpty) {
          return EmptyState(
            icon: Icons.insert_chart,
            message:
                'No Usage Records Found. Add your first usage record to start tracking your energy consumption.',
            buttonText: 'Add Record',
            onButtonPressed: _showAddRecordDialog,
          );
        }

        // Filter records based on selected month and appliance
        final filteredRecords = _filterRecords(allRecords);

        // Get available months for filter
        final months = _getUniqueMonths(allRecords);

        return Column(
          children: [
            // Filter section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Records',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Month filter
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Month',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    value: _validateSelectedMonth(months),
                    items: [
                      const DropdownMenuItem<String>(
                        value: "all",
                        child: Text('All Months'),
                      ),
                      ...months.map((month) {
                        final parts = month.split('-');
                        final year = int.parse(parts[0]);
                        final monthNum = int.parse(parts[1]);
                        final monthName = DateFormat(
                          'MMMM',
                        ).format(DateTime(year, monthNum));
                        return DropdownMenuItem(
                          value: month,
                          child: Text('$monthName $year'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value ?? "all";
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // We've temporarily disabled the appliance filter since the UsageRecordModel doesn't have applianceId
                  // Just show the month filter for now
                ],
              ),
            ),

            // Records count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredRecords.length} ${filteredRecords.length == 1 ? 'Record' : 'Records'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                  if (filteredRecords.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _showReportOptionsDialog(),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            // Records list
            Expanded(
              child: filteredRecords.isEmpty
                  ? const Center(
                      child: Text(
                        'No records found matching your criteria',
                        style: TextStyle(color: AppTheme.lightTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        return _buildRecordCard(
                          filteredRecords[index],
                          applianceService,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getUniqueMonths(List<UsageRecordModel> records) {
    final months = <String>{};
    for (final record in records) {
      final dateStr =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      months.add(dateStr);
    }
    return months.toList()..sort((a, b) => b.compareTo(a)); // Sort desc
  }
  
  // Helper method to ensure selected month is valid
  String _validateSelectedMonth(List<String> availableMonths) {
    // If selectedMonth is "all", that's always valid
    if (_selectedMonth == "all") {
      return _selectedMonth;
    }
    
    // Check if the currently selected month is in the available months
    if (availableMonths.contains(_selectedMonth)) {
      return _selectedMonth;
    }
    
    // If not, default to "all"
    return "all";
  }

  List<UsageRecordModel> _filterRecords(List<UsageRecordModel> records) {
    // For now, we're only filtering by month since the UsageRecordModel doesn't have an applianceId field
    if (_selectedMonth == "all") {
      return records;
    }

    return records.where((record) {
      // Filter by month
      final monthMatch =
          _selectedMonth == "all" ||
          (_selectedMonth ==
              '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}');

      return monthMatch;
    }).toList();
  }

  Widget _buildRecordCard(
    UsageRecordModel record,
    ApplianceService applianceService,
  ) {
    // No appliance direct reference in this model
    const applianceName = 'General Usage';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRecordDetails(record, applianceName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.electric_bolt,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applianceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(record.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.totalKwh} kWh',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      Text(
                        'LKR ${record.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Notes field not in model
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(UsageRecordModel record, String applianceName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(
                      Icons.electric_bolt,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Usage Details: $applianceName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Details
                _buildDetailRow(
                  'Date',
                  DateFormat('MMMM d, yyyy').format(record.date),
                ),
                _buildDetailRow('Energy Used', '${record.totalKwh} kWh'),
                _buildDetailRow(
                  'Cost',
                  'LKR ${record.totalCost.toStringAsFixed(2)}',
                ),

                // No hoursUsed field in model
                // No notes field in model
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddRecordDialog(record: record);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(record);
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.errorColor,
                      ),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecordDialog({UsageRecordModel? record}) async {
    final applianceService = Provider.of<ApplianceService>(
      context,
      listen: false,
    );
    final appliances = applianceService.appliances;

    if (appliances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add appliances first before adding usage records.',
          ),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // No applianceId in model
    String? selectedApplianceId = appliances.isNotEmpty
        ? appliances.first.id
        : null;
    final dateController = TextEditingController(
      text: record != null
          ? DateFormat('yyyy-MM-dd').format(record.date)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final kwhController = TextEditingController(
      text: record != null ? record.totalKwh.toString() : '',
    );
    final hoursController = TextEditingController(
      // No hoursUsed field in model
      text: '',
    );
    final costController = TextEditingController(
      text: record != null ? record.totalCost.toString() : '',
    );
    final notesController = TextEditingController(
      // No notes field in model
      text: '',
    );

    DateTime selectedDate = record?.date ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record == null ? 'Add Usage Record' : 'Edit Usage Record',
          style: const TextStyle(color: AppTheme.secondaryColor),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Appliance dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Appliance',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedApplianceId,
                  items: appliances.map((appliance) {
                    return DropdownMenuItem(
                      value: appliance.id,
                      child: Text(appliance.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedApplianceId = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an appliance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date picker
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(pickedDate);
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // kWh
                TextFormField(
                  controller: kwhController,
                  decoration: const InputDecoration(
                    labelText: 'Energy Used (kWh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bolt),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter energy used';
                    }
                    final kwh = double.tryParse(value);
                    if (kwh == null || kwh <= 0) {
                      return 'Please enter a valid value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Hours used
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Hours Used',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hours used';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null || hours <= 0 || hours > 24) {
                      return 'Please enter a valid value (1-24)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cost
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost (LKR)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cost';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Please enter a valid value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                setState(() {
                  _isLoading = true;
                });

                try {
                  final usageService = Provider.of<UsageRecordService>(
                    context,
                    listen: false,
                  );

                  final kwh = double.parse(kwhController.text);
                  // hoursUsed not used in updated model
                  // final hoursUsed = double.parse(hoursController.text);
                  final cost = double.parse(costController.text);
                  // notes not used in updated model
                  // final notes = notesController.text.isEmpty ? null : notesController.text;

                  if (record == null) {
                    // Add new record
                    await usageService.addUsageRecord(
                      date: selectedDate,
                      totalKwh: kwh,
                      totalCost: cost,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Record added successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    // Update existing record
                    await usageService.updateUsageRecord(
                      id: record.id,
                      date: selectedDate,
                      totalKwh: kwh,
                      totalCost: cost,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Record updated successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error saving record: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error saving record. Please try again.'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.pop(context);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(record == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(UsageRecordModel record) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'Are you sure you want to delete this usage record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isLoading = true;
              });

              try {
                final usageService = Provider.of<UsageRecordService>(
                  context,
                  listen: false,
                );
                await usageService.deleteUsageRecord(record.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Record deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting record: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error deleting record. Please try again.'),
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
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Generate Report',
          style: TextStyle(color: AppTheme.secondaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select report type:'),
            const SizedBox(height: 16),

            // Weekly Report Option
            ListTile(
              leading: const Icon(
                Icons.date_range,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Weekly Report'),
              subtitle: const Text('Generate report for the last 7 days'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
              ),
              onTap: () {
                Navigator.pop(context);
                _generateWeeklyReport();
              },
            ),

            const SizedBox(height: 8),

            // Monthly Report Option
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppTheme.secondaryColor,
              ),
              title: const Text('Monthly Report'),
              subtitle: const Text('Generate report for the selected month'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.5),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _generateMonthlyReport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _generateWeeklyReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usageService = Provider.of<UsageRecordService>(
        context,
        listen: false,
      );
      final budgetService = Provider.of<BudgetService>(context, listen: false);

      // Define the date range for the weekly report
      final endDate = DateTime.now();
      final startDate = endDate.subtract(
        const Duration(days: 6),
      ); // Last 7 days

      // Get records for the selected date range
      final weeklyRecords = usageService.getRecordsForDateRange(
        startDate,
        endDate,
      );

      // Calculate totals using the service methods
      final totalKwh = usageService.getTotalKwhForDateRange(startDate, endDate);
      final totalCost = usageService.getTotalCostForDateRange(
        startDate,
        endDate,
      );

      // Get current month's budget (approximate for weekly)
      final currentMonth =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}';
      final budget = budgetService.getBudgetForMonth(currentMonth);

      // Generate the report
      final filePath = await ReportService.generateReport(
        records: weeklyRecords,
        startDate: startDate,
        endDate: endDate,
        reportType: 'weekly',
        budget: budget,
        totalKwh: totalKwh,
        totalCost: totalCost,
      );

      setState(() {
        _isLoading = false;
      });

      if (filePath != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Weekly Report Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your weekly electricity usage report for ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)} has been created.',
                ),
                const SizedBox(height: 8),
                const Text('The report includes:'),
                const SizedBox(height: 4),
                const Text('• Weekly usage summary'),
                const Text('• Budget comparison'),
                const Text('• Daily usage details'),
                const SizedBox(height: 8),
                Text(
                  'Saved to: $filePath',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate weekly report')),
        );
      }
    } catch (e) {
      debugPrint('Error generating weekly report: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while generating the weekly report'),
        ),
      );
    }
  }

  void _generateMonthlyReport() async {
    if (_selectedMonth == "all") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specific month first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usageService = Provider.of<UsageRecordService>(
        context,
        listen: false,
      );
      final budgetService = Provider.of<BudgetService>(context, listen: false);

      // Get month and year from selected month
      final dateParts = _selectedMonth.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);

      // Create date range for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      // Get all records for the selected month
      final filteredRecords = _filterRecords(usageService.usageRecords);

      // Calculate totals
      final totalKwh = usageService.getTotalKwhForMonth(year, month);
      final totalCost = usageService.getTotalCostForMonth(year, month);

      // Get budget for the month
      final budget = budgetService.getBudgetForMonth(_selectedMonth);

      // Generate the report using the new method
      final filePath = await ReportService.generateReport(
        records: filteredRecords,
        startDate: startDate,
        endDate: endDate,
        reportType: 'monthly',
        budget: budget,
        totalKwh: totalKwh,
        totalCost: totalCost,
      );

      setState(() {
        _isLoading = false;
      });

      if (filePath != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Generated Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your electricity usage report for ${DateFormat('MMMM yyyy').format(DateTime(year, month))} has been created.',
                ),
                const SizedBox(height: 8),
                const Text('The report includes:'),
                const SizedBox(height: 4),
                const Text('• Monthly usage summary'),
                const Text('• Budget comparison'),
                const Text('• Daily usage details'),
                const SizedBox(height: 8),
                Text(
                  'Saved to: $filePath',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate report')),
        );
      }
    } catch (e) {
      debugPrint('Error generating report: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while generating the report'),
        ),
      );
    }
  }
}
