import 'package:flutter/material.dart';
import '../../models/admin_tip_model.dart';
import '../../services/admin_tip_service.dart';

class SendTipScreen extends StatefulWidget {
  final AdminTipModel? selectedTip;

  const SendTipScreen({Key? key, this.selectedTip}) : super(key: key);

  @override
  State<SendTipScreen> createState() => _SendTipScreenState();
}

class _SendTipScreenState extends State<SendTipScreen>
    with TickerProviderStateMixin {
  final AdminTipService _adminTipService = AdminTipService();
  late TabController _tabController;

  AdminTipModel? _selectedTip;
  bool _isLoading = false;
  bool _isSending = false;

  // Target audience selection
  List<String> _selectedTargetGroups = ['all'];
  double? _monthlyUsageMin;
  double? _monthlyUsageMax;
  List<String> _requiredAppliances = [];

  // Scheduling
  bool _scheduleForLater = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // Statistics
  Map<String, dynamic> _userStats = {};

  final List<String> _targetGroups = [
    'all',
    'high_usage',
    'medium_usage',
    'low_usage',
  ];

  final List<String> _applianceTypes = [
    'air_conditioner',
    'heater',
    'water_heater',
    'refrigerator',
    'washing_machine',
    'dryer',
    'dishwasher',
    'oven',
    'microwave',
    'tv',
    'computer',
    'lighting',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedTip = widget.selectedTip;
    _loadUserStats();

    if (_selectedTip != null) {
      _selectedTargetGroups = List.from(_selectedTip!.targetUserGroups);
      _monthlyUsageMin = _selectedTip!.targetCriteria['monthlyUsageMin']
          ?.toDouble();
      _monthlyUsageMax = _selectedTip!.targetCriteria['monthlyUsageMax']
          ?.toDouble();
      _requiredAppliances = List<String>.from(
        _selectedTip!.targetCriteria['hasAppliances'] ?? [],
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _adminTipService.getUserEngagementStats();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Tips to Users'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Send Now'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendNowTab(), _buildScheduleTab()],
      ),
    );
  }

  Widget _buildSendNowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserStats(),
          const SizedBox(height: 20),
          _buildTipSelection(),
          const SizedBox(height: 20),
          _buildTargetAudience(),
          const SizedBox(height: 20),
          _buildTargetingCriteria(),
          const SizedBox(height: 32),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipSelection(),
          const SizedBox(height: 20),
          _buildTargetAudience(),
          const SizedBox(height: 20),
          _buildTargetingCriteria(),
          const SizedBox(height: 20),
          _buildScheduleSettings(),
          const SizedBox(height: 32),
          _buildScheduleButton(),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  'Total Users',
                  _userStats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Active Users',
                  _userStats['activeUsers']?.toString() ?? '0',
                  Icons.people_alt,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Engagement',
                  '${(_userStats['engagementRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Tip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_selectedTip == null)
                  TextButton(
                    onPressed: _selectTip,
                    child: const Text('Browse Tips'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedTip != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getCategoryColor(
                            _selectedTip!.category,
                          ),
                          radius: 16,
                          child: Icon(
                            _getCategoryIcon(_selectedTip!.category),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTip!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedTip = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedTip!.description,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              _selectedTip!.category,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatCategoryName(_selectedTip!.category),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(_selectedTip!.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              'Priority ${_selectedTip!.priority}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tip selected',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a tip to send to users',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectTip,
                      child: const Text('Select Tip'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetAudience() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Audience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select user groups to receive this tip:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _targetGroups.map((group) {
                return FilterChip(
                  label: Text(_formatTargetGroupName(group)),
                  selected: _selectedTargetGroups.contains(group),
                  onSelected: (selected) {
                    setState(() {
                      if (group == 'all') {
                        if (selected) {
                          _selectedTargetGroups = ['all'];
                        }
                      } else {
                        if (selected) {
                          _selectedTargetGroups.remove('all');
                          _selectedTargetGroups.add(group);
                        } else {
                          _selectedTargetGroups.remove(group);
                        }
                        if (_selectedTargetGroups.isEmpty) {
                          _selectedTargetGroups = ['all'];
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetingCriteria() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Targeting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Min Monthly Usage (kWh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _monthlyUsageMin?.toString(),
                    onChanged: (value) {
                      _monthlyUsageMin = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Max Monthly Usage (kWh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _monthlyUsageMax?.toString(),
                    onChanged: (value) {
                      _monthlyUsageMax = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Required Appliances:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _applianceTypes.map((appliance) {
                return FilterChip(
                  label: Text(_formatApplianceName(appliance)),
                  selected: _requiredAppliances.contains(appliance),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _requiredAppliances.add(appliance);
                      } else {
                        _requiredAppliances.remove(appliance);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Select Date'),
                    subtitle: Text(
                      _scheduledDate != null
                          ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                          : 'No date selected',
                    ),
                    leading: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Select Time'),
                    subtitle: Text(
                      _scheduledTime != null
                          ? _scheduledTime!.format(context)
                          : 'No time selected',
                    ),
                    leading: const Icon(Icons.access_time),
                    onTap: _selectTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedTip != null && !_isSending) ? _sendTipNow : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSending
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Sending...'),
                ],
              )
            : const Text(
                'Send Tip Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildScheduleButton() {
    final canSchedule =
        _selectedTip != null &&
        _scheduledDate != null &&
        _scheduledTime != null &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSchedule ? _scheduleTip : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Scheduling...'),
                ],
              )
            : const Text(
                'Schedule Tip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectTip() async {
    final result = await showDialog<AdminTipModel>(
      context: context,
      builder: (context) => _TipSelectionDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedTip = result;
        // Update targeting based on selected tip
        _selectedTargetGroups = List.from(result.targetUserGroups);
        _monthlyUsageMin = result.targetCriteria['monthlyUsageMin']?.toDouble();
        _monthlyUsageMax = result.targetCriteria['monthlyUsageMax']?.toDouble();
        _requiredAppliances = List<String>.from(
          result.targetCriteria['hasAppliances'] ?? [],
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _scheduledDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() {
        _scheduledTime = time;
      });
    }
  }

  Future<void> _sendTipNow() async {
    if (_selectedTip == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Update the tip with current targeting criteria
      final updatedTip = _selectedTip!.copyWith(
        targetUserGroups: _selectedTargetGroups,
        targetCriteria: _buildTargetCriteria(),
      );

      await _adminTipService.sendTipToTargetGroups(updatedTip);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip sent successfully to target users!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _scheduleTip() async {
    if (_selectedTip == null ||
        _scheduledDate == null ||
        _scheduledTime == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      // Update the tip with current targeting criteria and schedule
      final updatedTip = _selectedTip!.copyWith(
        targetUserGroups: _selectedTargetGroups,
        targetCriteria: _buildTargetCriteria(),
        scheduledAt: scheduledDateTime,
        isScheduled: true,
      );

      await _adminTipService.scheduleTip(updatedTip, scheduledDateTime);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tip scheduled for ${_formatScheduledTime(scheduledDateTime)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _buildTargetCriteria() {
    Map<String, dynamic> criteria = {};

    if (_monthlyUsageMin != null) {
      criteria['monthlyUsageMin'] = _monthlyUsageMin;
    }
    if (_monthlyUsageMax != null) {
      criteria['monthlyUsageMax'] = _monthlyUsageMax;
    }
    if (_requiredAppliances.isNotEmpty) {
      criteria['hasAppliances'] = _requiredAppliances;
    }

    return criteria;
  }

  String _formatScheduledTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
  }

  // Helper methods (same as in other screens)
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hvac':
        return Colors.blue;
      case 'lighting':
        return Colors.yellow[700]!;
      case 'appliances':
        return Colors.green;
      case 'water_heating':
        return Colors.red;
      case 'insulation':
        return Colors.brown;
      case 'behavioral':
        return Colors.purple;
      case 'renewable':
        return Colors.teal;
      case 'smart_home':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hvac':
        return Icons.ac_unit;
      case 'lighting':
        return Icons.lightbulb;
      case 'appliances':
        return Icons.kitchen;
      case 'water_heating':
        return Icons.hot_tub;
      case 'insulation':
        return Icons.home;
      case 'behavioral':
        return Icons.psychology;
      case 'renewable':
        return Icons.solar_power;
      case 'smart_home':
        return Icons.home_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTargetGroupName(String group) {
    return group
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatApplianceName(String appliance) {
    return appliance
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _TipSelectionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminTipService adminTipService = AdminTipService();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Tip'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<AdminTipModel>>(
                stream: adminTipService.getActiveAdminTips(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final tips = snapshot.data ?? [];

                  if (tips.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No active tips available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create and activate tips first',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tips.length,
                    itemBuilder: (context, index) {
                      final tip = tips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(tip.category),
                            child: Icon(
                              _getCategoryIcon(tip.category),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(tip.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                        tip.category,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatCategoryName(tip.category),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getCategoryColor(tip.category),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
                                      Text(
                                        ' ${tip.priority}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(tip),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hvac':
        return Colors.blue;
      case 'lighting':
        return Colors.yellow[700]!;
      case 'appliances':
        return Colors.green;
      case 'water_heating':
        return Colors.red;
      case 'insulation':
        return Colors.brown;
      case 'behavioral':
        return Colors.purple;
      case 'renewable':
        return Colors.teal;
      case 'smart_home':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hvac':
        return Icons.ac_unit;
      case 'lighting':
        return Icons.lightbulb;
      case 'appliances':
        return Icons.kitchen;
      case 'water_heating':
        return Icons.hot_tub;
      case 'insulation':
        return Icons.home;
      case 'behavioral':
        return Icons.psychology;
      case 'renewable':
        return Icons.solar_power;
      case 'smart_home':
        return Icons.home_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
