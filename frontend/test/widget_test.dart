import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:instant_explore/main.dart';

void main() {
  testWidgets('Instant Explore home page test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InstantExploreApp());

    // Verify that the app title is displayed
    expect(find.text('Instant Explore'), findsOneWidget);

    // Verify that the welcome message is displayed
    expect(find.text('Hello, Instant Explore'), findsOneWidget);

    // Verify that the Chinese name is displayed
    expect(find.text('隨性探點'), findsOneWidget);

    // Verify that the explore icon is displayed
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });
}
