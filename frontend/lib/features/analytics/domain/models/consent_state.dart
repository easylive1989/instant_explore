import 'package:equatable/equatable.dart';

/// Whether the user has opted in to product analytics.
///
/// Defaults to enabled on first install (the onboarding flow shows a
/// transparent disclosure). Users can toggle it off in Settings; when
/// disabled the AnalyticsService drops events without enqueuing.
class ConsentState extends Equatable {
  final bool enabled;
  final DateTime updatedAt;

  const ConsentState({required this.enabled, required this.updatedAt});

  /// Default state used the first time the app runs: opted-in, with the
  /// timestamp set to "now".
  factory ConsentState.defaultOn() {
    return ConsentState(enabled: true, updatedAt: DateTime.now());
  }

  ConsentState copyWith({bool? enabled, DateTime? updatedAt}) {
    return ConsentState(
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [enabled, updatedAt];
}
