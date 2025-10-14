import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  // Getters
  User? get currentUser => _auth.currentUser;
  UserModel? get userModel => _user;
  bool get isAuthenticated => _auth.currentUser != null;

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        _user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        return _user;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Get user document from Firestore
  Future<DocumentSnapshot?> getUserDoc() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user document: $e');
      return null;
    }
  }

  // Update a specific field in the user document
  Future<bool> updateUserField(String fieldName, dynamic value) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        fieldName: value,
      });

      // Update local user model if we have one
      if (_user != null) {
        await getCurrentUserData();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user field: $e');
      return false;
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await getCurrentUserData();
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      rethrow;
    }
  }

  // Sign in with email and password - WITH BETTER ERROR HANDLING
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await getCurrentUserData();
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      
      // Provide more specific error messages to the UI
      if (e.toString().contains('network-request-failed')) {
        // Network error - likely temporary
        throw Exception('Network connection failed. Please check your internet connection and try again.');
      } else if (e.toString().contains('invalid-credential')) {
        // Wrong email or password
        throw Exception('Invalid email or password. Please check your credentials and try again.');
      } else if (e.toString().contains('user-not-found')) {
        // User doesn't exist
        throw Exception('No account found with this email address.');
      } else if (e.toString().contains('wrong-password')) {
        // Wrong password
        throw Exception('Incorrect password. Please try again.');
      } else {
        // Generic error
        throw Exception('Sign in failed. Please try again later.');
      }
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }
}
