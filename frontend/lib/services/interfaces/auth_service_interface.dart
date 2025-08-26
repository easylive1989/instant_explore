import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 認證服務介面
///
/// 定義所有認證相關功能的介面
/// 可以被真實認證服務或 Fake 認證服務實作
abstract interface class IAuthService {
  /// 初始化認證服務
  void initialize();

  /// Google 登入
  Future<AuthResponse?> signInWithGoogle();

  /// 登出
  Future<void> signOut();

  /// 取得當前使用者
  User? get currentUser;

  /// 檢查是否已登入
  bool get isSignedIn;

  /// 取得認證狀態串流
  Stream<AuthState> get authStateChanges;

  /// 清理資源（主要給 Fake 服務使用）
  void dispose() {}
}
