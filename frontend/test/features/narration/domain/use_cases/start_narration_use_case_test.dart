import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/start_narration_use_case.dart';
import 'package:context_app/core/domain/models/language.dart';

// Mock classes
class MockNarrationService extends Mock implements NarrationService {}

// Fake class for Place (required for mocktail any() matcher)
class FakePlace extends Fake implements Place {}

// Fake class for Language
class FakeLanguage extends Fake implements Language {}

void main() {
  late StartNarrationUseCase useCase;
  late MockNarrationService mockNarrationService;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakePlace());
    registerFallbackValue(NarrationAspect.historicalBackground);
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockNarrationService = MockNarrationService();
    useCase = StartNarrationUseCase(mockNarrationService);
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

    final testContent = NarrationContent.fromText(testGeneratedText);

    test('should successfully generate narration', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testContent);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: 'zh-TW',
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
    });

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
        ).thenAnswer((_) async => testContent);

        // Act
        final result = await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.architecture,
          language: 'en-US',
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

    test(
      'should throw NarrationGenerationException when service throws error for empty content',
      () async {
        // Arrange
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).thenThrow(Exception('Generated narration is empty'));

        // Act & Assert
        expect(
          () => useCase.execute(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: 'zh-TW',
          ),
          throwsA(isA<NarrationGenerationException>()),
        );
      },
    );

    test(
      'should throw NarrationGenerationException when NarrationService throws error',
      () async {
        // Arrange
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase.execute(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: 'zh-TW',
          ),
          throwsA(isA<NarrationGenerationException>()),
        );
      },
    );

    test('should use default language zh-TW when not specified', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testContent);

      // Act
      await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        // language not specified, should use default 'zh-TW'
      );

      // Assert
      verify(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.fromString('zh-TW'),
        ),
      ).called(1);
    });

    test('should correctly split text into segments', () async {
      // Arrange
      const textWithMultipleSegments = '''
第一句話。第二句話！第三句話？
第四句話。
''';

      final segmentedContent =
          NarrationContent.fromText(textWithMultipleSegments);

      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => segmentedContent);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: 'zh-TW',
      );

      // Assert
      expect(result.segments.length, equals(4));
      expect(result.segments[0], equals('第一句話。'));
      expect(result.segments[1], equals('第二句話！'));
      expect(result.segments[2], equals('第三句話？'));
      expect(result.segments[3], equals('第四句話。'));
    });

    test('should estimate duration based on text length', () async {
      // Arrange
      const shortText = '這是短文本。'; // ~6 characters
      final longText = '這' * 100; // 100 characters

      final shortContent = NarrationContent.fromText(shortText);
      final longContent = NarrationContent.fromText(longText);

      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => shortContent);

      // Act
      final resultShort = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
      );

      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.architecture,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => longContent);

      final resultLong = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.architecture,
      );

      // Assert - longer text should have longer estimated duration
      expect(
        resultLong.estimatedDuration,
        greaterThan(resultShort.estimatedDuration),
      );
    });
  });
}
