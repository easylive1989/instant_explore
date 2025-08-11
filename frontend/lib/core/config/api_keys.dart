/// API Keys Configuration
/// 
/// 此類別管理所有 API 金鑰的讀取和驗證
/// 所有金鑰都從環境變數中讀取，確保安全性
/// 
/// 使用方式：
/// 執行時需要透過 --dart-define 傳入環境變數
/// flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key
class ApiKeys {
  static const String googlePlacesApiKey = 
      String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
  
  static const String googleMapsApiKey = 
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  
  static const String googleDirectionsApiKey = 
      String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY', defaultValue: '');
  
  static const String environment = 
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  /// 檢查必要的 API 金鑰是否已設定
  static bool validateKeys() {
    final missingKeys = <String>[];
    
    if (googlePlacesApiKey.isEmpty) {
      missingKeys.add('GOOGLE_PLACES_API_KEY');
    }
    if (googleMapsApiKey.isEmpty) {
      missingKeys.add('GOOGLE_MAPS_API_KEY');
    }
    
    if (missingKeys.isNotEmpty) {
      print('⚠️ 警告: 以下 API 金鑰未設定: ${missingKeys.join(', ')}');
      print('請在執行時使用 --dart-define 參數設定環境變數');
      print('範例: flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key');
      return false;
    }
    
    return true;
  }
  
  /// 取得當前環境名稱
  static String get currentEnvironment => environment;
  
  /// 是否為開發環境
  static bool get isDevelopment => environment == 'development';
  
  /// 是否為生產環境
  static bool get isProduction => environment == 'production';
}