import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalesync_pro_ecosystem/widgets/stat_card.dart';

void main() {
  testWidgets('ScaleSyncPro StatCard rendering test', (WidgetTester tester) async {
    // Build a StatCard in a testable MaterialApp environment
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            icon: Icons.pets,
            title: 'Total Specimens',
            value: '42',
            change: '+5% this month',
            isPositive: true,
          ),
        ),
      ),
    );

    // Verify that the title, value, and change text are rendered correctly
    expect(find.text('Total Specimens'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('+5% this month'), findsOneWidget);
  });
} 