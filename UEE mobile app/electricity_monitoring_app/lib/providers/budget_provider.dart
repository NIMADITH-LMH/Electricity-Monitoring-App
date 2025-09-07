import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService;
  StreamSubscription<BudgetModel?>? _budgetSubscription;
  BudgetModel? _currentBudget;
  bool _isLoading = true;
  String? _error;
  
  // Constructor
  BudgetProvider(this._budgetService) {
    // Initialize by subscribing to the budget stream
    _subscribeToBudgetStream();
  }
  
  // Getters
  BudgetModel? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Subscribe to the budget stream
  void _subscribeToBudgetStream() {
    _isLoading = true;
    notifyListeners();
    
    // Cancel any existing subscription
    _budgetSubscription?.cancel();
    
    // Subscribe to the budget stream
    _budgetSubscription = _budgetService.getBudgetStream().listen(
      (budget) {
        _currentBudget = budget;
        _isLoading = false;
        _error = null;
        notifyListeners();
        debugPrint('BudgetProvider: Received budget update: ${budget?.toMap()}');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('BudgetProvider: Error in budget stream: $_error');
      }
    );
  }
  
  // Method to manually refresh the budget
  Future<void> loadBudget() async {
    _subscribeToBudgetStream();
  }
  
  // Add new budget (delegating to service)
  Future<BudgetModel?> addBudget({
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    try {
      return await _budgetService.addBudget(
        month: month,
        maxKwh: maxKwh,
        maxCost: maxCost,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Update existing budget (delegating to service)
  Future<bool> updateBudget({
    required String id,
    required String month,
    required double maxKwh,
    required double maxCost,
  }) async {
    try {
      final result = await _budgetService.updateBudget(
        id: id,
        month: month,
        maxKwh: maxKwh,
        maxCost: maxCost,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Clean up resources when provider is disposed
  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
