import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';

class LogoutUseCase {
  final AuthService _authService;
  final PurchaseRepository _purchaseRepository;

  LogoutUseCase(this._authService, this._purchaseRepository);

  Future<void> execute() async {
    // 登出 RevenueCat
    await _purchaseRepository.logout();
    // 登出 Supabase
    await _authService.signOut();
  }
}
