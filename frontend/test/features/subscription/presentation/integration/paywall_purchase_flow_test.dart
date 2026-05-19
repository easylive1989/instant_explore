// End-to-end paywall purchase flow. Picks up where
// paywall_enforcement_flow_test leaves off: the existing test stubs
// /subscription as an empty Scaffold and only asserts the route was
// pushed. This file drives the real SubscriptionScreen, completes the
// purchase via FakeSubscriptionService, and verifies the user is then
// unblocked when they return to the original screen.
//
// The wiring mirrors production: usageRepositoryProvider re-reads
// isPremiumProvider, so flipping the subscription status via the
// purchase callback must swap the user from a quota-exhausted free
// repo onto the unlimited repo on the next interaction.

import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_picker_service.dart';
import '../../../../fakes/fake_quick_guide_ai_service.dart';
import '../../../../fakes/fake_rewarded_ad_service.dart';
import '../../../../fakes/fake_subscription_service.dart';
import '../../../../fakes/in_memory_quick_guide_repository.dart';
import '../../../../fakes/in_memory_trip_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
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

  group('Paywall purchase flow', () {
    testWidgets(
      'given an exhausted free user, when the user upgrades from the '
      'paywall and the purchase succeeds, then the next attempt is '
      'unblocked and no paywall is shown',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final subscription = FakeSubscriptionService()
          ..stubGetAvailablePlans(plans: _kAllPlans)
          ..stubPurchase(status: const SubscriptionStatus(isPremium: true));

        await _pumpFlow(tester, picker: picker, subscription: subscription);

        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();
        expect(
          find.text('subscription.upgrade_cta'),
          findsOneWidget,
          reason: 'free user with quota=1/1 must see the paywall sheet',
        );
        expect(picker.pickCount, 0);

        await tester.tap(find.text('subscription.upgrade_cta'));
        await tester.pumpAndSettle();
        expect(find.byType(SubscriptionScreen), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('subscription.subscribe_yearly'),
          100,
        );
        await tester.tap(find.text('subscription.subscribe_yearly'));
        await tester.pumpAndSettle();

        expect(subscription.purchaseCalls, [SubscriptionPeriod.yearly]);
        expect(
          find.byType(SubscriptionScreen),
          findsNothing,
          reason: 'subscription screen should pop after successful purchase',
        );

        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();
        expect(
          find.text('subscription.upgrade_cta'),
          findsNothing,
          reason: 'premium user should not hit the paywall again',
        );
        expect(picker.pickCount, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'given an exhausted free user opens the paywall, when the user '
      'cancels the purchase, then the subscription screen stays open '
      'and no premium is granted',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final subscription = FakeSubscriptionService()
          ..stubGetAvailablePlans(plans: _kAllPlans)
          ..stubPurchase(status: null);

        await _pumpFlow(tester, picker: picker, subscription: subscription);

        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('subscription.upgrade_cta'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('subscription.subscribe_yearly'),
          100,
        );
        await tester.tap(find.text('subscription.subscribe_yearly'));
        await tester.pumpAndSettle();

        expect(subscription.purchaseCalls, [SubscriptionPeriod.yearly]);
        expect(
          find.byType(SubscriptionScreen),
          findsOneWidget,
          reason: 'a cancelled purchase must not pop the screen',
        );
      },
    );
  });
}

Future<void> _pumpFlow(
  WidgetTester tester, {
  required FakeImagePickerService picker,
  required FakeSubscriptionService subscription,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const QuickGuideScreen()),
      GoRoute(
        name: 'subscription',
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (_, __) => const Scaffold(
          key: Key('player-stub'),
          body: SizedBox.shrink(),
        ),
      ),
    ],
    overrides: [
      subscriptionServiceProvider.overrideWithValue(subscription),
      // Mirror the production composition: usage repo is chosen by
      // isPremium. Flipping isPremium after the purchase must swap the
      // user onto an unlimited repo without further test plumbing.
      usageRepositoryProvider.overrideWith((ref) {
        final isPremium = ref.watch(isPremiumProvider);
        if (isPremium) {
          return InMemoryUsageRepository(dailyFreeLimit: 999999);
        }
        return InMemoryUsageRepository(usedToday: 1, dailyFreeLimit: 1);
      }),
      quickGuideRepositoryProvider.overrideWithValue(
        InMemoryQuickGuideRepository(),
      ),
      quickGuideAiServiceProvider.overrideWithValue(FakeQuickGuideAiService()),
      tripRepositoryProvider.overrideWithValue(InMemoryTripRepository()),
      rewardedAdServiceProvider.overrideWithValue(FakeRewardedAdService()),
      imagePickerServiceProvider.overrideWithValue(picker),
    ],
  );
}

Future<void> _tapTakePhoto(WidgetTester tester) async {
  await tester.tap(find.text('quick_guide.take_photo'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
