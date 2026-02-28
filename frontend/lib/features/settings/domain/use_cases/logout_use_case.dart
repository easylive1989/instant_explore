import 'package:context_app/features/auth/data/auth_service.dart';

class LogoutUseCase {
  final AuthService _authService;

  LogoutUseCase(this._authService);

  Future<void> execute() async {
    await _authService.signOut();
  }
}
