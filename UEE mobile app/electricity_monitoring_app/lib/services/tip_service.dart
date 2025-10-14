import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/tip_model.dart';
import '../models/user_model.dart';
import '../models/user_tip_model.dart';
import '../services/usage_record_service.dart';

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

  // Get tips from Firestore - OPTIMIZED FOR PERFORMANCE
  Future<List<TipModel>> fetchTips() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user found');
        return [];
      }

      debugPrint('Fetching tips for user: ${_auth.currentUser!.uid}');

      // Fetch user's custom tips with limit
      final userTipsSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tips')
          .orderBy('createdAt', descending: true)
          .limit(20) // Limit to 20 most recent tips
          .get();

      _tips = userTipsSnapshot.docs
          .map((doc) => TipModel.fromMap(doc.data(), doc.id))
          .toList();

      debugPrint('Fetched ${_tips.length} user tips');

      // Fetch system/admin tips with limit and in parallel for better performance
      List<TipModel> systemTips = [];
      List<TipModel> adminTips = [];
      
      // Use Future.wait to load system and admin tips in parallel
      await Future.wait([
        // Fetch system tips
        () async {
          try {
            final systemTipsSnapshot = await _firestore
                .collection('tips')
                .orderBy('createdAt', descending: true)
                .limit(10) // Limit to 10 most recent system tips
                .get();

            systemTips = systemTipsSnapshot.docs
                .map((doc) => TipModel.fromMap(doc.data(), doc.id))
                .toList();

            debugPrint('Fetched ${systemTips.length} system tips');
          } catch (systemTipsError) {
            debugPrint('Error fetching system tips: $systemTipsError');
          }
        }(),
        
        // Fetch admin tips
        () async {
          try {
            final adminTipsSnapshot = await _firestore
                .collection('admin_tips')
                .where('isActive', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .limit(10) // Limit to 10 most recent admin tips
                .get();

            debugPrint('Fetched ${adminTipsSnapshot.docs.length} admin tips');

            adminTips = adminTipsSnapshot.docs.map((doc) {
              final data = doc.data();
              debugPrint('Processing admin tip: ${data['title']}');
              // Convert AdminTipModel to TipModel for display
              return TipModel(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                category: data['category'] ?? '',
                createdBy: 'admin', // Mark as admin-created
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                estimatedSavings: (data['estimatedSavings'] as num?)?.toDouble(),
                difficulty: data['difficulty'] ?? 'medium',
                potentialSavingsKwh:
                    (data['potentialSavingsKwh'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList();

            debugPrint(
              'Converted ${adminTips.length} admin tips to TipModel format',
            );
          } catch (adminTipsError) {
            debugPrint('Error fetching admin tips: $adminTipsError');
            if (adminTipsError.toString().contains('permission-denied')) {
              debugPrint(
                'Permission denied for admin_tips collection. Check Firestore security rules.',
              );
            }
          }
        }()
      ]);

      // Combine system tips and admin tips
      _systemTips = [...systemTips, ...adminTips];

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

  // PERSONALIZED TIPS FEATURE

  // Get user interaction data with tips - WITH BETTER ERROR HANDLING
  Future<List<UserTipModel>> getUserTipInteractions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_tips')
          .where('userId', isEqualTo: userId)
          .get();

      List<UserTipModel> results = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();

          // Safe timestamp handling for debugging - ONLY LOG WARNINGS
          final lastUpdatedAt = data['lastUpdatedAt'];
          if (lastUpdatedAt == null) {
            // This is expected for some documents, don't log as warning
            // debugPrint('Info: lastUpdatedAt field is null for doc ${doc.id}');
          } else if (lastUpdatedAt is! Timestamp) {
            // debugPrint('Info: lastUpdatedAt is not a Timestamp for doc ${doc.id}: ${lastUpdatedAt.runtimeType}');
          }

          // Use our safer fromMap method that has null safety built in
          results.add(UserTipModel.fromMap(data, doc.id));
        } catch (docError) {
          debugPrint('Error processing document ${doc.id}: $docError');
          // Continue processing other documents
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error getting user tip interactions: $e');
      // Handle network issues gracefully
      if (e.toString().contains('permission-denied')) {
        debugPrint('Permission denied getting user tip interactions');
        // Return empty list instead of throwing error
        return [];
      } else if (e.toString().contains('unavailable') || 
                 e.toString().contains('network') ||
                 e.toString().contains('Failed to get service')) {
        debugPrint('Network issue getting user tip interactions, returning empty list');
        // Network issues are temporary, return empty list
        return [];
      }
      return [];
    }
  }

  // Record that a tip has been shown to the user
  Future<void> recordTipShown(String userId, String tipId) async {
    try {
      // Check if a record already exists
      final querySnapshot = await _firestore
          .collection('user_tips')
          .where('userId', isEqualTo: userId)
          .where('tipId', isEqualTo: tipId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Record exists, update it
        await _firestore
            .collection('user_tips')
            .doc(querySnapshot.docs.first.id)
            .update({'shown': true, 'shownAt': FieldValue.serverTimestamp()});
      } else {
        // Create a new record
        await _firestore.collection('user_tips').add({
          'userId': userId,
          'tipId': tipId,
          'shown': true,
          'dismissed': false,
          'implemented': false,
          'effectivenessRating': null,
          'shownAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error recording tip shown: $e');
    }
  }

  // Record that a tip has been dismissed by the user
  Future<void> recordTipDismissed(String userId, String tipId) async {
    try {
      // Check if a record already exists
      final querySnapshot = await _firestore
          .collection('user_tips')
          .where('userId', isEqualTo: userId)
          .where('tipId', isEqualTo: tipId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Record exists, update it
        await _firestore
            .collection('user_tips')
            .doc(querySnapshot.docs.first.id)
            .update({
              'dismissed': true,
              'dismissedAt': FieldValue.serverTimestamp(),
            });
      } else {
        // Create a new record
        await _firestore.collection('user_tips').add({
          'userId': userId,
          'tipId': tipId,
          'shown': true,
          'dismissed': true,
          'implemented': false,
          'effectivenessRating': null,
          'shownAt': FieldValue.serverTimestamp(),
          'dismissedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error recording tip dismissed: $e');
    }
  }

  // Record that a tip has been implemented by the user
  Future<void> recordTipImplemented(
    String userId,
    String tipId, {
    double? effectivenessRating,
  }) async {
    try {
      // Check if a record already exists
      final querySnapshot = await _firestore
          .collection('user_tips')
          .where('userId', isEqualTo: userId)
          .where('tipId', isEqualTo: tipId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Record exists, update it
        await _firestore
            .collection('user_tips')
            .doc(querySnapshot.docs.first.id)
            .update({
              'implemented': true,
              'effectivenessRating': effectivenessRating,
              'implementedAt': FieldValue.serverTimestamp(),
            });
      } else {
        // Create a new record
        await _firestore.collection('user_tips').add({
          'userId': userId,
          'tipId': tipId,
          'shown': true,
          'dismissed': false,
          'implemented': true,
          'effectivenessRating': effectivenessRating,
          'shownAt': FieldValue.serverTimestamp(),
          'implementedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error recording tip implemented: $e');
    }
  }

  // Get personalized tips for a user based on their usage patterns and preferences
  Future<List<TipModel>> getPersonalizedTips(
    UserModel user, {
    int limit = 3,
  }) async {
    try {
      // Get user's usage data from UsageRecordService
      final usageRecordService = UsageRecordService();
      final recentUsage = await usageRecordService.getRecentUsage(user.id);

      // Get tips the user has already seen or implemented
      final userTipInteractions = await getUserTipInteractions(user.id);
      final seenTipIds = userTipInteractions
          .where((ut) => ut.shown)
          .map((ut) => ut.tipId)
          .toList();

      // Get all available tips
      await fetchTips();

      // Create a scoring system for tips based on relevance to the user
      final scoredTips = <Map<String, dynamic>>[];

      for (final tip in tips) {
        // Skip tips the user has already seen recently or implemented
        if (seenTipIds.contains(tip.id)) {
          continue;
        }

        // Calculate a relevance score based on various factors
        double relevanceScore = 0;

        // Consider appliance-specific tips if they match user's appliances
        if (tip.relevanceFactors.containsKey('applianceTypes')) {
          // TODO: Match with user's appliances
          // For now, give a small boost to generic tips
          relevanceScore += 0.2;
        }

        // Consider seasonal relevance
        if (tip.relevanceFactors.containsKey('season')) {
          final currentSeason = _getCurrentSeason();
          if (tip.relevanceFactors['season'] == currentSeason) {
            relevanceScore += 0.5;
          }
        }

        // Consider usage pattern relevance (high usage gets high-impact tips)
        if (recentUsage >
            user.notificationPreferences.usageThresholds['daily']!) {
          // For high usage users, prioritize tips with higher potential savings
          relevanceScore += tip.potentialSavingsKwh / 10; // Normalize
        }

        // Add to scored tips
        scoredTips.add({'tip': tip, 'score': relevanceScore});
      }

      // Sort by relevance score (highest first)
      scoredTips.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      // Return the top N tips
      return scoredTips
          .take(limit)
          .map((item) => item['tip'] as TipModel)
          .toList();
    } catch (e) {
      debugPrint('Error getting personalized tips: $e');
      return [];
    }
  }

  // Helper method to get current season
  String _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;

    // Simple season determination based on month
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }
}
