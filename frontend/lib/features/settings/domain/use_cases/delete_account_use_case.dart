import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/auth/data/auth_service.dart';

class DeleteAccountUseCase {
  final AuthService _authService;

  DeleteAccountUseCase(this._authService);

  Future<void> execute() async {
    await _authService.deleteAccount();
  }
}

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  return DeleteAccountUseCase(authService);
});
