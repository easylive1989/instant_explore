import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API 配置類別
///
/// 管理所有 API 金鑰和配置參數
/// 透過 Riverpod 進行依賴注入，取代原有的靜態 ApiKeys 類別
class ApiConfig {
  final String googleMapsApiKey;
  final String googleDirectionsApiKey;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String supabaseServiceRoleKey;
  final String googleWebClientId;
  final String googleIosClientId;
  final String geminiApiKey;
  const ApiConfig({
    required this.googleMapsApiKey,
    required this.googleDirectionsApiKey,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.supabaseServiceRoleKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
    required this.geminiApiKey,
  });

  /// 從環境變數建立配置
  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(
      googleMapsApiKey: String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: '',
      ),
      googleDirectionsApiKey: String.fromEnvironment(
        'GOOGLE_DIRECTIONS_API_KEY',
        defaultValue: '',
      ),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
      supabaseServiceRoleKey: String.fromEnvironment(
        'SUPABASE_SERVICE_ROLE_KEY',
        defaultValue: '',
      ),
      googleWebClientId: String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
      ),
      googleIosClientId: String.fromEnvironment(
        'GOOGLE_IOS_CLIENT_ID',
        defaultValue: '',
      ),
      geminiApiKey: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );
  }

  /// 檢查必要的 API 金鑰是否已設定
  bool validateKeys() {
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
    if (geminiApiKey.isEmpty) {
      missingKeys.add('GEMINI_API_KEY');
    }

    if (missingKeys.isNotEmpty) {
      debugPrint('⚠️ 警告: 以下 API 金鑰未設定: ${missingKeys.join(', ')}');
      debugPrint('請在 .env 檔案中設定對應的環境變數');
      return false;
    }

    return true;
  }

  /// 取得 Google Maps API 金鑰是否已配置
  bool get isGoogleMapsConfigured => googleMapsApiKey.isNotEmpty;

  /// 取得 Supabase 是否已配置
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// 取得 Gemini 是否已配置
  bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  @override
  String toString() {
    return 'ApiConfig('
        'googleMapsConfigured: $isGoogleMapsConfigured, '
        'supabaseConfigured: $isSupabaseConfigured, '
        'geminiConfigured: $isGeminiConfigured'
        ')';
  }
}

/// API 配置 Provider
///
/// 提供全域的 API 配置存取
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});
