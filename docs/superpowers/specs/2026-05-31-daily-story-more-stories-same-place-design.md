# 每日故事「探索更多故事」→ 同地點生成頁 設計

- 日期：2026-05-31
- 狀態：已通過 brainstorming，待寫實作計畫

## 背景與問題

每日故事詳情頁（`DailyStoryDetailScreen`）底部有「探索更多故事」CTA
（eyebrow「想知道更多嗎？」）。目前點擊後導向 `context.go('/?tab=explore')`，
進到 Explore 探索分頁。

期望行為：點擊後進到 **config 生成頁**（`SelectStoryHookScreen`，`/config`），
針對 **同一篇每日故事的地點** 生成更多歷史故事 hooks。

### 技術阻礙

`/config` 生成 hooks / narration 的硬需求是 `Place.id` 帶有 `wikidata:Qxxxx`
前綴（`story_hook_api_service.dart` 的 `_extractWikidataId`；回傳 null 時直接丟
`insufficientSource`，不打後端）。但是：

- `DailyStory` 模型與 Supabase `daily_stories` / `daily_story_places` 資料表
  **都沒有 wikidata id**，只有 `place_name` / `place_location` / `wikipedia_url`
  /（places 表）`wikipedia_title_en`。
- `daily_story_places` 由 `scripts/daily_story_setup/fetch_world_heritage_sites.py`
  一次性手動 seed，該腳本用 Wikidata SPARQL 抓 UNESCO 世界遺產，**本來就取得
  Q-id（`?item`）只是丟棄沒存**。
- 每日生成 job（`backend/.../daily_story/job.py`、`story_writer.py`）只用
  `wikipedia_title_en` 查 Wikipedia，不涉及 Q-id。

## 決策摘要

| 決策 | 選擇 |
| --- | --- |
| wikidata id 來源 | **A：後端 pipeline 預先解析並存入 `daily_story_places`** |
| 缺 wikidata_id 時的按鈕 | **A：隱藏「探索更多故事」CTA** |
| 既有資料 backfill | **A：一次性 backfill 腳本，用 `wikipedia_title_en` 反查 Q-id** |
| wikidata_id 送到前端的方式 | **方案 1：透過既有 `daily_story_places` join 讀欄位**（不動每日生成 job） |
| 前端組 Place | **方案 3：抽 `DailyStory → Place` 對映，放在 `app/` 層（見「feature 隔離」）** |

### feature 隔離考量

`Place` 屬於 explore feature。若 daily_story 直接組 `Place`，daily_story 就會
import explore，違反 CLAUDE.md「features 之間不可互相依賴；跨 feature 整合放在
`app/`」。因此 `DailyStory → Place` 的對映與 `/config` 導航放在 **`app/` 層**：

- daily_story 詳情頁只讀 `story.wikidataId` 決定 CTA 是否顯示（純讀自家 model），
  並呼叫 app 層 launcher 進行導航，**不 import explore 的 `Place`**。
- app 層 helper（可依賴 explore 與 narration 路由）負責 `DailyStory → Place`
  與 `context.push('/config', extra: place)`。
- `/config` 既有契約不變（explore 仍傳 `Place`）。

## 架構與資料流

```
[seed / backfill] 寫入 daily_story_places.wikidata_id
        ↓ (place_id FK)
daily_stories ──join──> daily_story_places(wikidata_id, ...)
        ↓ supabase_daily_story_repository._select
DailyStory(wikidataId: String?)
        ↓ DailyStoryDetailScreen (只讀 wikidataId，不 import Place)
   wikidataId == null → 隱藏 CTA
   wikidataId != null → 呼叫 app 層 launcher
        ↓ app/ 層：DailyStory → Place，context.push('/config', extra: place)
SelectStoryHookScreen (同地點生成 hooks)
```

每日生成 job **不需改動**：前端是用 `daily_stories.place_id` FK embed
`daily_story_places`，欄位補上後 join 即可帶出 `wikidata_id`。

## 變更項目

### 資料層 / 後端（Python `backend/` + `scripts/`）

1. **DB migration**
   `supabase/migrations/<時間戳>_add_wikidata_id_to_daily_story_places.sql`
   - `ALTER TABLE public.daily_story_places ADD COLUMN wikidata_id text;`（nullable）

2. **Seed 腳本**：`scripts/daily_story_setup/fetch_world_heritage_sites.py`
   - 從 SPARQL `?item`（`http://www.wikidata.org/entity/Qxxxx`）擷取 `Qxxxx`，
     寫進 CSV 新增的 `wikidata_id` 欄。
   - 同步更新 `scripts/daily_story_setup/README.md` 的 `\copy` 欄位清單。

3. **一次性 backfill 腳本**（新檔）：
   `scripts/daily_story_setup/backfill_wikidata_ids.py`
   - 查 `daily_story_places` 中 `wikidata_id IS NULL` 的列。
   - 以 `wikipedia_title_en` 透過 MediaWiki API（enwiki `pageprops.wikibase_item`，
     或 `wbgetentities?sites=enwiki&titles=...`）反查 Q-id。
   - 用 service-role supabase client 更新該列；解析不到者記 log，不動其他欄位、
     不新增/刪除地點。

### 前端（Flutter）

4. **`_select` 投影**：`supabase_daily_story_repository.dart`
   `'*, daily_story_places!left(card_location_en, card_city_ch, card_city_en, wikidata_id)'`

5. **`DailyStory` model**：`daily_story.dart`
   - 新增 `final String? wikidataId;`（constructor + `props`）。

6. **Mapper**：`rowToStory`
   - `wikidataId: place?['wikidata_id'] as String?`。

7. **`DailyStory → Place` 對映 + 導航 launcher**（新檔，放在 **`app/` 層**，
   例如 `lib/app/utils/daily_story_config_launcher.dart`）：
   - 純對映函式（可單獨單元測試），只在 `wikidataId != null` 時組出：
   ```dart
   Place(
     id: 'wikidata:$wikidataId',
     name: story.placeName,
     address: story.placeLocation,
     location: const PlaceLocation(latitude: 0, longitude: 0), // 生成不使用座標
     tags: const [],
     photos: story.imageUrl != null
         ? [PlacePhoto(url: story.imageUrl!, width: 0, height: 0,
                       attributions: const [])]
         : const [],
     category: PlaceCategory.historicalCultural, // 世界遺產 → 人文古蹟
   )
   ```
   - launcher：`context.push('/config', extra: place)`（thin wrapper）。
   - 生成只用 `id`/`name`/`address`；config 畫面 UI 只用 `name`/`category`/
     `primaryPhoto`，欄位齊備。

8. **導航 + CTA 顯示**：`daily_story_detail_screen.dart`
   - `wikidataId == null` → 不傳 `onExploreMore`，CTA 不渲染
     （`CardLayoutBody` 與 `_LegacyLayoutBody` 皆然）。
   - `wikidataId != null` → CTA 點擊呼叫 app 層 launcher（詳情頁不 import
     explore 的 `Place`）。
   - 移除舊的 `context.go('/?tab=explore')`。

## 邊界情境

- `wikidataId == null` → 隱藏 CTA。需確認 `CardLayoutBody` 與 `_LegacyLayoutBody`
  都在 `onExploreMore == null` 時不渲染 CTA。
- `imageUrl == null` → Place `photos` 為空，config 背景走 `_BackgroundImage`
  既有無圖 fallback。
- 進 config 後後端仍回 `insufficientSource`（極少數）→ 沿用 config 既有「資料不足」
  狀態，不另外處理。

## 測試

### 前端
- mapper 單元測試：`rowToStory` 正確映射 `wikidata_id`（有值／null）。
- app 層對映單元測試：有 `wikidataId` 組出 `id == 'wikidata:Qxxx'`；帶/不帶
  `imageUrl` 的 `photos`。
- 詳情頁 widget 測試：
  - 有 `wikidataId` → 點 CTA 導到 `/config`，extra 為 id 為 `wikidata:Qxxx`
    的 Place（取代既有 `/?tab=explore` 測試）。
  - 無 `wikidataId` → CTA 不顯示。

### 後端（Python）
- seed 腳本：SPARQL entity URI → `Qxxx` 擷取的單元測試。
- backfill：title→Q-id resolver 以 mock MediaWiki 回應測試（含解析不到的情況）。

## 任務拆解（順序由使用者決定；前端程式碼可先寫，不必等 backfill 實際跑）

- **T1**（DB）：migration 加 `wikidata_id` 欄。
- **T2**（後端）：seed 腳本保留 Q-id ＋ 更新 README。
- **T3**（後端）：一次性 backfill 腳本 ＋ 測試。
- **T4**（前端）：`_select` ＋ model ＋ mapper ＋ mapper 測試。
- **T5**（前端 / `app/` 層）：`DailyStory → Place` 對映 ＋ launcher ＋ 對映單元測試。
- **T6**（前端）：詳情頁呼叫 launcher ＋ CTA 顯示邏輯 ＋ widget 測試。

## 不在範圍（YAGNI）

- 不改每日故事生成 job 的插入邏輯（不把 wikidata_id 反正規化進 `daily_stories`）。
- 不為 daily story 地點補座標 / 真實照片 metadata（生成與 config UI 都用不到）。
- 不處理 config 既有的 `insufficientSource` 流程以外的新錯誤 UX。
