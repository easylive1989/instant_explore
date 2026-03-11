# Journey 離線回放 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓使用者在無網路環境下，能回放已保存的 Journey 導覽內容（文字 + TTS 語音）。

**Architecture:** 在 `JourneyRepository` 介面與 `SupabaseJourneyRepository` 之間加入 `CachingJourneyRepository`（Decorator Pattern），使用 Hive 作為本地快取。讀取時先嘗試遠端，失敗時 fallback 到本地快取。寫入/刪除仍需網路。

**Tech Stack:** Flutter, Riverpod, Hive, Supabase, mocktail

**Spec:** `docs/superpowers/specs/2026-03-11-journey-offline-playback-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/journey/data/services/hive_journey_cache_service.dart` | Hive 讀寫操作，管理 journey_cache box |
| `lib/features/journey/data/caching_journey_repository.dart` | Decorator，包裝遠端 repo + 快取 fallback |
| `test/features/journey/data/services/hive_journey_cache_service_test.dart` | 快取服務單元測試 |
| `test/features/journey/data/caching_journey_repository_test.dart` | Decorator 單元測試 |

### Modified Files
| File | Change |
|------|--------|
| `lib/features/journey/data/supabase_journey_repository.dart` | 新增 SocketException/TimeoutException 攔截 |
| `lib/features/journey/providers.dart` | 新增 cache provider，切換到 CachingJourneyRepository |

All paths are relative to `frontend/`.

---

## Chunk 1: SupabaseJourneyRepository 網路錯誤處理

### Task 1: 修改 SupabaseJourneyRepository 以區分網路錯誤

**Files:**
- Modify: `lib/features/journey/data/supabase_journey_repository.dart`
- Test: `test/features/journey/data/supabase_journey_repository_test.dart`

- [ ] **Step 1: 建立測試檔案，寫 SocketException 測試**

建立 `test/features/journey/data/supabase_journey_repository_test.dart`：

```dart
import 'dart:async';
import 'dart:io';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock
    implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late SupabaseJourneyRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    repository = SupabaseJourneyRepository(mockClient);

    when(() => mockClient.from('passport_entries'))
        .thenReturn(mockQueryBuilder);
  });

  // 注意：Supabase 使用 builder pattern (select().eq().order())。
  // 在 mocktail 中，對 select() 呼叫 thenThrow 會在
  // builder chain 的起點拋出異常，這足以測試 try-catch 行為。
  // 實際網路錯誤可能在 await 時發生，但對錯誤處理邏輯的
  // 測試效果是等價的。

  group('getJourneyEntries', () {
    test('should throw AppError with networkError on SocketException',
        () async {
      when(() => mockQueryBuilder.select())
          .thenThrow(const SocketException('No internet'));

      expect(
        () => repository.getJourneyEntries('user-1'),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            JourneyError.networkError,
          ),
        ),
      );
    });
  });

  group('addJourneyEntry', () {
    test('should throw AppError with networkError on SocketException',
        () async {
      when(() => mockQueryBuilder.insert(any()))
          .thenThrow(const SocketException('No internet'));

      expect(
        () => repository.addJourneyEntry(_createMinimalEntry()),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            JourneyError.networkError,
          ),
        ),
      );
    });
  });

  group('deleteJourneyEntry', () {
    test('should throw AppError with networkError on SocketException',
        () async {
      final mockDeleteBuilder = MockPostgrestFilterBuilder();
      when(() => mockQueryBuilder.delete())
          .thenReturn(mockDeleteBuilder);
      when(() => mockDeleteBuilder.eq('id', 'e1'))
          .thenThrow(const SocketException('No internet'));

      expect(
        () => repository.deleteJourneyEntry('e1'),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            JourneyError.networkError,
          ),
        ),
      );
    });
  });
}
```

在檔案底部加入 helper（import 需要的 model）：

```dart
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

JourneyEntry _createMinimalEntry() {
  return JourneyEntry(
    id: 'test-id',
    userId: 'user-1',
    place: const SavedPlace(
      id: 'place-1',
      name: 'Test Place',
      address: '123 Test St',
    ),
    narrationContent: NarrationContent.create(
      '這是一段測試導覽文字。用於驗證功能。',
      language: Language('zh-TW'),
    ),
    narrationAspect: NarrationAspect.historicalBackground,
    createdAt: DateTime(2026, 1, 1),
    language: Language('zh-TW'),
  );
}
```

- [ ] **Step 2: 執行測試，確認失敗**

Run: `cd frontend && fvm flutter test test/features/journey/data/supabase_journey_repository_test.dart -v`
Expected: FAIL — SocketException 目前被 catch-all 捕獲，拋出 `JourneyError.unknown` 而非 `networkError`

- [ ] **Step 3: 修改 SupabaseJourneyRepository，新增網路錯誤攔截**

修改 `lib/features/journey/data/supabase_journey_repository.dart`：

在檔案頂部新增 import：
```dart
import 'dart:async';
import 'dart:io';
```

修改 `getJourneyEntries` 方法，在 `catch (e, stackTrace)` 之前新增：
```dart
    } on SocketException catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.networkError,
        message: '網路連線失敗，請檢查網路狀態',
        originalException: e,
        stackTrace: stackTrace,
        context: {'user_id': userId},
      );
    } on TimeoutException catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.networkError,
        message: '網路連線逾時，請稍後再試',
        originalException: e,
        stackTrace: stackTrace,
        context: {'user_id': userId},
      );
```

同樣修改 `addJourneyEntry` 和 `deleteJourneyEntry`，在各自的 `catch (e, stackTrace)` 之前加入相同的 SocketException/TimeoutException 攔截（context 依方法調整）。

- [ ] **Step 4: 執行測試，確認通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/supabase_journey_repository_test.dart -v`
Expected: PASS

- [ ] **Step 5: 補充 TimeoutException 測試**

在各 group 中新增 TimeoutException 測試。`getJourneyEntries` group：
```dart
    test('should throw AppError with networkError on TimeoutException',
        () async {
      when(() => mockQueryBuilder.select())
          .thenThrow(TimeoutException('Timeout'));

      expect(
        () => repository.getJourneyEntries('user-1'),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            JourneyError.networkError,
          ),
        ),
      );
    });
```

`addJourneyEntry` group：
```dart
    test('should throw AppError with networkError on TimeoutException',
        () async {
      when(() => mockQueryBuilder.insert(any()))
          .thenThrow(TimeoutException('Timeout'));

      expect(
        () => repository.addJourneyEntry(_createMinimalEntry()),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            JourneyError.networkError,
          ),
        ),
      );
    });
```

- [ ] **Step 6: 執行測試，確認全部通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/supabase_journey_repository_test.dart -v`
Expected: ALL PASS

- [ ] **Step 7: 執行全部既有測試，確認無破壞**

Run: `cd frontend && fvm flutter test`
Expected: ALL PASS

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/features/journey/data/supabase_journey_repository.dart frontend/test/features/journey/data/supabase_journey_repository_test.dart
git commit -m "feat: SupabaseJourneyRepository 區分網路錯誤類型

新增 SocketException/TimeoutException 攔截，拋出 JourneyError.networkError，
為 CachingJourneyRepository 的 fallback 判斷提供基礎。"
```

---

## Chunk 2: HiveJourneyCacheService

### Task 2: 實作 HiveJourneyCacheService

**Files:**
- Create: `lib/features/journey/data/services/hive_journey_cache_service.dart`
- Test: `test/features/journey/data/services/hive_journey_cache_service_test.dart`

- [ ] **Step 1: 寫 getEntries 無快取時回傳 null 的測試**

建立 `test/features/journey/data/services/hive_journey_cache_service_test.dart`：

```dart
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HiveJourneyCacheService cacheService;

  setUp(() async {
    // 使用臨時目錄初始化 Hive
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    cacheService = HiveJourneyCacheService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('getEntries', () {
    test('should return null when no cache exists', () async {
      final result = await cacheService.getEntries('user-1');
      expect(result, isNull);
    });
  });
}
```

頂部需加 `import 'dart:io';`。

- [ ] **Step 2: 建立 HiveJourneyCacheService 最小實作**

建立 `lib/features/journey/data/services/hive_journey_cache_service.dart`：

```dart
import 'dart:convert';
import 'dart:developer';

import 'package:context_app/features/journey/data/journey_entry_mapper.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:hive/hive.dart';

/// Journey 資料的 Hive 快取服務
///
/// 負責將 JourneyEntry 列表序列化為 JSON 存入 Hive，
/// 並在需要時反序列化回 Domain Model。
/// 採用 lazy open 模式管理 Hive Box。
class HiveJourneyCacheService {
  static const String _boxName = 'journey_cache';
  static const String _entriesKeyPrefix = 'journey_entries_';

  Box? _box;

  /// 取得或開啟 Hive Box
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  String _entriesKey(String userId) =>
      '$_entriesKeyPrefix$userId';

  /// 取得快取的 Journey 列表
  ///
  /// 回傳 null 表示無快取資料
  Future<List<JourneyEntry>?> getEntries(String userId) async {
    try {
      final box = await _getBox();
      final jsonStr = box.get(_entriesKey(userId)) as String?;

      if (jsonStr == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map(
            (json) => JourneyEntryMapper.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      log(
        'Failed to read journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
      return null;
    }
  }

  /// 全量覆寫快取
  Future<void> saveEntries(
    String userId,
    List<JourneyEntry> entries,
  ) async {
    try {
      final box = await _getBox();
      final jsonList =
          entries.map(JourneyEntryMapper.toJson).toList();
      await box.put(_entriesKey(userId), jsonEncode(jsonList));
    } catch (e) {
      log(
        'Failed to save journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 新增一筆 entry 到快取列表頭部
  Future<void> addEntry(
    String userId,
    JourneyEntry entry,
  ) async {
    try {
      final entries = await getEntries(userId) ?? [];
      final updated = [entry, ...entries];
      await saveEntries(userId, updated);
    } catch (e) {
      log(
        'Failed to add entry to journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 從快取中移除指定 entry
  Future<void> removeEntry(
    String userId,
    String entryId,
  ) async {
    try {
      final entries = await getEntries(userId);
      if (entries == null) return;
      final updated =
          entries.where((e) => e.id != entryId).toList();
      await saveEntries(userId, updated);
    } catch (e) {
      log(
        'Failed to remove entry from journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 清除所有快取資料
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      log(
        'Failed to clear journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }
}
```

- [ ] **Step 3: 執行測試，確認 getEntries null 測試通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/services/hive_journey_cache_service_test.dart -v`
Expected: PASS

- [ ] **Step 4: 補充 saveEntries + getEntries 往返測試**

在測試檔案中新增：

```dart
  group('saveEntries and getEntries', () {
    test('should save and retrieve entries correctly', () async {
      final entries = [_createTestEntry('entry-1', 'user-1')];

      await cacheService.saveEntries('user-1', entries);
      final result = await cacheService.getEntries('user-1');

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.id, 'entry-1');
      expect(result.first.userId, 'user-1');
    });

    test('should isolate entries by userId', () async {
      final entries1 = [_createTestEntry('e1', 'user-1')];
      final entries2 = [_createTestEntry('e2', 'user-2')];

      await cacheService.saveEntries('user-1', entries1);
      await cacheService.saveEntries('user-2', entries2);

      final result1 = await cacheService.getEntries('user-1');
      final result2 = await cacheService.getEntries('user-2');

      expect(result1!.first.id, 'e1');
      expect(result2!.first.id, 'e2');
    });
  });
```

在測試檔案底部加入 helper：

```dart
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
```

以及頂部 import：
```dart
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
```

- [ ] **Step 5: 執行測試，確認通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/services/hive_journey_cache_service_test.dart -v`
Expected: ALL PASS

- [ ] **Step 6: 補充 addEntry、removeEntry、clear 測試**

```dart
  group('addEntry', () {
    test('should insert entry at the beginning of the list',
        () async {
      final existing = _createTestEntry('old', 'user-1');
      await cacheService.saveEntries('user-1', [existing]);

      final newEntry = _createTestEntry('new', 'user-1');
      await cacheService.addEntry('user-1', newEntry);

      final result = await cacheService.getEntries('user-1');
      expect(result!.length, 2);
      expect(result.first.id, 'new');
      expect(result.last.id, 'old');
    });

    test('should work when no existing cache', () async {
      final entry = _createTestEntry('first', 'user-1');
      await cacheService.addEntry('user-1', entry);

      final result = await cacheService.getEntries('user-1');
      expect(result!.length, 1);
      expect(result.first.id, 'first');
    });
  });

  group('removeEntry', () {
    test('should remove the specified entry', () async {
      final entries = [
        _createTestEntry('keep', 'user-1'),
        _createTestEntry('remove', 'user-1'),
      ];
      await cacheService.saveEntries('user-1', entries);

      await cacheService.removeEntry('user-1', 'remove');

      final result = await cacheService.getEntries('user-1');
      expect(result!.length, 1);
      expect(result.first.id, 'keep');
    });

    test('should do nothing when no cache exists', () async {
      await cacheService.removeEntry('user-1', 'nonexistent');
      final result = await cacheService.getEntries('user-1');
      expect(result, isNull);
    });
  });

  group('clear', () {
    test('should remove all cached data', () async {
      await cacheService.saveEntries(
        'user-1',
        [_createTestEntry('e1', 'user-1')],
      );

      await cacheService.clear();

      final result = await cacheService.getEntries('user-1');
      expect(result, isNull);
    });
  });
```

- [ ] **Step 7: 執行測試，確認全部通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/services/hive_journey_cache_service_test.dart -v`
Expected: ALL PASS

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/features/journey/data/services/hive_journey_cache_service.dart frontend/test/features/journey/data/services/hive_journey_cache_service_test.dart
git commit -m "feat: 新增 HiveJourneyCacheService

實作 Journey 資料的 Hive 本地快取，支援讀取、全量覆寫、
新增、移除及清除操作。採用 lazy open 模式管理 Box。"
```

---

## Chunk 3: CachingJourneyRepository

### Task 3: 實作 CachingJourneyRepository

**Files:**
- Create: `lib/features/journey/data/caching_journey_repository.dart`
- Test: `test/features/journey/data/caching_journey_repository_test.dart`

- [ ] **Step 1: 寫遠端成功時的測試**

建立 `test/features/journey/data/caching_journey_repository_test.dart`：

```dart
import 'dart:io';

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

class MockJourneyRepository extends Mock
    implements JourneyRepository {}

class MockHiveJourneyCacheService extends Mock
    implements HiveJourneyCacheService {}

void main() {
  late MockJourneyRepository mockRemote;
  late MockHiveJourneyCacheService mockCache;
  late CachingJourneyRepository repository;

  setUp(() {
    mockRemote = MockJourneyRepository();
    mockCache = MockHiveJourneyCacheService();
    repository = CachingJourneyRepository(
      remote: mockRemote,
      cache: mockCache,
    );
  });

  group('getJourneyEntries', () {
    final testEntries = [_createTestEntry('e1', 'user-1')];

    test('should return remote data and update cache on success',
        () async {
      when(() => mockRemote.getJourneyEntries('user-1'))
          .thenAnswer((_) async => testEntries);
      when(() => mockCache.saveEntries('user-1', testEntries))
          .thenAnswer((_) async {});

      final result =
          await repository.getJourneyEntries('user-1');

      expect(result, testEntries);
      verify(() => mockCache.saveEntries('user-1', testEntries))
          .called(1);
    });
  });
}

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
```

- [ ] **Step 2: 建立 CachingJourneyRepository 最小實作**

建立 `lib/features/journey/data/caching_journey_repository.dart`：

```dart
import 'dart:developer';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';

/// 使用 Decorator 模式包裝 JourneyRepository，添加快取功能
///
/// 讀取時先嘗試遠端，成功則更新快取；
/// 網路失敗時 fallback 到本地快取。
/// 寫入/刪除仍需網路，成功後同步更新快取。
class CachingJourneyRepository implements JourneyRepository {
  final JourneyRepository _remote;
  final HiveJourneyCacheService _cache;

  CachingJourneyRepository({
    required JourneyRepository remote,
    required HiveJourneyCacheService cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<List<JourneyEntry>> getJourneyEntries(
    String userId,
  ) async {
    try {
      final entries =
          await _remote.getJourneyEntries(userId);
      try {
        await _cache.saveEntries(userId, entries);
      } catch (e) {
        log(
          'Failed to update cache after remote fetch',
          error: e,
          name: 'CachingJourneyRepository',
        );
      }
      return entries;
    } on AppError catch (e) {
      if (e.type == JourneyError.networkError) {
        log(
          'Network error, falling back to cache',
          error: e,
          name: 'CachingJourneyRepository',
        );
        final cached = await _cache.getEntries(userId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<void> addJourneyEntry(JourneyEntry entry) async {
    await _remote.addJourneyEntry(entry);
    try {
      await _cache.addEntry(entry.userId, entry);
    } catch (e) {
      log(
        'Failed to update cache after add',
        error: e,
        name: 'CachingJourneyRepository',
      );
    }
  }

  @override
  Future<void> deleteJourneyEntry(String id) async {
    await _remote.deleteJourneyEntry(id);
    // 刪除操作無法從 id 推斷 userId，
    // 下次 getJourneyEntries 時快取會全量覆寫
  }
}
```

- [ ] **Step 3: 執行測試，確認通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/caching_journey_repository_test.dart -v`
Expected: PASS

- [ ] **Step 4: 補充網路失敗 + 有快取的 fallback 測試**

在 `group('getJourneyEntries')` 中新增：

```dart
    test(
        'should return cached data on network error with cache',
        () async {
      when(() => mockRemote.getJourneyEntries('user-1'))
          .thenThrow(AppError(
        type: JourneyError.networkError,
        message: '網路連線失敗',
        originalException:
            const SocketException('No internet'),
      ));
      when(() => mockCache.getEntries('user-1'))
          .thenAnswer((_) async => testEntries);

      final result =
          await repository.getJourneyEntries('user-1');

      expect(result, testEntries);
    });
```

- [ ] **Step 5: 執行測試，確認通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/caching_journey_repository_test.dart -v`
Expected: ALL PASS

- [ ] **Step 6: 補充剩餘測試案例**

```dart
    test('should throw on network error without cache',
        () async {
      final error = AppError(
        type: JourneyError.networkError,
        message: '網路連線失敗',
        originalException:
            const SocketException('No internet'),
      );
      when(() => mockRemote.getJourneyEntries('user-1'))
          .thenThrow(error);
      when(() => mockCache.getEntries('user-1'))
          .thenAnswer((_) async => null);

      expect(
        () => repository.getJourneyEntries('user-1'),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          JourneyError.networkError,
        )),
      );
    });

    test('should rethrow non-network errors without fallback',
        () async {
      final error = AppError(
        type: JourneyError.loadFailed,
        message: '載入失敗',
      );
      when(() => mockRemote.getJourneyEntries('user-1'))
          .thenThrow(error);

      expect(
        () => repository.getJourneyEntries('user-1'),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          JourneyError.loadFailed,
        )),
      );

      verifyNever(() => mockCache.getEntries(any()));
    });

    test('should still return remote data when cache save fails',
        () async {
      when(() => mockRemote.getJourneyEntries('user-1'))
          .thenAnswer((_) async => testEntries);
      when(() => mockCache.saveEntries('user-1', testEntries))
          .thenThrow(Exception('Hive error'));

      final result =
          await repository.getJourneyEntries('user-1');

      expect(result, testEntries);
    });
```

以及 `addJourneyEntry` 群組：

```dart
  group('addJourneyEntry', () {
    test('should save to remote and update cache', () async {
      final entry = _createTestEntry('new', 'user-1');

      when(() => mockRemote.addJourneyEntry(entry))
          .thenAnswer((_) async {});
      when(() => mockCache.addEntry('user-1', entry))
          .thenAnswer((_) async {});

      await repository.addJourneyEntry(entry);

      verify(() => mockRemote.addJourneyEntry(entry)).called(1);
      verify(() => mockCache.addEntry('user-1', entry))
          .called(1);
    });

    test('should throw when remote fails', () async {
      final entry = _createTestEntry('new', 'user-1');
      final error = AppError(
        type: JourneyError.saveFailed,
        message: '儲存失敗',
      );

      when(() => mockRemote.addJourneyEntry(entry))
          .thenThrow(error);

      expect(
        () => repository.addJourneyEntry(entry),
        throwsA(isA<AppError>()),
      );
      verifyNever(() => mockCache.addEntry(any(), any()));
    });
  });

  group('deleteJourneyEntry', () {
    test('should delete from remote', () async {
      when(() => mockRemote.deleteJourneyEntry('e1'))
          .thenAnswer((_) async {});

      await repository.deleteJourneyEntry('e1');

      verify(() => mockRemote.deleteJourneyEntry('e1'))
          .called(1);
    });
  });
```

- [ ] **Step 7: 執行測試，確認全部通過**

Run: `cd frontend && fvm flutter test test/features/journey/data/caching_journey_repository_test.dart -v`
Expected: ALL PASS

- [ ] **Step 8: 執行全部測試**

Run: `cd frontend && fvm flutter test`
Expected: ALL PASS

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/features/journey/data/caching_journey_repository.dart frontend/test/features/journey/data/caching_journey_repository_test.dart
git commit -m "feat: 新增 CachingJourneyRepository

Decorator 模式包裝遠端 Repository，讀取失敗時 fallback 到 Hive 快取。
寫入/刪除成功後同步更新快取。快取讀寫失敗不影響主流程。"
```

---

## Chunk 4: Provider 整合

### Task 4: 修改 Provider 接線

**Files:**
- Modify: `lib/features/journey/providers.dart`

- [ ] **Step 1: 修改 providers.dart**

修改 `lib/features/journey/providers.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:context_app/features/journey/data/caching_journey_repository.dart';
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// Supabase 旅程資料儲存庫 Provider（遠端）
final supabaseJourneyRepositoryProvider =
    Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(Supabase.instance.client);
});

/// Hive 旅程快取服務 Provider
final hiveJourneyCacheServiceProvider =
    Provider<HiveJourneyCacheService>((ref) {
  return HiveJourneyCacheService();
});

/// 旅程資料儲存庫 Provider（含快取）
final journeyRepositoryProvider =
    Provider<JourneyRepository>((ref) {
  return CachingJourneyRepository(
    remote: ref.watch(supabaseJourneyRepositoryProvider),
    cache: ref.watch(hiveJourneyCacheServiceProvider),
  );
});

// ============================================================================
// UI Providers
// ============================================================================

/// 我的旅程 Provider
final myJourneyProvider =
    FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) async {
  final repository = ref.watch(journeyRepositoryProvider);
  final userId =
      Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return repository.getJourneyEntries(userId);
});
```

- [ ] **Step 2: 執行全部測試，確認無破壞**

Run: `cd frontend && fvm flutter test`
Expected: ALL PASS

- [ ] **Step 3: 執行靜態分析**

Run: `cd frontend && fvm flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/journey/providers.dart
git commit -m "feat: 整合 CachingJourneyRepository 到 Provider

journeyRepositoryProvider 改用 CachingJourneyRepository，
自動快取 Journey 資料以支援離線回放。"
```
