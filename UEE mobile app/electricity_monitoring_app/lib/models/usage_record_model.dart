import 'package:cloud_firestore/cloud_firestore.dart';

class UsageRecordModel {
  final String id;
  final DateTime date;
  final double totalKwh;
  final double totalCost;
  final DateTime createdAt;

  UsageRecordModel({
    required this.id,
    required this.date,
    required this.totalKwh,
    required this.totalCost,
    required this.createdAt,
  });

  factory UsageRecordModel.fromMap(Map<String, dynamic> map, String id) {
    // Safe date timestamp handling
    DateTime recordDate;
    if (map['date'] != null && map['date'] is Timestamp) {
      recordDate = (map['date'] as Timestamp).toDate();
    } else {
      recordDate = DateTime.now();
    }
    
    // Safe createdAt timestamp handling
    DateTime recordCreatedAt;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      recordCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else {
      recordCreatedAt = DateTime.now();
    }
    
    return UsageRecordModel(
      id: id,
      date: recordDate,
      totalKwh: (map['totalKwh'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      createdAt: recordCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalKwh': totalKwh,
      'totalCost': totalCost,
      'createdAt': createdAt,
    };
  }
}
