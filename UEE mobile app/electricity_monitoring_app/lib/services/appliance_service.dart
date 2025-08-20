import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/appliance_model.dart';

class ApplianceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ApplianceModel> _appliances = [];

  // Getters
  List<ApplianceModel> get appliances => _appliances;

  // Get user appliances from Firestore
  Future<List<ApplianceModel>> fetchAppliances() async {
    try {
      if (_auth.currentUser == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('appliances')
          .orderBy('createdAt', descending: true)
          .get();

      _appliances = snapshot.docs
          .map((doc) => ApplianceModel.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
      return _appliances;
    } catch (e) {
      debugPrint('Error fetching appliances: $e');
      return [];
    }
  }

  // Add new appliance
  Future<ApplianceModel?> addAppliance({
    required String name,
    required double wattage,
    required double dailyUsageHrs,
    required String location,
  }) async {
    try {
      if (_auth.currentUser == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('appliances')
          .add({
            'name': name,
            'wattage': wattage,
            'dailyUsageHrs': dailyUsageHrs,
            'location': location,
            'createdAt': FieldValue.serverTimestamp(),
          });

      final doc = await docRef.get();
      final newAppliance = ApplianceModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      _appliances.insert(0, newAppliance);
      notifyListeners();
      return newAppliance;
    } catch (e) {
      debugPrint('Error adding appliance: $e');
      return null;
    }
  }

  // Update existing appliance
  Future<bool> updateAppliance({
    required String id,
    required String name,
    required double wattage,
    required double dailyUsageHrs,
    required String location,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('appliances')
          .doc(id)
          .update({
            'name': name,
            'wattage': wattage,
            'dailyUsageHrs': dailyUsageHrs,
            'location': location,
          });

      // Update local list
      final index = _appliances.indexWhere((appliance) => appliance.id == id);
      if (index != -1) {
        final updatedAppliance = ApplianceModel(
          id: id,
          name: name,
          wattage: wattage,
          dailyUsageHrs: dailyUsageHrs,
          location: location,
          createdAt: _appliances[index].createdAt,
        );
        _appliances[index] = updatedAppliance;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating appliance: $e');
      return false;
    }
  }

  // Delete appliance
  Future<bool> deleteAppliance(String id) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('appliances')
          .doc(id)
          .delete();

      // Update local list
      _appliances.removeWhere((appliance) => appliance.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting appliance: $e');
      return false;
    }
  }
}
