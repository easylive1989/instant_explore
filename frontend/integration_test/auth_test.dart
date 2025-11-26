import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:travel_diary/main.dart' as app;

void main() {
  patrolTest('Authentication flow - Login', ($) async {
    // Launch the app with test configuration

    await $.pumpWidgetAndSettle(await app.init());

    // Wait for initial loading
    await $.pumpAndSettle(duration: const Duration(seconds: 2));
    await $.pumpAndSettle(duration: const Duration(seconds: 2));
    await $.pumpAndSettle(duration: const Duration(seconds: 2));

    // Tap Google Sign In button
    await $('Sign in with Google').tap();

    // Wait for navigation to complete
    await $.pumpAndSettle(duration: const Duration(seconds: 1));

    expect(find.text('登入成功！'), findsOneWidget);
  });
}
