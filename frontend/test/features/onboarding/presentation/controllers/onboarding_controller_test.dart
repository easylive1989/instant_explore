import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/in_memory_onboarding_repository.dart';

void main() {
  group('OnboardingController', () {
    test(
      'given a fresh repository, when the controller loads, '
      'then state flips to hasLoaded with welcomeDone false',
      () async {
        final repo = InMemoryOnboardingRepository();
        final container = _containerWith(repo);

        await _ensureLoaded(container);

        final state = container.read(onboardingControllerProvider);
        expect(state.hasLoaded, isTrue);
        expect(state.welcomeDone, isFalse);
        expect(state.seenTips, isEmpty);
        expect(repo.loadCalls, 1);
      },
    );

    test(
      'given welcome not done, when completeWelcome is called, '
      'then the flag is persisted and reflected in state',
      () async {
        final repo = InMemoryOnboardingRepository();
        final container = _containerWith(repo);
        await _ensureLoaded(container);

        await container
            .read(onboardingControllerProvider.notifier)
            .completeWelcome();

        expect(repo.markWelcomeDoneCalls, 1);
        expect(
          container.read(onboardingControllerProvider).welcomeDone,
          isTrue,
        );
      },
    );

    test(
      'given a tip has not been seen, when markTipSeen is called, '
      'then the tip is recorded in state and storage',
      () async {
        final repo = InMemoryOnboardingRepository();
        final container = _containerWith(repo);
        await _ensureLoaded(container);

        await container
            .read(onboardingControllerProvider.notifier)
            .markTipSeen(OnboardingTip.quickGuide);

        expect(repo.markedTips, [OnboardingTip.quickGuide]);
        expect(
          container.read(onboardingControllerProvider).hasSeen(
            OnboardingTip.quickGuide,
          ),
          isTrue,
        );
      },
    );

    test(
      'given a tip has already been seen, when markTipSeen is called again, '
      'then the repository is not written to twice',
      () async {
        final repo = InMemoryOnboardingRepository();
        final container = _containerWith(repo);
        await _ensureLoaded(container);
        final notifier = container.read(onboardingControllerProvider.notifier);

        await notifier.markTipSeen(OnboardingTip.quickGuide);
        await notifier.markTipSeen(OnboardingTip.quickGuide);

        expect(repo.markedTips, [OnboardingTip.quickGuide]);
      },
    );

    test(
      'given the user has finished onboarding, when resetAll is called, '
      'then state returns to the unseen default but stays hasLoaded',
      () async {
        final repo = InMemoryOnboardingRepository(
          welcomeDone: true,
          seenTips: {OnboardingTip.quickGuide},
        );
        final container = _containerWith(repo);
        await _ensureLoaded(container);

        await container
            .read(onboardingControllerProvider.notifier)
            .resetAll();

        final state = container.read(onboardingControllerProvider);
        expect(state.hasLoaded, isTrue);
        expect(state.welcomeDone, isFalse);
        expect(state.seenTips, isEmpty);
        expect(repo.resetCalls, 1);
      },
    );

    test(
      'given the user has finished tips, when resetTips is called, '
      'then welcomeDone is preserved but tips are cleared',
      () async {
        final repo = InMemoryOnboardingRepository(
          welcomeDone: true,
          seenTips: {OnboardingTip.quickGuide, OnboardingTip.journey},
        );
        final container = _containerWith(repo);
        await _ensureLoaded(container);

        await container
            .read(onboardingControllerProvider.notifier)
            .resetTips();

        final state = container.read(onboardingControllerProvider);
        expect(state.welcomeDone, isTrue);
        expect(state.seenTips, isEmpty);
      },
    );
  });
}

ProviderContainer _containerWith(InMemoryOnboardingRepository repo) {
  final container = ProviderContainer(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _ensureLoaded(ProviderContainer container) async {
  await container
      .read(onboardingControllerProvider.notifier)
      .ensureLoaded();
}
