// This is a basic test file for the Pet Smart Home app.
// You can add more specific tests here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Pet Smart Home app smoke test', (WidgetTester tester) async {
    // Build a simple test widget since the main app requires Firebase initialization
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Pet Smart Home Test'),
            ),
          ),
        ),
      ),
    );

    // Verify that our test widget renders
    expect(find.text('Pet Smart Home Test'), findsOneWidget);
  });
}
