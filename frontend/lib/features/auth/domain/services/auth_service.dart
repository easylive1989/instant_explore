import 'package:context_app/features/auth/domain/models/auth_user.dart';

/// Domain-level authentication facade. The implementation is responsible
/// for translating provider-specific (Google / Apple / Supabase) details
/// into a single [AuthUser] stream.
abstract class AuthService {
  /// Returns the currently authenticated user, or `null` when signed out.
  AuthUser? get currentUser;

  /// Emits the latest [AuthUser] whenever the session changes.
  Stream<AuthUser?> authStateChanges();

  /// Starts the Google Sign-In flow and signs into the backend.
  Future<AuthUser> signInWithGoogle();

  /// Starts the Sign in with Apple flow and signs into the backend.
  Future<AuthUser> signInWithApple();

  /// Clears the current session both locally and on the backend.
  Future<void> signOut();
}

/// Thrown when a sign-in flow is cancelled by the user.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Thrown when authentication fails for an unexpected reason.
class AuthFailureException implements Exception {
  final String message;
  const AuthFailureException(this.message);

  @override
  String toString() => 'AuthFailureException: $message';
}
