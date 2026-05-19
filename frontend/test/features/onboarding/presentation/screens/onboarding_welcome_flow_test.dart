// Sequence-level tests for the onboarding welcome flow.
//
// The pre-existing onboarding_welcome_screen_test exercises the loaded
// state and the skip path; this file fills in the remaining behaviour
// the user actually goes through: paging to the final card, trying the
// sample narration, finishing the carousel, and the replay-onboarding
// reset path on the controller.

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
      'given the welcome screen is visible, when the user taps Get Started '
      'on the final page, then welcomeDone is persisted and the router '
      'leaves /onboarding',
      (tester) async {
        final repo = InMemoryOnboardingRepository();
        await _pumpOnboardingFlow(tester, repo: repo);

        await _advanceToFinalPage(tester);
        await tester.tap(find.text('onboarding.get_started'));
        await tester.pumpAndSettle();

        expect(repo.markWelcomeDoneCalls, 1);
        expect(find.text('home-stub'), findsOneWidget);
      },
    );

    testWidgets(
      'given the user is on the final page, when the user taps Try Sample, '
      'then the player route is pushed with a non-null narration content',
      (tester) async {
        final extras = <Object?>[];
        await _pumpOnboardingFlow(tester, onPlayerPush: extras.add);

        await _advanceToFinalPage(tester);
        await tester.tap(find.text('onboarding.try_sample'));
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

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

/// Taps the IntroductionScreen "next" arrow three times to reach page 4.
Future<void> _advanceToFinalPage(WidgetTester tester) async {
  for (var i = 0; i < 3; i += 1) {
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
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
