import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginWithGoogleUseCase {
  final AuthService _authService;

  LoginWithGoogleUseCase(this._authService);

  Future<AuthResponse?> execute() async {
    return _authService.signInWithGoogle();
  }
}
