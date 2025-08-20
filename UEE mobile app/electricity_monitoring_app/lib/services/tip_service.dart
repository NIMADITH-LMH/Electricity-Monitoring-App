import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/tip_model.dart';

class TipService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TipModel> _tips = [];
  List<TipModel> _systemTips = []; // Tips provided by the system/admin
  List<String> _categories = [];

  // Getters
  List<TipModel> get tips => [..._systemTips, ..._tips];
  List<TipModel> get userTips => _tips;
  List<TipModel> get systemTips => _systemTips;
  List<String> get categories => _categories;

  // Get tips from Firestore
  Future<List<TipModel>> fetchTips() async {
    try {
      if (_auth.currentUser == null) return [];

      // Fetch user's custom tips
      final userTipsSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tips')
          .orderBy('createdAt', descending: true)
          .get();

      _tips = userTipsSnapshot.docs
          .map((doc) => TipModel.fromMap(doc.data(), doc.id))
          .toList();

      // Fetch system/admin tips (available to all users)
      final systemTipsSnapshot = await _firestore
          .collection('tips')
          .orderBy('createdAt', descending: true)
          .get();

      _systemTips = systemTipsSnapshot.docs
          .map((doc) => TipModel.fromMap(doc.data(), doc.id))
          .toList();

      // Extract unique categories
      _updateCategories();

      notifyListeners();
      return tips;
    } catch (e) {
      debugPrint('Error fetching tips: $e');
      return [];
    }
  }

  // Update categories list
  void _updateCategories() {
    final allCategories = <String>{};

    for (final tip in _tips) {
      if (tip.category != null && tip.category!.isNotEmpty) {
        allCategories.add(tip.category!);
      }
    }

    for (final tip in _systemTips) {
      if (tip.category != null && tip.category!.isNotEmpty) {
        allCategories.add(tip.category!);
      }
    }

    _categories = allCategories.toList()..sort();
  }

  // Add new custom tip
  Future<TipModel?> addTip({
    required String title,
    required String description,
    String? category,
    double? estimatedSavings,
  }) async {
    try {
      if (_auth.currentUser == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tips')
          .add({
            'title': title,
            'description': description,
            'createdBy': _auth.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'category': category,
            'estimatedSavings': estimatedSavings,
          });

      final doc = await docRef.get();
      final newTip = TipModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      _tips.insert(0, newTip);
      _updateCategories();
      notifyListeners();
      return newTip;
    } catch (e) {
      debugPrint('Error adding tip: $e');
      return null;
    }
  }

  // Update existing custom tip
  Future<bool> updateTip({
    required String id,
    required String title,
    required String description,
    String? category,
    double? estimatedSavings,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tips')
          .doc(id)
          .update({
            'title': title,
            'description': description,
            'category': category,
            'estimatedSavings': estimatedSavings,
          });

      // Update local list
      final index = _tips.indexWhere((tip) => tip.id == id);
      if (index != -1) {
        final updatedTip = TipModel(
          id: id,
          title: title,
          description: description,
          createdBy: _tips[index].createdBy,
          createdAt: _tips[index].createdAt,
          category: category,
          estimatedSavings: estimatedSavings,
        );
        _tips[index] = updatedTip;
        _updateCategories();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating tip: $e');
      return false;
    }
  }

  // Delete custom tip
  Future<bool> deleteTip(String id) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tips')
          .doc(id)
          .delete();

      // Update local list
      _tips.removeWhere((tip) => tip.id == id);
      _updateCategories();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting tip: $e');
      return false;
    }
  }

  // Filter tips by category
  List<TipModel> filterByCategory(String category) {
    if (category.isEmpty) return tips;

    return tips.where((tip) => tip.category == category).toList();
  }
}
