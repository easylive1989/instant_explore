# Journey 離線化設計文件（Hive 本地儲存）

**日期：** 2026-03-22
**狀態：** 已核准

---

## 概述

移除 Journey（旅程歷程）功能對 Supabase 的依賴，改為純 Hive 本地儲存，讓所有使用者（無論是否登入）都能自由使用 Journey 功能。

---

## 架構

採用現有 Feature-First + Clean Architecture 架構，只替換 data 層，保留 domain 介面。

---

## 異動摘要

### 新增

- `lib/features/journey/data/hive_journey_repository.dart` — 實作 `JourneyRepository`，使用 Hive JSON 字串儲存（與 `HivePlanRepository` 相同模式）

### 修改

- `lib/features/journey/domain/models/journey_entry.dart` — 移除 `userId`，新增 `toJson()`/`fromJson()`
- `lib/features/journey/domain/repositories/journey_repository.dart` — 移除 `userId` 參數，方法名改為 `getAll()`/`save()`/`delete()`
- `lib/features/journey/providers.dart` — 使用 `HiveJourneyRepository`，移除 Supabase 相關 provider
- `lib/features/journey/presentation/screens/journey_screen.dart` — 移除 auth gate
- `lib/features/journey/presentation/widgets/timeline_entry.dart` — 呼叫 `delete(id)` 取代 `deleteJourneyEntry(id)`
- `lib/features/narration/presentation/widgets/save_to_passport_button.dart` — 移除 auth check 與登入 dialog
- `lib/features/narration/presentation/controllers/player_controller.dart` — 移除 `userId` 參數，呼叫 `save()` 取代 `addJourneyEntry()`
- `test/features/journey/domain/models/journey_entry_test.dart` — 移除 `userId` 參數及相關 assertions

### 刪除

- `lib/features/journey/data/supabase_journey_repository.dart`
- `lib/features/journey/data/caching_journey_repository.dart`
- `lib/features/journey/data/journey_entry_mapper.dart`
- `lib/features/journey/data/services/hive_journey_cache_service.dart`
- `test/features/journey/data/supabase_journey_repository_test.dart`
- `test/features/journey/data/caching_journey_repository_test.dart`
- `test/features/journey/data/services/` 目錄（如有 `hive_journey_cache_service_test.dart`）

---

## 資料模型

### JourneyEntry（修改後）

```dart
class JourneyEntry {
  final String id;
  // userId 移除
  final SavedPlace place;
  final NarrationContent narrationContent;
  final NarrationAspect narrationAspect;
  final DateTime createdAt;
  final Language language;

  factory JourneyEntry.create({
    required Place place,
    required NarrationAspect aspect,
    required NarrationContent content,
    required Language language,
  }) { ... }

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': place.id,
    'place_name': place.name,
    'place_address': place.address,
    'place_image_url': place.imageUrl,
    'narration_text': narrationContent.text,
    'narration_style': NarrationAspectMapper.toApiString(narrationAspect),
    'created_at': createdAt.toIso8601String(),
    'language': language.code,
  };

  factory JourneyEntry.fromJson(Map<String, dynamic> json) { ... }
}
```

> `fromJson` 邏輯沿用現有 `JourneyEntryMapper.fromJson()`，移除 `user_id` 欄位的讀取。

---

## Repository 介面（修改後）

```dart
abstract class JourneyRepository {
  Future<List<JourneyEntry>> getAll();
  Future<void> save(JourneyEntry entry);
  Future<void> delete(String id);
}
```

---

## HiveJourneyRepository

```dart
class HiveJourneyRepository implements JourneyRepository {
  static const String _boxName = 'journey_entries';

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<JourneyEntry>> getAll() async {
    try {
      final box = await _getBox();
      return box.values
          .map((v) => JourneyEntry.fromJson(
                jsonDecode(v as String) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(JourneyEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
```

---

## Providers（修改後）

```dart
final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((ref) {
  return ref.watch(journeyRepositoryProvider).getAll();
});
```

---

## UI 異動

### JourneyScreen

- 移除 `isSignedIn` 判斷，直接呼叫 `_buildJourneyList(ref)`
- 移除 `_buildLoginPrompt` 方法
- 移除 `login_dialog.dart`、`auth/providers.dart` imports

### SaveToPassportButton

移除：
```dart
var userId = Supabase.instance.client.auth.currentUser?.id;
if (userId == null) {
  final loggedIn = await showLoginDialog(context);
  ...
}
await playerController.saveToJourney(userId, language: Language(locale));
```

改為：
```dart
await playerController.saveToJourney(language: Language(locale));
```

移除：`supabase_flutter`、`login_dialog.dart` imports

### PlayerController.saveToJourney()

```dart
// 原本
Future<void> saveToJourney(String userId, {required Language language})

// 改為
Future<void> saveToJourney({required Language language})
```

內部呼叫 `JourneyEntry.create()` 時移除 `userId:` 參數，`_journeyRepository.addJourneyEntry(entry)` 改為 `_journeyRepository.save(entry)`。

---

## Hive Box 命名

| Box 名稱 | 說明 |
|----------|------|
| `journey_entries` | 新的 HiveJourneyRepository 使用（key = entry.id） |
| `journey_cache` | 舊的 HiveJourneyCacheService，廢棄不再使用 |

> 舊的 `journey_cache` box 不會主動清除，僅停止讀寫。若未來有需要可在 main.dart 加入清除邏輯。

---

## 測試

- `test/features/journey/data/hive_journey_repository_test.dart` — 測試 CRUD 及排序（仿照 `hive_plan_repository_test.dart`）
- 驗證 `JourneyEntry.fromJson(toJson())` 完整 round-trip（包含 NarrationAspect 及 Language）

---

## 不在本次範圍內

- 舊 Supabase 資料的遷移
- 登入使用者的雲端同步
- Journey 資料的匯出/備份
