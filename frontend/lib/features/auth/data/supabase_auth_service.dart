import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:context_app/app/config/api_config.dart';
import 'package:context_app/features/auth/domain/models/auth_user.dart';
import 'package:context_app/features/auth/domain/services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// Supabase-backed implementation of [AuthService].
///
/// Handles Google Sign-In via the native `google_sign_in` plugin and
/// Apple Sign-In via `sign_in_with_apple`, then exchanges the resulting
/// ID token for a Supabase session.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({
    required ApiConfig apiConfig,
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
  }) : _client = client ?? Supabase.instance.client,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             clientId: Platform.isIOS ? apiConfig.googleIosClientId : null,
             serverClientId: apiConfig.googleWebClientId,
             scopes: const ['email', 'openid', 'profile'],
           );

  static final _log = Logger('SupabaseAuthService');

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  @override
  AuthUser? get currentUser => _toAuthUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map(
      (state) => _toAuthUser(state.session?.user),
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthCancelledException();
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if (idToken == null) {
        throw const AuthFailureException('Google did not return an ID token');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailureException('Supabase did not return a user');
      }
      return _toAuthUser(user)!;
    } on AuthCancelledException {
      rethrow;
    } catch (e, stack) {
      _log.warning('Google sign-in failed', e, stack);
      if (e is AuthFailureException) rethrow;
      throw AuthFailureException(e.toString());
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256
          .convert(utf8.encode(rawNonce))
          .toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthFailureException('Apple did not return an ID token');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailureException('Supabase did not return a user');
      }
      return _toAuthUser(user)!;
    } on SignInWithAppleAuthorizationException catch (e, stack) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      _log.warning('Apple sign-in failed', e, stack);
      throw AuthFailureException(e.message);
    } catch (e, stack) {
      _log.warning('Apple sign-in failed', e, stack);
      if (e is AuthFailureException || e is AuthCancelledException) rethrow;
      throw AuthFailureException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out is best-effort; Supabase signOut is the source of truth.
    }
    await _client.auth.signOut();
  }

  static AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName =
        metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        user.email;
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: displayName,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
