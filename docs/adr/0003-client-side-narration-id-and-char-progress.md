# ADR 0003：Narration analytics 採用客戶端生成 narrationId 與字符位置進度

- 狀態：Accepted（過渡決定）
- 日期：2026-05-20
- 影響範圍：`features/analytics/presentation/narration_analytics_observer.dart`、Firebase Analytics 事件 payload 的解讀方式、後續資料分析查詢

## 背景

Sprint 1 實作 `NarrationAnalyticsObserver`（位於 `lib/features/analytics/presentation/narration_analytics_observer.dart`）時，需要對 narration 播放發送 4 種事件（started / progress / completed / abandoned），每個事件依規格需要：

- `narration_id`（穩定識別一次「narration session」）
- `elapsed_ms`、`total_duration_ms`、`listen_duration_ms`、`progress_pct`、`completion_rate`（時間 / 進度資訊）

**Observer 在實作時探查既有 narration 模組（`features/narration/presentation/controllers/player_controller.dart` 等），發現兩個跟原始 spec 假設不一致的事實**：

1. **既有 narration 沒有「narrationId」概念**。一段 narration 是 `(Place + NarrationContent)` 的組合：`Place` 有 ID（`wikidata:XXX`），`NarrationContent` 是 LLM 即時生成的純文字物件，沒有 ID 也不持久化。同一個 place 重新觸發會產生新的 `NarrationContent`，但兩者在領域層上沒有獨立識別。
2. **既有 narration 沒有毫秒級時間軸**。Lorescape 用裝置端 `flutter_tts` 朗讀，state 暴露的是 `currentCharPosition: int`（TTS 已朗讀到的字符索引），文本總長度則是 `content.text.length`（字符數）。**沒有 elapsed / total / listen duration in ms**。

可選的應對方式：

- **(A)** 修改 narration 模組，加上 `narrationId` 欄位與 ms 計時器 → 違反 Sprint 1 的「zero pollution」原則（observer 不可侵入 narration），且 ms 計時需要動 TTS 層；工程量 1-2 人天
- **(B)** 用 `place.id` 直接當 narration_id → 同一 place 多次播放會混淆（observer 無法區分「同一場 narration 的後續事件」vs「第二次重播」）
- **(C)** Observer 自己生成 narrationId（per session），ms 欄位先用「字符位置 / 文本長度」當代理 → 對 narration 模組零侵入

## 決策

採用 **(C)**：

### 1. `narration_id` — 客戶端 session UUID v4

`NarrationAnalyticsObserver` 偵測「narration session 開始」時（從非播放轉到播放狀態），自己 `Uuid().v4()` 生一個 UUID v4 作為該 session 的 `narration_id`。記錄在 observer 的內部 state，整個 session 期間沿用，session 結束或切換到新 narration 時 reset。

「同一 session」的判定：以 `(place.id, content.text.length)` 為 session key。若兩個欄位都沒變，視為同一 session（容忍 pause / resume）。任一改變則視為新 session。

### 2. 時間欄位 — 字符位置代理

| 規格欄位 | 實際塞入的值 | 單位 |
|---|---|---|
| `elapsed_ms` | `currentCharPosition` | 字符數（**不是 ms**） |
| `total_duration_ms` | `content.text.length` | 字符數 |
| `listen_duration_ms` | session 累計朗讀過的字符數 | 字符數 |
| `progress_pct` | `currentCharPosition / content.text.length * 100` | 百分比（**正確**） |
| `completion_rate` | 同上 | 百分比（**正確**） |

**「百分比 / 完成率」相對精準**（字符與時間在 TTS 大致線性對應），但**絕對時間數值錯誤**（單位是字符不是 ms）。

### 3. 全部標 `TODO(story-2)` 註解

Observer 內所有走「字符代理」與「hardcode source = explore」的位置都加上 `// TODO(story-2): ...` 註解，方便未來搜尋與替換。

## 影響

### 對資料分析的解讀

- **能信的指標**：
  - `narration_started` / `narration_completed` / `narration_abandoned` 的**次數**與**比例**
  - `progress_pct` 與 `completion_rate`（百分比相對精準）
  - 北極星指標 WPSCU（Weekly Place-Stories Completed per Active User）— 計數型，不依賴時間
  - First-time vs returning 行為（`is_first_lifetime_narration` flag 正確）
- **不能直接信的指標**：
  - 「平均聆聽時長（秒 / 分鐘）」— 因為 elapsed/total 是字符，不能直接換算秒
  - 「絕對流失點時間」— 同上
- **要 join place 才能分析的維度**：
  - 「哪些景點完成率最高」— 必須以 `place_id` 做 GROUP BY，不能用 `narration_id`（每次 session 都不同）
  - 「重複聆聽行為」— 同一 place_id 出現多個 narration_id 即為重播

### 對 Story 2（A/B 實驗）

- A/B 實驗的核心指標是「D0 narration_completed ≥ 1 的比例」與「W4 留存」，**這些都不依賴時間軸**，完全可用。
- A/B 結論不會受本 ADR 影響。

### 對未來重構

當 TtsService 暴露真實 `Duration` 時，observer 改動範圍可控：
- `_handleTransition` 內把 `currentCharPosition` 換成 `position.inMilliseconds`、`content.text.length` 換成 `duration.inMilliseconds`
- 模型欄位名稱不必改（仍叫 `elapsed_ms` 等）
- Firebase 收到的歷史事件需在分析時用 `app_version` 切片處理（舊版字符、新版 ms）

當需要 stable narration_id（例如要 join 內容元資料時），可改用 `place.id + content hash` 或新增持久化的 narration 表，observer 改一行映射即可。

## 替代方案（考慮過但未採用）

### A：修改 narration 模組加 narrationId / ms timer

理由：違反「Sprint 1 不侵入 narration」原則，且 ms timer 牽涉 TTS 層改造，工程量大、風險高。如果之後 TtsService 為了其他需求（如預生成音檔、A/B 內容測試）必須暴露時間軸，再順勢加上 narration_id 即可。

### B：用 place_id 當 narration_id

理由：同一 place 多次重播會被 GA / BigQuery 視為同一 narration 的多個事件，難以區分「同一 session 的連續事件」vs「不同 session」。會嚴重影響 funnel 分析正確性。

### C（採用）：客戶端生成 session UUID + 字符代理

理由：
- **零侵入** narration 模組
- session 邊界清楚，funnel 計算正確
- 百分比指標相對精準，足以驗證 Sprint 1 的所有產品假設
- 不能信的「絕對時間」指標暫時不依賴，等之後升級到真實 ms 再啟用

## 對 Firebase Analytics dashboard 的具體建議

在 Firebase Console 自訂事件分析時，**請忽略**以下參數的單位：

- `elapsed_ms` / `total_duration_ms` / `listen_duration_ms`（單位是「字符」不是「毫秒」）

**請使用**以下作為主要分析維度：

- `event_count`（Firebase 自動）
- `progress_pct`、`completion_rate`（百分比可信）
- `is_first_lifetime_narration`（0/1，bool 轉 int）
- `source`、`place_id`、`abandon_reason`、`milestone`（類別）

未來如要 export 到 BigQuery 做 SQL 分析，建議：
```sql
-- ❌ 不要這樣（單位錯）
SELECT AVG(listen_duration_ms) / 1000 AS avg_seconds FROM events;

-- ✅ 改成這樣（用百分比 + 已知文本平均長度估算）
SELECT
  AVG(progress_pct) AS avg_progress_pct,
  COUNT(DISTINCT narration_id) AS sessions
FROM events
WHERE event_type = 'narration_completed';
```

## 後續追蹤

- **Story 2 完成後**：observer 補上實際 source（從 router / player state 推導），TODO 對應位置 ~3 行
- **TtsService 升級**：等暴露 `Duration` 後，observer 內 ms 欄位改實際值，**同時更新本 ADR 的「不能直接信」清單**
- **後續 ADR**：若決定加 stable narration_id（例如 Story 3 預生成內容會帶內容 ID），需新寫 ADR 描述遷移路徑

## 參考

- 關鍵實作：`frontend/lib/features/analytics/presentation/narration_analytics_observer.dart`（搜尋 `TODO(story-2)`）
- 既有 narration state shape：`frontend/lib/features/narration/presentation/controllers/player_controller.dart`、`frontend/lib/features/narration/domain/models/`
- Sprint 1 對話脈絡：developer 在 Task 1.9 探查 narration state 後回報的 mismatch
- 相關決策：見 [ADR 0002](./0002-use-firebase-analytics-instead-of-supabase.md)
