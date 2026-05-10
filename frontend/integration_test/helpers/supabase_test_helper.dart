import 'package:supabase_flutter/supabase_flutter.dart';

/// 測試用的 Supabase 輔助函數
class SupabaseTestHelper {
  /// 預設測試用戶資訊
  static const testEmail = 'e2e-test@example.com';
  static const testPassword = 'TestPassword123!';

  /// 使用 Supabase Admin 建立並登入測試用戶
  ///
  /// 如果用戶不存在會先建立，然後登入
  static Future<User> signInTestUser() async {
    final client = Supabase.instance.client;

    try {
      // 嘗試登入
      final response = await client.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );

      if (response.user != null) {
        return response.user!;
      }

      throw Exception('Failed to sign in test user');
    } on AuthException catch (e) {
      // 如果用戶不存在，建立新用戶
      if (e.message.contains('Invalid login credentials')) {
        final signUpResponse = await client.auth.signUp(
          email: testEmail,
          password: testPassword,
        );

        if (signUpResponse.user != null) {
          return signUpResponse.user!;
        }
      }
      rethrow;
    }
  }

  /// 登出當前用戶
  static Future<void> signOut() async {
    final client = Supabase.instance.client;
    await client.auth.signOut();
  }
}
