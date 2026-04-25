import 'package:context_app/app/config/legal_urls.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
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
      'given a ready plan, when the screen loads, '
      'then the localized price string is rendered',
      (tester) async {
        final service = _serviceWithPlan();

        await _givenSubscriptionScreen(tester, service: service);

        expect(find.text('NT\$90'), findsOneWidget);
        expect(find.text('subscription.plan_period'), findsOneWidget);
        expect(find.text('subscription.plan_label'), findsOneWidget);
      },
    );

    testWidgets(
      'given the screen is shown, when it loads, '
      'then the benefits and primary actions are visible',
      (tester) async {
        await _givenSubscriptionScreen(tester, service: _serviceWithPlan());

        expect(find.text('subscription.benefit_no_ads'), findsOneWidget);
        expect(find.text('subscription.benefit_unlimited'), findsOneWidget);
        expect(find.text('subscription.benefit_route'), findsOneWidget);
        expect(find.text('subscription.subscribe'), findsOneWidget);
        expect(find.text('subscription.restore'), findsOneWidget);
      },
    );

    testWidgets(
      'given a successful purchase, when the user subscribes, '
      'then the screen dismisses with a positive result',
      (tester) async {
        final service = _serviceWithPlan()
          ..stubPurchase(
            status: const SubscriptionStatus(isPremium: true),
          );

        await _givenSubscriptionScreenOnRoute(tester, service);
        await _whenUserTapsSubscribe(tester);

        expect(find.byType(SubscriptionScreen), findsNothing);
      },
    );

    testWidgets(
      'given no prior purchase, when the user taps restore, '
      'then the no-purchases snackbar is shown',
      (tester) async {
        final service = _serviceWithPlan()
          ..stubRestore(status: SubscriptionStatus.free);

        await _givenSubscriptionScreen(tester, service: service);
        await _whenUserTapsRestore(tester);

        expect(find.text('subscription.no_purchases_found'), findsOneWidget);
      },
    );

    testWidgets(
      'given the terms link is tapped, when the user interacts, '
      'then the injected launcher is called with the terms URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenSubscriptionScreen(
          tester,
          service: _serviceWithPlan(),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.scrollUntilVisible(
          find.text('subscription.terms'),
          100,
        );
        await tester.tap(find.text('subscription.terms'));
        await tester.pumpAndSettle();

        expect(launched, [Uri.parse(LegalUrls.termsOfUse)]);
      },
    );

    testWidgets(
      'given the privacy link is tapped, when the user interacts, '
      'then the injected launcher is called with the privacy URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenSubscriptionScreen(
          tester,
          service: _serviceWithPlan(),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.scrollUntilVisible(
          find.text('subscription.privacy'),
          100,
        );
        await tester.tap(find.text('subscription.privacy'));
        await tester.pumpAndSettle();

        expect(launched, [Uri.parse(LegalUrls.privacyPolicy)]);
      },
    );

    testWidgets(
      'given the plan fails to load, when retry is tapped, '
      'then getCurrentPlan is called again',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubGetCurrentPlan(error: Exception('network'));

        await _givenSubscriptionScreen(tester, service: service);

        expect(find.byKey(const ValueKey('planCard.retry')), findsOneWidget);

        service.stubGetCurrentPlan(
          plan: const SubscriptionPlan(
            priceString: 'NT\$90',
            period: SubscriptionPeriod.monthly,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pumpAndSettle();

        expect(find.text('NT\$90'), findsOneWidget);
      },
    );
  });
}

FakeSubscriptionService _serviceWithPlan() {
  return FakeSubscriptionService()
    ..stubGetCurrentPlan(
      plan: const SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
      ),
    );
}

Future<void> _givenSubscriptionScreen(
  WidgetTester tester, {
  required FakeSubscriptionService service,
  Future<bool> Function(Uri)? launcher,
}) async {
  await pumpScreen(
    tester,
    child: SubscriptionScreen(launchUrl: launcher),
    overrides: [subscriptionServiceProvider.overrideWithValue(service)],
  );
  await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
}

Future<void> _whenUserTapsSubscribe(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('subscription.subscribe'),
    100,
  );
  await tester.tap(find.text('subscription.subscribe'));
  await tester.pumpAndSettle();
}

Future<void> _whenUserTapsRestore(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('subscription.restore'),
    100,
  );
  await tester.tap(find.text('subscription.restore'));
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
