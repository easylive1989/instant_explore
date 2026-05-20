/// Domain-level error types for the analytics feature.
///
/// These are intentionally lightweight — analytics failures must never
/// surface to the user or break the calling flow. The type is reserved
/// for internal flow control / logging and may be expanded as later
/// tasks add the data layer.
sealed class AnalyticsError {
  const AnalyticsError();
}

/// Raised when the caller attempts to record an event while the user
/// has analytics consent disabled. Callers MUST swallow this and
/// continue without side-effects.
class AnalyticsConsentDisabled extends AnalyticsError {
  const AnalyticsConsentDisabled();
}
