import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class BudgetService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<BudgetModel> _budgets = [];

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
    // Load on init
    _loadBudgets();
  }
  
  // Internal method to load budgets
  Future<void> _loadBudgets() async {
    try {
      debugPrint('Loading budgets for user: ${_auth.currentUser?.uid}');
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user, returning empty budget list');
        _budgets = [];
        notifyListeners();
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
          .orderBy('month', descending: true)
          .get();

      debugPrint('Loaded ${snapshot.docs.length} budget documents');
      _budgets = snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }
  }
  
  // Public method to fetch budgets, for backward compatibility with existing code
  Future<void> fetchBudgets() async {
    return _loadBudgets();
  }

  // Getters
  List<BudgetModel> get budgets => _budgets;
  
  // Get budget as a stream for more efficient updates
  Stream<BudgetModel?> getBudgetStream() {
    if (_auth.currentUser == null) {
      return Stream.value(null);
    }
    
    // Return a stream that will emit the current month's budget
    return _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('budgets')
      .orderBy('month', descending: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        
        // Get current month in format YYYY-MM
        final now = DateTime.now();
        final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        
        // Try to find current month budget
        try {
          final currentBudgetDoc = snapshot.docs.firstWhere(
            (doc) => doc.data()['month'] == currentMonth
          );
          return BudgetModel.fromMap(currentBudgetDoc.data(), currentBudgetDoc.id);
        } catch (e) {
          // Try fallback to previous month
          try {
            final previousMonth = DateTime(now.year, now.month - 1);
            final previousMonthFormatted = 
                '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
            
            final fallbackBudgetDoc = snapshot.docs.firstWhere(
              (doc) => doc.data()['month'] == previousMonthFormatted
            );
            return BudgetModel.fromMap(fallbackBudgetDoc.data(), fallbackBudgetDoc.id);
          } catch (e) {
            // No fallback available, create a default budget
            return BudgetModel(
              id: 'default-${currentMonth}',
              month: currentMonth,
              maxKwh: 150.0, // default values
              maxCost: 500.0,
              createdAt: DateTime.now(),
            );
          }
        }
      });
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
  
  // Add new budget
  Future<BudgetModel?> addBudget({
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    try {
      if (_auth.currentUser == null) return null;

      // Check if a budget already exists for this month
      final existingBudget = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
          .where('month', isEqualTo: month)
          .get();

      if (existingBudget.docs.isNotEmpty) {
        throw Exception('A budget already exists for this month');
      }

      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
          .add({
            'month': month,
            'maxKwh': maxKwh,
            'maxCost': maxCost,
            'createdAt': FieldValue.serverTimestamp(),
          });

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
      rethrow;
    }
  }

  // Update existing budget
  Future<bool> updateBudget({
    required String id,
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
          .doc(id)
          .update({'month': month, 'maxKwh': maxKwh, 'maxCost': maxCost});

      // Update local list
      final index = _budgets.indexWhere((budget) => budget.id == id);
      if (index != -1) {
        final updatedBudget = BudgetModel(
          id: id,
          month: month,
          maxKwh: maxKwh,
          maxCost: maxCost,
          createdAt: _budgets[index].createdAt,
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

  // Delete budget
  Future<bool> deleteBudget(String id) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
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
        final previousMonthFormatted = '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
        debugPrint('Current month budget not found, trying previous month: $previousMonthFormatted');
        
        budget = getBudgetForMonth(previousMonthFormatted);
        if (budget != null) {
          // Create a new budget for current month based on previous month's data
          debugPrint('Using previous month budget as fallback: $previousMonthFormatted');
          budget = BudgetModel(
            id: 'fallback-${currentMonth}',
            month: currentMonth, // Use current month in UI
            maxKwh: budget.maxKwh,
            maxCost: budget.maxCost,
            createdAt: DateTime.now(),
          );
          debugPrint('Created fallback budget for current month: ${budget.toMap()}');
        } else {
          // If still not found, create a default budget object
          debugPrint('No budget found, using default values');
          budget = BudgetModel(
            id: 'default-${currentMonth}',
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
        id: 'default-${currentMonth}',
        month: currentMonth,
        maxKwh: 150.0, // default values
        maxCost: 500.0,
        createdAt: DateTime.now(),
      );
    }
  }
}
