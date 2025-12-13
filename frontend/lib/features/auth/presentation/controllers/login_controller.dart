import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/auth/application/login_with_email_use_case.dart';
import 'package:context_app/features/auth/application/login_with_google_use_case.dart';

class LoginController extends StateNotifier<AsyncValue<void>> {
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  LoginController(this._loginWithEmailUseCase, this._loginWithGoogleUseCase)
    : super(const AsyncValue.data(null));

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _loginWithEmailUseCase.execute(email: email, password: password);
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _loginWithGoogleUseCase.execute();
      if (response == null) {
        throw const AuthException('Google Sign In Cancelled');
      }
    });
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      final loginWithEmailUseCase = ref.watch(loginWithEmailUseCaseProvider);
      final loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
      return LoginController(loginWithEmailUseCase, loginWithGoogleUseCase);
    });
