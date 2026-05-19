// Integration tests that verify the subscription paywall is actually
// enforced when a free user exhausts their daily quota — i.e. that the
// quota check, the watch-ad bonus path, and the "subscribe" handoff to
// the subscription route are all wired together correctly.
//
// These cross-feature tests sit under the subscription/ feature folder
// because subscription enforcement is the contract under test even
// though the entry point is the Quick Guide screen.

import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_picker_service.dart';
import '../../../../fakes/fake_quick_guide_ai_service.dart';
import '../../../../fakes/fake_rewarded_ad_service.dart';
import '../../../../fakes/in_memory_quick_guide_repository.dart';
import '../../../../fakes/in_memory_trip_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('Paywall enforcement flow', () {
    testWidgets(
      'given an exhausted free user, when the user taps take photo, '
      'then the picker is blocked and the watch-ad sheet is shown',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final usage = InMemoryUsageRepository(usedToday: 1, dailyFreeLimit: 1);

        await _pumpQuickGuide(tester, picker: picker, usage: usage);
        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();

        expect(picker.pickCount, 0, reason: 'picker must stay blocked');
        expect(find.text('ads.quota_exceeded_title'), findsOneWidget);
        expect(find.text('ads.watch_video'), findsOneWidget);
        expect(find.text('subscription.upgrade_cta'), findsOneWidget);
      },
    );

    testWidgets(
      'given the user watches the rewarded ad, '
      'when the ad completes successfully, '
      'then a bonus is granted and the daily quota becomes usable again',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        final usage = InMemoryUsageRepository(usedToday: 1, dailyFreeLimit: 1);
        final ads = FakeRewardedAdService();
        final pushedPlayer = <Object?>[];

        // After the bonus the retry actually drives the picker -> AI ->
        // success path which pushes /player; we need a router with that
        // route registered so the push does not crash on a missing
        // GoRouter ancestor.
        await _pumpQuickGuideWithRetryRouter(
          tester,
          picker: picker,
          usage: usage,
          ads: ads,
          onPlayerPush: pushedPlayer.add,
        );
        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ads.watch_video'));
        await tester.pumpAndSettle();

        expect(ads.showCount, 1, reason: 'rewarded ad must actually show');

        final restored = await usage.getUsageStatus();
        expect(
          restored.canUseNarration,
          isTrue,
          reason: 'bonus from ad should re-open the quota',
        );

        // Now retry the picker; the bonus should let the picker through.
        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();
        expect(picker.pickCount, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'given the user chooses subscribe instead of watching an ad, '
      'when the upgrade button is tapped, '
      'then the app navigates to the subscription route',
      (tester) async {
        final pushedRoutes = <String>[];

        await _pumpQuickGuideWithRouter(
          tester,
          usage: InMemoryUsageRepository(usedToday: 1, dailyFreeLimit: 1),
          onSubscriptionPushed: () => pushedRoutes.add('/subscription'),
        );
        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('subscription.upgrade_cta'));
        await tester.pumpAndSettle();

        expect(pushedRoutes, ['/subscription']);
      },
    );

    testWidgets(
      'given a premium user with effectively unlimited quota, '
      'when the user picks an image, '
      'then no paywall is shown and the picker is invoked',
      (tester) async {
        final picker = FakeImagePickerService.withImage();
        // Premium users get unlimited via UnlimitedUsageRepository in prod;
        // we model "effectively unlimited" by a very high free limit so the
        // free-user path is exercised without ever tripping the paywall.
        final usage = InMemoryUsageRepository(
          usedToday: 999,
          dailyFreeLimit: 10000,
        );

        // Picking succeeds → AI returns text → controller goes to success
        // → screen pushes /player. Need a router with that route to
        // catch the navigation instead of crashing.
        await _pumpQuickGuideWithRetryRouter(
          tester,
          picker: picker,
          usage: usage,
          onPlayerPush: (_) {},
        );
        await _tapTakePhoto(tester);
        await tester.pumpAndSettle();

        expect(find.text('ads.quota_exceeded_title'), findsNothing);
        expect(picker.pickCount, 1);
      },
    );
  });
}

Future<void> _pumpQuickGuide(
  WidgetTester tester, {
  required FakeImagePickerService picker,
  required InMemoryUsageRepository usage,
  FakeRewardedAdService? ads,
}) async {
  await pumpScreen(
    tester,
    child: const QuickGuideScreen(),
    overrides: _overrides(picker: picker, usage: usage, ads: ads),
  );
}

/// Like [_pumpQuickGuide] but inside a GoRouter that registers `/player`,
/// so a successful pick → analyse → push does not crash on a missing
/// GoRouter ancestor.
Future<void> _pumpQuickGuideWithRetryRouter(
  WidgetTester tester, {
  required FakeImagePickerService picker,
  required InMemoryUsageRepository usage,
  FakeRewardedAdService? ads,
  required void Function(Object? extra) onPlayerPush,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const QuickGuideScreen()),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          onPlayerPush(state.extra);
          return const Scaffold(
            key: Key('player-stub'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: _overrides(picker: picker, usage: usage, ads: ads),
  );
}

Future<void> _pumpQuickGuideWithRouter(
  WidgetTester tester, {
  required InMemoryUsageRepository usage,
  required VoidCallback onSubscriptionPushed,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const QuickGuideScreen(),
      ),
      GoRoute(
        name: 'subscription',
        path: '/subscription',
        builder: (_, __) {
          onSubscriptionPushed();
          return const Scaffold(
            key: Key('subscription-stub'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: _overrides(
      picker: FakeImagePickerService.withImage(),
      usage: usage,
    ),
  );
}

List<Override> _overrides({
  required FakeImagePickerService picker,
  required InMemoryUsageRepository usage,
  FakeRewardedAdService? ads,
}) {
  return [
    quickGuideRepositoryProvider.overrideWithValue(
      InMemoryQuickGuideRepository(),
    ),
    quickGuideAiServiceProvider.overrideWithValue(FakeQuickGuideAiService()),
    tripRepositoryProvider.overrideWithValue(InMemoryTripRepository()),
    usageRepositoryProvider.overrideWithValue(usage),
    rewardedAdServiceProvider.overrideWithValue(ads ?? FakeRewardedAdService()),
    imagePickerServiceProvider.overrideWithValue(picker),
  ];
}

Future<void> _tapTakePhoto(WidgetTester tester) async {
  await tester.tap(find.text('quick_guide.take_photo'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
