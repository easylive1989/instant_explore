import 'dart:async';

import 'package:context_app/features/auth/domain/models/auth_user.dart';
import 'package:context_app/features/auth/domain/services/auth_service.dart';

/// In-memory [AuthService] used by widget tests.
///
/// Captures method-call counts so tests can verify which sign-in flow
/// was triggered without going through Google/Apple SDKs.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initialUser}) : _user = initialUser {
    _controller.add(_user);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  int googleSignInCount = 0;
  int appleSignInCount = 0;
  int signOutCount = 0;
  bool shouldFailSignIn = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleSignInCount += 1;
    if (shouldFailSignIn) {
      throw const AuthFailureException('forced failure');
    }
    final user = const AuthUser(
      id: 'fake-google-user',
      email: 'fake@example.com',
      displayName: 'Fake User',
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    appleSignInCount += 1;
    if (shouldFailSignIn) {
      throw const AuthFailureException('forced failure');
    }
    final user = const AuthUser(
      id: 'fake-apple-user',
      email: 'apple@example.com',
      displayName: 'Apple User',
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    _user = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
