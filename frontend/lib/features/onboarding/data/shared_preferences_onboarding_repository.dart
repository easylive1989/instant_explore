import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:context_app/features/onboarding/domain/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [OnboardingRepository].
///
/// Each flag is stored under its own key so a corrupt/missing value for
/// one step never cascades into another.
class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  static const _welcomeDoneKey = 'onboarding_welcome_done';

  @override
  Future<OnboardingState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeDone = prefs.getBool(_welcomeDoneKey) ?? false;
    final seen = <OnboardingTip>{};
    for (final tip in OnboardingTip.values) {
      if (prefs.getBool(tip.storageKey) ?? false) {
        seen.add(tip);
      }
    }
    return OnboardingState(
      hasLoaded: true,
      welcomeDone: welcomeDone,
      seenTips: seen,
    );
  }

  @override
  Future<void> markWelcomeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeDoneKey, true);
  }

  @override
  Future<void> markTipSeen(OnboardingTip tip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tip.storageKey, true);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeDoneKey);
    for (final tip in OnboardingTip.values) {
      await prefs.remove(tip.storageKey);
    }
  }
}
