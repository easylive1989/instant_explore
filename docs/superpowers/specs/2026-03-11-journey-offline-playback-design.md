# Journey 離線回放設計

## 概述

讓使用者在無網路環境下，能回放已保存的 Journey 導覽內容（文字 + TTS 語音）。

## 範圍

- **包含**：Journey 已保存導覽的離線讀取與 TTS 回放
- **不包含**：離線寫入/刪除、TTS 音檔快取、全域離線狀態 UI、景點探索離線

## 架構

### Decorator Pattern

在 `JourneyRepository` 介面與 `SupabaseJourneyRepository` 之間加入 `CachingJourneyRepository`。

```
JourneyRepository (interface)
       ↑
CachingJourneyRepository (decorator, 新增)
       ↑
SupabaseJourneyRepository (現有)
```

與現有 `CachingPlacesRepository` 採用相同模式，保持架構一致性。

### 資料流

**讀取 (getJourneyEntries)**：
1. 嘗試從 Supabase 載入
2. 成功 → 更新 Hive 快取 → 回傳資料
3. 網路失敗 → 讀取 Hive 快取 → 回傳快取資料
4. 網路失敗 + 無快取 → 拋出原始錯誤

**保存 (addJourneyEntry)**：
1. 寫入 Supabase
2. 成功 → 同步寫入 Hive
3. 失敗 → 拋出錯誤（不做離線寫入）

**刪除 (deleteJourneyEntry)**：
1. 從 Supabase 刪除
2. 成功 → 從 Hive 移除
3. 失敗 → 拋出錯誤

## 快取實作

### Hive Box

- Box 名稱：`journey_cache`
- Key：`journey_entries_{userId}`
- Value：`List<Map<String, dynamic>>`（JourneyEntry JSON 列表）
- 無 TTL：每次有網路時從 Supabase 重新載入並覆寫

### HiveJourneyCacheService

新增快取服務，職責單一：

- `getEntries(userId)` → `List<JourneyEntry>?`
- `saveEntries(userId, entries)` → 全量覆寫
- `addEntry(userId, entry)` → 插入列表頭部
- `removeEntry(userId, entryId)` → 從列表移除
- `clear()` → 清除所有快取

序列化複用 `JourneyEntryMapper` 現有的 `fromJson`/`toJson` 方法，不需要新增方法。

## Provider 整合

```dart
final hiveJourneyCacheServiceProvider = Provider<HiveJourneyCacheService>(...);

final cachingJourneyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => CachingJourneyRepository(
    remote: ref.read(supabaseJourneyRepositoryProvider),
    cache: ref.read(hiveJourneyCacheServiceProvider),
  ),
);
```

修改現有 `myJourneyProvider`，改用 `cachingJourneyRepositoryProvider`。

## 錯誤處理

| 情境 | 行為 |
|------|------|
| Supabase 成功 | 更新快取，回傳遠端資料 |
| Supabase 網路失敗 + 有快取 | 靜默回傳快取資料 |
| Supabase 網路失敗 + 無快取 | 拋出原始錯誤 |
| Supabase 非網路錯誤 | 不 fallback，直接拋出 |
| 快取讀寫失敗 | 靜默忽略，不影響主流程 |

**網路錯誤判定**：`CachingJourneyRepository` 攔截 `AppError` 並檢查 `type == JourneyError.networkError`。為此需修改 `SupabaseJourneyRepository`，在 catch-all 之前明確攔截 `SocketException` 和 `TimeoutException`，將其包裝為 `AppError(type: JourneyError.networkError)`。此改法與 `PlacesApiService`、`GeminiService` 的錯誤處理模式一致。

**快取一致性備註**：`addEntry` 將新項目插入列表頭部，在跨裝置使用的情況下，快取排序可能不完全與 Supabase 一致。這是可接受的 trade-off，因為下次有網路時 `getJourneyEntries` 會全量覆寫快取。

## 初始化

採用與 `HivePlacesCacheService` 相同的 lazy open 模式：`HiveJourneyCacheService` 內部自行管理 box 的開啟，不需要在 `main.dart` 預先初始化。

## TTS 離線

`flutter_tts` 使用設備內建 TTS 引擎，本身支援離線合成。只要導覽文字存在本地，TTS 播放自然可離線運作，無需額外處理。

## 測試策略

### HiveJourneyCacheService 測試
- 存取 entries 正確性
- 新增/移除單筆 entry
- 無快取時回傳 null
- clear 清除所有資料

### CachingJourneyRepository 測試
- 遠端成功 → 回傳遠端資料 + 快取更新
- 遠端網路失敗 + 有快取 → 回傳快取
- 遠端網路失敗 + 無快取 → 拋出錯誤
- 遠端非網路錯誤 → 不 fallback
- 保存/刪除成功 → 快取同步
- 快取讀寫失敗 → 靜默忽略

### SupabaseJourneyRepository 補充測試
- `SocketException` → 拋出 `AppError(type: JourneyError.networkError)`
- `TimeoutException` → 拋出 `AppError(type: JourneyError.networkError)`

Mock 策略：使用 `mocktail`。落 fallback 到快取時加入 log 記錄（使用 `logging` 套件）。

## 影響的檔案

### 新增
- `features/journey/data/services/hive_journey_cache_service.dart`
- `features/journey/data/caching_journey_repository.dart`
- `test/features/journey/data/services/hive_journey_cache_service_test.dart`
- `test/features/journey/data/caching_journey_repository_test.dart`

### 修改
- `features/journey/data/supabase_journey_repository.dart` — 新增 `SocketException`/`TimeoutException` 攔截，拋出 `JourneyError.networkError`
- `features/journey/providers.dart` — 新增 provider，切換到 CachingJourneyRepository
