import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:equatable/equatable.dart';

/// Snapshot of the user's onboarding progress.
///
/// The welcome carousel is tracked separately from contextual tips so
/// Settings can replay them independently. [hasLoaded] distinguishes the
/// unknown startup state from a user who genuinely hasn't completed the
/// flow — the router uses it to avoid flashing onboarding at returning
/// users while SharedPreferences resolves.
class OnboardingState extends Equatable {
  /// Whether storage has been consulted at least once. Until this flips,
  /// consumers should treat the other fields as "unknown".
  final bool hasLoaded;

  /// Whether the user has finished the welcome carousel at least once.
  final bool welcomeDone;

  /// Set of tips the user has already viewed or dismissed.
  final Set<OnboardingTip> seenTips;

  const OnboardingState({
    required this.hasLoaded,
    required this.welcomeDone,
    required this.seenTips,
  });

  const OnboardingState.initial()
      : hasLoaded = false,
        welcomeDone = false,
        seenTips = const <OnboardingTip>{};

  bool hasSeen(OnboardingTip tip) => seenTips.contains(tip);

  OnboardingState copyWith({
    bool? hasLoaded,
    bool? welcomeDone,
    Set<OnboardingTip>? seenTips,
  }) {
    return OnboardingState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      welcomeDone: welcomeDone ?? this.welcomeDone,
      seenTips: seenTips ?? this.seenTips,
    );
  }

  @override
  List<Object?> get props => [hasLoaded, welcomeDone, seenTips];
}
