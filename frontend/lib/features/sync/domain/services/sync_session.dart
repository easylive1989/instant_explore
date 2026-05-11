import 'package:equatable/equatable.dart';

/// Combined snapshot of "is sync currently active?" — both the user
/// preference and the signed-in user id must be present.
class SyncSession extends Equatable {
  final bool enabled;
  final String? userId;

  const SyncSession({required this.enabled, required this.userId});

  const SyncSession.disabled() : enabled = false, userId = null;

  bool get isActive => enabled && userId != null && userId!.isNotEmpty;

  @override
  List<Object?> get props => [enabled, userId];
}
