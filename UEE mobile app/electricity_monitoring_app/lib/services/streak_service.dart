import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/badge_model.dart';

class StreakService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _currentStreak = 0;
  DateTime? _lastSavedDate;
  List<BadgeModel> _badges = [];
  
  // Default milestone days for streak badges
  final List<int> _milestones = [3, 7, 30];
  
  // Getters
  int get currentStreak => _currentStreak;
  DateTime? get lastSavedDate => _lastSavedDate;
  List<BadgeModel> get badges => _badges;
  List<int> get milestones => _milestones;
  
  // Constructor
  StreakService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('Auth state changed, loading streak data');
        _loadStreakData();
        _loadBadges();
      } else {
        _currentStreak = 0;
        _lastSavedDate = null;
        _badges = [];
        notifyListeners();
      }
    });
    // Load on init
    _loadStreakData();
    _loadBadges();
  }
  
  // Calculate the next milestone
  int getNextMilestone(int streak) {
    for (final milestone in _milestones) {
      if (streak < milestone) return milestone;
    }
    return _milestones.last; // if beyond last milestone, show last milestone
  }
  
  // Calculate progress towards next milestone (0.0 to 1.0)
  double getProgressToNextMilestone(int streak) {
    final nextMilestone = getNextMilestone(streak);
    return (streak / nextMilestone).clamp(0.0, 1.0);
  }
  
  // Load streak data from Firestore
  Future<void> _loadStreakData() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user');
        return;
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentStreak = data['streak'] ?? 0;
        
        if (data['lastSavedDate'] != null) {
          if (data['lastSavedDate'] is Timestamp) {
            _lastSavedDate = (data['lastSavedDate'] as Timestamp).toDate();
          } else {
            _lastSavedDate = DateTime.parse(data['lastSavedDate'].toString());
          }
        }
        
        debugPrint('Loaded streak data: $_currentStreak days, last saved: $_lastSavedDate');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }
  
  // Load badges from Firestore
  Future<void> _loadBadges() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user');
        return;
      }
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('badges')
          .get();
      
      _badges = snapshot.docs
          .map((doc) => BadgeModel.fromMap(doc.data(), doc.id))
          .toList();
      
      debugPrint('Loaded ${_badges.length} badges');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }
  }
  
  // Register an energy saving action
  Future<bool> recordEnergySavingAction() async {
    try {
      if (_auth.currentUser == null) return false;
      
      final today = DateTime.now();
      today.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      
      int newStreak = _currentStreak;
      
      // Check if this is a continuation of the streak
      if (_lastSavedDate != null) {
        final lastSavedDay = _lastSavedDate!.copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
        
        final difference = today.difference(lastSavedDay).inDays;
        
        if (difference == 0) {
          // Already saved today, no streak increment
          return true;
        } else if (difference == 1) {
          // Consecutive day, increment streak
          newStreak = _currentStreak + 1;
        } else {
          // Streak broken, start over
          newStreak = 1;
        }
      } else {
        // First time saving energy
        newStreak = 1;
      }
      
      // Update user document with new streak info
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({
            'streak': newStreak,
            'lastSavedDate': Timestamp.fromDate(today),
          }, SetOptions(merge: true));
      
      _currentStreak = newStreak;
      _lastSavedDate = today;
      
      // Check if this unlocked any badges
      await _checkAndUnlockBadges(newStreak);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording energy saving action: $e');
      return false;
    }
  }
  
  // Check if any badges should be unlocked
  Future<void> _checkAndUnlockBadges(int streak) async {
    try {
      if (_auth.currentUser == null) return;
      
      // Check each milestone
      for (final milestone in _milestones) {
        if (streak >= milestone) {
          // Check if this badge already exists
          final badgeId = 'streak_$milestone';
          final existingBadge = _badges.firstWhere(
            (badge) => badge.id == badgeId,
            orElse: () => BadgeModel(
              id: '',
              title: '',
              description: '',
              iconPath: '',
              isUnlocked: false,
              type: 'streak',
            ),
          );
          
          // If badge doesn't exist or is not unlocked, create/update it
          if (existingBadge.id.isEmpty || !existingBadge.isUnlocked) {
            final now = DateTime.now();
            
            // Create badge document
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('badges')
                .doc(badgeId)
                .set({
                  'title': '$milestone-Day Streak',
                  'description': 'Saved energy for $milestone days in a row!',
                  'iconPath': 'assets/images/badges/streak_$milestone.png',
                  'isUnlocked': true,
                  'unlockedAt': Timestamp.fromDate(now),
                  'type': 'streak',
                });
            
            // Add notification for the user
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('notifications')
                .add({
                  'title': 'New Badge Unlocked!',
                  'message': 'You earned the $milestone-Day Streak badge!',
                  'read': false,
                  'createdAt': Timestamp.fromDate(now),
                  'type': 'badge',
                });
            
            debugPrint('Unlocked $milestone-day streak badge');
          }
        }
      }
      
      // Reload badges to get updated list
      await _loadBadges();
    } catch (e) {
      debugPrint('Error checking and unlocking badges: $e');
    }
  }
}