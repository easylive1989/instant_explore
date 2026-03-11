import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/data/caching_journey_repository.dart';
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockJourneyRepository extends Mock implements JourneyRepository {}

class MockHiveJourneyCacheService extends Mock
    implements HiveJourneyCacheService {}

JourneyEntry _createTestEntry(String id, String userId) {
  return JourneyEntry(
    id: id,
    userId: userId,
    place: const SavedPlace(
      id: 'place-1',
      name: 'Test Place',
      address: '123 Test St',
    ),
    narrationContent: NarrationContent.create(
      '這是一段測試導覽文字。用於驗證快取功能。',
      language: Language('zh-TW'),
    ),
    narrationAspect: NarrationAspect.historicalBackground,
    createdAt: DateTime(2026, 1, 1),
    language: Language('zh-TW'),
  );
}

void main() {
  late MockJourneyRepository mockRemote;
  late MockHiveJourneyCacheService mockCache;
  late CachingJourneyRepository sut;

  const userId = 'user-1';

  setUp(() {
    mockRemote = MockJourneyRepository();
    mockCache = MockHiveJourneyCacheService();
    sut = CachingJourneyRepository(
      remote: mockRemote,
      cache: mockCache,
    );
    registerFallbackValue(_createTestEntry('fallback', 'fallback'));
  });

  group('getJourneyEntries', () {
    test(
      '遠端成功時回傳遠端資料，並更新快取',
      () async {
        // Arrange
        final entries = [
          _createTestEntry('1', userId),
          _createTestEntry('2', userId),
        ];
        when(
          () => mockRemote.getJourneyEntries(userId),
        ).thenAnswer((_) async => entries);
        when(
          () => mockCache.saveEntries(userId, entries),
        ).thenAnswer((_) async {});

        // Act
        final result = await sut.getJourneyEntries(userId);

        // Assert
        expect(result, entries);
        verify(() => mockCache.saveEntries(userId, entries)).called(1);
      },
    );

    test(
      '遠端網路錯誤且有快取時，回傳快取資料',
      () async {
        // Arrange
        final cached = [_createTestEntry('cached-1', userId)];
        when(
          () => mockRemote.getJourneyEntries(userId),
        ).thenThrow(
          const AppError(
            type: JourneyError.networkError,
            message: 'Network error',
          ),
        );
        when(
          () => mockCache.getEntries(userId),
        ).thenAnswer((_) async => cached);

        // Act
        final result = await sut.getJourneyEntries(userId);

        // Assert
        expect(result, cached);
        verify(() => mockCache.getEntries(userId)).called(1);
      },
    );

    test(
      '遠端網路錯誤且無快取時，重新拋出錯誤',
      () async {
        // Arrange
        final networkError = const AppError(
          type: JourneyError.networkError,
          message: 'Network error',
        );
        when(
          () => mockRemote.getJourneyEntries(userId),
        ).thenThrow(networkError);
        when(
          () => mockCache.getEntries(userId),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => sut.getJourneyEntries(userId),
          throwsA(isA<AppError>()),
        );
      },
    );

    test(
      '遠端非網路錯誤時，重新拋出錯誤且不嘗試讀取快取',
      () async {
        // Arrange
        when(
          () => mockRemote.getJourneyEntries(userId),
        ).thenThrow(
          const AppError(
            type: JourneyError.loadFailed,
            message: 'Load failed',
          ),
        );

        // Act & Assert
        await expectLater(
          () => sut.getJourneyEntries(userId),
          throwsA(
            isA<AppError>().having(
              (e) => e.type,
              'type',
              JourneyError.loadFailed,
            ),
          ),
        );
        verifyNever(() => mockCache.getEntries(any()));
      },
    );

    test(
      '遠端成功但快取存儲失敗時，仍回傳遠端資料',
      () async {
        // Arrange
        final entries = [_createTestEntry('1', userId)];
        when(
          () => mockRemote.getJourneyEntries(userId),
        ).thenAnswer((_) async => entries);
        when(
          () => mockCache.saveEntries(userId, entries),
        ).thenThrow(Exception('Cache write failed'));

        // Act
        final result = await sut.getJourneyEntries(userId);

        // Assert
        expect(result, entries);
      },
    );
  });

  group('addJourneyEntry', () {
    test(
      '遠端成功後，呼叫 cache.addEntry',
      () async {
        // Arrange
        final entry = _createTestEntry('1', userId);
        when(
          () => mockRemote.addJourneyEntry(entry),
        ).thenAnswer((_) async {});
        when(
          () => mockCache.addEntry(userId, entry),
        ).thenAnswer((_) async {});

        // Act
        await sut.addJourneyEntry(entry);

        // Assert
        verify(() => mockCache.addEntry(userId, entry)).called(1);
      },
    );

    test(
      '遠端失敗時拋出例外，且不呼叫 cache.addEntry',
      () async {
        // Arrange
        final entry = _createTestEntry('1', userId);
        when(
          () => mockRemote.addJourneyEntry(entry),
        ).thenThrow(
          const AppError(
            type: JourneyError.saveFailed,
            message: 'Save failed',
          ),
        );

        // Act & Assert
        await expectLater(
          () => sut.addJourneyEntry(entry),
          throwsA(isA<AppError>()),
        );
        verifyNever(() => mockCache.addEntry(any(), any()));
      },
    );
  });

  group('deleteJourneyEntry', () {
    test(
      '遠端成功時，呼叫 remote.deleteJourneyEntry',
      () async {
        // Arrange
        const entryId = 'entry-1';
        when(
          () => mockRemote.deleteJourneyEntry(entryId),
        ).thenAnswer((_) async {});

        // Act
        await sut.deleteJourneyEntry(entryId);

        // Assert
        verify(() => mockRemote.deleteJourneyEntry(entryId)).called(1);
      },
    );
  });
}
