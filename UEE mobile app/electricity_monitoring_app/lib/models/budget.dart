import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String month; // Format: "2025-08"
  final double maxKwh;
  final double maxCost;
  final DateTime createdAt;
  final String userId;

  Budget({
    required this.id,
    required this.month,
    required this.maxKwh,
    required this.maxCost,
    required this.createdAt,
    required this.userId,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safe timestamp handling
    DateTime createdDateTime;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdDateTime = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdDateTime = DateTime.now();
    }
    
    return Budget(
      id: doc.id,
      month: data['month'] ?? '',
      maxKwh: (data['maxKwh'] ?? 0).toDouble(),
      maxCost: (data['maxCost'] ?? 0).toDouble(),
      createdAt: createdDateTime,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'maxKwh': maxKwh,
      'maxCost': maxCost,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'Budget{id: $id, month: $month, maxKwh: $maxKwh, maxCost: $maxCost}';
  }
}
