import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTipModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double? estimatedSavings;
  final String difficulty; // 'easy', 'medium', 'hard'
  final double potentialSavingsKwh;
  final List<String>
  targetUserGroups; // 'all', 'high_usage', 'low_usage', 'medium_usage'
  final Map<String, dynamic> targetCriteria; // Usage patterns, appliances, etc.
  final DateTime createdAt;
  final DateTime? scheduledAt; // When to send this tip
  final bool isScheduled;
  final bool isActive;
  final int priority; // 1-5, where 5 is highest priority
  final List<String> tags; // For better organization
  final String? imageUrl; // Optional image for the tip
  final String? actionUrl; // Optional URL for more information

  AdminTipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.estimatedSavings,
    this.difficulty = 'medium',
    this.potentialSavingsKwh = 0.0,
    this.targetUserGroups = const ['all'],
    this.targetCriteria = const {},
    required this.createdAt,
    this.scheduledAt,
    this.isScheduled = false,
    this.isActive = true,
    this.priority = 3,
    this.tags = const [],
    this.imageUrl,
    this.actionUrl,
  });

  factory AdminTipModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime tipCreatedAt;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      tipCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else {
      tipCreatedAt = DateTime.now();
    }

    DateTime? tipScheduledAt;
    if (map['scheduledAt'] != null && map['scheduledAt'] is Timestamp) {
      tipScheduledAt = (map['scheduledAt'] as Timestamp).toDate();
    }

    return AdminTipModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      estimatedSavings: map['estimatedSavings']?.toDouble(),
      difficulty: map['difficulty'] ?? 'medium',
      potentialSavingsKwh: map['potentialSavingsKwh']?.toDouble() ?? 0.0,
      targetUserGroups: List<String>.from(map['targetUserGroups'] ?? ['all']),
      targetCriteria: Map<String, dynamic>.from(map['targetCriteria'] ?? {}),
      createdAt: tipCreatedAt,
      scheduledAt: tipScheduledAt,
      isScheduled: map['isScheduled'] ?? false,
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 3,
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'estimatedSavings': estimatedSavings,
      'difficulty': difficulty,
      'potentialSavingsKwh': potentialSavingsKwh,
      'targetUserGroups': targetUserGroups,
      'targetCriteria': targetCriteria,
      'createdAt': createdAt,
      'scheduledAt': scheduledAt,
      'isScheduled': isScheduled,
      'isActive': isActive,
      'priority': priority,
      'tags': tags,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'createdBy': 'admin', // Always admin for admin tips
    };
  }

  AdminTipModel copyWith({
    String? title,
    String? description,
    String? category,
    double? estimatedSavings,
    String? difficulty,
    double? potentialSavingsKwh,
    List<String>? targetUserGroups,
    Map<String, dynamic>? targetCriteria,
    DateTime? scheduledAt,
    bool? isScheduled,
    bool? isActive,
    int? priority,
    List<String>? tags,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AdminTipModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedSavings: estimatedSavings ?? this.estimatedSavings,
      difficulty: difficulty ?? this.difficulty,
      potentialSavingsKwh: potentialSavingsKwh ?? this.potentialSavingsKwh,
      targetUserGroups: targetUserGroups ?? this.targetUserGroups,
      targetCriteria: targetCriteria ?? this.targetCriteria,
      createdAt: createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isScheduled: isScheduled ?? this.isScheduled,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}
