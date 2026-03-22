import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

class LogoutUseCase {
  final AuthService _authService;
  final SubscriptionService _subscriptionService;

  LogoutUseCase(this._authService, this._subscriptionService);

  Future<void> execute() async {
    await _subscriptionService.logOut();
    await _authService.signOut();
  }
}
