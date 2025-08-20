import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/usage_record_model.dart';

class UsageRecordService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UsageRecordModel> _usageRecords = [];

  // Getters
  List<UsageRecordModel> get usageRecords => _usageRecords;

  // Get user usage records from Firestore
  Future<List<UsageRecordModel>> fetchUsageRecords() async {
    try {
      if (_auth.currentUser == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('usageRecords')
          .orderBy('date', descending: true)
          .get();

      _usageRecords = snapshot.docs
          .map((doc) => UsageRecordModel.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
      return _usageRecords;
    } catch (e) {
      debugPrint('Error fetching usage records: $e');
      return [];
    }
  }

  // Add new usage record
  Future<UsageRecordModel?> addUsageRecord({
    required DateTime date,
    required double totalKwh,
    required double totalCost,
  }) async {
    try {
      if (_auth.currentUser == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('usageRecords')
          .add({
            'date': Timestamp.fromDate(date),
            'totalKwh': totalKwh,
            'totalCost': totalCost,
            'createdAt': FieldValue.serverTimestamp(),
          });

      final doc = await docRef.get();
      final newUsageRecord = UsageRecordModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      _usageRecords.insert(0, newUsageRecord);
      notifyListeners();
      return newUsageRecord;
    } catch (e) {
      debugPrint('Error adding usage record: $e');
      return null;
    }
  }

  // Update existing usage record
  Future<bool> updateUsageRecord({
    required String id,
    required DateTime date,
    required double totalKwh,
    required double totalCost,
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('usageRecords')
          .doc(id)
          .update({
            'date': Timestamp.fromDate(date),
            'totalKwh': totalKwh,
            'totalCost': totalCost,
          });

      // Update local list
      final index = _usageRecords.indexWhere((record) => record.id == id);
      if (index != -1) {
        final updatedRecord = UsageRecordModel(
          id: id,
          date: date,
          totalKwh: totalKwh,
          totalCost: totalCost,
          createdAt: _usageRecords[index].createdAt,
        );
        _usageRecords[index] = updatedRecord;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating usage record: $e');
      return false;
    }
  }

  // Delete usage record
  Future<bool> deleteUsageRecord(String id) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('usageRecords')
          .doc(id)
          .delete();

      // Update local list
      _usageRecords.removeWhere((record) => record.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting usage record: $e');
      return false;
    }
  }

  // Get usage records for a specific month
  List<UsageRecordModel> getRecordsForMonth(int year, int month) {
    return _usageRecords.where((record) {
      return record.date.year == year && record.date.month == month;
    }).toList();
  }

  // Calculate total kWh for a specific month
  double getTotalKwhForMonth(int year, int month) {
    final records = getRecordsForMonth(year, month);
    return records.fold(0, (total, record) => total + record.totalKwh);
  }

  // Calculate total cost for a specific month
  double getTotalCostForMonth(int year, int month) {
    final records = getRecordsForMonth(year, month);
    return records.fold(0, (total, record) => total + record.totalCost);
  }
}
