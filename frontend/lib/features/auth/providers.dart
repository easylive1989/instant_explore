import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:context_app/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// 認證服務 Provider
///
/// 提供認證服務實例，在測試中可透過 overrides 注入 Fake 實作
@protected
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
// Controller Providers
// ============================================================================

/// 登入控制器 Provider
final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return LoginController(authService);
    });

/// 註冊控制器 Provider
final registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return RegisterController(authService);
    });
