import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String month; // Format: "2025-08"
  final double maxKwh;
  final double maxCost;
  final DateTime createdAt;
  final String? name;
  final String? description;
  final List<String>? recommendations;

  BudgetModel({
    required this.id,
    required this.month,
    required this.maxKwh,
    required this.maxCost,
    required this.createdAt,
    this.name,
    this.description,
    this.recommendations,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    // Safe timestamp handling
    DateTime createdDateTime;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      createdDateTime = (map['createdAt'] as Timestamp).toDate();
    } else {
      createdDateTime = DateTime.now();
    }
    
    // Handle recommendations array
    List<String>? recommendations;
    if (map['recommendations'] != null && map['recommendations'] is List) {
      recommendations = List<String>.from(
        (map['recommendations'] as List).map((item) => item.toString())
      );
    }
    
    return BudgetModel(
      id: id,
      month: map['month'] ?? '',
      maxKwh: (map['maxKwh'] ?? 0).toDouble(),
      maxCost: (map['maxCost'] ?? 0).toDouble(),
      createdAt: createdDateTime,
      name: map['name'],
      description: map['description'],
      recommendations: recommendations,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'month': month,
      'maxKwh': maxKwh,
      'maxCost': maxCost,
      'createdAt': createdAt,
    };
    
    // Add optional fields if they exist
    if (name != null) map['name'] = name!;
    if (description != null) map['description'] = description!;
    if (recommendations != null) map['recommendations'] = recommendations!;
    
    return map;
  }

  @override
  String toString() {
    return 'BudgetModel{id: $id, month: $month, maxKwh: $maxKwh, maxCost: $maxCost, name: $name}';
  }
}
