import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesApiService _apiService;

  PlacesRepositoryImpl(this._apiService);

  /// 最低評論數門檻
  ///
  /// 評論數低於此值的地點會被過濾，避免顯示非真正景點。
  /// 根據研究，真正的觀光景點通常至少會有 10 則以上的 Google 評論，
  /// 低於此數量的地點很可能是被錯誤標記的商家或臨時性地點。
  static const int _minUserRatingCount = 10;

  static const List<String> _includedTypes = [
    'tourist_attraction',
    'historical_landmark',
    'art_gallery',
    'museum',
    'park',
    'national_park',
    'city_hall',
    'library',
    'aquarium',
    'zoo',
  ];

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    try {
      final dtos = await _apiService.searchNearby(
        location,
        includedTypes: _includedTypes,
        languageCode: language.code,
        radius: radius,
      );

      // DTO -> Domain 轉換，同時產生照片 URL
      // 過濾掉評論數不足的地點，避免顯示非真正景點
      return dtos
          .map((dto) => dto.toDomain(apiKey: _apiService.apiKey))
          .where(_hasEnoughReviews)
          .toList();
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '獲取附近地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    try {
      final dtos = await _apiService.searchByText(
        query,
        languageCode: language.code,
      );

      // DTO -> Domain 轉換，同時產生照片 URL
      // 過濾掉評論數不足的地點，避免顯示非真正景點
      return dtos
          .map((dto) => dto.toDomain(apiKey: _apiService.apiKey))
          .where(_hasEnoughReviews)
          .toList();
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '搜尋地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 檢查地點是否有足夠的評論數
  ///
  /// 若 API 未回傳 userRatingCount（為 null），視為評論數不足並過濾。
  bool _hasEnoughReviews(Place place) {
    final count = place.userRatingCount;
    return count != null && count >= _minUserRatingCount;
  }
}
