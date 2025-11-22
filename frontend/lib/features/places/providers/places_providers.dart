import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/places/services/places_service.dart';
import 'package:travel_diary/core/config/api_config.dart';

/// Places Service Provider
///
/// 提供 Google Places API 服務實例
/// 在測試中可透過 overrides 注入 Fake 實作
final placesServiceProvider = Provider<PlacesService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return PlacesService(apiConfig);
});
