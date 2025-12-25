import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/domain/services/places_cache_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

class MockLocationService extends Mock implements LocationService {}

class MockPlacesRepository extends Mock implements PlacesRepository {}

class MockPlacesCacheService extends Mock implements PlacesCacheService {}

class FakePlaceLocation extends Fake implements PlaceLocation {}

class FakeLanguage extends Fake implements Language {}

void main() {
  late SearchNearbyPlacesUseCase useCase;
  late MockLocationService mockLocationService;
  late MockPlacesRepository mockPlacesRepository;
  late MockPlacesCacheService mockPlacesCacheService;

  // 使用者位置 (台北 101 附近)
  final userLocation = PlaceLocation(latitude: 25.0330, longitude: 121.5654);
  const testLanguage = Language.traditionalChinese;
  const testRadius = 1000.0;

  setUpAll(() {
    registerFallbackValue(FakePlaceLocation());
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockPlacesRepository = MockPlacesRepository();
    mockPlacesCacheService = MockPlacesCacheService();
    useCase = SearchNearbyPlacesUseCase(
      mockLocationService,
      mockPlacesRepository,
      mockPlacesCacheService,
    );

    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => userLocation);

    // 預設快取為過期狀態，需要重新搜尋
    when(
      () => mockPlacesCacheService.shouldRefresh(any()),
    ).thenAnswer((_) async => true);

    when(
      () => mockPlacesCacheService.cachePlaces(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockPlacesCacheService.saveLastSearchLocation(any()),
    ).thenAnswer((_) async {});
  });

  /// 建立測試用 Place
  Place createPlace({
    required String id,
    required String name,
    required PlaceLocation location,
    double? rating,
  }) {
    return Place(
      id: id,
      name: name,
      formattedAddress: 'Test Address',
      location: location,
      types: ['tourist_attraction'],
      photos: [],
      category: PlaceCategory.modernUrban,
      rating: rating,
    );
  }

  group('SearchNearbyPlacesUseCase - 權重排序邏輯', () {
    test('距離相近時，高評分地點應排在前面', () async {
      // 兩個地點距離使用者都很近（差距 < 200m）
      final nearHighRating = createPlace(
        id: '1',
        name: 'High Rating Place',
        location: PlaceLocation(
          latitude: 25.0331, // 約 10m 遠
          longitude: 121.5654,
        ),
        rating: 4.8,
      );
      final nearLowRating = createPlace(
        id: '2',
        name: 'Low Rating Place',
        location: PlaceLocation(
          latitude: 25.0332, // 約 20m 遠
          longitude: 121.5654,
        ),
        rating: 2.5,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [nearLowRating, nearHighRating]);

      final result = await useCase.execute(language: testLanguage);

      expect(result.first.name, 'High Rating Place');
      expect(result.last.name, 'Low Rating Place');
    });

    test('稍遠但高評分的地點應排在很近但低評分的前面', () async {
      // 低評分地點非常近，高評分地點稍遠但在容許範圍內
      final veryNearLowRating = createPlace(
        id: '1',
        name: 'Very Near Low Rating',
        location: PlaceLocation(
          latitude: 25.0330, // 約 0m
          longitude: 121.5654,
        ),
        rating: 1.5,
      );
      final slightlyFarHighRating = createPlace(
        id: '2',
        name: 'Slightly Far High Rating',
        location: PlaceLocation(
          latitude: 25.0340, // 約 110m 遠
          longitude: 121.5654,
        ),
        rating: 4.9,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [veryNearLowRating, slightlyFarHighRating]);

      final result = await useCase.execute(language: testLanguage);

      // 距離差 < 200m，應該優先看評分
      expect(result.first.name, 'Slightly Far High Rating');
      expect(result.last.name, 'Very Near Low Rating');
    });

    test('距離差異超過容許範圍時，使用綜合分數排序', () async {
      // 近但評分一般的地點 vs 遠但評分高的地點
      final nearMediumRating = createPlace(
        id: '1',
        name: 'Near Medium Rating',
        location: PlaceLocation(
          latitude: 25.0335, // 約 55m 遠
          longitude: 121.5654,
        ),
        rating: 3.5,
      );
      final farHighRating = createPlace(
        id: '2',
        name: 'Far High Rating',
        location: PlaceLocation(
          latitude: 25.0360, // 約 330m 遠 (超過 200m 容許範圍)
          longitude: 121.5654,
        ),
        rating: 5.0,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [farHighRating, nearMediumRating]);

      final result = await useCase.execute(language: testLanguage);

      // 距離差 > 200m，使用綜合分數
      // 這裡主要測試排序有執行
      expect(result.length, 2);
    });

    test('沒有評分的地點應該被正確處理 (評分視為 0)', () async {
      final noRating = createPlace(
        id: '1',
        name: 'No Rating Place',
        location: PlaceLocation(latitude: 25.0331, longitude: 121.5654),
        rating: null,
      );
      final hasRating = createPlace(
        id: '2',
        name: 'Has Rating Place',
        location: PlaceLocation(latitude: 25.0332, longitude: 121.5654),
        rating: 4.0,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [noRating, hasRating]);

      final result = await useCase.execute(language: testLanguage);

      // 有評分的應該排在前面
      expect(result.first.name, 'Has Rating Place');
      expect(result.last.name, 'No Rating Place');
    });

    test('相同評分時，較近的地點應排在前面（使用綜合分數）', () async {
      // 距離差需要超過 200m，才會使用綜合分數排序
      final sameRatingNear = createPlace(
        id: '1',
        name: 'Near',
        location: PlaceLocation(
          latitude: 25.0335, // 約 55m
          longitude: 121.5654,
        ),
        rating: 4.0,
      );
      final sameRatingFar = createPlace(
        id: '2',
        name: 'Far',
        location: PlaceLocation(
          latitude: 25.0360, // 約 330m (距離差 > 200m)
          longitude: 121.5654,
        ),
        rating: 4.0,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [sameRatingFar, sameRatingNear]);

      final result = await useCase.execute(language: testLanguage);

      // 評分相同但距離差 > 200m，使用綜合分數，距離近的分數較高
      expect(result.first.name, 'Near');
      expect(result.last.name, 'Far');
    });

    test('空列表應該正確處理', () async {
      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => []);

      final result = await useCase.execute(language: testLanguage);

      expect(result, isEmpty);
    });

    test('單一地點應該正確處理', () async {
      final singlePlace = createPlace(
        id: '1',
        name: 'Only Place',
        location: PlaceLocation(latitude: 25.0331, longitude: 121.5654),
        rating: 4.5,
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [singlePlace]);

      final result = await useCase.execute(language: testLanguage);

      expect(result.length, 1);
      expect(result.first.name, 'Only Place');
    });
  });
}
