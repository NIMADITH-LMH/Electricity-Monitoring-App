import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tip_model.dart';
import '../../services/tip_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_card.dart';

class TipsListScreen extends StatefulWidget {
  static const routeName = '/tips';

  const TipsListScreen({super.key});

  @override
  State<TipsListScreen> createState() => _TipsListScreenState();
}

class _TipsListScreenState extends State<TipsListScreen> {
  bool _isLoading = false;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Energy Saving Tips',
        showBackButton: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryColor,
        onPressed: () => _showAddEditTipDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TipService>(
      builder: (context, tipService, child) {
        if (_isLoading) {
          return const LoadingIndicator(message: 'Loading tips...');
        }

        final allTips = tipService.tips;

        if (allTips.isEmpty) {
          return EmptyState(
            icon: Icons.lightbulb_outline,
            message:
                'No Energy Saving Tips Found. Add your first tip to start saving energy and money.',
            buttonText: 'Add Tip',
            onButtonPressed: _showAddEditTipDialog,
          );
        }

        // Filter tips based on search and category
        final filteredTips = _filterTips(allTips);

        // Get unique categories for the filter
        final categories = _getUniqueCategories(allTips);

        return Column(
          children: [
            // Search and filter section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tips...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Category filter
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                        ...categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tips count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filteredTips.length} ${filteredTips.length == 1 ? 'Tip' : 'Tips'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tips list
            Expanded(
              child: filteredTips.isEmpty
                  ? const Center(
                      child: Text(
                        'No tips found matching your criteria',
                        style: TextStyle(color: AppTheme.lightTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTips.length,
                      itemBuilder: (context, index) {
                        return _buildTipCard(filteredTips[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getUniqueCategories(List<TipModel> tips) {
    final categories = <String>{};
    for (final tip in tips) {
      if (tip.category != null && tip.category!.isNotEmpty) {
        categories.add(tip.category!);
      }
    }
    return categories.toList()..sort();
  }

  List<TipModel> _filterTips(List<TipModel> tips) {
    if (_searchController.text.isEmpty && _selectedCategory == null) {
      return tips;
    }

    return tips.where((tip) {
      // Filter by search text
      final searchMatch =
          _searchController.text.isEmpty ||
          tip.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          tip.description.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      // Filter by category
      final categoryMatch =
          _selectedCategory == null || tip.category == _selectedCategory;

      return searchMatch && categoryMatch;
    }).toList();
  }

  Widget _buildTipCard(TipModel tip) {
    return CustomCard(
      // margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (tip.category != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tip.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showTipOptions(tip),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.description,
            style: const TextStyle(fontSize: 14, color: AppTheme.textColor),
          ),
          if (tip.estimatedSavings != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.savings,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Est. savings: LKR ${tip.estimatedSavings!.toStringAsFixed(2)}/year',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
          // Source field is not in the model
        ],
      ),
    );
  }

  void _showTipOptions(TipModel tip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.secondaryColor),
                title: const Text('Edit Tip'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditTipDialog(tip: tip);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Delete Tip'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(tip);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppTheme.primaryColor),
                title: const Text('Share Tip'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEditTipDialog({TipModel? tip}) async {
    final titleController = TextEditingController(text: tip?.title);
    final descriptionController = TextEditingController(text: tip?.description);
    final categoryController = TextEditingController(text: tip?.category);
    // Source field removed
    final sourceController = TextEditingController();
    final savingsController = TextEditingController(
      text: tip?.estimatedSavings?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tip == null ? 'Add Energy Saving Tip' : 'Edit Energy Saving Tip',
          style: const TextStyle(color: AppTheme.secondaryColor),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: savingsController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Yearly Savings (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final savings = double.tryParse(value);
                      if (savings == null || savings < 0) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Source (optional)',
                    border: OutlineInputBorder(),
                  ),
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
                  final tipService = Provider.of<TipService>(
                    context,
                    listen: false,
                  );

                  double? estimatedSavings;
                  if (savingsController.text.isNotEmpty) {
                    estimatedSavings = double.tryParse(savingsController.text);
                  }

                  if (tip == null) {
                    // Add new tip
                    await tipService.addTip(
                      title: titleController.text,
                      description: descriptionController.text,
                      category: categoryController.text.isEmpty
                          ? null
                          : categoryController.text,
                      estimatedSavings: estimatedSavings,
                      // source parameter removed
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tip added successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    // Update existing tip
                    await tipService.updateTip(
                      id: tip.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      category: categoryController.text.isEmpty
                          ? null
                          : categoryController.text,
                      estimatedSavings: estimatedSavings,
                      // source parameter removed
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tip updated successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error saving tip: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error saving tip. Please try again.'),
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
            child: Text(tip == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(TipModel tip) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tip'),
        content: Text('Are you sure you want to delete "${tip.title}"?'),
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
                final tipService = Provider.of<TipService>(
                  context,
                  listen: false,
                );
                await tipService.deleteTip(tip.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tip deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting tip: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error deleting tip. Please try again.'),
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
}
