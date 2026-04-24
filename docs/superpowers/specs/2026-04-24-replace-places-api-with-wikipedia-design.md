# 用 Wikipedia + Wikidata 取代 Google Places API — 設計文件

- 日期：2026-04-24
- 範圍：`frontend/lib/features/explore` 模組的資料源替換

## 背景與目標

Google Places API 的 Nearby Search（新版）單價約 $32/1000 次、Place Photos 另計，隨用戶數增長會成為顯著成本。經檢視 `_includedTypes` 清單（`tourist_attraction`、`historical_landmark`、`museum`、`park`、`zoo` 等），本 App 只使用觀光/文化類景點——這類 POI 在免費資料源的覆蓋率高。

**目標**：在不降低探索頁產品體驗的前提下，以 Wikipedia + Wikidata + Wikimedia Commons 取代 Google Places API，將探索頁的外部 API 成本降為零。

## 當前狀態

| 元件 | 責任 |
|---|---|
| `PlacesApiService` | 直接呼叫 Google Places API（searchNearby / searchText / getPlaceById）|
| `PlacesRepositoryImpl` | 包裝 Service、做 DTO → Domain 轉換、產生照片 URL |
| `CachingPlacesRepository` | 透過 `HivePlacesCacheService` 本地快取 |
| `GooglePlaceDto` | API 回傳結構；`toDomain()` 用 API Key 組 Place Photo URL |
| `PlaceCategoryMapper.fromPlaceTypes` | Google types → `PlaceCategory`（5 類）|

取代範圍：**僅 `PlacesApiService` 與其 DTO/Mapper 層**。`PlacesRepository` interface、`Place` domain model、`PlaceCategory`、`explore_screen`、`HivePlacesCacheService` **維持不變**。

## 選定方案：Wikipedia GeoSearch + Wikidata P31 白名單

已完成 9 個地點（都會/小鎮/鄉下/歐美/亞洲）+ 30 筆 Wikidata P31 實測，結論：
- 圖片覆蓋率 80-100%（鄉下也穩）
- P31 白名單過濾準確率：景點保留 94%、雜訊砍除 100%
- zh/ja/en Wikipedia 覆蓋率差異比預期小（熱門景點各語言版本都有）

### 資料流程

```
getNearbyPlaces(location, language, radius)
    │
    ├─ Call 1: <lang>.wikipedia.org  action=query
    │          generator=geosearch (lat/lon/radius)
    │          prop=pageimages|coordinates|pageprops
    │          pithumbsize=400  ppprop=wikibase_item
    │          → [ {title, lat, lon, thumbnail, wikidata_id} ]
    │
    ├─ Call 2: www.wikidata.org  action=wbgetentities
    │          ids=<wikidata_ids joined by |>  (max 50/call)
    │          props=claims  languages=<lang>|en
    │          → { wd_id: { P31: [class_ids] } }
    │
    ├─ 過濾：只保留 P31 與白名單有交集的地點
    ├─ 分類：P31 class → PlaceCategory
    ├─ 取縮圖 URL（已由 pageimages 回傳，免再 call）
    ├─ 動態 radius：若結果 <3，以 radius×5 重試一次
    └─ 語言 fallback：若 0 結果，以 en.wiki 再試一次
```

### API 呼叫成本

每次 `getNearbyPlaces`：最多 2 次 HTTP request（原本 Google 要 1 次 nearby + N 次 photo）；免 API Key、免費。

## 架構設計

### 新增檔案

```
features/explore/data/
├── services/
│   └── wikipedia_places_service.dart         # 新：取代 PlacesApiService
├── dto/
│   ├── wiki_place_dto.dart                   # 新：GeoSearch 回傳結構
│   └── wikidata_entity_dto.dart              # 新：wbgetentities 回傳結構
└── mappers/
    ├── wikidata_category_mapper.dart         # 新：P31 → PlaceCategory
    └── wiki_place_filter.dart                # 新：P31 白名單過濾
```

### 修改檔案

- `PlacesRepositoryImpl`：建構子改注入 `WikipediaPlacesService`；`getNearbyPlaces` 流程改走新 API。
- `providers.dart`：`placesApiServiceProvider` 替換為 `wikipediaPlacesServiceProvider`。
- `GooglePlaceDto` / `PlaceCategoryMapper.fromPlaceTypes` / `GooglePlacePhotoDto`：**移除**（Repository 層已不再使用）。

### 不變的檔案

- `PlacesRepository`（interface）
- `Place`、`PlaceLocation`、`PlacePhoto`、`PlaceCategory` domain models
- `CachingPlacesRepository` + `HivePlacesCacheService`（快取 key 用座標+語言，與資料源無關）
- `explore_screen` 與所有 presentation 層

## 關鍵設計決策

### 1. P31 白名單

以下類別會保留（初版，可擴充）：

| Wikidata ID | 意義 | → PlaceCategory |
|---|---|---|
| Q5393308 | Buddhist temple | historicalCultural |
| Q845945 | Shinto shrine | historicalCultural |
| Q2680845 | Chinese temple | historicalCultural |
| Q16970 | church building | historicalCultural |
| Q32815 | mosque | historicalCultural |
| Q23413 | castle | historicalCultural |
| Q16560 | palace | historicalCultural |
| Q4989906 | monument | historicalCultural |
| Q839954 | archaeological site | historicalCultural |
| Q22746 | historic site | historicalCultural |
| Q123314524 | yamajiro (mountain castle) | historicalCultural |
| Q667783 | sandō (temple approach) | historicalCultural |
| Q33506 | museum | museumArt |
| Q207694 | art museum | museumArt |
| Q2065736 | cultural institution | museumArt |
| Q7075 | library | museumArt |
| Q22698 | park | naturalLandscape |
| Q46831 | mountain range | naturalLandscape |
| Q8502 | mountain | naturalLandscape |
| Q23397 | lake | naturalLandscape |
| Q34038 | waterfall | naturalLandscape |
| Q46169 | national park | naturalLandscape |
| Q40080 | beach | naturalLandscape |
| Q43501 | zoo | naturalLandscape |
| Q130003 | aquarium | naturalLandscape |
| Q570116 | tourist attraction | modernUrban |
| Q12280 | bridge | modernUrban |
| Q11303 | skyscraper | modernUrban |
| Q44782 | urban park | modernUrban |

規則：一個地點的 P31 **只要任一筆落在白名單內即保留**；分類取第一個命中的白名單項。`foodMarket` 類別暫無對應 Wikidata 類別，初版不涵蓋（觀察後再決定）。

### 2. 動態 radius

- 使用者傳入的 `radius` 作為第一次查詢
- 若結果數 < 3，以 `radius × 5` 重試一次
- 第二次仍不足則回傳現有結果（不再重試）

目的：都會區維持精確、小鎮自動擴大範圍。

### 3. 語言 fallback

- 先打 `<userLang>.wikipedia.org`
- 若首次查詢 **0 結果**，fallback 到 `en.wikipedia.org`
- 若使用者語言本就是 en，不做 fallback

不做永久多語言查詢（增加延遲、大多數熱門景點在用戶語言版本已有條目）。

### 4. Place ID 格式

Place.id 改用 `wikidata:Q221716` 前綴字串（Wikidata 是跨語言穩定 ID）。`getPlaceById` 接受此格式，拆 prefix 後直接用 `wbgetentities` 查。

**向後相容風險**：`HivePlacesCacheService` 既有快取是 Google place ID，升級後需清空或加版本號。計畫採用 cache 版本號策略（見下）。

### 5. 快取版本

`HivePlacesCacheService` 加入 `cacheSchemaVersion`。版本變動時自動清空舊 cache，無感升級。

### 6. text search

`PlacesRepository.searchPlaces` 暫時保留但改打 `list=search` + geocode。若使用情境少（需確認），後續可考慮簡化。初版先維持功能對等。

## 錯誤處理

| 情境 | 行為 |
|---|---|
| 網路錯誤 | 丟 `PlaceError.networkError`（沿用現有 AppError 結構）|
| Wiki API 回 5xx | 丟 `PlaceError.searchFailed` |
| GeoSearch 0 結果（含 fallback）| 回傳空 list（非錯誤）|
| Wikidata batch 部分失敗 | 該地點視為「無 P31」直接砍掉，不中斷整批 |
| 地點無 thumbnail | 仍保留，`Place.photos` 為空 list（UI 已處理）|

## User-Agent 與 rate limit

Wikimedia 要求所有請求帶具辨識性的 User-Agent。HTTP Client 全域設定：
```
User-Agent: InstantExplore/1.0 (https://instant-explore.app; support@instant-explore.app)
```
Rate limit 保守串行（非並發 batch），遠低於 Wikimedia 公告上限。

## 測試策略

### 單元測試

- `WikipediaPlacesService`：以 fake http client 驗證 URL/parameter 組裝、JSON parsing
- `WikiPlaceFilter`：P31 白名單過濾邏輯（9 組實測資料當 fixture）
- `WikidataCategoryMapper`：各 P31 → PlaceCategory 對應
- `PlacesRepositoryImpl`：注入 fake service，驗證動態 radius、語言 fallback 行為

### Widget 測試

- `ExploreScreen` 既有測試應**無變化通過**（Repository interface 未變）

### 手動驗證

實作完成後，以這 9 個座標手動驗證結果合理：
- 台北 101 / 京都清水寺 / 台南舊城 / 巴黎艾菲爾 / Cinque Terre / 舊金山金門橋 / Stowe VT / 澎湖馬公 / 北海道富良野

## 不在本次範圍（YAGNI）

- ❌ `foodMarket` 類別對應（Wikidata 沒好類別）
- ❌ OSM / Overpass 作為補強資料源
- ❌ 並發批次查詢
- ❌ 移除 Google Maps Flutter 套件（地圖顯示仍依賴）
- ❌ Unsplash/Pexels 圖片 fallback

## 風險與緩解

| 風險 | 可能性 | 影響 | 緩解 |
|---|---|---|---|
| 名店被分為 `company` 被誤殺（如七味家本舗）| 中 | 低 | 可接受；未來視需求擴充白名單 |
| 小鎮結果不足 | 中 | 中 | 動態 radius 放大 |
| Wiki API 服務中斷 | 低 | 高 | 本地 cache 仍可提供曾查過的地點 |
| P31 白名單遺漏重要類別 | 中 | 中 | 先實作，手動驗證時蒐集 miss case |
| Place ID 格式變更 | 低 | 中 | cache schema version 處理 |

## 成功指標

1. 全部 9 個手動驗證座標產生合理景點清單（景點保留率 ≥ 90%、雜訊 ≤ 1 筆）
2. 既有 explore 相關 widget 測試全過
3. 新增的 unit test 覆蓋關鍵流程
4. `fvm flutter analyze --fatal-infos` 無錯誤
