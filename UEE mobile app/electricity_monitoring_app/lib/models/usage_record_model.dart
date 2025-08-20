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
    return UsageRecordModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      totalKwh: (map['totalKwh'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
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
