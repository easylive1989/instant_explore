import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the persisted onboarding state to the UI and mediates writes
/// back to [OnboardingRepository].
///
/// The controller starts at [OnboardingState.initial] and only reaches out
/// to storage when a caller invokes [ensureLoaded]. This avoids racing the
/// Notifier lifecycle during `build()` and makes tests deterministic.
class OnboardingController extends Notifier<OnboardingState> {
  late final OnboardingRepository _repository;
  Future<void>? _loadFuture;

  @override
  OnboardingState build() {
    _repository = ref.read(onboardingRepositoryProvider);
    return const OnboardingState.initial();
  }

  /// Loads persisted state, guaranteeing `state.hasLoaded == true` when the
  /// returned future resolves. Safe to call many times; the same future is
  /// reused after the first invocation.
  Future<void> ensureLoaded() {
    return _loadFuture ??= _loadFromRepository();
  }

  Future<void> _loadFromRepository() async {
    final loaded = await _repository.load();
    // Guard against a user-initiated write (e.g. completeWelcome) that
    // may have landed while the async load was in flight.
    if (state.hasLoaded) return;
    state = loaded.copyWith(hasLoaded: true);
  }

  Future<void> completeWelcome() async {
    state = state.copyWith(hasLoaded: true, welcomeDone: true);
    await _repository.markWelcomeDone();
  }

  /// Resets every flag so the user sees the welcome carousel again.
  /// Used by "replay onboarding" in Settings.
  Future<void> resetAll() async {
    await _repository.reset();
    // Preserve `hasLoaded=true` so the router doesn't treat the reset as
    // "still booting" and block navigation.
    state = const OnboardingState(hasLoaded: true, welcomeDone: false);
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
