# ADR 0002：Story 1 埋點採用 Firebase Analytics，而非自建 Supabase events table

- 狀態：Accepted
- 日期：2026-05-20
- 影響範圍：`features/analytics/`、`lib/main.dart`、`lib/app.dart`、`pubspec.yaml`、後續 Story 2 的 feature flag 實作

## 背景

Lorescape 在 Sprint 1（Story 1 — Narration 核心事件埋點）規劃階段，由架構師建議採「自建 Supabase `analytics_events` table + Hive outbox + 自訂 batch flush」路線，理由是「Schema 自己掌握、與既有 Supabase 統一」。Sprint 1 已先實作了 domain layer（4 個 event subtype + envelope + queue / repository 介面 + consent state，共 12 個檔案、30 個測試），尚未進到 data 層實作。

進入 data 層實作前，PO 在審視規劃時提出：「分析不通常都是用 GA 嗎？」促使整個方案重新評估。

評估的關鍵事實：

1. **業界標準**：Firebase Analytics（GA4）是 mobile app 早中期的事實標準，免費、不限事件量、內建漏斗 / 留存 dashboard、BigQuery export、可與 Crashlytics / Remote Config / Cloud Messaging 整合。
2. **Lorescape 已在 Firebase 生態系**：`firebase_core: ^4.3.0` 與 `firebase_ai: ^3.6.1`（Gemini）已在 pubspec，加 `firebase_analytics` 是零摩擦延伸。
3. **Firebase SDK 內建關鍵能力**：offline queue、batch、retry、dedup、auto-attach userId / appInstanceId / appVersion / platform —— 這些**原本要自己寫 200~300 行的 outbox 邏輯**完全省下。
4. **原架構師的「schema 掌控」論點對成熟產品才成立**：早期產品的瓶頸是「資料拿不出來」而非「schema 不夠彈性」。Firebase Analytics 的 25 參數上限對 narration 事件綽綽有餘。
5. **隱私風險可控**：Firebase 支援用戶級 opt-out（`setAnalyticsCollectionEnabled(false)`），且 Lorescape 的事件 payload 不含全文、不含精確 GPS（只有 place_id），不會踩個資紅線。

## 決策

**改採 Firebase Analytics 作為 Story 1 唯一的事件後端**，不雙寫 Supabase。具體影響：

| 原計畫 | 改後 |
|---|---|
| 自建 Supabase `analytics_events` table + RLS | 取消 |
| `HiveEventQueue`（5000 上限、FIFO eviction、event_id 去重） | 取消 — Firebase SDK 內建 |
| `SupabaseAnalyticsRepository`（batch upsert） | 改為 `FirebaseAnalyticsService`（薄包裝，~40 行） |
| `EventEnvelope` model（attach userId / installId / sessionId / appVersion / platform） | 取消 — Firebase 自動 attach |
| `EventQueue` / `AnalyticsRepository` 介面 | 改為單一 `AnalyticsService.logEvent(event)` 介面 |
| Story 1 工期 8-10 人天 | 縮為 3-5 人天 |

同時順勢確認 **Story 2 的 feature flag 也採用 Firebase Remote Config**（取代原計畫的自建 Supabase `feature_flags` table + SharedPreferences cache + TTL 邏輯），Story 2 工期從 6-8 天縮為 4 天。

### 保留的 domain layer 設計

雖然 envelope / queue / repository 介面取消，但 sealed class `AnalyticsEvent` 與其 4 個 subtype（`NarrationStarted` / `NarrationProgress` / `NarrationCompleted` / `NarrationAbandoned`）**保留**，理由：

- **強型別事件定義**避免拼字 bug（例如 `logEvent('narrtaion_started')`）
- 編譯期 exhaustive：sealed class + `switch` pattern matching，新增 event 編譯期會炸
- 純函式 `firebaseParametersFor(AnalyticsEvent)` 把 model 轉成 Firebase 接受的 `Map<String, Object>`（處理 `bool → int`、null 過濾、字串長度檢查），讓 unit test 完全不依賴 Firebase SDK

### 介面抽象化

對外仍以 `abstract class AnalyticsService { Future<void> logEvent(AnalyticsEvent event); }` 暴露入口。`FirebaseAnalyticsService` 是當下唯一實作，但未來若要更換到 Mixpanel / Amplitude / 自建，只要寫一個新的實作，呼叫端零改動。

## 影響

### 對開發團隊

- **Sprint 1 工期實際節省約 4-5 人天**（含 outbox + repository 實作 + 對應測試）
- **Sprint 2 也跟著瘦身**：feature flag 不必自建 service / cache / TTL，直接用 Firebase Remote Config
- **新人友善**：任何接觸過 mobile dev 的人都會 Firebase Analytics，不必讀我們的客製 outbox

### 對資料分析

- **儀表板免費附贈**：DAU、留存、漏斗、cohort、地理分布等 Firebase Console 直接看，不必自建 dashboard
- **BigQuery export 可選**：未來要做 SQL-based 進階分析時，免費接到 BigQuery，再從 BigQuery 跑（不必動 app code）
- **可能的限制**：Firebase Analytics 每事件最多 25 個參數、字串最大 100 字元。目前 4 個 narration 事件最多 7 個參數，遠在限制內

### 對既有 Supabase

- **未變動**：auth、subscription、journey、saved_locations 等業務資料仍在 Supabase。Firebase Analytics 只負責**行為事件**，不取代業務資料庫
- **未來若要 join**：可從 BigQuery 把 Firebase events export 出來，與 Supabase pg_dump 在 data warehouse 對拼。這條路徑保留但目前用不到

### 對隱私 / 法遵

- **Consent gating 自建**：在 `NarrationAnalyticsObserver` 內讀 `ConsentRepository`，consent 關閉時跳過 `logEvent`。**不依賴 Firebase 自己的 `setAnalyticsCollectionEnabled`**，目的是讓「停送」決策完全在 app 層可見可測
- **Consent 預設 ON + onboarding 透明告知**（已寫進 PO 決策清單），符合台灣個資法與 GDPR 寬鬆地區的最低要求

## 替代方案（考慮過但未採用）

### A：雙寫 Firebase + Supabase
Firebase 主要用 dashboard / acquisition / funnel，Supabase 留特定關鍵業務事件（訂閱、撤銷）。
- 拒絕原因：複雜度雙倍、schema 變更要動兩處、目前看不到明確「Supabase 才能做到的事」。當未來確實有「跨業務 + 行為」的 SQL 分析需求，再從 BigQuery export 補回即可。

### B：純自建 Supabase（原計畫）
全套 outbox + batch + dashboard 自己刻。
- 拒絕原因：工程量 vs 學習價值不成比例。Lorescape 的事件量短期內不會超過 Firebase 免費額度，「schema 掌控」對早期產品不是價值點。

### C：Mixpanel / Amplitude
更強的 funnel / cohort 工具。
- 拒絕原因：付費（免費額度小）、Lorescape 還不到需要這些工具的階段。Firebase 已綽綽有餘，未來若要升級，介面 `AnalyticsService` 已抽象，遷移成本可控。

## 後續追蹤

- **真機 smoke test**：實際在 iOS / Android 真機跑、用 Firebase Console DebugView 驗證事件流入（屬執行性 checklist，不需 ADR）
- **Story 2 ADR**（待寫）：採用 Firebase Remote Config 與自建 SHA-256 hash 分組共存的設計，詳述「為何不直接用 Firebase A/B Testing」
- **BigQuery export 啟用時機**：等 Story 1 上線 30 天、累積足夠資料後評估是否要 export 進 BigQuery 做進階分析

## 參考

- Sprint 1 對話脈絡：2026-05-19 ~ 2026-05-20 的 8-agent 探索與 PO 收斂
- `frontend/pubspec.yaml`：新增 `firebase_analytics: ^12.4.1`
- 關鍵實作：
  - `frontend/lib/features/analytics/data/firebase_analytics_service.dart`
  - `frontend/lib/features/analytics/presentation/narration_analytics_observer.dart`
  - `frontend/lib/features/analytics/providers.dart`
- 相關決策：見 [ADR 0003](./0003-client-side-narration-id-and-char-progress.md)
