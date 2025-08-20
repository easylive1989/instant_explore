import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_explore/screens/login_screen.dart';

void main() {
  group('Login Screen Test', () {
    testWidgets('should display login screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Instant Explore'), findsOneWidget);
      expect(find.text('隨性探點'), findsOneWidget);
    });
  });
}
