import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'package:context_app/features/analytics/domain/models/abandon_reason.dart';
import 'package:context_app/features/analytics/domain/models/narration_event_source.dart';

const Uuid _uuid = Uuid();

/// An analytics event captured by the Lorescape client.
///
/// All concrete subtypes carry an [eventId] (UUID v4), the
/// [narrationId] the event belongs to, and the [occurredAt] timestamp
/// of when the event was created. Use [toJson] to flatten the event
/// into the envelope payload.
sealed class AnalyticsEvent extends Equatable {
  final String eventId;
  final String narrationId;
  final DateTime occurredAt;

  AnalyticsEvent({
    String? eventId,
    required this.narrationId,
    DateTime? occurredAt,
  }) : eventId = eventId ?? _uuid.v4(),
       occurredAt = occurredAt ?? DateTime.now();

  /// Wire-format event name (matches the analytics schema).
  String get type;

  /// Serialise the event-specific payload (excluding envelope fields).
  ///
  /// Includes `event_id`, `event_type`, `narration_id`, `occurred_at`
  /// plus the subtype-specific fields. Keys are snake_case.
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_type': type,
      'narration_id': narrationId,
      'occurred_at': occurredAt.toIso8601String(),
      ...payload(),
    };
  }

  /// Subtype-specific payload merged into [toJson].
  Map<String, dynamic> payload();

  @override
  List<Object?> get props => [eventId, narrationId, occurredAt];
}

/// Fired when a narration begins playing.
class NarrationStarted extends AnalyticsEvent {
  final String placeId;
  final NarrationEventSource source;
  final bool isFirstLifetimeNarration;

  NarrationStarted({
    super.eventId,
    required super.narrationId,
    required this.placeId,
    required this.source,
    required this.isFirstLifetimeNarration,
    super.occurredAt,
  });

  @override
  String get type => 'narration_started';

  @override
  Map<String, dynamic> payload() => {
    'place_id': placeId,
    'source': source.wireName,
    'is_first_lifetime_narration': isFirstLifetimeNarration,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    placeId,
    source,
    isFirstLifetimeNarration,
  ];
}

/// Fired when the listener crosses a 25 / 50 / 75 progress milestone.
///
/// Seek does NOT backfill skipped milestones — each milestone fires at
/// most once per narration.
class NarrationProgress extends AnalyticsEvent {
  final int milestone;
  final int elapsedMs;
  final int totalDurationMs;

  NarrationProgress({
    super.eventId,
    required super.narrationId,
    required this.milestone,
    required this.elapsedMs,
    required this.totalDurationMs,
    super.occurredAt,
  });

  @override
  String get type => 'narration_progress';

  @override
  Map<String, dynamic> payload() => {
    'milestone': milestone,
    'elapsed_ms': elapsedMs,
    'total_duration_ms': totalDurationMs,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    milestone,
    elapsedMs,
    totalDurationMs,
  ];
}

/// Fired when a narration reaches the completion threshold
/// (Story 1 AC3, default >= 95% of total duration).
class NarrationCompleted extends AnalyticsEvent {
  final int totalDurationMs;
  final int listenDurationMs;
  final double completionRate;

  NarrationCompleted({
    super.eventId,
    required super.narrationId,
    required this.totalDurationMs,
    required this.listenDurationMs,
    required this.completionRate,
    super.occurredAt,
  });

  @override
  String get type => 'narration_completed';

  @override
  Map<String, dynamic> payload() => {
    'total_duration_ms': totalDurationMs,
    'listen_duration_ms': listenDurationMs,
    'completion_rate': completionRate,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    totalDurationMs,
    listenDurationMs,
    completionRate,
  ];
}

/// Fired when playback ends before the completion threshold.
///
/// [abandonReason] captures the cause; [progressPct] is the percentage
/// listened (0~100) at the time of abandonment.
class NarrationAbandoned extends AnalyticsEvent {
  final AbandonReason abandonReason;
  final int elapsedMs;
  final double progressPct;

  NarrationAbandoned({
    super.eventId,
    required super.narrationId,
    required this.abandonReason,
    required this.elapsedMs,
    required this.progressPct,
    super.occurredAt,
  });

  @override
  String get type => 'narration_abandoned';

  @override
  Map<String, dynamic> payload() => {
    'abandon_reason': abandonReason.wireName,
    'elapsed_ms': elapsedMs,
    'progress_pct': progressPct,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    abandonReason,
    elapsedMs,
    progressPct,
  ];
}
