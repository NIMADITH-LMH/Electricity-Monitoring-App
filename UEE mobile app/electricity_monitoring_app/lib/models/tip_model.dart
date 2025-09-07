import 'package:cloud_firestore/cloud_firestore.dart';

class TipModel {
  final String id;
  final String title;
  final String description;
  final String createdBy; // "admin" or userId
  final DateTime createdAt;
  final String? category;
  final double? estimatedSavings;
  final Map<String, dynamic> relevanceFactors;
  final String difficulty; // 'easy', 'medium', 'hard'
  final double potentialSavingsKwh;

  TipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.category,
    this.estimatedSavings,
    Map<String, dynamic>? relevanceFactors,
    this.difficulty = 'medium',
    this.potentialSavingsKwh = 0.0,
  }) : relevanceFactors = relevanceFactors ?? {};

  factory TipModel.fromMap(Map<String, dynamic> map, String id) {
    // Safe timestamp handling
    DateTime tipCreatedAt;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      tipCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else {
      tipCreatedAt = DateTime.now();
    }
    
    return TipModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: tipCreatedAt,
      category: map['category'],
      estimatedSavings: map['estimatedSavings']?.toDouble(),
      relevanceFactors: Map<String, dynamic>.from(
        map['relevanceFactors'] ?? {},
      ),
      difficulty: map['difficulty'] ?? 'medium',
      potentialSavingsKwh: map['potentialSavingsKwh']?.toDouble() ?? 0.0,
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
      'relevanceFactors': relevanceFactors,
      'difficulty': difficulty,
      'potentialSavingsKwh': potentialSavingsKwh,
    };
  }
}
