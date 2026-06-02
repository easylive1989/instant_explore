import 'package:equatable/equatable.dart';

/// Authenticated user as exposed by the auth domain.
///
/// Wraps just the fields the UI cares about so providers do not leak
/// the Supabase SDK type across feature boundaries.
class AuthUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;

  /// Whether this is a Supabase anonymous user that has not yet linked a
  /// real identity. Anonymous users get the free tier on a single device;
  /// purchasing and cloud sync require a permanent (non-anonymous) account.
  final bool isAnonymous;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [id, email, displayName, isAnonymous];
}
