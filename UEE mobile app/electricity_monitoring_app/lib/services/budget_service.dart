import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class BudgetService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<BudgetModel> _budgets = [];
  bool _initialized = false;

  // Constructor
  BudgetService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('Auth state changed, loading budgets');
        _loadBudgets();
      } else {
        _budgets = [];
        notifyListeners();
      }
    });
    // Don't load on init, wait for auth state change
  }

  // Manual initialization method
  Future<void> initialize() async {
    if (!_initialized && _auth.currentUser != null) {
      _initialized = true;
      await _loadBudgets();
    }
  }

  // Internal method to load budgets - WITH BETTER ERROR HANDLING
  Future<void> _loadBudgets() async {
    try {
      debugPrint('Loading budgets for user: ${_auth.currentUser?.uid}');
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user, returning empty budget list');
        _budgets = [];
        notifyListeners();
        return;
      }

      // Simplified query to avoid composite index requirement
      // We'll sort the results manually after fetching
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      debugPrint('Loaded ${snapshot.docs.length} budget documents');
      _budgets = snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by month descending manually
      _budgets.sort((a, b) => b.month.compareTo(a.month));

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading budgets: $e');

      // Handle different types of errors
      if (e.toString().contains('permission-denied')) {
        debugPrint('Permission denied - using fallback budget handling');
        // Continue with empty budgets list, app will use fallback budgets
        _budgets = [];
        notifyListeners();
      } else if (e.toString().contains('unavailable') || e.toString().contains('Failed to get service')) {
        debugPrint('Temporary network issue loading budgets, keeping existing data');
        // Keep existing data and don't notify listeners to avoid UI flickering
        // The offline data will be used until connection is restored
      } else {
        // For other errors, still set empty list but log the error
        _budgets = [];
        notifyListeners();
      }
    }
  }

  // Public method to fetch budgets, for backward compatibility with existing code
  Future<void> fetchBudgets() async {
    return _loadBudgets();
  }

  // Getters
  List<BudgetModel> get budgets => _budgets;

  // Get budget as a stream for more efficient updates - WITH BETTER ERROR HANDLING
  Stream<BudgetModel?> getBudgetStream() {
    if (_auth.currentUser == null) {
      return Stream.value(null);
    }

    try {
      // Simplified query to avoid composite index requirement
      // We'll sort the results manually after fetching
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .snapshots()
          .handleError((error) {
            debugPrint('Error in budget stream: $error');
            // Return empty stream on error
            return Stream<BudgetModel?>.value(null);
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            
            // Convert documents to BudgetModel objects
            List<BudgetModel> budgets = snapshot.docs
                .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
                .toList();
            
            // Sort by month descending manually
            budgets.sort((a, b) => b.month.compareTo(a.month));
            
            // Get current month in format YYYY-MM
            final now = DateTime.now();
            final currentMonth =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';

            // Try to find current month budget
            try {
              return budgets.firstWhere(
                (budget) => budget.month == currentMonth,
              );
            } catch (e) {
              // Try fallback to previous month
              try {
                final previousMonth = DateTime(now.year, now.month - 1);
                final previousMonthFormatted =
                    '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';

                return budgets.firstWhere(
                  (budget) => budget.month == previousMonthFormatted,
                );
              } catch (e) {
                // No fallback available, create a default budget
                return BudgetModel(
                  id: 'default-$currentMonth',
                  month: currentMonth,
                  maxKwh: 150.0, // default values
                  maxCost: 500.0,
                  createdAt: DateTime.now(),
                );
              }
            }
          });
    } catch (e) {
      debugPrint('Error creating budget stream: $e');
      // Return empty stream on error
      return Stream<BudgetModel?>.value(null);
    }
  }

  // Get budget for specific month
  BudgetModel? getBudgetForMonth(String month) {
    try {
      debugPrint('Looking for budget for month: $month');
      debugPrint('Available budgets: ${_budgets.map((b) => b.month).toList()}');

      if (_budgets.isEmpty) {
        debugPrint('No budgets available');
        return null;
      }

      // Changed from firstWhere with exception to try/catch with direct find
      for (final budget in _budgets) {
        if (budget.month == month) {
          debugPrint('Found budget: ${budget.toMap()}');
          return budget;
        }
      }

      // If we get here, no budget was found
      debugPrint('Budget not found for month: $month');
      return null;
    } catch (e) {
      debugPrint('Error getting budget for month $month: $e');
      return null;
    }
  }

  // Add new budget - FIXED COLLECTION PATH AND DATA STRUCTURE
  Future<BudgetModel?> addBudget({
    required String month,
    required double maxKwh,
    required double maxCost,
    String? name,
    String? description,
    List<String>? recommendations,
  }) async {
    try {
      if (_auth.currentUser == null) return null;

      // Check if a budget already exists for this month
      final existingBudget = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('month', isEqualTo: month)
          .get();

      if (existingBudget.docs.isNotEmpty) {
        throw Exception('A budget already exists for this month');
      }

      // Prepare document data
      final Map<String, dynamic> budgetData = {
        'userId': _auth.currentUser!.uid, // Add userId for querying
        'month': month,
        'maxKwh': maxKwh,
        'maxCost': maxCost,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (name != null) budgetData['name'] = name;
      if (description != null) budgetData['description'] = description;
      if (recommendations != null)
        budgetData['recommendations'] = recommendations;

      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .add(budgetData);

      final doc = await docRef.get();
      final newBudget = BudgetModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      _budgets.insert(0, newBudget);
      debugPrint('Added new budget: ${newBudget.toString()}');

      // Re-load budgets to ensure we have all the latest data
      _loadBudgets();

      return newBudget;
    } catch (e) {
      debugPrint('Error adding budget: $e');

      // Handle permission errors specifically
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied: Unable to create budget. Please check your Firebase security rules.',
        );
      } else {
        throw Exception('Failed to create budget: ${e.toString()}');
      }
    }
  }

  // Update existing budget - FIXED COLLECTION PATH
  Future<bool> updateBudget({
    required String id,
    required String month,
    required double maxKwh,
    required double maxCost,
    String? name,
    String? description,
    List<String>? recommendations,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      // Check if this is a fallback budget that doesn't exist in Firestore
      if (id.startsWith('fallback-')) {
        debugPrint(
          'Detected update for fallback budget. Creating new budget instead.',
        );
        // Create a new budget instead of updating
        final newBudget = await addBudget(
          month: month,
          maxKwh: maxKwh,
          maxCost: maxCost,
          name: name,
          description: description,
          recommendations: recommendations,
        );
        return newBudget != null;
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'month': month,
        'maxKwh': maxKwh,
        'maxCost': maxCost,
      };

      // Add optional fields if provided
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (recommendations != null)
        updateData['recommendations'] = recommendations;

      // Normal update for real budgets - FIXED COLLECTION PATH
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .doc(id)
          .update(updateData);

      // Update local list
      final index = _budgets.indexWhere((budget) => budget.id == id);
      if (index != -1) {
        final updatedBudget = BudgetModel(
          id: id,
          month: month,
          maxKwh: maxKwh,
          maxCost: maxCost,
          createdAt: _budgets[index].createdAt,
          name: name ?? _budgets[index].name,
          description: description ?? _budgets[index].description,
          recommendations: recommendations ?? _budgets[index].recommendations,
        );

        _budgets[index] = updatedBudget;
        debugPrint('Updated budget: ${updatedBudget.toString()}');

        // Re-load budgets to ensure we have all the latest data
        _loadBudgets();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating budget: $e');
      return false;
    }
  }

  // Delete budget - FIXED COLLECTION PATH
  Future<bool> deleteBudget(String id) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .doc(id)
          .delete();

      // Update local list
      _budgets.removeWhere((budget) => budget.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  // Get current month's budget with fallback mechanisms (legacy method)
  BudgetModel getCurrentMonthBudget() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      debugPrint('Looking for budget for month: $currentMonth');
      debugPrint('Available budgets: ${_budgets.map((b) => b.month).toList()}');

      // First try the exact month match
      BudgetModel? budget = getBudgetForMonth(currentMonth);

      // If not found, try fallback to previous month
      if (budget == null) {
        final previousMonth = DateTime(now.year, now.month - 1);
        final previousMonthFormatted =
            '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
        debugPrint(
          'Current month budget not found, trying previous month: $previousMonthFormatted',
        );

        budget = getBudgetForMonth(previousMonthFormatted);
        if (budget != null) {
          // Create a new budget for current month based on previous month's data
          debugPrint(
            'Using previous month budget as fallback: $previousMonthFormatted',
          );
          budget = BudgetModel(
            id: 'fallback-$currentMonth',
            month: currentMonth, // Use current month in UI
            maxKwh: budget.maxKwh,
            maxCost: budget.maxCost,
            createdAt: DateTime.now(),
          );
          debugPrint(
            'Created fallback budget for current month: ${budget.toMap()}',
          );
        } else {
          // If still not found, create a default budget object
          debugPrint('No budget found, using default values');
          budget = BudgetModel(
            id: 'default-$currentMonth',
            month: currentMonth,
            maxKwh: 150.0, // default values
            maxCost: 500.0,
            createdAt: DateTime.now(),
          );
        }
      }

      debugPrint('Returning budget: ${budget.toMap()}');
      return budget;
    } catch (e) {
      debugPrint('Error getting budget with fallback: $e');
      return BudgetModel(
        id: 'default-$currentMonth',
        month: currentMonth,
        maxKwh: 150.0, // default values
        maxCost: 500.0,
        createdAt: DateTime.now(),
      );
    }
  }
}