import 'package:context_app/app/config/api_config.dart';
import 'package:context_app/features/auth/data/supabase_auth_service.dart';
import 'package:context_app/features/auth/domain/models/auth_user.dart';
import 'package:context_app/features/auth/domain/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default auth service (Supabase + Google/Apple). Override in tests.
final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService(apiConfig: ref.watch(apiConfigProvider));
});

/// Stream of the currently authenticated user. Emits `null` when signed out.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  // Seed with the current synchronous value so subscribers don't flicker
  // between loading and signed-in on hot restart.
  return service.authStateChanges().distinct();
});

/// Synchronous accessor for the current user, derived from [authStateProvider].
/// Falls back to [AuthService.currentUser] before the first stream event.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final stream = ref.watch(authStateProvider);
  return stream.maybeWhen(
    data: (user) => user,
    orElse: () => ref.watch(authServiceProvider).currentUser,
  );
});

/// Convenience flag exposing whether a user is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
