import 'package:flutter/foundation.dart';
import '../core/config/api_keys.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'fake/fake_auth_service.dart';
import 'fake/fake_location_service.dart';
import 'fake/fake_places_service.dart';

/// Service Provider Factory
///
/// 根據是否為 E2E 測試模式來決定使用真實服務或 Fake 服務
/// 這樣可以在測試時完全隔離外部依賴
class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  factory ServiceProvider() => _instance;
  ServiceProvider._internal() {
    _initialize();
  }

  // 真實服務實例
  late final AuthService _realAuthService;
  late final LocationService _realLocationService;
  late final PlacesService _realPlacesService;

  // Fake 服務實例
  late final FakeAuthService _fakeAuthService;
  late final FakeLocationService _fakeLocationService;
  late final FakePlacesService _fakePlacesService;

  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;

    debugPrint('🏭 ServiceProvider: 初始化服務提供者...');
    debugPrint('🧪 E2E 測試模式: ${ApiKeys.isE2ETestMode}');

    // 初始化真實服務
    _realAuthService = AuthService();
    _realLocationService = LocationService();
    _realPlacesService = PlacesService();

    // 初始化 Fake 服務
    _fakeAuthService = FakeAuthService();
    _fakeLocationService = FakeLocationService();
    _fakePlacesService = FakePlacesService();

    _isInitialized = true;
    debugPrint('✅ ServiceProvider: 服務提供者初始化完成');
  }

  /// 取得認證服務
  dynamic get authService {
    _ensureInitialized();
    if (ApiKeys.isE2ETestMode) {
      debugPrint('🧪 ServiceProvider: 使用 FakeAuthService');
      return _fakeAuthService;
    } else {
      debugPrint('🔐 ServiceProvider: 使用真實 AuthService');
      return _realAuthService;
    }
  }

  /// 取得位置服務
  dynamic get locationService {
    _ensureInitialized();
    if (ApiKeys.isE2ETestMode) {
      debugPrint('🧪 ServiceProvider: 使用 FakeLocationService');
      return _fakeLocationService;
    } else {
      debugPrint('📍 ServiceProvider: 使用真實 LocationService');
      return _realLocationService;
    }
  }

  /// 取得地點服務
  dynamic get placesService {
    _ensureInitialized();
    if (ApiKeys.isE2ETestMode) {
      debugPrint('🧪 ServiceProvider: 使用 FakePlacesService');
      return _fakePlacesService;
    } else {
      debugPrint('🗺️ ServiceProvider: 使用真實 PlacesService');
      return _realPlacesService;
    }
  }

  /// 初始化所有服務
  void initializeServices() {
    _ensureInitialized();

    debugPrint('🚀 ServiceProvider: 初始化所有服務...');

    if (ApiKeys.isE2ETestMode) {
      // E2E 測試模式：初始化 Fake 服務
      debugPrint('🧪 初始化測試服務...');
      _fakeAuthService.initialize();
    } else {
      // 生產模式：初始化真實服務
      debugPrint('🔐 初始化生產服務...');
      _realAuthService.initialize();
    }

    debugPrint('✅ ServiceProvider: 所有服務初始化完成');
  }

  /// 確保服務提供者已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _initialize();
    }
  }

  /// 重置服務提供者 (主要用於測試)
  void reset() {
    debugPrint('🔄 ServiceProvider: 重置服務提供者');
    _isInitialized = false;
    _initialize();
  }

  /// 取得當前模式描述
  String get currentModeDescription {
    return ApiKeys.isE2ETestMode ? '🧪 E2E 測試模式' : '🚀 生產模式';
  }

  /// 檢查是否為測試模式
  bool get isTestMode => ApiKeys.isE2ETestMode;
}

/// 全域服務提供者實例
final serviceProvider = ServiceProvider();
