import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/core/services/gemini_service.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/models/playback_state.dart';
import 'package:context_app/features/player/application/start_narration_use_case.dart';

// Mock classes
class MockGeminiService extends Mock implements GeminiService {}

class MockTtsService extends Mock implements TtsService {}

// Fake class for Place (required for mocktail any() matcher)
class FakePlace extends Fake implements Place {}

// Fake class for NarrationStyle (required for mocktail any() matcher)
class FakeNarrationStyle extends Fake {}

void main() {
  late StartNarrationUseCase useCase;
  late MockGeminiService mockGeminiService;
  late MockTtsService mockTtsService;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakePlace());
    registerFallbackValue(NarrationStyle.brief);
  });

  setUp(() {
    mockGeminiService = MockGeminiService();
    mockTtsService = MockTtsService();
    useCase = StartNarrationUseCase(mockGeminiService, mockTtsService);
  });

  group('StartNarrationUseCase', () {
    final testPlace = Place(
      id: 'test-place-id',
      name: 'Test Place',
      formattedAddress: '123 Test St, Test City',
      location: PlaceLocation(latitude: 25.0, longitude: 121.0),
      types: const ['tourist_attraction'],
      photos: const [],
    );

    const testGeneratedText = '''
這是一個測試地點。這裡有豐富的歷史。
許多遊客來到這裡參觀。這是一個著名的景點。
''';

    test('should successfully generate narration with brief style', () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => testGeneratedText);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage('zh-TW'))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
        language: 'zh-TW',
      );

      // Assert
      expect(result.place, equals(testPlace));
      expect(result.style, equals(NarrationStyle.brief));
      expect(result.state, equals(PlaybackState.ready));
      expect(result.content, isNotNull);
      expect(result.content!.text, equals(testGeneratedText));
      expect(result.content!.segments.length, greaterThan(0));
      expect(result.duration, greaterThan(0));

      // Verify method calls
      verify(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).called(1);
      verify(() => mockTtsService.initialize()).called(1);
      verify(() => mockTtsService.setLanguage('zh-TW')).called(1);
    });

    test('should successfully generate narration with deepDive style',
        () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.deepDive,
            language: 'en-US',
          )).thenAnswer((_) async => testGeneratedText);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage('en-US'))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.deepDive,
        language: 'en-US',
      );

      // Assert
      expect(result.place, equals(testPlace));
      expect(result.style, equals(NarrationStyle.deepDive));
      expect(result.state, equals(PlaybackState.ready));
      expect(result.content, isNotNull);

      verify(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.deepDive,
            language: 'en-US',
          )).called(1);
      verify(() => mockTtsService.setLanguage('en-US')).called(1);
    });

    test('should throw NarrationGenerationException when generated text is empty',
        () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => '');

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          style: NarrationStyle.brief,
          language: 'zh-TW',
        ),
        throwsA(isA<NarrationGenerationException>()),
      );
    });

    test(
        'should throw NarrationGenerationException when GeminiService throws error',
        () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenThrow(Exception('Network error'));

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          style: NarrationStyle.brief,
          language: 'zh-TW',
        ),
        throwsA(isA<NarrationGenerationException>()),
      );
    });

    test('should throw NarrationGenerationException when TtsService fails',
        () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => testGeneratedText);

      when(() => mockTtsService.initialize()).thenThrow(
        Exception('TTS initialization failed'),
      );

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          style: NarrationStyle.brief,
          language: 'zh-TW',
        ),
        throwsA(isA<NarrationGenerationException>()),
      );
    });

    test('should use default language zh-TW when not specified', () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => testGeneratedText);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage('zh-TW'))
          .thenAnswer((_) async => {});

      // Act
      await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
        // language not specified, should use default 'zh-TW'
      );

      // Assert
      verify(() => mockTtsService.setLanguage('zh-TW')).called(1);
    });

    test('should create unique narration ID for each execution', () async {
      // Arrange
      when(() => mockGeminiService.generateNarration(
            place: any(named: 'place'),
            style: any(named: 'style'),
            language: any(named: 'language'),
          )).thenAnswer((_) async => testGeneratedText);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage(any()))
          .thenAnswer((_) async => {});

      // Act
      final result1 = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
      );
      final result2 = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
      );

      // Assert
      expect(result1.id, isNotEmpty);
      expect(result2.id, isNotEmpty);
      expect(result1.id, isNot(equals(result2.id)));
    });

    test('should correctly split text into segments', () async {
      // Arrange
      const textWithMultipleSegments = '''
第一句話。第二句話！第三句話？
第四句話。
''';

      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => textWithMultipleSegments);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage('zh-TW'))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
        language: 'zh-TW',
      );

      // Assert
      expect(result.content!.segments.length, equals(4));
      expect(result.content!.segments[0], equals('第一句話。'));
      expect(result.content!.segments[1], equals('第二句話！'));
      expect(result.content!.segments[2], equals('第三句話？'));
      expect(result.content!.segments[3], equals('第四句話。'));
    });

    test('should estimate duration based on text length', () async {
      // Arrange
      const shortText = '這是短文本。'; // ~6 characters
      final longText = '這' * 100; // 100 characters

      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.brief,
            language: 'zh-TW',
          )).thenAnswer((_) async => shortText);

      when(() => mockTtsService.initialize()).thenAnswer((_) async => {});
      when(() => mockTtsService.setLanguage(any()))
          .thenAnswer((_) async => {});

      // Act
      final resultShort = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.brief,
      );

      when(() => mockGeminiService.generateNarration(
            place: testPlace,
            style: NarrationStyle.deepDive,
            language: 'zh-TW',
          )).thenAnswer((_) async => longText);

      final resultLong = await useCase.execute(
        place: testPlace,
        style: NarrationStyle.deepDive,
      );

      // Assert - longer text should have longer duration
      expect(resultLong.duration, greaterThan(resultShort.duration));
    });
  });
}
