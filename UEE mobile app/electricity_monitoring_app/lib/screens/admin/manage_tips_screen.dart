import 'package:flutter/material.dart';
import '../../models/admin_tip_model.dart';
import '../../services/admin_tip_service.dart';
import 'create_tip_screen.dart';

class ManageTipsScreen extends StatefulWidget {
  const ManageTipsScreen({Key? key}) : super(key: key);

  @override
  State<ManageTipsScreen> createState() => _ManageTipsScreenState();
}

class _ManageTipsScreenState extends State<ManageTipsScreen>
    with TickerProviderStateMixin {
  final AdminTipService _adminTipService = AdminTipService();
  late TabController _tabController;

  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  bool _showActiveOnly = false;

  final List<String> _categories = [
    'all',
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

  final List<String> _difficulties = ['all', 'easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tips'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Tips'),
            Tab(icon: Icon(Icons.check_circle), text: 'Active Tips'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTipsList(showActiveOnly: false),
                _buildTipsList(showActiveOnly: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTipScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tips...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildTipsList({required bool showActiveOnly}) {
    return StreamBuilder<List<AdminTipModel>>(
      stream: showActiveOnly
          ? _adminTipService.getActiveAdminTips()
          : _adminTipService.getAdminTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<AdminTipModel> tips = snapshot.data ?? [];

        // Apply filters
        tips = _filterTips(tips);

        if (tips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No tips found'
                      : 'No tips created yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try adjusting your search or filters'
                      : 'Create your first tip to get started!',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTipScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Tip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return _buildTipCard(tips[index]);
            },
          ),
        );
      },
    );
  }

  List<AdminTipModel> _filterTips(List<AdminTipModel> tips) {
    return tips.where((tip) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!tip.title.toLowerCase().contains(query) &&
            !tip.description.toLowerCase().contains(query) &&
            !tip.category.toLowerCase().contains(query) &&
            !tip.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'all' && tip.category != _selectedCategory) {
        return false;
      }

      // Difficulty filter
      if (_selectedDifficulty != 'all' &&
          tip.difficulty != _selectedDifficulty) {
        return false;
      }

      // Active filter
      if (_showActiveOnly && !tip.isActive) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildTipCard(AdminTipModel tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _editTip(tip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _getCategoryColor(tip.category),
                    radius: 20,
                    child: Icon(
                      _getCategoryIcon(tip.category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tip.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusChip(tip),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, tip),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: Row(
                          children: [
                            Icon(
                              tip.isActive ? Icons.pause : Icons.play_arrow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(tip.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'send',
                        child: Row(
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text('Send to Users'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('View Stats'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(tip.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatCategoryName(tip.category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(tip.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        tip.difficulty,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDifficultyIcon(tip.difficulty),
                          size: 12,
                          color: _getDifficultyColor(tip.difficulty),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDifficultyName(tip.difficulty),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(tip.difficulty),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        tip.priority.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (tip.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: tip.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (tip.estimatedSavings != null ||
                  tip.potentialSavingsKwh > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (tip.estimatedSavings != null) ...[
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      Text(
                        '\$${tip.estimatedSavings!.toStringAsFixed(2)}/mo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (tip.potentialSavingsKwh > 0) ...[
                      Icon(Icons.flash_on, size: 16, color: Colors.blue[600]),
                      Text(
                        '${tip.potentialSavingsKwh.toStringAsFixed(1)} kWh/mo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AdminTipModel tip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tip.isActive ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tip.isActive ? Icons.check_circle : Icons.pause_circle,
            size: 12,
            color: tip.isActive ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            tip.isActive ? 'Active' : 'Paused',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: tip.isActive ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, AdminTipModel tip) {
    switch (action) {
      case 'edit':
        _editTip(tip);
        break;
      case 'toggle_active':
        _toggleTipActive(tip);
        break;
      case 'send':
        _sendTip(tip);
        break;
      case 'stats':
        _viewStats(tip);
        break;
      case 'delete':
        _deleteTip(tip);
        break;
    }
  }

  void _editTip(AdminTipModel tip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateTipScreen(tip: tip)),
    );
  }

  Future<void> _toggleTipActive(AdminTipModel tip) async {
    try {
      final updatedTip = tip.copyWith(isActive: !tip.isActive);
      await _adminTipService.updateAdminTip(updatedTip);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tip ${updatedTip.isActive ? 'activated' : 'deactivated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendTip(AdminTipModel tip) {
    // Navigate to send tip screen with this specific tip
    Navigator.pushNamed(context, '/admin/send-tip', arguments: tip);
  }

  Future<void> _viewStats(AdminTipModel tip) async {
    try {
      final stats = await _adminTipService.getTipStats(tip.id);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${tip.title} - Stats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Times Sent: ${stats['sentCount'] ?? 0}'),
              Text('Times Read: ${stats['readCount'] ?? 0}'),
              if (stats['lastSentAt'] != null)
                Text('Last Sent: ${_formatDate(stats['lastSentAt'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTip(AdminTipModel tip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tip'),
        content: Text(
          'Are you sure you want to delete "${tip.title}"? This action cannot be undone.',
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
        await _adminTipService.deleteAdminTip(tip.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tips'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category:'),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_formatCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Difficulty:'),
              DropdownButton<String>(
                value: _selectedDifficulty,
                isExpanded: true,
                items: _difficulties.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(_formatDifficultyName(difficulty)),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active only'),
                value: _showActiveOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showActiveOnly = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'all';
                _selectedDifficulty = 'all';
                _showActiveOnly = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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

  String _formatCategoryName(String category) {
    if (category == 'all') return 'All Categories';
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDifficultyName(String difficulty) {
    if (difficulty == 'all') return 'All Difficulties';
    return difficulty[0].toUpperCase() + difficulty.substring(1);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Never';
    DateTime dateTime = date is DateTime ? date : date.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
