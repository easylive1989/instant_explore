import 'package:context_app/features/auth/data/auth_service.dart';

class DeleteAccountUseCase {
  final AuthService _authService;

  DeleteAccountUseCase(this._authService);

  Future<void> execute() async {
    await _authService.deleteAccount();
  }
}
