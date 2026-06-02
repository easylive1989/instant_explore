import 'package:context_app/app/config/legal_urls.dart';
import 'package:context_app/features/auth/domain/models/auth_user.dart';
import 'package:context_app/features/auth/providers.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_subscription_service.dart';
import '../../../../helpers/pump_app.dart';

const _kWeekly = SubscriptionPlan(
  priceString: 'NT\$30',
  period: SubscriptionPeriod.weekly,
  packageIdentifier: r'$rc_weekly',
);
const _kMonthly = SubscriptionPlan(
  priceString: 'NT\$90',
  period: SubscriptionPeriod.monthly,
  packageIdentifier: r'$rc_monthly',
);
const _kYearly = SubscriptionPlan(
  priceString: 'NT\$900',
  period: SubscriptionPeriod.yearly,
  packageIdentifier: r'$rc_annual',
  isBestValue: true,
);
const _kAllPlans = [_kWeekly, _kMonthly, _kYearly];

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionScreen', () {
    testWidgets(
      'given plans loaded, when the screen first shows, '
      'then yearly is selected and Best value badge is visible',
      (tester) async {
        await _givenScreen(tester, _serviceWith(_kAllPlans));

        expect(find.text('subscription.plan_yearly'), findsOneWidget);
        expect(find.text('subscription.badge_best_value'), findsOneWidget);
        expect(find.text('subscription.subscribe_yearly'), findsOneWidget);
      },
    );

    testWidgets(
      'given yearly selected, when the user taps the weekly card, '
      'then subscribe button label changes to Subscribe Weekly',
      (tester) async {
        await _givenScreen(tester, _serviceWith(_kAllPlans));

        await tester.tap(find.text('subscription.plan_weekly'));
        await tester.pumpAndSettle();

        expect(find.text('subscription.subscribe_weekly'), findsOneWidget);
        expect(find.text('subscription.subscribe_yearly'), findsNothing);
      },
    );

    testWidgets(
      'given the user taps subscribe, when purchase succeeds, '
      'then the service is called with the selected period and the screen pops',
      (tester) async {
        final service = _serviceWith(_kAllPlans)
          ..stubPurchase(status: const SubscriptionStatus(isPremium: true));

        await _givenScreenOnRoute(tester, service);

        await tester.scrollUntilVisible(
          find.text('subscription.subscribe_yearly'),
          100,
        );
        await tester.tap(find.text('subscription.subscribe_yearly'));
        await tester.pumpAndSettle();

        expect(service.purchaseCalls, [SubscriptionPeriod.yearly]);
        expect(find.byType(SubscriptionScreen), findsNothing);
      },
    );

    testWidgets(
      'given an anonymous user taps subscribe, '
      'then a sign-in prompt is shown and no purchase is made',
      (tester) async {
        final service = _serviceWith(_kAllPlans)
          ..stubPurchase(status: const SubscriptionStatus(isPremium: true));

        await _givenScreenOnRoute(tester, service, user: _anonUser);

        await tester.scrollUntilVisible(
          find.text('subscription.subscribe_yearly'),
          100,
        );
        await tester.tap(find.text('subscription.subscribe_yearly'));
        await tester.pumpAndSettle();

        expect(find.text('subscription.login_required'), findsOneWidget);
        expect(service.purchaseCalls, isEmpty);
      },
    );

    testWidgets(
      'given the service returns only weekly + monthly, when the screen loads, '
      'then weekly is selected by default (yearly missing) and only two cards render',
      (tester) async {
        await _givenScreen(tester, _serviceWith(const [_kWeekly, _kMonthly]));

        expect(find.text('subscription.plan_weekly'), findsOneWidget);
        expect(find.text('subscription.plan_monthly'), findsOneWidget);
        expect(find.text('subscription.plan_yearly'), findsNothing);
        expect(find.text('subscription.subscribe_weekly'), findsOneWidget);
      },
    );

    testWidgets(
      'given the service throws on load, when retry is tapped, '
      'then getAvailablePlans is called again and plans render',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubGetAvailablePlans(error: Exception('network'));

        await _givenScreen(tester, service);

        expect(find.byKey(const ValueKey('planCard.retry')), findsOneWidget);

        service.stubGetAvailablePlans(plans: _kAllPlans);
        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pumpAndSettle();

        expect(find.text('NT\$900'), findsOneWidget);
      },
    );

    testWidgets(
      'given no prior purchase, when the user taps restore, '
      'then the no-purchases snackbar is shown',
      (tester) async {
        final service = _serviceWith(_kAllPlans)
          ..stubRestore(status: SubscriptionStatus.free);

        await _givenScreen(tester, service);

        await tester.scrollUntilVisible(
          find.text('subscription.restore'),
          100,
        );
        await tester.tap(find.text('subscription.restore'));
        await tester.pumpAndSettle();

        expect(find.text('subscription.no_purchases_found'), findsOneWidget);
      },
    );

    testWidgets(
      'given the terms link is tapped, when the user interacts, '
      'then the injected launcher is called with the terms URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenScreen(
          tester,
          _serviceWith(_kAllPlans),
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
        await _givenScreen(
          tester,
          _serviceWith(_kAllPlans),
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
  });
}

/// A signed-in permanent account (the default for paywall tests — the user
/// has already passed the sign-in gate).
const _permanentUser = AuthUser(id: 'perm-user', isAnonymous: false);

/// An anonymous user, who must sign in before purchasing.
const _anonUser = AuthUser(id: 'anon-user', isAnonymous: true);

FakeSubscriptionService _serviceWith(List<SubscriptionPlan> plans) {
  return FakeSubscriptionService()..stubGetAvailablePlans(plans: plans);
}

Future<void> _givenScreen(
  WidgetTester tester,
  FakeSubscriptionService service, {
  Future<bool> Function(Uri)? launcher,
  AuthUser? user = _permanentUser,
}) async {
  await pumpScreen(
    tester,
    child: SubscriptionScreen(launchUrl: launcher),
    overrides: [
      subscriptionServiceProvider.overrideWithValue(service),
      currentUserProvider.overrideWithValue(user),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _givenScreenOnRoute(
  WidgetTester tester,
  FakeSubscriptionService service, {
  AuthUser? user = _permanentUser,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Host()),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
    ],
    overrides: [
      subscriptionServiceProvider.overrideWithValue(service),
      currentUserProvider.overrideWithValue(user),
    ],
  );
  final context = tester.element(find.byType(_Host));
  GoRouter.of(context).push('/subscription');
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
