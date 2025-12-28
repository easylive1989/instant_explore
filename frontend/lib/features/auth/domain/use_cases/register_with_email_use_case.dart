import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterWithEmailUseCase {
  final AuthService _authService;

  RegisterWithEmailUseCase(this._authService);

  Future<AuthResponse> execute({
    required String email,
    required String password,
  }) async {
    return _authService.signUpWithEmail(email: email, password: password);
  }
}
