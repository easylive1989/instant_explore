// Sequence-level tests for the onboarding welcome flow.
//
// The pre-existing onboarding_welcome_screen_test exercises the loaded
// state and the skip-tap-records-call path; this file pins down the
// remaining wires:
//
// - The shared `_finish()` path used by both skip and done buttons
//   actually navigates the router to `/` after completeWelcome.
// - The Try Sample CTA on the final page pushes /player with a
//   non-null narration content (the demo factory wire-up).
// - The resetAll controller method drops welcomeDone.

import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:context_app/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/in_memory_onboarding_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('Onboarding welcome flow', () {
    testWidgets(
      'given the welcome screen is visible, when the user taps Skip, '
      'then welcomeDone is persisted and the router lands on /',
      (tester) async {
        // Skip and Done both call `_finish()` — testing skip exercises
        // the same code path without having to drive the
        // IntroductionScreen carousel through three page transitions,
        // which is brittle in widget tests.
        final repo = InMemoryOnboardingRepository();
        await _pumpOnboardingFlow(tester, repo: repo);

        await tester.tap(find.text('onboarding.skip'));
        await _settle(tester);

        expect(repo.markWelcomeDoneCalls, 1);
        expect(find.text('home-stub'), findsOneWidget);
      },
    );

    testWidgets(
      'given the user reaches the final page, when the user taps Try Sample, '
      'then the player route is pushed with a non-null narration content',
      (tester) async {
        final extras = <Object?>[];
        await _pumpOnboardingFlow(tester, onPlayerPush: extras.add);

        // Drive the carousel by swiping the PageView directly — the
        // `next` arrow tap is unreliable across IntroductionScreen's
        // animation timing in widget tests.
        await _swipeToFinalPage(tester);

        expect(
          find.text('onboarding.try_sample'),
          findsOneWidget,
          reason: 'should be on page 4 with the Try Sample CTA',
        );
        await tester.tap(find.text('onboarding.try_sample'));
        await _settle(tester);

        expect(extras, hasLength(1));
        final extra = extras.single as Map<String, dynamic>;
        expect(extra['narrationContent'], isNotNull);
        expect(extra['autoPlay'], isTrue);
      },
    );

    testWidgets(
      'given welcomeDone has been set, when resetAll runs, '
      'then the repository is reset and the controller drops welcomeDone',
      (tester) async {
        final repo = InMemoryOnboardingRepository(welcomeDone: true);
        await _pumpOnboardingFlow(tester, repo: repo);

        final element = tester.element(find.byType(OnboardingWelcomeScreen));
        final scope = ProviderScope.containerOf(element, listen: false);
        await scope
            .read(onboardingControllerProvider.notifier)
            .resetAll();
        await _settle(tester);

        expect(repo.resetCalls, 1);
        expect(
          scope.read(onboardingControllerProvider).welcomeDone,
          isFalse,
        );
      },
    );
  });
}

Future<void> _pumpOnboardingFlow(
  WidgetTester tester, {
  InMemoryOnboardingRepository? repo,
  void Function(Object? extra)? onPlayerPush,
}) async {
  final resolved = repo ?? InMemoryOnboardingRepository();
  await pumpRouterApp(
    tester,
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _HomeStub()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          onPlayerPush?.call(state.extra);
          return const _PlayerStub();
        },
      ),
    ],
    overrides: [onboardingRepositoryProvider.overrideWithValue(resolved)],
  );
  await tester.pump(const Duration(milliseconds: 50));
}

/// Drives the IntroductionScreen's PageView from page 1 to page 4
/// using horizontal swipes — more reliable than tapping the next arrow
/// because the carousel honours fling gestures synchronously.
Future<void> _swipeToFinalPage(WidgetTester tester) async {
  for (var i = 0; i < 3; i += 1) {
    await tester.fling(
      find.byType(PageView),
      const Offset(-500, 0),
      2000,
    );
    await _settle(tester);
  }
}

/// Replaces pumpAndSettle because the screen's PulsingGlow animation
/// never quiesces. A handful of finite pumps cover the page transition
/// and any post-tap async work without hanging the test.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home-stub')));
}

class _PlayerStub extends StatelessWidget {
  const _PlayerStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('player-stub')));
}
