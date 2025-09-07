import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_plan.dart';

class BudgetPlanService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<BudgetPlan> _availablePlans = [];
  BudgetPlan? _selectedPlan;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<BudgetPlan> get availablePlans => _availablePlans;
  BudgetPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Constructor
  BudgetPlanService() {
    _initializePlans();
  }
  
  // Initialize with default plans and load user's selected plan
  Future<void> _initializePlans() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Initialize with default plans
      _availablePlans = [
        BudgetPlan.createPlan1(),
        BudgetPlan.createPlan2(),
        BudgetPlan.createPlan3(),
      ];
      
      await _loadUserSelectedPlan();
      
      _error = null;
    } catch (e) {
      debugPrint('Error initializing budget plans: $e');
      _error = 'Failed to load budget plans';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load user's selected plan from Firestore
  Future<void> _loadUserSelectedPlan() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('No user logged in, cannot load selected plan');
        return;
      }
      
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (!userDoc.exists || !userDoc.data()!.containsKey('selectedBudgetPlan')) {
        // No plan selected, set Plan 2 (standard) as default
        _selectedPlan = BudgetPlan.createPlan2();
        return;
      }
      
      final selectedPlanId = userDoc.data()!['selectedBudgetPlan'];
      final planDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .doc(selectedPlanId)
          .get();
      
      if (planDoc.exists) {
        _selectedPlan = BudgetPlan.fromFirestore(planDoc);
      } else {
        // Fallback to default Plan 2
        _selectedPlan = BudgetPlan.createPlan2();
      }
    } catch (e) {
      debugPrint('Error loading selected budget plan: $e');
    }
  }
  
  // Select a new budget plan
  Future<bool> selectBudgetPlan(String planId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (_auth.currentUser == null) {
        throw Exception('No user logged in');
      }
      
      // Find the plan in available plans
      final selectedPlan = _availablePlans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => throw Exception('Invalid plan ID'),
      );
      
      // Update Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'selectedBudgetPlan': planId});
      
      // Save the plan to user's budgetPlans collection
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .doc(planId)
          .set(selectedPlan.toMap());
      
      _selectedPlan = selectedPlan;
      _error = null;
      
      return true;
    } catch (e) {
      debugPrint('Error selecting budget plan: $e');
      _error = 'Failed to select budget plan: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a custom budget plan
  Future<bool> createCustomBudgetPlan({
    required String name,
    required double maxKwh,
    required double maxCost,
    required String description,
    List<String>? recommendations,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (_auth.currentUser == null) {
        throw Exception('No user logged in');
      }
      
      // Create a new plan document
      final planRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('budgetPlans')
          .doc();
      
      final newPlan = BudgetPlan(
        id: planRef.id,
        name: name,
        maxKwh: maxKwh,
        maxCost: maxCost,
        description: description,
        recommendations: recommendations ?? [],
        createdAt: DateTime.now(),
      );
      
      // Save to Firestore
      await planRef.set(newPlan.toMap());
      
      // Add to available plans
      _availablePlans.add(newPlan);
      
      // Select the new plan
      await selectBudgetPlan(newPlan.id);
      
      _error = null;
      return true;
    } catch (e) {
      debugPrint('Error creating custom budget plan: $e');
      _error = 'Failed to create budget plan: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset to default plans
  Future<void> resetToDefaultPlans() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _availablePlans = [
        BudgetPlan.createPlan1(),
        BudgetPlan.createPlan2(),
        BudgetPlan.createPlan3(),
      ];
      
      _selectedPlan = BudgetPlan.createPlan2();
      
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'selectedBudgetPlan': 'plan2'});
      }
      
      _error = null;
    } catch (e) {
      debugPrint('Error resetting to default plans: $e');
      _error = 'Failed to reset plans';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get budget recommendations
  List<String> getBudgetRecommendations() {
    if (_selectedPlan == null) {
      return [];
    }
    return _selectedPlan!.recommendations;
  }
  
  // Get remaining budget values
  Map<String, dynamic> getRemainingBudget(double currentKwh, double currentCost) {
    if (_selectedPlan == null) {
      return {
        'kwhPercentage': 0.0,
        'costPercentage': 0.0,
        'remainingKwh': 0.0,
        'remainingCost': 0.0,
      };
    }
    
    final kwhPercentage = (_selectedPlan!.maxKwh > 0) 
        ? (currentKwh / _selectedPlan!.maxKwh) * 100 
        : 0.0;
    
    final costPercentage = (_selectedPlan!.maxCost > 0) 
        ? (currentCost / _selectedPlan!.maxCost) * 100 
        : 0.0;
    
    return {
      'kwhPercentage': kwhPercentage,
      'costPercentage': costPercentage,
      'remainingKwh': _selectedPlan!.maxKwh - currentKwh,
      'remainingCost': _selectedPlan!.maxCost - currentCost,
    };
  }
}
