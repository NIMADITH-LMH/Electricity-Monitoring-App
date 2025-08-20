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
        debugPrint('Auth state changed, fetching budgets');
        fetchBudgets();
      } else {
        _budgets = [];
        notifyListeners();
      }
    });
    // Fetch on init
    fetchBudgets();
  }

  // Getters
  List<BudgetModel> get budgets => _budgets;

  // Get user budgets from Firestore
  Future<List<BudgetModel>> fetchBudgets() async {
    try {
      debugPrint('Fetching budgets for user: ${_auth.currentUser?.uid}');
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user, returning empty budget list');
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgets')
          .orderBy('month', descending: true)
          .get();

      debugPrint('Fetched ${snapshot.docs.length} budget documents');
      _budgets = snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
          .toList();

      // Debug print each budget
      for (final budget in _budgets) {
        debugPrint(
          'Budget: ${budget.month}, maxKwh: ${budget.maxKwh}, maxCost: ${budget.maxCost}',
        );
      }

      notifyListeners();
      return _budgets;
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      return [];
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

      // Re-fetch budgets to ensure we have all the latest data
      fetchBudgets();
      notifyListeners();
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

        // Re-fetch budgets to ensure we have all the latest data
        fetchBudgets();
        notifyListeners();
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

  // Get budget for specific month
  BudgetModel? getBudgetForMonth(String month) {
    try {
      debugPrint('Looking for budget for month: $month');
      debugPrint('Available budgets: ${_budgets.map((b) => b.month).toList()}');

      if (_budgets.isEmpty) {
        debugPrint('No budgets available');
        return null;
      }

      final budget = _budgets.firstWhere(
        (budget) => budget.month == month,
        orElse: () => throw Exception('Budget not found for month: $month'),
      );

      debugPrint('Found budget: ${budget.toMap()}');
      return budget;
    } catch (e) {
      debugPrint('Error getting budget for month $month: $e');
      return null;
    }
  }

  // Get current month's budget
  BudgetModel? getCurrentMonthBudget() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final budget = getBudgetForMonth(currentMonth);
    debugPrint('getCurrentMonthBudget for $currentMonth: ${budget?.toMap()}');
    return budget;
  }
}
