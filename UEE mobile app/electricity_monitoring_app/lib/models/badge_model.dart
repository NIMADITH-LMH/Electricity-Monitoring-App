import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String type; // 'streak', 'savings', etc.
  
  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    this.unlockedAt,
    required this.type,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> data, String id) {
    return BadgeModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? 'assets/images/badges/default_badge.png',
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null ? 
        (data['unlockedAt'] is Timestamp ? 
          (data['unlockedAt'] as Timestamp).toDate() : 
          DateTime.parse(data['unlockedAt'].toString())) : 
        null,
      type: data['type'] ?? 'streak',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt,
      'type': type,
    };
  }
}