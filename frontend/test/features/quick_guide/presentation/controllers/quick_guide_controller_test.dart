import 'dart:typed_data';

import 'package:context_app/features/quick_guide/data/quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/presentation/controllers/quick_guide_controller.dart';
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
    test('sets status to success and saves entry to journey', () async {
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
      expect(repo._entries.length, 1);
      expect(repo._entries.first.aiDescription, 'A lovely temple.');
    });

    test('sets status to error when AI service throws', () async {
      final aiService = _FakeAiService(
        exceptionToThrow: const QuickGuideAiException(
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
      expect(repo._entries, isEmpty);
    });

    test('sets status to error when repository throws', () async {
      final aiService = _FakeAiService(responseToReturn: 'desc');
      final repo = _FakeRepository()..saveException = Exception('disk full');
      final controller = QuickGuideController(aiService, repo);

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.error);
      expect(controller.state.hasError, isTrue);
    });

    test('stores imageBytes in state while analyzing', () async {
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
