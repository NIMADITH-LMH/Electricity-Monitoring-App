import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProfileService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification preferences keys
  static const String _keyUsageAlerts = 'usage_alerts_enabled';
  static const String _keyTipsNotifications = 'tips_notifications_enabled';
  static const String _keyBudgetAlerts = 'budget_alerts_enabled';
  static const String _keyAppUpdates = 'app_updates_enabled';

  // Get user profile data
  Future<UserModel?> getUserProfile() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({required String name}) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Update user email
  Future<bool> updateUserEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      // Re-authenticate the user first
      final credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: password,
      );

      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth
      await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user email: $e');
      return false;
    }
  }

  // Update user password
  Future<bool> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      // Re-authenticate the user first
      final credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );

      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Update password in Firebase Auth
      await _auth.currentUser!.updatePassword(newPassword);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user password: $e');
      return false;
    }
  }

  // Notification Preferences

  // Get usage alerts preference
  Future<bool> getUsageAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUsageAlerts) ?? true;
  }

  // Set usage alerts preference
  Future<bool> setUsageAlertsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.setBool(_keyUsageAlerts, value);
    notifyListeners();
    return result;
  }

  // Get tips notifications preference
  Future<bool> getTipsNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTipsNotifications) ?? true;
  }

  // Set tips notifications preference
  Future<bool> setTipsNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.setBool(_keyTipsNotifications, value);
    notifyListeners();
    return result;
  }

  // Get budget alerts preference
  Future<bool> getBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlerts) ?? true;
  }

  // Set budget alerts preference
  Future<bool> setBudgetAlertsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.setBool(_keyBudgetAlerts, value);
    notifyListeners();
    return result;
  }

  // Get app updates preference
  Future<bool> getAppUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppUpdates) ?? true;
  }

  // Set app updates preference
  Future<bool> setAppUpdatesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.setBool(_keyAppUpdates, value);
    notifyListeners();
    return result;
  }
}
