import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

class MockLocationService extends Mock implements LocationService {}

class MockPlacesRepository extends Mock implements PlacesRepository {}

class FakePlaceLocation extends Fake implements PlaceLocation {}

class FakeLanguage extends Fake implements Language {}

void main() {
  late SearchNearbyPlacesUseCase useCase;
  late MockLocationService mockLocationService;
  late MockPlacesRepository mockPlacesRepository;

  // 使用者位置 (台北 101 附近)
  const userLocation = PlaceLocation(latitude: 25.0330, longitude: 121.5654);
  const testLanguage = Language.traditionalChinese;
  const testRadius = 1000.0;

  setUpAll(() {
    registerFallbackValue(FakePlaceLocation());
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockPlacesRepository = MockPlacesRepository();
    useCase = SearchNearbyPlacesUseCase(
      mockLocationService,
      mockPlacesRepository,
    );

    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => userLocation);
  });

  /// 建立測試用 Place
  Place createPlace({
    required String id,
    required String name,
    required PlaceLocation location,
  }) {
    return Place(
      id: id,
      name: name,
      formattedAddress: 'Test Address',
      location: location,
      types: const ['tourist_attraction'],
      photos: const [
        PlacePhoto(
          url: 'https://example.com/photo.jpg',
          widthPx: 200,
          heightPx: 200,
          authorAttributions: [],
        ),
      ],
      category: PlaceCategory.modernUrban,
    );
  }

  group('SearchNearbyPlacesUseCase - 距離排序邏輯', () {
    test('較近的地點應排在前面', () async {
      final near = createPlace(
        id: '1',
        name: 'Near Place',
        location: const PlaceLocation(
          latitude: 25.0331, // 約 11m
          longitude: 121.5654,
        ),
      );
      final far = createPlace(
        id: '2',
        name: 'Far Place',
        location: const PlaceLocation(
          latitude: 25.0360, // 約 333m
          longitude: 121.5654,
        ),
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [far, near]);

      final result = await useCase.execute(language: testLanguage);

      expect(result.places.first.name, 'Near Place');
      expect(result.places.last.name, 'Far Place');
    });

    test('結果應包含正確的使用者位置', () async {
      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => []);

      final result = await useCase.execute(language: testLanguage);

      expect(result.userLocation, userLocation);
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

      expect(result.places, isEmpty);
    });

    test('單一地點應該正確處理', () async {
      final singlePlace = createPlace(
        id: '1',
        name: 'Only Place',
        location: const PlaceLocation(latitude: 25.0331, longitude: 121.5654),
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [singlePlace]);

      final result = await useCase.execute(language: testLanguage);

      expect(result.places.single.name, 'Only Place');
    });

    test('多個地點依距離升序排列', () async {
      final p1 = createPlace(
        id: '1',
        name: 'Closest',
        location: const PlaceLocation(latitude: 25.0331, longitude: 121.5654),
      );
      final p2 = createPlace(
        id: '2',
        name: 'Middle',
        location: const PlaceLocation(latitude: 25.0340, longitude: 121.5654),
      );
      final p3 = createPlace(
        id: '3',
        name: 'Farthest',
        location: const PlaceLocation(latitude: 25.0360, longitude: 121.5654),
      );

      when(
        () => mockPlacesRepository.getNearbyPlaces(
          userLocation,
          language: testLanguage,
          radius: testRadius,
        ),
      ).thenAnswer((_) async => [p3, p1, p2]);

      final result = await useCase.execute(language: testLanguage);

      expect(result.places[0].name, 'Closest');
      expect(result.places[1].name, 'Middle');
      expect(result.places[2].name, 'Farthest');
    });
  });
}
