import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake AuthService for E2E testing
///
/// 模擬認證服務，在 E2E 測試中使用
/// 直接回傳成功的認證結果，避免真實的 Google 登入流程
class FakeAuthService {
  static final FakeAuthService _instance = FakeAuthService._internal();
  factory FakeAuthService() => _instance;
  FakeAuthService._internal();

  User? _currentUser;
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  /// 初始化 (測試模式下不需要實際操作)
  void initialize() {
    // 測試模式下無需實際操作
  }

  /// 模擬 Google 登入
  /// 直接回傳成功的 AuthResponse
  Future<AuthResponse?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final testUser = User(
      id: 'fake-user-id-12345',
      appMetadata: {'provider': 'google'},
      userMetadata: {
        'email': 'test@example.com',
        'name': '測試使用者',
        'avatar_url': 'https://example.com/avatar.jpg',
      },
      aud: 'authenticated',
      email: 'test@example.com',
      createdAt: DateTime.now().toIso8601String(),
      role: 'authenticated',
    );

    _currentUser = testUser;

    final session = Session(
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      user: testUser,
    );

    final authResponse = AuthResponse(user: testUser, session: session);
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));

    return authResponse;
  }

  /// 模擬登出
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  /// 取得當前使用者
  User? get currentUser => _currentUser;

  /// 檢查是否已登入
  bool get isSignedIn => _currentUser != null;

  /// 取得認證狀態串流
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  /// 清理資源
  void dispose() {
    _authStateController.close();
  }
}
