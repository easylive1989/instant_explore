import 'package:flutter/foundation.dart';

/// API Keys Configuration
///
/// 此類別管理所有 API 金鑰的讀取和驗證
/// 所有金鑰都從環境變數中讀取，確保安全性
///
/// 使用方式：
/// 執行時需要透過 --dart-define 傳入環境變數
/// flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key
class ApiKeys {
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String googleDirectionsApiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: '',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// 檢測是否為 E2E 測試模式
  static bool get isE2ETestMode =>
      const String.fromEnvironment('E2E_TEST_MODE', defaultValue: 'false') ==
      'true';

  /// 檢查必要的 API 金鑰是否已設定
  static bool validateKeys() {
    // E2E 測試模式下跳過 API 金鑰驗證
    if (isE2ETestMode) {
      debugPrint('🧪 E2E 測試模式：跳過 API 金鑰驗證');
      return true;
    }

    final missingKeys = <String>[];

    if (googleMapsApiKey.isEmpty) {
      missingKeys.add('GOOGLE_MAPS_API_KEY');
    }
    if (supabaseUrl.isEmpty) {
      missingKeys.add('SUPABASE_URL');
    }
    if (supabaseAnonKey.isEmpty) {
      missingKeys.add('SUPABASE_ANON_KEY');
    }
    if (googleWebClientId.isEmpty) {
      missingKeys.add('GOOGLE_WEB_CLIENT_ID');
    }

    if (missingKeys.isNotEmpty) {
      debugPrint('⚠️ 警告: 以下 API 金鑰未設定: ${missingKeys.join(', ')}');
      debugPrint('請在執行時使用 --dart-define 參數設定環境變數');
      debugPrint('範例: flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key');
      return false;
    }

    return true;
  }
}
