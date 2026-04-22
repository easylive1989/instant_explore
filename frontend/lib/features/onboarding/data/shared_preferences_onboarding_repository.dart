import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [OnboardingRepository].
class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  static const _welcomeDoneKey = 'onboarding_welcome_done';

  @override
  Future<OnboardingState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeDone = prefs.getBool(_welcomeDoneKey) ?? false;
    return OnboardingState(hasLoaded: true, welcomeDone: welcomeDone);
  }

  @override
  Future<void> markWelcomeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeDoneKey, true);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeDoneKey);
  }
}
