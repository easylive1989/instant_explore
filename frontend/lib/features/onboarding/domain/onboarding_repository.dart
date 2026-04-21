import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';

/// Persists onboarding progress so first-time flows only run once.
abstract class OnboardingRepository {
  Future<OnboardingState> load();

  Future<void> markWelcomeDone();

  Future<void> markTipSeen(OnboardingTip tip);

  /// Clears all flags so the user can replay the full onboarding.
  Future<void> reset();
}
