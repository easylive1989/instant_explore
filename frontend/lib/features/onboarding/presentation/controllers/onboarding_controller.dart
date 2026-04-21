import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:context_app/features/onboarding/domain/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the persisted onboarding state to the UI and mediates writes
/// back to [OnboardingRepository].
///
/// Reads are optimistic: the controller starts from [OnboardingState.initial]
/// and asynchronously replaces it once storage resolves. Callers that
/// redirect based on `welcomeDone` must therefore tolerate a single frame
/// of the initial value.
class OnboardingController extends Notifier<OnboardingState> {
  late final OnboardingRepository _repository;

  @override
  OnboardingState build() {
    _repository = ref.read(onboardingRepositoryProvider);
    // Defer the load until after build() returns. Otherwise the first
    // `state` read inside _loadFromRepository would fire before the
    // Notifier has installed its initial state.
    Future.microtask(_loadFromRepository);
    return const OnboardingState.initial();
  }

  Future<void> _loadFromRepository() async {
    if (state.hasLoaded) return;
    final loaded = await _repository.load();
    // Re-check: a user-initiated write (e.g. completeWelcome) could
    // have landed between our initial check and the async load.
    if (state.hasLoaded) return;
    state = loaded.copyWith(hasLoaded: true);
  }

  Future<void> completeWelcome() async {
    state = state.copyWith(hasLoaded: true, welcomeDone: true);
    await _repository.markWelcomeDone();
  }

  Future<void> markTipSeen(OnboardingTip tip) async {
    if (state.hasSeen(tip)) return;
    state = state.copyWith(seenTips: {...state.seenTips, tip});
    await _repository.markTipSeen(tip);
  }

  /// Resets every flag so the user sees the welcome carousel and tips
  /// again. Used by "replay onboarding" in Settings.
  Future<void> resetAll() async {
    await _repository.reset();
    // Preserve `hasLoaded=true` so the router doesn't treat the reset as
    // "still booting" and block navigation.
    state = const OnboardingState(
      hasLoaded: true,
      welcomeDone: false,
      seenTips: <OnboardingTip>{},
    );
  }

  /// Resets only the contextual tips, leaving the welcome flag intact.
  Future<void> resetTips() async {
    final wasWelcomeDone = state.welcomeDone;
    await _repository.reset();
    if (wasWelcomeDone) {
      await _repository.markWelcomeDone();
    }
    state = state.copyWith(seenTips: <OnboardingTip>{});
  }
}

/// Overridden by the main app with a real [OnboardingRepository]. A late
/// throw keeps forgotten wiring loud during tests.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  throw UnimplementedError(
    'onboardingRepositoryProvider must be overridden at the app root',
  );
});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
