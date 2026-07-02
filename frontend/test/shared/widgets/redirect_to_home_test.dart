import 'package:context_app/shared/widgets/redirect_to_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('RedirectToHome', () {
    testWidgets(
      'given a URL matching no route, when the router errorBuilder renders '
      'RedirectToHome, then the app lands back on the home route',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          errorBuilder: (context, state) => const RedirectToHome(),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('HOME')),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('HOME'), findsOneWidget);

        // An unmatched path (e.g. a malformed deep link) hits the
        // errorBuilder, which redirects back home.
        router.go('/zh/storybook');
        await tester.pumpAndSettle();

        expect(find.text('HOME'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
