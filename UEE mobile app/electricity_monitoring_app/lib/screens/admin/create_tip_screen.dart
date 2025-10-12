import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_tip_model.dart';
import '../../services/admin_tip_service.dart';

class CreateTipScreen extends StatefulWidget {
  final AdminTipModel? tip; // For editing existing tips

  const CreateTipScreen({Key? key, this.tip}) : super(key: key);

  @override
  State<CreateTipScreen> createState() => _CreateTipScreenState();
}

class _CreateTipScreenState extends State<CreateTipScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminTipService _adminTipService = AdminTipService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedSavingsController = TextEditingController();
  final _potentialSavingsKwhController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();

  // Form values
  String _selectedCategory = 'general';
  String _selectedDifficulty = 'medium';
  int _priority = 3;
  bool _isActive = true;
  List<String> _selectedTargetGroups = ['all'];
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  // Target criteria
  double? _monthlyUsageMin;
  double? _monthlyUsageMax;
  List<String> _requiredAppliances = [];

  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _categories = [
    'general',
    'hvac',
    'lighting',
    'appliances',
    'water_heating',
    'insulation',
    'behavioral',
    'renewable',
    'smart_home',
  ];

  final List<String> _difficulties = ['easy', 'medium', 'hard'];

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
    if (widget.tip != null) {
      _isEditing = true;
      _populateFieldsFromTip(widget.tip!);
    }
  }

  void _populateFieldsFromTip(AdminTipModel tip) {
    _titleController.text = tip.title;
    _descriptionController.text = tip.description;
    _selectedCategory = tip.category;
    _estimatedSavingsController.text = tip.estimatedSavings?.toString() ?? '';
    _selectedDifficulty = tip.difficulty;
    _potentialSavingsKwhController.text = tip.potentialSavingsKwh.toString();
    _selectedTargetGroups = List.from(tip.targetUserGroups);
    _priority = tip.priority;
    _isActive = tip.isActive;
    _tags = List.from(tip.tags);
    _imageUrlController.text = tip.imageUrl ?? '';
    _actionUrlController.text = tip.actionUrl ?? '';

    // Target criteria
    _monthlyUsageMin = tip.targetCriteria['monthlyUsageMin']?.toDouble();
    _monthlyUsageMax = tip.targetCriteria['monthlyUsageMax']?.toDouble();
    _requiredAppliances = List<String>.from(
      tip.targetCriteria['hasAppliances'] ?? [],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedSavingsController.dispose();
    _potentialSavingsKwhController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tip' : 'Create New Tip'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildCategoryAndDifficulty(),
              const SizedBox(height: 24),
              _buildSavingsInfo(),
              const SizedBox(height: 24),
              _buildTargeting(),
              const SizedBox(height: 24),
              _buildAdvancedSettings(),
              const SizedBox(height: 24),
              _buildTags(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tip Title *',
                hintText: 'Enter a clear, concise title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Provide detailed instructions and benefits',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAndDifficulty() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category & Difficulty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_formatCategoryName(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty Level',
                border: OutlineInputBorder(),
              ),
              items: _difficulties.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Row(
                    children: [
                      Icon(
                        _getDifficultyIcon(difficulty),
                        color: _getDifficultyColor(difficulty),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDifficultyName(difficulty)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Priority Level: $_priority',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _priority.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _priority.toString(),
              onChanged: (value) {
                setState(() {
                  _priority = value.round();
                });
              },
            ),
            Text(
              _getPriorityDescription(_priority),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Savings Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedSavingsController,
              decoration: const InputDecoration(
                labelText: 'Estimated Monthly Savings (\$)',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _potentialSavingsKwhController,
              decoration: const InputDecoration(
                labelText: 'Potential Savings (kWh/month)',
                hintText: '0.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flash_on),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  double? kwh = double.tryParse(value);
                  if (kwh == null || kwh < 0) {
                    return 'Please enter a valid kWh value';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargeting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Audience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Target User Groups:',
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
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Advanced Targeting'),
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Minimum Monthly Usage (kWh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _monthlyUsageMin?.toString(),
                  onChanged: (value) {
                    _monthlyUsageMin = double.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Maximum Monthly Usage (kWh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _monthlyUsageMax?.toString(),
                  onChanged: (value) {
                    _monthlyUsageMax = double.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Tip is available for sending to users'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actionUrlController,
              decoration: const InputDecoration(
                labelText: 'Action URL (optional)',
                hintText: 'https://example.com/more-info',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Tag',
                      hintText: 'e.g., summer, winter, quick-win',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTag(_tagController.text),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTip,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditing ? 'Update Tip' : 'Create Tip',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveTip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build target criteria
      Map<String, dynamic> targetCriteria = {};
      if (_monthlyUsageMin != null) {
        targetCriteria['monthlyUsageMin'] = _monthlyUsageMin;
      }
      if (_monthlyUsageMax != null) {
        targetCriteria['monthlyUsageMax'] = _monthlyUsageMax;
      }
      if (_requiredAppliances.isNotEmpty) {
        targetCriteria['hasAppliances'] = _requiredAppliances;
      }

      final tip = AdminTipModel(
        id: _isEditing ? widget.tip!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        estimatedSavings: _estimatedSavingsController.text.isNotEmpty
            ? double.tryParse(_estimatedSavingsController.text)
            : null,
        difficulty: _selectedDifficulty,
        potentialSavingsKwh:
            double.tryParse(_potentialSavingsKwhController.text) ?? 0.0,
        targetUserGroups: _selectedTargetGroups,
        targetCriteria: targetCriteria,
        createdAt: _isEditing ? widget.tip!.createdAt : DateTime.now(),
        isActive: _isActive,
        priority: _priority,
        tags: _tags,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        actionUrl: _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
      );

      if (_isEditing) {
        await _adminTipService.updateAdminTip(tip);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _adminTipService.createAdminTip(tip);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tip'),
        content: const Text(
          'Are you sure you want to delete this tip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminTipService.deleteAdminTip(widget.tip!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting tip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDifficultyName(String difficulty) {
    return difficulty[0].toUpperCase() + difficulty.substring(1);
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

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityDescription(int priority) {
    switch (priority) {
      case 1:
        return 'Low priority - Optional tips';
      case 2:
        return 'Below normal priority';
      case 3:
        return 'Normal priority';
      case 4:
        return 'High priority - Important tips';
      case 5:
        return 'Critical priority - Essential tips';
      default:
        return 'Normal priority';
    }
  }
}
