import 'dart:async';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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

PlayerController _makeController({_FakeTtsService? ttsService}) {
  return PlayerController(ttsService ?? _FakeTtsService());
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PlayerController.initializeWithContent', () {
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

    test('aspect 為 null（播放模式不帶面向）', () async {
      final controller = _makeController();

      final content = NarrationContent.create(
        _testNarrationText,
        language: Language.traditionalChinese,
      );

      await controller.initializeWithContent(_testPlace, content);

      expect(controller.state.aspect, isNull);
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
  });
}
