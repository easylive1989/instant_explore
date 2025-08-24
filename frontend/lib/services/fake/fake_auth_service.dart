import 'dart:async';
import 'package:flutter/foundation.dart';
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
    debugPrint('🧪 FakeAuthService: 初始化 (測試模式)');
  }

  /// 模擬 Google 登入
  /// 直接回傳成功的 AuthResponse
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('🧪 FakeAuthService: 開始模擬 Google 登入...');

      // 模擬登入延遲
      await Future.delayed(const Duration(milliseconds: 500));

      // 建立測試用戶
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

      // 建立模擬的 Session
      final session = Session(
        accessToken: 'fake-access-token',
        refreshToken: 'fake-refresh-token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        user: testUser,
      );

      // 建立模擬的 AuthResponse
      final authResponse = AuthResponse(user: testUser, session: session);

      // 觸發認證狀態變更
      _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));

      debugPrint('✅ FakeAuthService: 模擬登入成功');
      debugPrint('👤 測試使用者: ${testUser.email}');

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('❌ FakeAuthService: 模擬登入失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 模擬登出
  Future<void> signOut() async {
    try {
      debugPrint('🧪 FakeAuthService: 開始模擬登出...');

      // 模擬登出延遲
      await Future.delayed(const Duration(milliseconds: 200));

      _currentUser = null;

      // 觸發登出狀態變更
      _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));

      debugPrint('✅ FakeAuthService: 模擬登出完成');
    } catch (e, stackTrace) {
      debugPrint('❌ FakeAuthService: 模擬登出失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
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
