import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:context_app/features/narration/domain/services/narration_service_exception.dart';
import 'package:context_app/features/narration/domain/services/narration_service_error_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

// Mock classes
class MockNarrationService extends Mock implements NarrationService {}

// Fake class for Place (required for mocktail any() matcher)
class FakePlace extends Fake implements Place {}

// Fake class for Language
class FakeLanguage extends Fake implements Language {}

void main() {
  late CreateNarrationUseCase useCase;
  late MockNarrationService mockNarrationService;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakePlace());
    registerFallbackValue(NarrationAspect.historicalBackground);
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockNarrationService = MockNarrationService();
    useCase = CreateNarrationUseCase(mockNarrationService);
  });

  group('StartNarrationUseCase', () {
    final testPlace = Place(
      id: 'test-place-id',
      name: 'Test Place',
      formattedAddress: '123 Test St, Test City',
      location: PlaceLocation(latitude: 25.0, longitude: 121.0),
      types: const ['tourist_attraction'],
      photos: const [],
      category: PlaceCategory.historicalCultural,
    );

    const testGeneratedText = '''
這是一個測試地點。這裡有豐富的歷史。
許多遊客來到這裡參觀。這是一個著名的景點。
''';

    test(
      'should successfully generate narration and create NarrationContent',
      () async {
        // Arrange - Service now returns String
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => testGeneratedText);

        // Act
        final result = await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        );

        // Assert
        expect(result, isA<NarrationContent>());
        expect(result.text, equals(testGeneratedText));
        expect(result.segments.length, greaterThan(0));

        // Verify method calls
        verify(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).called(1);
      },
    );

    test(
      'should successfully generate narration with architecture aspect',
      () async {
        // Arrange
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.architecture,
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => testGeneratedText);

        // Act
        final result = await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.architecture,
          language: Language.english,
        );

        // Assert
        expect(result, isA<NarrationContent>());

        verify(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.architecture,
            language: any(named: 'language'),
          ),
        ).called(1);
      },
    );

    test('should throw NarrationException when text is empty', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => '');

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        ),
        throwsA(isA<NarrationContentException>()),
      );
    });

    test('should throw NarrationException when text is too short', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => '短');

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        ),
        throwsA(isA<NarrationContentException>()),
      );
    });

    test('should rethrow NarrationServiceException from service', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenThrow(
        NarrationServiceException.quotaExceeded(rawMessage: 'Quota exceeded'),
      );

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        ),
        throwsA(isA<NarrationServiceException>()),
      );
    });

    test(
      'should rethrow NarrationServiceException with correct error type',
      () async {
        // Arrange
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).thenThrow(
          NarrationServiceException.unsupportedLocation(
            rawMessage: 'Location not supported',
          ),
        );

        // Act & Assert
        try {
          await useCase.execute(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: Language.traditionalChinese,
          );
          fail('Should have thrown');
        } on NarrationServiceException catch (e) {
          expect(e.type, equals(NarrationServiceErrorType.unsupportedLocation));
        }
      },
    );

    test('should correctly split text into segments', () async {
      // Arrange
      const textWithMultipleSegments = '''
第一句話。第二句話！第三句話？
第四句話。
''';

      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => textWithMultipleSegments);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      // Assert
      expect(result.segments.length, equals(4));
      expect(result.segments[0].text, equals('第一句話。'));
      expect(result.segments[1].text, equals('第二句話！'));
      expect(result.segments[2].text, equals('第三句話？'));
      expect(result.segments[3].text, equals('第四句話。'));
    });
  });
}
