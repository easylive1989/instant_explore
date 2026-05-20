import 'package:context_app/features/analytics/domain/models/analytics_event.dart';

/// Records analytics events without raising errors to the caller.
///
/// Implementations are expected to swallow transport/transient
/// failures and log them internally. The underlying transport
/// (e.g. Firebase Analytics SDK) handles offline queueing,
/// batching, and retries — callers only need to fire-and-forget.
abstract class AnalyticsService {
  /// Records [event]. Returns once the event has been handed to the
  /// underlying transport; this does NOT guarantee remote delivery.
  Future<void> logEvent(AnalyticsEvent event);
}
