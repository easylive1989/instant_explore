import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../services/interfaces/auth_service_interface.dart';
import '../services/interfaces/location_service_interface.dart';
import '../services/interfaces/places_service_interface.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

/// 認證服務 Provider
///
/// 提供認證服務實例，在測試中可透過 overrides 注入 Fake 實作
final authServiceProvider = Provider<IAuthService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  final authService = AuthService(apiConfig);
  authService.initialize();
  return authService;
});

/// 位置服務 Provider
///
/// 提供位置服務實例，在測試中可透過 overrides 注入 Fake 實作
final locationServiceProvider = Provider<ILocationService>((ref) {
  return LocationService();
});

/// 地點服務 Provider
///
/// 提供地點服務實例，在測試中可透過 overrides 注入 Fake 實作
final placesServiceProvider = Provider<IPlacesService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return PlacesService(apiConfig);
});
