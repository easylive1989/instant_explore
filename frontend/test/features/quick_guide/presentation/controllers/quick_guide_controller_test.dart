import 'dart:typed_data';

import 'package:context_app/features/quick_guide/data/quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/presentation/controllers/quick_guide_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAiService implements QuickGuideAiService {
  final String? responseToReturn;
  final Exception? exceptionToThrow;

  _FakeAiService({this.responseToReturn, this.exceptionToThrow});

  @override
  Future<String> describeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return responseToReturn ?? 'AI description';
  }
}

class _FakeRepository implements QuickGuideRepository {
  final List<QuickGuideEntry> _entries = [];
  Exception? saveException;

  @override
  Future<List<QuickGuideEntry>> getAll() async => List.unmodifiable(_entries);

  @override
  Future<void> save(QuickGuideEntry entry) async {
    if (saveException != null) throw saveException!;
    _entries.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final imageBytes = Uint8List.fromList([10, 20, 30]);

  group('QuickGuideController.analyzeImage', () {
    test('sets status to success with description on success', () async {
      final aiService = _FakeAiService(responseToReturn: 'A lovely temple.');
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.success);
      expect(controller.state.aiDescription, 'A lovely temple.');
      expect(controller.state.imageBytes, imageBytes);
      expect(controller.state.hasError, isFalse);
    });

    test('sets status to error when AI service throws', () async {
      final aiService = _FakeAiService(
        exceptionToThrow: QuickGuideAiException(
          type: QuickGuideAiErrorType.network,
          message: 'no connection',
        ),
      );
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.error);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('stores imageBytes in state while analyzing', () async {
      // Track the sequence of states
      final states = <QuickGuideState>[];
      final aiService = _FakeAiService(responseToReturn: 'desc');
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      controller.addListener(states.add, fireImmediately: false);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(states.first.status, QuickGuideStatus.analyzing);
      expect(states.first.imageBytes, imageBytes);
    });
  });

  group('QuickGuideController.saveToJourney', () {
    test('saves entry and sets status to saved', () async {
      final aiService = _FakeAiService(responseToReturn: 'Some description.');
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );
      await controller.saveToJourney(Language.traditionalChinese);

      expect(controller.state.status, QuickGuideStatus.saved);
      expect(controller.state.isSaved, isTrue);
      expect(repo._entries.length, 1);
      expect(repo._entries.first.aiDescription, 'Some description.');
    });

    test('does nothing when no image or description is available', () async {
      final aiService = _FakeAiService();
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      await controller.saveToJourney(Language.traditionalChinese);

      expect(controller.state.status, QuickGuideStatus.idle);
      expect(repo._entries, isEmpty);
    });

    test('sets error status when repository throws', () async {
      final aiService = _FakeAiService(responseToReturn: 'desc');
      final repo = _FakeRepository()
        ..saveException = Exception('disk full');
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );
      await controller.saveToJourney(Language.traditionalChinese);

      expect(controller.state.status, QuickGuideStatus.error);
      expect(controller.state.hasError, isTrue);
    });
  });

  group('QuickGuideController.reset', () {
    test('resets to idle state with no data', () async {
      final aiService = _FakeAiService(responseToReturn: 'desc');
      final repo = _FakeRepository();
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      controller.reset();

      expect(controller.state.status, QuickGuideStatus.idle);
      expect(controller.state.imageBytes, isNull);
      expect(controller.state.aiDescription, isNull);
      expect(controller.state.errorMessage, isNull);
    });
  });
}
