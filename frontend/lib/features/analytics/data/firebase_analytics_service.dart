import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logging/logging.dart';

import 'package:context_app/features/analytics/domain/models/analytics_event.dart';
import 'package:context_app/features/analytics/domain/services/analytics_service.dart';

final Logger _log = Logger('FirebaseAnalyticsService');

/// [AnalyticsService] implementation backed by the Firebase Analytics
/// SDK.
///
/// Firebase Analytics imposes the following constraints, which this
/// service satisfies via [firebaseParametersFor]:
///
///   * Parameter values may only be `String` or `num` — `bool` is
///     unsupported and must be coerced to `int` (true → 1, false → 0).
///   * String values are capped at 100 characters.
///   * Each event may carry at most 25 parameters.
///
/// Transport failures are logged but never propagated to the caller;
/// the underlying SDK handles offline queueing, batching, and retry.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._firebase);

  final FirebaseAnalytics _firebase;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    try {
      await _firebase.logEvent(
        name: event.type,
        parameters: firebaseParametersFor(event),
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to log analytics event ${event.type}',
        error,
        stackTrace,
      );
    }
  }
}

/// Converts [event] into a `Map<String, Object>` suitable for
/// [FirebaseAnalytics.logEvent].
///
/// Common envelope fields ([AnalyticsEvent.eventId],
/// [AnalyticsEvent.narrationId], [AnalyticsEvent.occurredAt]) are
/// always included alongside the subtype-specific payload. `bool`
/// values are coerced to `int` so they satisfy the Firebase Analytics
/// parameter contract.
///
/// Exposed as a top-level function so it can be unit-tested without
/// instantiating the Firebase SDK.
Map<String, Object> firebaseParametersFor(AnalyticsEvent event) {
  final Map<String, Object> base = {
    'event_id': event.eventId,
    'narration_id': event.narrationId,
    'occurred_at': event.occurredAt.toIso8601String(),
  };

  final Map<String, Object?> subtype = switch (event) {
    NarrationStarted() => {
      'place_id': event.placeId,
      'source': event.source.wireName,
      'is_first_lifetime_narration': event.isFirstLifetimeNarration ? 1 : 0,
    },
    NarrationProgress() => {
      'milestone': event.milestone,
      'elapsed_ms': event.elapsedMs,
      'total_duration_ms': event.totalDurationMs,
    },
    NarrationCompleted() => {
      'total_duration_ms': event.totalDurationMs,
      'listen_duration_ms': event.listenDurationMs,
      'completion_rate': event.completionRate,
    },
    NarrationAbandoned() => {
      'abandon_reason': event.abandonReason.wireName,
      'elapsed_ms': event.elapsedMs,
      'progress_pct': event.progressPct,
    },
  };

  for (final entry in subtype.entries) {
    final value = entry.value;
    if (value != null) {
      base[entry.key] = value;
    }
  }
  return base;
}
