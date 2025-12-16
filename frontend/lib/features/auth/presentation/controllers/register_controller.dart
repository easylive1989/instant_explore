import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/auth/domain/use_cases/register_with_email_use_case.dart';
import 'package:context_app/features/auth/domain/use_cases/login_with_google_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final RegisterWithEmailUseCase _registerWithEmailUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  RegisterController(
    this._registerWithEmailUseCase,
    this._loginWithGoogleUseCase,
  ) : super(const AsyncValue.data(null));

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _registerWithEmailUseCase.execute(email: email, password: password);
    });
  }

  Future<void> registerWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _loginWithGoogleUseCase.execute();
      if (response == null) {
        throw const AuthException('Google Sign In Cancelled');
      }
    });
  }
}

final registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>((ref) {
      final registerWithEmailUseCase = ref.watch(
        registerWithEmailUseCaseProvider,
      );
      final loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
      return RegisterController(
        registerWithEmailUseCase,
        loginWithGoogleUseCase,
      );
    });
