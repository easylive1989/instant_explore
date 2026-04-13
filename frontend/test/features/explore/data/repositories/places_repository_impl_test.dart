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

  group('getNearbyPlaces - 評論數過濾', () {
    test('應過濾掉評論數低於 10 的地點', () async {
      final dtos = [
        createDto(id: '1', name: 'Popular', userRatingCount: 500),
        createDto(id: '2', name: 'Too Few', userRatingCount: 5),
        createDto(id: '3', name: 'Enough', userRatingCount: 10),
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

      expect(result.length, 2);
      expect(result.map((p) => p.name), ['Popular', 'Enough']);
    });

    test('應過濾掉 userRatingCount 為 null 的地點', () async {
      final dtos = [
        createDto(id: '1', name: 'Has Reviews', userRatingCount: 50),
        createDto(id: '2', name: 'No Data', userRatingCount: null),
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

      expect(result.length, 1);
      expect(result.first.name, 'Has Reviews');
    });

    test('剛好 10 則評論的地點應保留', () async {
      final dtos = [
        createDto(
          id: '1',
          name: 'Exactly 10',
          userRatingCount: 10,
        ),
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

      expect(result.length, 1);
      expect(result.first.name, 'Exactly 10');
    });

    test('9 則評論的地點應被過濾', () async {
      final dtos = [
        createDto(id: '1', name: 'Almost', userRatingCount: 9),
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

      expect(result, isEmpty);
    });

    test('所有地點都被過濾時應回傳空列表', () async {
      final dtos = [
        createDto(id: '1', name: 'Low 1', userRatingCount: 3),
        createDto(id: '2', name: 'Low 2', userRatingCount: 0),
        createDto(id: '3', name: 'No Data', userRatingCount: null),
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

      expect(result, isEmpty);
    });
  });

  group('searchPlaces - 評論數過濾', () {
    test('文字搜尋也應過濾掉評論數不足的地點', () async {
      final dtos = [
        createDto(id: '1', name: 'Popular', userRatingCount: 200),
        createDto(id: '2', name: 'Too Few', userRatingCount: 3),
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

      expect(result.length, 1);
      expect(result.first.name, 'Popular');
    });
  });
}
