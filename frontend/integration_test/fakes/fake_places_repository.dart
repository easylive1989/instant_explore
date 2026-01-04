import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 測試用的假地點儲存庫
///
/// 回傳預設的地點列表，模擬 Google Places API
class FakePlacesRepository implements PlacesRepository {
  /// 預設的測試地點 A (台北 101)
  static const fakePlaceA = Place(
    id: 'fake_place_a',
    name: '台北 101',
    formattedAddress: '台北市信義區信義路五段7號',
    location: PlaceLocation(latitude: 25.0339, longitude: 121.5645),
    rating: 4.5,
    types: ['tourist_attraction', 'point_of_interest'],
    photos: [],
    category: PlaceCategory.modernUrban,
  );

  /// 預設的測試地點 B (國立故宮博物院)
  static const fakePlaceB = Place(
    id: 'fake_place_b',
    name: '國立故宮博物院',
    formattedAddress: '台北市士林區至善路二段221號',
    location: PlaceLocation(latitude: 25.1024, longitude: 121.5485),
    rating: 4.7,
    types: ['museum', 'tourist_attraction'],
    photos: [],
    category: PlaceCategory.museumArt,
  );

  /// 預設的測試地點 C (龍山寺)
  static const fakePlaceC = Place(
    id: 'fake_place_c',
    name: '龍山寺',
    formattedAddress: '台北市萬華區廣州街211號',
    location: PlaceLocation(latitude: 25.0372, longitude: 121.4997),
    rating: 4.6,
    types: ['temple', 'place_of_worship'],
    photos: [],
    category: PlaceCategory.historicalCultural,
  );

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    // 模擬網路延遲
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return [fakePlaceA, fakePlaceB, fakePlaceC];
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // 簡單的搜尋邏輯
    final allPlaces = [fakePlaceA, fakePlaceB, fakePlaceC];
    if (query.isEmpty) return allPlaces;

    return allPlaces
        .where(
          (place) =>
              place.name.toLowerCase().contains(query.toLowerCase()) ||
              place.formattedAddress.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
  }
}
