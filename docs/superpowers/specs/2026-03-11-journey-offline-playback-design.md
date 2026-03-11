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

序列化複用 `JourneyEntryMapper` 的轉換邏輯。

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

**網路錯誤判定**：攔截 `SocketException`、`TimeoutException`。其他錯誤不觸發 fallback。

## 初始化

在 `main.dart` 啟動流程中開啟 `journey_cache` Hive box，與現有 `places_cache` 放在一起。

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

### JourneyEntryMapper 補充測試
- JSON 雙向轉換正確性（如需新增 `fromMap`）

Mock 策略：使用 `mocktail`。

## 影響的檔案

### 新增
- `features/journey/data/hive_journey_cache_service.dart`
- `features/journey/data/caching_journey_repository.dart`
- `test/unit/journey/hive_journey_cache_service_test.dart`
- `test/unit/journey/caching_journey_repository_test.dart`

### 修改
- `main.dart` — Hive box 初始化
- Journey provider 定義 — 切換到 CachingJourneyRepository
- `JourneyEntryMapper` — 可能補充 `fromMap` 方法
