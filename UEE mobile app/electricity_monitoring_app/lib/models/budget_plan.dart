import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetPlan {
  final String id;
  final String name; // "Plan 1", "Plan 2", "Plan 3"
  final double maxKwh;
  final double maxCost;
  final String description;
  final List<String> recommendations;
  final DateTime createdAt;

  BudgetPlan({
    required this.id,
    required this.name,
    required this.maxKwh,
    required this.maxCost,
    required this.description,
    required this.recommendations,
    required this.createdAt,
  });

  // Create from Firestore document
  factory BudgetPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle recommendations list
    List<String> recs = [];
    if (data['recommendations'] != null) {
      recs = List<String>.from(data['recommendations']);
    }
    
    // Safe timestamp handling
    DateTime createdDateTime;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdDateTime = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdDateTime = DateTime.now();
    }
    
    return BudgetPlan(
      id: doc.id,
      name: data['name'] ?? '',
      maxKwh: (data['maxKwh'] ?? 0).toDouble(),
      maxCost: (data['maxCost'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      recommendations: recs,
      createdAt: createdDateTime,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'maxKwh': maxKwh,
      'maxCost': maxCost,
      'description': description,
      'recommendations': recommendations,
      'createdAt': createdAt,
    };
  }

  // Create a copy with modified fields
  BudgetPlan copyWith({
    String? name,
    double? maxKwh,
    double? maxCost,
    String? description,
    List<String>? recommendations,
  }) {
    return BudgetPlan(
      id: this.id,
      name: name ?? this.name,
      maxKwh: maxKwh ?? this.maxKwh,
      maxCost: maxCost ?? this.maxCost,
      description: description ?? this.description,
      recommendations: recommendations ?? this.recommendations,
      createdAt: this.createdAt,
    );
  }

  // Predefined budget plans
  static BudgetPlan createPlan1() {
    return BudgetPlan(
      id: 'plan1',
      name: 'Economy Plan',
      maxKwh: 100,
      maxCost: 300,
      description: 'Basic plan for minimal electricity usage.',
      recommendations: [
        'Use natural lighting during daytime',
        'Turn off electronics when not in use',
        'Use energy-efficient LED bulbs'
      ],
      createdAt: DateTime.now(),
    );
  }

  static BudgetPlan createPlan2() {
    return BudgetPlan(
      id: 'plan2',
      name: 'Standard Plan',
      maxKwh: 200,
      maxCost: 500,
      description: 'Standard plan for average households.',
      recommendations: [
        'Use energy-efficient appliances',
        'Set AC/heater to optimal temperature',
        'Run washing machines with full loads'
      ],
      createdAt: DateTime.now(),
    );
  }

  static BudgetPlan createPlan3() {
    return BudgetPlan(
      id: 'plan3',
      name: 'Premium Plan',
      maxKwh: 350,
      maxCost: 800,
      description: 'Higher limit plan for larger households.',
      recommendations: [
        'Consider installing solar panels',
        'Use smart power strips for electronics',
        'Invest in energy-efficient major appliances'
      ],
      createdAt: DateTime.now(),
    );
  }
}
