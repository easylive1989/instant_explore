import 'package:context_app/features/explore/data/dto/google_place_dto.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlacesApiService extends Mock implements PlacesApiService {}

class FakePlaceLocation extends Fake implements PlaceLocation {}

void main() {
  late PlacesRepositoryImpl repository;
  late MockPlacesApiService mockApiService;

  const testLocation = PlaceLocation(
    latitude: 25.0330,
    longitude: 121.5654,
  );
  const testLanguage = Language.traditionalChinese;
  const testRadius = 1000.0;

  setUpAll(() {
    registerFallbackValue(FakePlaceLocation());
  });

  setUp(() {
    mockApiService = MockPlacesApiService();
    repository = PlacesRepositoryImpl(mockApiService);

    when(() => mockApiService.apiKey).thenReturn('test-api-key');
  });

  /// 建立測試用 GooglePlaceDto
  GooglePlaceDto createDto({
    required String id,
    required String name,
    int? userRatingCount,
    double? rating,
  }) {
    return GooglePlaceDto(
      id: id,
      displayName: {'text': name},
      formattedAddress: 'Test Address',
      location: {
        'latitude': 25.0330,
        'longitude': 121.5654,
      },
      rating: rating,
      userRatingCount: userRatingCount,
      types: ['tourist_attraction'],
      photos: [],
    );
  }

  group('getNearbyPlaces - 回傳所有地點（不過濾）', () {
    test('應回傳所有地點，包括評論數少的', () async {
      final dtos = [
        createDto(id: '1', name: 'Popular', userRatingCount: 500),
        createDto(id: '2', name: 'Few Reviews', userRatingCount: 5),
        createDto(id: '3', name: 'No Reviews', userRatingCount: null),
      ];

      when(
        () => mockApiService.searchNearby(
          any(),
          includedTypes: any(named: 'includedTypes'),
          languageCode: any(named: 'languageCode'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => dtos);

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result.length, 3);
    });

    test('應正確傳遞 userRatingCount 到 Domain Model', () async {
      final dtos = [
        createDto(id: '1', name: 'Place', userRatingCount: 42),
      ];

      when(
        () => mockApiService.searchNearby(
          any(),
          includedTypes: any(named: 'includedTypes'),
          languageCode: any(named: 'languageCode'),
          radius: any(named: 'radius'),
        ),
      ).thenAnswer((_) async => dtos);

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result.first.userRatingCount, 42);
    });
  });

  group('searchPlaces - 回傳所有地點（不過濾）', () {
    test('應回傳所有搜尋結果', () async {
      final dtos = [
        createDto(id: '1', name: 'Popular', userRatingCount: 200),
        createDto(id: '2', name: 'Tiny', userRatingCount: 3),
      ];

      when(
        () => mockApiService.searchByText(
          any(),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => dtos);

      final result = await repository.searchPlaces(
        '台北景點',
        language: testLanguage,
      );

      expect(result.length, 2);
    });
  });
}
