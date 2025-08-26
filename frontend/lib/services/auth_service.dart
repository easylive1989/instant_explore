import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/api_config.dart';
import 'interfaces/auth_service_interface.dart';

/// 認證服務類別
///
/// 負責處理 Google 登入和 Supabase 認證整合
class AuthService implements IAuthService {
  final ApiConfig _apiConfig;
  late GoogleSignIn _googleSignIn;

  AuthService(this._apiConfig);

  /// 初始化 Google Sign In
  @override
  void initialize() {
    _googleSignIn = GoogleSignIn(
      clientId: _apiConfig.googleIosClientId,
      serverClientId: _apiConfig.googleWebClientId,
    );
  }

  /// Google 登入
  @override
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('🔐 開始 Google 登入流程...');

      // 1. Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ 使用者取消 Google 登入');
        return null;
      }

      // 2. 取得 Google 認證資訊
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('無法取得 Google ID Token');
      }

      debugPrint('✅ Google 登入成功，正在與 Supabase 整合...');

      // 3. 使用 Google ID Token 登入 Supabase
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );

      if (response.user != null) {
        debugPrint('✅ Supabase 認證成功');
        debugPrint('👤 使用者: ${response.user!.email}');
        return response;
      } else {
        throw Exception('Supabase 認證失敗');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Google 登入失敗: $e');
      debugPrint('Stack trace: $stackTrace');

      // 清理 Google 登入狀態
      await _googleSignIn.signOut();

      rethrow;
    }
  }

  /// 登出
  @override
  Future<void> signOut() async {
    try {
      debugPrint('🚪 開始登出流程...');

      // 1. 登出 Supabase
      await Supabase.instance.client.auth.signOut();

      // 2. 登出 Google
      await _googleSignIn.signOut();

      debugPrint('✅ 登出完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 登出失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 取得當前使用者
  @override
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// 檢查是否已登入
  @override
  bool get isSignedIn => currentUser != null;

  /// 取得認證狀態串流
  @override
  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  /// 清理資源（真實服務通常不需要特殊清理）
  @override
  void dispose() {
    // 真實的 AuthService 通常不需要特殊的清理邏輯
  }
}
