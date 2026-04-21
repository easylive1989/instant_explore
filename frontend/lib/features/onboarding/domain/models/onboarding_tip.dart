/// Identifies a contextual coach-mark tip shown on a specific tab.
///
/// Each value maps to its own persistence key so tips can be dismissed
/// independently: seeing (or skipping) one tip never blocks another.
enum OnboardingTip {
  quickGuide,
  explore,
  journey;

  /// Key used to persist "already seen" state in SharedPreferences.
  String get storageKey => 'onboarding_tip_seen_$name';
}
