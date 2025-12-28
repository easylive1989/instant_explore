import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginWithEmailUseCase {
  final AuthService _authService;

  LoginWithEmailUseCase(this._authService);

  Future<AuthResponse> execute({
    required String email,
    required String password,
  }) async {
    return _authService.signInWithEmail(email: email, password: password);
  }
}
