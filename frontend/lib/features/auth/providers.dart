import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/auth/domain/use_cases/login_with_email_use_case.dart';
import 'package:context_app/features/auth/domain/use_cases/login_with_google_use_case.dart';
import 'package:context_app/features/auth/domain/use_cases/register_with_email_use_case.dart';
import 'package:context_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:context_app/features/auth/presentation/controllers/register_controller.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// 認證服務 Provider
///
/// 提供認證服務實例，在測試中可透過 overrides 注入 Fake 實作
final authServiceProvider = Provider<AuthService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  final authService = AuthService(apiConfig);
  authService.initialize();
  return authService;
});

// ============================================================================
// Auth State Providers
// ============================================================================

/// 認證狀態 Provider
/// 監聽 Supabase 的認證狀態變化
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 當前使用者 Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 是否已登入 Provider
final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// 電子郵件登入用例 Provider
final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginWithEmailUseCase(authService);
});

/// Google 登入用例 Provider
final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginWithGoogleUseCase(authService);
});

/// 電子郵件註冊用例 Provider
final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  return RegisterWithEmailUseCase(authService);
});

// ============================================================================
// Controller Providers
// ============================================================================

/// 登入控制器 Provider
final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      final loginWithEmailUseCase = ref.watch(loginWithEmailUseCaseProvider);
      final loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
      return LoginController(loginWithEmailUseCase, loginWithGoogleUseCase);
    });

/// 註冊控制器 Provider
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
