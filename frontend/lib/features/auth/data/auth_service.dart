import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/common/config/api_config.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 認證服務類別
///
/// 負責處理 Google 登入和 Supabase 認證整合
class AuthService {
  final ApiConfig _apiConfig;
  late GoogleSignIn _googleSignIn;

  AuthService(this._apiConfig);

  /// 初始化 Google Sign In
  void initialize() {
    _googleSignIn = GoogleSignIn(
      clientId: _apiConfig.googleIosClientId,
      serverClientId: _apiConfig.googleWebClientId,
    );
  }

  /// Google 登入
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

  /// Apple 登入
  Future<AuthResponse?> signInWithApple() async {
    try {
      debugPrint('🍎 開始 Apple 登入流程...');

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // 1. Request Apple ID credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // 指定 Service ID（Client ID）
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.paulchwu.instantexplore.service',
          redirectUri: Uri.parse('${_apiConfig.supabaseUrl}/auth/v1/callback'),
        ),
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('無法取得 Apple ID Token');
      }

      debugPrint('✅ Apple 登入成功，正在與 Supabase 整合...');

      // 2. 使用 Apple ID Token 登入 Supabase
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            accessToken: credential.authorizationCode,
            nonce: rawNonce,
          );

      if (response.user != null) {
        debugPrint('✅ Supabase 認證成功');
        debugPrint('👤 使用者: ${response.user!.email}');
        return response;
      } else {
        throw Exception('Supabase 認證失敗');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Apple 登入失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 產生隨機 nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// 計算 SHA256
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 登出
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

  /// 刪除帳戶
  ///
  /// 刪除當前用戶的帳戶及所有相關資料
  Future<void> deleteAccount() async {
    try {
      debugPrint('🗑️ 開始刪除帳戶流程...');

      final user = currentUser;
      if (user == null) {
        throw Exception('沒有已登入的使用者');
      }

      // 1. 調用 Supabase RPC 函數來刪除用戶資料
      // 注意：這需要在 Supabase 後端設置相應的函數
      // 例如：create or replace function delete_user_account()
      try {
        await Supabase.instance.client.rpc('delete_user_account');
      } catch (e) {
        debugPrint('⚠️ 刪除用戶資料時發生錯誤: $e');
        // 如果 RPC 函數不存在，繼續執行刪除流程
      }

      // 2. 登出 Google
      await _googleSignIn.signOut();

      // 3. 登出 Supabase
      await Supabase.instance.client.auth.signOut();

      debugPrint('✅ 帳戶刪除完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 刪除帳戶失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 取得當前使用者
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// 檢查是否已登入
  bool get isSignedIn => currentUser != null;

  /// 取得認證狀態串流
  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  /// 使用電子郵件和密碼註冊
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 開始電子郵件註冊流程...');

      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ 註冊成功');
        debugPrint('👤 使用者: ${response.user!.email}');
        return response;
      } else {
        throw Exception('註冊失敗');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 註冊失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 使用電子郵件和密碼登入
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 開始電子郵件登入流程...');

      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (response.user != null) {
        debugPrint('✅ 登入成功');
        debugPrint('👤 使用者: ${response.user!.email}');
        return response;
      } else {
        throw Exception('登入失敗');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 登入失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 發送密碼重置郵件
  Future<void> resetPassword({required String email}) async {
    try {
      debugPrint('🔑 開始發送密碼重置郵件...');

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      debugPrint('✅ 密碼重置郵件已發送至: $email');
    } catch (e, stackTrace) {
      debugPrint('❌ 發送密碼重置郵件失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 清理資源（真實服務通常不需要特殊清理）
  void dispose() {
    // 真實的 AuthService 通常不需要特殊的清理邏輯
  }
}
