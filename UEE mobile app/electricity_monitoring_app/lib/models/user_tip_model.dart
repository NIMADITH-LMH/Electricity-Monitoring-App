import 'package:cloud_firestore/cloud_firestore.dart';

class UserTipModel {
  final String id;
  final String userId;
  final String tipId;
  final bool shown;
  final bool dismissed;
  final bool implemented;
  final double? resultEffectiveness; // User rating of how effective the tip was
  final DateTime lastUpdatedAt;

  UserTipModel({
    required this.id,
    required this.userId,
    required this.tipId,
    this.shown = false,
    this.dismissed = false,
    this.implemented = false,
    this.resultEffectiveness,
    DateTime? lastUpdatedAt,
  }) : this.lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  factory UserTipModel.fromMap(Map<String, dynamic> map, String id) {
    return UserTipModel(
      id: id,
      userId: map['userId'] ?? '',
      tipId: map['tipId'] ?? '',
      shown: map['shown'] ?? false,
      dismissed: map['dismissed'] ?? false,
      implemented: map['implemented'] ?? false,
      resultEffectiveness: map['resultEffectiveness']?.toDouble(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tipId': tipId,
      'shown': shown,
      'dismissed': dismissed,
      'implemented': implemented,
      'resultEffectiveness': resultEffectiveness,
      'lastUpdatedAt': lastUpdatedAt,
    };
  }

  UserTipModel copyWith({
    String? id,
    String? userId,
    String? tipId,
    bool? shown,
    bool? dismissed,
    bool? implemented,
    double? resultEffectiveness,
    DateTime? lastUpdatedAt,
  }) {
    return UserTipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tipId: tipId ?? this.tipId,
      shown: shown ?? this.shown,
      dismissed: dismissed ?? this.dismissed,
      implemented: implemented ?? this.implemented,
      resultEffectiveness: resultEffectiveness ?? this.resultEffectiveness,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
    );
  }
}
