import 'dart:io';

import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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
      language: const Language('zh-TW'),
    ),
    narrationAspect: NarrationAspect.historicalBackground,
    createdAt: DateTime(2026, 1, 1),
    language: const Language('zh-TW'),
  );
}

void main() {
  late HiveJourneyCacheService cacheService;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    cacheService = HiveJourneyCacheService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('HiveJourneyCacheService', () {
    group('getEntries', () {
      test('returns null when no cache exists', () async {
        final result = await cacheService.getEntries('user-1');

        expect(result, isNull);
      });

      test('returns entries after saveEntries roundtrip', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        final entry2 = _createTestEntry('entry-2', 'user-1');

        await cacheService.saveEntries('user-1', [entry1, entry2]);
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result[0].id, 'entry-1');
        expect(result[1].id, 'entry-2');
      });

      test('returns entries with correct field values after roundtrip', () async {
        final entry = _createTestEntry('entry-1', 'user-1');

        await cacheService.saveEntries('user-1', [entry]);
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        final retrieved = result!.first;
        expect(retrieved.id, entry.id);
        expect(retrieved.userId, entry.userId);
        expect(retrieved.place.name, entry.place.name);
        expect(retrieved.narrationContent.text, entry.narrationContent.text);
        expect(retrieved.narrationAspect, entry.narrationAspect);
        expect(retrieved.createdAt, entry.createdAt);
      });
    });

    group('user isolation', () {
      test('different userIds do not interfere with each other', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        final entry2 = _createTestEntry('entry-2', 'user-2');

        await cacheService.saveEntries('user-1', [entry1]);
        await cacheService.saveEntries('user-2', [entry2]);

        final result1 = await cacheService.getEntries('user-1');
        final result2 = await cacheService.getEntries('user-2');

        expect(result1, isNotNull);
        expect(result1!.length, 1);
        expect(result1.first.id, 'entry-1');

        expect(result2, isNotNull);
        expect(result2!.length, 1);
        expect(result2.first.id, 'entry-2');
      });

      test('getEntries for unknown userId returns null', () async {
        final entry = _createTestEntry('entry-1', 'user-1');
        await cacheService.saveEntries('user-1', [entry]);

        final result = await cacheService.getEntries('user-999');

        expect(result, isNull);
      });
    });

    group('addEntry', () {
      test('inserts new entry at list head', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        final entry2 = _createTestEntry('entry-2', 'user-1');
        await cacheService.saveEntries('user-1', [entry1]);

        await cacheService.addEntry('user-1', entry2);
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result.first.id, 'entry-2');
        expect(result.last.id, 'entry-1');
      });

      test('works with empty cache (no prior entries)', () async {
        final entry = _createTestEntry('entry-1', 'user-1');

        await cacheService.addEntry('user-1', entry);
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result.first.id, 'entry-1');
      });
    });

    group('removeEntry', () {
      test('removes specified entry from list', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        final entry2 = _createTestEntry('entry-2', 'user-1');
        await cacheService.saveEntries('user-1', [entry1, entry2]);

        await cacheService.removeEntry('user-1', 'entry-1');
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result.first.id, 'entry-2');
      });

      test('does nothing when no cache exists', () async {
        await cacheService.removeEntry('user-1', 'entry-1');
        final result = await cacheService.getEntries('user-1');

        expect(result, isNull);
      });

      test('leaves list intact when entryId not found', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        await cacheService.saveEntries('user-1', [entry1]);

        await cacheService.removeEntry('user-1', 'non-existent-id');
        final result = await cacheService.getEntries('user-1');

        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result.first.id, 'entry-1');
      });
    });

    group('clear', () {
      test('removes all cached data for all users', () async {
        final entry1 = _createTestEntry('entry-1', 'user-1');
        final entry2 = _createTestEntry('entry-2', 'user-2');
        await cacheService.saveEntries('user-1', [entry1]);
        await cacheService.saveEntries('user-2', [entry2]);

        await cacheService.clear();

        final result1 = await cacheService.getEntries('user-1');
        final result2 = await cacheService.getEntries('user-2');
        expect(result1, isNull);
        expect(result2, isNull);
      });
    });
  });
}
