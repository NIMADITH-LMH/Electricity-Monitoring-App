import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_monitoring_app/screens/appliance/appliance_form_screen.dart';
import 'package:electricity_monitoring_app/models/appliance_model.dart';

void main() {
  testWidgets('ApplianceFormScreen displays correctly for new appliance', (
    WidgetTester tester,
  ) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: ApplianceFormScreen()));

    // Check title and sections
    expect(find.text('Add Appliance'), findsOneWidget);
    expect(find.text('Appliance Information'), findsOneWidget);
    expect(find.text('Power Information'), findsOneWidget);

    // Check form fields
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Appliance Name'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Wattage (W)'), findsOneWidget);
    expect(find.text('Daily Usage (hours)'), findsOneWidget);

    // Check buttons
    expect(find.text('Add Appliance'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('ApplianceFormScreen displays correctly for editing appliance', (
    WidgetTester tester,
  ) async {
    // Create test appliance
    final testAppliance = ApplianceModel(
      id: '123',
      name: 'Test Appliance',
      wattage: 100,
      dailyUsageHrs: 5,
      location: 'Test Location',
      createdAt: DateTime.now(),
    );

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(home: ApplianceFormScreen(appliance: testAppliance)),
    );

    // Check title
    expect(find.text('Edit Appliance'), findsOneWidget);

    // Check pre-filled form fields
    expect(find.text('Test Appliance'), findsOneWidget);
    expect(find.text('Test Location'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);

    // Check button
    expect(find.text('Update Appliance'), findsOneWidget);
  });
}
