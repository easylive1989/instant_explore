import 'dart:async';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
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

/// NarrationService that records whether it was called.
///
/// When [textToReturn] is null, throws [AppError] with
/// [NarrationError.serverError] to let [PlayerController] catch it and
/// transition to an error state.
class _SpyNarrationService implements NarrationService {
  bool called = false;
  final String? textToReturn;

  _SpyNarrationService({this.textToReturn});

  @override
  Future<String> generateNarration({
    required Place place,
    required NarrationAspect aspect,
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
  @override
  Future<List<JourneyEntry>> getAll() async => [];

  @override
  Future<void> save(JourneyEntry entry) async {}

  @override
  Future<void> delete(String id) async {}
}

/// Minimal TtsService fake that records calls and exposes controllable streams.
class _FakeTtsService implements TtsService {
  bool initializeCalled = false;
  Language? lastLanguageSet;

  final _completeController = StreamController<void>.broadcast();
  final _startController = StreamController<void>.broadcast();
  final _pauseController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _progressController = StreamController<TtsProgress>.broadcast();

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<void> setLanguage(Language language) async {
    lastLanguageSet = language;
  }

  @override
  Future<bool> speak(String text) async => true;

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _completeController.close();
    await _startController.close();
    await _pauseController.close();
    await _errorController.close();
    await _progressController.close();
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<List<dynamic>> getLanguages() async => [];

  @override
  Future<List<dynamic>> getVoices() async => [];

  @override
  Future<bool> isPlaying() async => false;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Stream<void> get onStart => _startController.stream;

  @override
  Stream<void> get onPause => _pauseController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  Stream<TtsProgress> get onProgress => _progressController.stream;
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

PlayerController _makeController({
  _SpyNarrationService? narrationService,
  _FakeTtsService? ttsService,
}) {
  final service = narrationService ?? _SpyNarrationService();
  final useCase = CreateNarrationUseCase(service, _FakeUsageRepository());
  return PlayerController(useCase, _FakeJourneyRepository(), ttsService ?? _FakeTtsService());
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PlayerController.initializeWithContent', () {
    test('使用現有內容初始化，不呼叫 AI 生成', () async {
      final narrationService = _SpyNarrationService();
      final controller = _makeController(narrationService: narrationService);

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(
        narrationService.called,
        isFalse,
        reason: '回放已儲存的導覽時，不應呼叫 AI 服務重新生成',
      );
    });

    test('初始化後狀態為 ready', () async {
      final controller = _makeController();

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(controller.state.isReady, isTrue);
    });

    test('狀態包含正確的內容和地點', () async {
      final controller = _makeController();

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(controller.state.content, equals(content));
      expect(controller.state.place, equals(_testPlace));
    });

    test('aspect 為 null（回放模式不帶面向）', () async {
      final controller = _makeController();

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(
        controller.state.aspect,
        isNull,
        reason: '從 Journey 卡片回放時不應帶有 aspect',
      );
    });

    test('初始化 TtsService 並設定語言', () async {
      final ttsService = _FakeTtsService();
      final controller = _makeController(ttsService: ttsService);

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(ttsService.initializeCalled, isTrue);
      expect(ttsService.lastLanguageSet, equals(Language.traditionalChinese));
    });

    test('載入後清除先前的錯誤狀態', () async {
      // Arrange: first put the controller into an error state via initialize
      // (use case throws because narration service is not set up to return)
      final failingService = _SpyNarrationService();
      final useCase = CreateNarrationUseCase(failingService, _FakeUsageRepository());
      final controller = PlayerController(
        useCase,
        _FakeJourneyRepository(),
        _FakeTtsService(),
      );

      // Trigger error via initialize (service.called = true but throws)
      await controller.initialize(
        _testPlace,
        NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );
      expect(controller.state.hasError, isTrue);

      // Act: replay from journey card
      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );
      await controller.initializeWithContent(_testPlace, content);

      // Assert: error is cleared
      expect(controller.state.hasError, isFalse);
      expect(controller.state.errorType, isNull);
      expect(controller.state.isReady, isTrue);
    });
  });

  group('PlayerController.initialize', () {
    test('呼叫 AI 服務生成新導覽', () async {
      final narrationService = _SpyNarrationService(
        textToReturn: _testNarrationText,
      );
      final useCase = CreateNarrationUseCase(
        narrationService,
        _FakeUsageRepository(),
      );
      final controller = PlayerController(
        useCase,
        _FakeJourneyRepository(),
        _FakeTtsService(),
      );

      await controller.initialize(
        _testPlace,
        NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      expect(
        narrationService.called,
        isTrue,
        reason: '生成新導覽時應呼叫 AI 服務',
      );
      expect(controller.state.isReady, isTrue);
    });
  });
}
