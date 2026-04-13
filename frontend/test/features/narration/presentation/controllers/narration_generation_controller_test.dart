import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeUsageRepository implements UsageRepository {
  @override
  Future<UsageStatus> getUsageStatus() async =>
      const UsageStatus(usedToday: 0, dailyFreeLimit: 3);

  @override
  Future<void> consumeUsage() async {}

  @override
  Future<void> addBonusFromAd() async {}
}

class _SpyNarrationService implements NarrationService {
  bool called = false;
  final String? textToReturn;

  _SpyNarrationService({this.textToReturn});

  @override
  Future<String> generateNarration({
    required Place place,
    required Set<NarrationAspect> aspects,
    required Language language,
  }) async {
    called = true;
    if (textToReturn == null) {
      throw const AppError(
        type: NarrationError.serverError,
        message: 'spy: no text configured',
      );
    }
    return textToReturn!;
  }
}

class _FakeJourneyRepository implements JourneyRepository {
  bool saveCalled = false;

  @override
  Future<List<JourneyEntry>> getAll() async => [];

  @override
  Future<void> save(JourneyEntry entry) async {
    saveCalled = true;
  }

  @override
  Future<void> delete(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _testPlace = Place(
  id: 'place-1',
  name: 'Test Place',
  formattedAddress: 'Test Address',
  location: PlaceLocation(latitude: 25.0, longitude: 121.0),
  types: [],
  photos: [],
  category: PlaceCategory.historicalCultural,
);

const _testNarrationText =
    '這是一個測試地點。這裡有豐富的歷史。許多遊客來到這裡參觀。這是一個著名的景點。';

NarrationGenerationController _makeController({
  _SpyNarrationService? narrationService,
  _FakeJourneyRepository? journeyRepository,
}) {
  final service = narrationService ?? _SpyNarrationService();
  final useCase = CreateNarrationUseCase(service, _FakeUsageRepository());
  return NarrationGenerationController(
    useCase,
    journeyRepository ?? _FakeJourneyRepository(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NarrationGenerationController.generate', () {
    test('成功生成後狀態為 success 且包含內容', () async {
      final controller = _makeController(
        narrationService: _SpyNarrationService(
          textToReturn: _testNarrationText,
        ),
      );

      await controller.generate(
        place: _testPlace,
        aspects: {NarrationAspect.historicalBackground},
        language: Language.traditionalChinese,
      );

      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.content, isNotNull);
      expect(controller.state.content!.text, _testNarrationText.trim());
    });

    test('生成失敗後狀態為 error', () async {
      final controller = _makeController(
        narrationService: _SpyNarrationService(),
      );

      await controller.generate(
        place: _testPlace,
        aspects: {NarrationAspect.historicalBackground},
        language: Language.traditionalChinese,
      );

      expect(controller.state.hasError, isTrue);
      expect(controller.state.errorType, isNotNull);
    });

    test('生成中狀態為 generating', () async {
      final controller = _makeController(
        narrationService: _SpyNarrationService(
          textToReturn: _testNarrationText,
        ),
      );

      final states = <NarrationGenerationStatus>[];
      // fireImmediately: false 避免收到初始狀態 idle
      controller.addListener(
        (state) {
          states.add(state.status);
        },
        fireImmediately: false,
      );

      await controller.generate(
        place: _testPlace,
        aspects: {NarrationAspect.historicalBackground},
        language: Language.traditionalChinese,
      );

      expect(states.first, NarrationGenerationStatus.generating);
    });

    test('成功生成後自動儲存到歷程', () async {
      final journeyRepo = _FakeJourneyRepository();
      final controller = _makeController(
        narrationService: _SpyNarrationService(
          textToReturn: _testNarrationText,
        ),
        journeyRepository: journeyRepo,
      );

      await controller.generate(
        place: _testPlace,
        aspects: {NarrationAspect.historicalBackground},
        language: Language.traditionalChinese,
      );

      expect(journeyRepo.saveCalled, isTrue);
    });
  });

  group('NarrationGenerationController.reset', () {
    test('重置後狀態為 idle', () async {
      final controller = _makeController(
        narrationService: _SpyNarrationService(
          textToReturn: _testNarrationText,
        ),
      );

      await controller.generate(
        place: _testPlace,
        aspects: {NarrationAspect.historicalBackground},
        language: Language.traditionalChinese,
      );
      expect(controller.state.isSuccess, isTrue);

      controller.reset();
      expect(controller.state.isIdle, isTrue);
      expect(controller.state.content, isNull);
    });
  });
}
