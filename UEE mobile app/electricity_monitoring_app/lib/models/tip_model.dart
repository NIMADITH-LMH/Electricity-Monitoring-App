import 'package:cloud_firestore/cloud_firestore.dart';

class TipModel {
  final String id;
  final String title;
  final String description;
  final String createdBy; // "admin" or userId
  final DateTime createdAt;
  final String? category;
  final double? estimatedSavings;

  TipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.category,
    this.estimatedSavings,
  });

  factory TipModel.fromMap(Map<String, dynamic> map, String id) {
    return TipModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      category: map['category'],
      estimatedSavings: map['estimatedSavings']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'category': category,
      'estimatedSavings': estimatedSavings,
    };
  }
}
