import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/auth/services/auth_service.dart';

class LogoutUseCase {
  final AuthService _authService;

  LogoutUseCase(this._authService);

  Future<void> execute() async {
    await _authService.signOut();
  }
}

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LogoutUseCase(authService);
});
