import 'package:context_app/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

export 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart'
    show onboardingControllerProvider, onboardingRepositoryProvider;

/// Default override installed at the app root so the production build wires
/// the SharedPreferences-backed repository. Widget tests swap this for an
/// in-memory fake.
final defaultOnboardingRepositoryOverride =
    onboardingRepositoryProvider.overrideWith(
  (ref) => SharedPreferencesOnboardingRepository(),
);
