import 'dart:convert';
import 'package:http/http.dart' as http;

/// Supabase Admin API 輔助工具
///
/// 負責使用 service_role key 執行管理員操作，包括：
/// - 檢查用戶是否存在
/// - 刪除測試用戶
class SupabaseAdminHelper {
  late final String _supabaseUrl;
  late final String _serviceRoleKey;

  SupabaseAdminHelper() {
    _supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://127.0.0.1:54321',
    );
    _serviceRoleKey = const String.fromEnvironment(
      'SUPABASE_SERVICE_ROLE_KEY',
      defaultValue: '',
    );

    if (_serviceRoleKey.isEmpty) {
      throw Exception(
        'SUPABASE_SERVICE_ROLE_KEY is required for admin operations. '
        'Please set it via --dart-define.',
      );
    }
  }

  /// 檢查用戶是否存在
  ///
  /// [email] 用戶的 email 地址
  /// 回傳 true 如果用戶存在，否則回傳 false
  Future<bool> userExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',
          'apikey': _serviceRoleKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] as List;
        return users.any((user) => user['email'] == email);
      }

      // ignore: avoid_print
      print('Failed to check user existence: ${response.statusCode}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error checking user existence: $e');
      return false;
    }
  }

  /// 刪除測試用戶
  ///
  /// [email] 要刪除的用戶 email 地址
  Future<void> deleteTestUser(String email) async {
    try {
      // 1. 查詢用戶 ID
      final userId = await _getUserIdByEmail(email);
      if (userId == null) {
        // ignore: avoid_print
        print('User not found, no need to delete: $email');
        return;
      }

      // 2. 使用 Admin API 刪除用戶
      final response = await http.delete(
        Uri.parse('$_supabaseUrl/auth/v1/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',
          'apikey': _serviceRoleKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('✅ Successfully deleted test user: $email');
      } else {
        // ignore: avoid_print
        print(
          '⚠️  Failed to delete user: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error deleting test user: $e');
      // 不拋出異常，避免影響測試執行
    }
  }

  /// 根據 email 查詢用戶 ID
  ///
  /// [email] 用戶的 email 地址
  /// 回傳用戶 ID，如果找不到則回傳 null
  Future<String?> _getUserIdByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',
          'apikey': _serviceRoleKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] as List;

        for (var user in users) {
          if (user['email'] == email) {
            return user['id'] as String;
          }
        }
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user ID: $e');
      return null;
    }
  }
}
