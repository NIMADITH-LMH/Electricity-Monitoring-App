import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String month; // Format: "2025-08"
  final double maxKwh;
  final double maxCost;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.maxKwh,
    required this.maxCost,
    required this.createdAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      month: map['month'] ?? '',
      maxKwh: (map['maxKwh'] ?? 0).toDouble(),
      maxCost: (map['maxCost'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'maxKwh': maxKwh,
      'maxCost': maxCost,
      'createdAt': createdAt,
      'id': id,
    };
  }

  @override
  String toString() {
    return 'BudgetModel{id: $id, month: $month, maxKwh: $maxKwh, maxCost: $maxCost}';
  }
}
