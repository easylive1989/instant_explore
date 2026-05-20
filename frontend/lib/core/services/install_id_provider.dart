/// Returns the stable install id used to attribute analytics events
/// and feature-flag A/B bucketing to a single device install.
///
/// The install id MUST be:
///   * generated once on first launch (UUID v4),
///   * persisted across app restarts,
///   * cleared on uninstall (i.e. not synced via iCloud / restore).
///
/// Lives under `core/services/` because multiple features rely on it
/// (analytics for event attribution, feature flags for A/B hashing).
///
/// Default production implementation is backed by
/// `FirebaseAnalytics.appInstanceId`, which already satisfies the
/// uninstall-clear and per-install uniqueness contract; the interface
/// is kept transport-agnostic so tests can substitute a deterministic
/// fake.
abstract class InstallIdProvider {
  Future<String> get();
}
