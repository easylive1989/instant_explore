import 'dart:async';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateNarrationUseCase extends Mock
    implements CreateNarrationUseCase {}

class MockJourneyRepository extends Mock implements JourneyRepository {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  late PlayerController controller;
  late MockCreateNarrationUseCase mockUseCase;
  late MockJourneyRepository mockJourneyRepository;
  late MockTtsService mockTtsService;

  setUp(() {
    mockUseCase = MockCreateNarrationUseCase();
    mockJourneyRepository = MockJourneyRepository();
    mockTtsService = MockTtsService();

    when(() => mockTtsService.onComplete).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => mockTtsService.onStart).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(
      () => mockTtsService.onError,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockTtsService.onProgress).thenAnswer(
      (_) => const Stream.empty(),
    );

    controller = PlayerController(
      mockUseCase,
      mockJourneyRepository,
      mockTtsService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  const testPlace = Place(
    id: 'place-1',
    name: 'Test Place',
    formattedAddress: '123 Test St',
    location: PlaceLocation(latitude: 25.0, longitude: 121.0),
    types: [],
    photos: [],
    category: PlaceCategory.modernUrban,
  );

  final testContent = NarrationContent.create(
    '這是第一段。\n這是第二段。',
    language: Language.traditionalChinese,
  );

  group('initializeWithContent', () {
    test('使用已儲存內容，不重新生成導覽', () async {
      when(() => mockTtsService.initialize()).thenAnswer((_) async {});
      when(
        () => mockTtsService.setLanguage(any()),
      ).thenAnswer((_) async {});

      await controller.initializeWithContent(testPlace, testContent);

      verifyNever(
        () => mockUseCase.execute(
          place: any(named: 'place'),
          aspect: any(named: 'aspect'),
          language: any(named: 'language'),
        ),
      );
    });

    test('初始化後狀態為 ready', () async {
      when(() => mockTtsService.initialize()).thenAnswer((_) async {});
      when(
        () => mockTtsService.setLanguage(any()),
      ).thenAnswer((_) async {});

      await controller.initializeWithContent(testPlace, testContent);

      expect(controller.state.isReady, isTrue);
      expect(controller.state.content, equals(testContent));
      expect(controller.state.place, equals(testPlace));
    });

    test('以內容語言初始化 TTS', () async {
      when(() => mockTtsService.initialize()).thenAnswer((_) async {});
      when(
        () => mockTtsService.setLanguage(any()),
      ).thenAnswer((_) async {});

      await controller.initializeWithContent(testPlace, testContent);

      verify(
        () => mockTtsService.setLanguage(testContent.language),
      ).called(1);
    });
  });
}
