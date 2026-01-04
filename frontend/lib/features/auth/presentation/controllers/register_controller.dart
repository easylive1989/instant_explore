import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  RegisterController(this._authService) : super(const AsyncValue.data(null));

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signUpWithEmail(email: email, password: password);
    });
  }

  Future<void> registerWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _authService.signInWithGoogle();
      if (response == null) {
        throw const AuthException('Google Sign In Cancelled');
      }
    });
  }
}
