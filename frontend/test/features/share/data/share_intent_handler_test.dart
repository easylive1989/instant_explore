import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/share/data/share_intent_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlacesRepository extends Mock implements PlacesRepository {}

void main() {
  late MockPlacesRepository mockRepository;
  late ShareIntentHandler handler;

  const testPlace = Place(
    id: 'ChIJ_1',
    name: '台北101',
    formattedAddress: '台北市信義區信義路五段7號',
    location: PlaceLocation(latitude: 25.03, longitude: 121.56),
    types: ['tourist_attraction'],
    photos: [],
    category: PlaceCategory.modernUrban,
  );

  setUp(() {
    mockRepository = MockPlacesRepository();
    handler = ShareIntentHandler(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(const Language('zh-TW'));
  });

  group('ShareIntentHandler', () {
    test('resolves place from Google Maps share text', () async {
      when(() => mockRepository.searchPlaces(
            '台北101',
            language: any(named: 'language'),
          )).thenAnswer((_) async => [testPlace]);

      final result = await handler.resolveSharedText(
        '台北101\nhttps://maps.app.goo.gl/abc123',
        language: const Language('zh-TW'),
      );

      expect(result, isNotNull);
      expect(result!.name, '台北101');
      verify(() => mockRepository.searchPlaces(
            '台北101',
            language: any(named: 'language'),
          )).called(1);
    });

    test('returns null for non-Google Maps text', () async {
      final result = await handler.resolveSharedText(
        'Just some random text',
        language: const Language('zh-TW'),
      );

      expect(result, isNull);
      verifyNever(
          () => mockRepository.searchPlaces(
                any(),
                language: any(named: 'language'),
              ));
    });

    test('falls back to URL-derived name when no text before URL',
        () async {
      when(() => mockRepository.searchPlaces(
            'Taipei 101',
            language: any(named: 'language'),
          )).thenAnswer((_) async => [testPlace]);

      final result = await handler.resolveSharedText(
        'https://www.google.com/maps/place/Taipei+101/@25.03,121.56',
        language: const Language('en'),
      );

      expect(result, isNotNull);
      expect(result!.name, '台北101');
    });

    test('returns null when place not found', () async {
      when(() => mockRepository.searchPlaces(
            any(),
            language: any(named: 'language'),
          )).thenAnswer((_) async => []);

      final result = await handler.resolveSharedText(
        '不存在的地方\nhttps://maps.app.goo.gl/xyz',
        language: const Language('zh-TW'),
      );

      expect(result, isNull);
    });
  });
}
