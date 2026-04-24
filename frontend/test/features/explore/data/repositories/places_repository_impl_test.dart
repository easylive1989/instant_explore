import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWikipediaPlacesService extends Mock
    implements WikipediaPlacesService {}

void main() {
  late PlacesRepositoryImpl repository;
  late MockWikipediaPlacesService mockService;

  const testLocation = PlaceLocation(latitude: 25.0336, longitude: 121.5644);
  const testLanguage = Language.traditionalChinese;
  const testRadius = 1000.0;

  setUp(() {
    mockService = MockWikipediaPlacesService();
    repository = PlacesRepositoryImpl(mockService);
  });

  WikiGeoSearchResultDto geoDto({
    required String title,
    required String wikidataId,
    String? thumb = 'https://img/x.jpg',
  }) {
    return WikiGeoSearchResultDto(
      pageId: title.hashCode,
      title: title,
      lat: 25.0,
      lon: 121.0,
      thumbnailUrl: thumb,
      thumbnailWidth: thumb == null ? null : 400,
      thumbnailHeight: thumb == null ? null : 300,
      wikidataId: wikidataId,
    );
  }

  group('getNearbyPlaces', () {
    test('calls geoSearch with zh, then wbgetentities, builds Place list',
        () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            geoDto(title: '清水寺', wikidataId: 'Q221716'),
            geoDto(title: '小学校', wikidataId: 'Q17219693'),
          ]);

      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q221716': const WikidataEntityDto(
              id: 'Q221716',
              p31ClassIds: ['Q5393308'], // temple → kept
            ),
            'Q17219693': const WikidataEntityDto(
              id: 'Q17219693',
              p31ClassIds: ['Q5358913'], // elementary school → dropped
            ),
          });

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result, hasLength(1));
      expect(result.first.name, '清水寺');
      expect(result.first.id, 'wikidata:Q221716');
      expect(result.first.category, PlaceCategory.historicalCultural);
      expect(result.first.photos.first.url, 'https://img/x.jpg');

      verify(() => mockService.geoSearch(
            lat: 25.0336,
            lon: 121.5644,
            radiusMeters: 1000.0,
            wikiLang: 'zh',
          )).called(1);
    });

    test('skips results with no wikidata id', () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            const WikiGeoSearchResultDto(
              pageId: 1,
              title: 'orphan',
              lat: 0,
              lon: 0,
              // no wikidataId
            ),
          ]);
      when(() => mockService.fetchEntities(any()))
          .thenAnswer((_) async => {});

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result, isEmpty);
    });

    test('Place.photos is empty when no thumbnail', () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            geoDto(title: 't', wikidataId: 'Q1', thumb: null),
          ]);
      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q1': const WikidataEntityDto(id: 'Q1', p31ClassIds: ['Q33506']),
          });

      final result = await repository.getNearbyPlaces(
          testLocation, language: testLanguage, radius: testRadius);

      expect(result.first.photos, isEmpty);
    });
  });
}
