import 'package:equatable/equatable.dart';

/// Authenticated user as exposed by the auth domain.
///
/// Wraps just the fields the UI cares about so providers do not leak
/// the Supabase SDK type across feature boundaries.
class AuthUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;

  const AuthUser({required this.id, this.email, this.displayName});

  @override
  List<Object?> get props => [id, email, displayName];
}
