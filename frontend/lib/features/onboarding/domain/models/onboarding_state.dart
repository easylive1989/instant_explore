import 'package:equatable/equatable.dart';

/// Snapshot of the user's onboarding progress.
///
/// [hasLoaded] distinguishes the unknown startup state from a user who
/// genuinely hasn't completed the flow — the router uses it to avoid
/// flashing onboarding at returning users while SharedPreferences resolves.
class OnboardingState extends Equatable {
  /// Whether storage has been consulted at least once. Until this flips,
  /// consumers should treat the other fields as "unknown".
  final bool hasLoaded;

  /// Whether the user has finished the welcome carousel at least once.
  final bool welcomeDone;

  const OnboardingState({required this.hasLoaded, required this.welcomeDone});

  const OnboardingState.initial() : hasLoaded = false, welcomeDone = false;

  OnboardingState copyWith({bool? hasLoaded, bool? welcomeDone}) {
    return OnboardingState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      welcomeDone: welcomeDone ?? this.welcomeDone,
    );
  }

  @override
  List<Object?> get props => [hasLoaded, welcomeDone];
}
