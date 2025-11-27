/// 測試用戶資料常數
///
/// 定義測試帳號的固定資料，確保測試的一致性
class TestUser {
  TestUser._(); // 防止實例化

  /// 測試帳號 email
  static const String email = 'test01@example.com';

  /// 測試帳號密碼
  /// 符合密碼要求：
  /// - 最少 8 個字元
  /// - 至少一個大寫字母 (X)
  /// - 至少一個小寫字母 (qaz, ws)
  /// - 至少一個數字 (2)
  /// - 至少一個特殊字元 (!)
  static const String password = '!qaz2wsX';
}
