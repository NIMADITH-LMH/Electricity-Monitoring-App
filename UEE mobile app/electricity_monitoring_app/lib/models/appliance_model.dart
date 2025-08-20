import 'package:cloud_firestore/cloud_firestore.dart';

class ApplianceModel {
  final String id;
  final String name;
  final double wattage;
  final double dailyUsageHrs;
  final String location;
  final DateTime createdAt;

  ApplianceModel({
    required this.id,
    required this.name,
    required this.wattage,
    required this.dailyUsageHrs,
    required this.location,
    required this.createdAt,
  });

  // Calculate daily consumption in kWh
  double get dailyConsumption => (wattage * dailyUsageHrs) / 1000;

  // Calculate monthly consumption (approx. 30 days)
  double get monthlyConsumption => dailyConsumption * 30;

  // Calculate annual consumption
  double get annualConsumption => dailyConsumption * 365;

  factory ApplianceModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplianceModel(
      id: id,
      name: map['name'] ?? '',
      wattage: (map['wattage'] ?? 0).toDouble(),
      dailyUsageHrs: (map['dailyUsageHrs'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'wattage': wattage,
      'dailyUsageHrs': dailyUsageHrs,
      'location': location,
      'createdAt': createdAt,
    };
  }
}
