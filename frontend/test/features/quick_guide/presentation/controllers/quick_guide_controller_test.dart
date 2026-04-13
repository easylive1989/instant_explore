import 'dart:typed_data';

import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/domain/services/quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/domain/use_cases/generate_quick_guide_use_case.dart';
import 'package:context_app/features/quick_guide/presentation/controllers/quick_guide_controller.dart';
import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
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

class _FakeUsageRepository implements UsageRepository {
  bool hasQuota;
  int consumeCallCount = 0;

  _FakeUsageRepository({this.hasQuota = true});

  @override
  Future<UsageStatus> getUsageStatus() async => UsageStatus(
    usedToday: hasQuota ? 0 : 1,
    dailyFreeLimit: 1,
  );

  @override
  Future<void> consumeUsage() async => consumeCallCount++;

  @override
  Future<void> addBonusFromAd() async {}
}

class _FakeRepository implements QuickGuideRepository {
  final List<QuickGuideEntry> _entries = [];
  Exception? saveException;

  @override
  Future<List<QuickGuideEntry>> getAll() async =>
      List.unmodifiable(_entries);

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
// Helpers
// ---------------------------------------------------------------------------

int _idCounter = 0;
String _testIdGenerator() => 'test-id-${_idCounter++}';

QuickGuideController _makeController({
  String? aiResponse,
  Exception? aiException,
  Exception? saveException,
  bool hasQuota = true,
  _FakeUsageRepository? usageRepo,
  _FakeRepository? repo,
}) {
  final aiService = _FakeAiService(
    responseToReturn: aiResponse,
    exceptionToThrow: aiException,
  );
  final repository = repo ?? (_FakeRepository()..saveException = saveException);
  final usageRepository = usageRepo ?? _FakeUsageRepository(hasQuota: hasQuota);

  final useCase = GenerateQuickGuideUseCase(
    aiService,
    repository,
    usageRepository,
    _testIdGenerator,
  );

  return QuickGuideController(useCase);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final imageBytes = Uint8List.fromList([10, 20, 30]);

  setUp(() => _idCounter = 0);

  group('QuickGuideController.analyzeImage', () {
    test('sets status to success, saves entry, and consumes usage',
        () async {
      final usageRepo = _FakeUsageRepository();
      final repo = _FakeRepository();
      final controller = _makeController(
        aiResponse: 'A lovely temple.',
        usageRepo: usageRepo,
        repo: repo,
      );

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.success);
      expect(controller.state.aiDescription, 'A lovely temple.');
      expect(controller.state.imageBytes, imageBytes);
      expect(repo._entries.length, 1);
      expect(repo._entries.first.aiDescription, 'A lovely temple.');
      expect(usageRepo.consumeCallCount, 1);
    });

    test('sets status to quotaExceeded when daily limit is reached',
        () async {
      final controller = _makeController(
        aiResponse: 'desc',
        hasQuota: false,
      );

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.quotaExceeded);
      expect(controller.state.isQuotaExceeded, isTrue);
    });

    test('sets status to error when AI service throws', () async {
      final controller = _makeController(
        aiException: const QuickGuideAiException(
          type: QuickGuideAiErrorType.network,
          message: 'no connection',
        ),
      );

      await controller.analyzeImage(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'zh-TW',
      );

      expect(controller.state.status, QuickGuideStatus.error);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('sets status to error when repository throws', () async {
      final controller = _makeController(
        aiResponse: 'desc',
        saveException: Exception('disk full'),
      );

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
      final controller = _makeController(aiResponse: 'desc');
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
      final controller = _makeController(aiResponse: 'desc');

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
