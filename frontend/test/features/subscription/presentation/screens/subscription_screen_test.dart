import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_subscription_service.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionScreen', () {
    testWidgets(
      'given the paywall is displayed, when the screen loads, '
      'then the benefits and primary actions are visible',
      (tester) async {
        await _givenSubscriptionScreen(tester);

        _thenBenefitsAreVisible();
        _thenPrimaryActionsAreVisible();
      },
    );

    testWidgets(
      'given a successful purchase, when the user subscribes, '
      'then the screen dismisses with a positive result',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubPurchase(
            status: const SubscriptionStatus(isPremium: true),
          );

        await _givenSubscriptionScreenOnRoute(tester, service);
        await _whenUserTapsSubscribe(tester);

        _thenSubscriptionScreenIsDismissed();
      },
    );

    testWidgets(
      'given no prior purchase, when the user taps restore, '
      'then the no-purchases snackbar is shown',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubRestore(status: SubscriptionStatus.free);

        await _givenSubscriptionScreen(tester, service: service);
        await _whenUserTapsRestore(tester);

        _thenNoPurchasesSnackbarIsShown();
      },
    );

    testWidgets(
      'given a premium restore result, when the user taps restore, '
      'then the screen dismisses with a positive result',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubRestore(
            status: const SubscriptionStatus(isPremium: true),
          );

        await _givenSubscriptionScreenOnRoute(tester, service);
        await _whenUserTapsRestore(tester);

        _thenSubscriptionScreenIsDismissed();
      },
    );
  });
}

Future<void> _givenSubscriptionScreen(
  WidgetTester tester, {
  FakeSubscriptionService? service,
}) async {
  final resolved = service ?? FakeSubscriptionService();
  await pumpScreen(
    tester,
    child: const SubscriptionScreen(),
    overrides: [
      subscriptionServiceProvider.overrideWithValue(resolved),
    ],
  );
}

Future<void> _givenSubscriptionScreenOnRoute(
  WidgetTester tester,
  FakeSubscriptionService service,
) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Host()),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
    ],
    overrides: [subscriptionServiceProvider.overrideWithValue(service)],
  );
  final context = tester.element(find.byType(_Host));
  GoRouter.of(context).push('/subscription');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _whenUserTapsSubscribe(WidgetTester tester) async {
  await tester.tap(find.text('subscription.subscribe'));
  await tester.pumpAndSettle();
}

Future<void> _whenUserTapsRestore(WidgetTester tester) async {
  await tester.tap(find.text('subscription.restore'));
  await tester.pumpAndSettle();
}

void _thenBenefitsAreVisible() {
  expect(find.text('subscription.benefit_no_ads'), findsOneWidget);
  expect(find.text('subscription.benefit_unlimited'), findsOneWidget);
  expect(find.text('subscription.benefit_route'), findsOneWidget);
}

void _thenPrimaryActionsAreVisible() {
  expect(find.text('subscription.subscribe'), findsOneWidget);
  expect(find.text('subscription.restore'), findsOneWidget);
}

void _thenSubscriptionScreenIsDismissed() {
  expect(find.byType(SubscriptionScreen), findsNothing);
}

void _thenNoPurchasesSnackbarIsShown() {
  expect(find.text('subscription.no_purchases_found'), findsOneWidget);
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
