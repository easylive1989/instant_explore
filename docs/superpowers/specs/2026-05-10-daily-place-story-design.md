# 每日景點故事 (Daily Place Story) 設計

**日期**: 2026-05-10
**狀態**: Draft

## 背景與目標

讓使用者每次打開 app，能在 Explore 首頁看到「今日故事」——一則關於某個世界知名景點的真實歷史短文。每天全球統一一個景點，以 zh-TW 與 en 兩種語言呈現。內容由 Gemini 在後端排程生成，Wikipedia 作為事實來源以避免幻覺。

> 這是「Lorescape — AI pocket historian」品牌定位的延伸：把「歷史導覽」從「使用者主動到達景點」擴展成「每天主動推送一段歷史」。

## 範圍

### 包含
- VPS 上的 Python (FastAPI) 後端服務，承載每日 cron job 與未來其他 API
- Supabase 兩張新表：`daily_story_places`（景點主表）、`daily_stories`（每日生成的故事）
- 從 Wikipedia World Heritage Sites 自動抓候選景點清單，人工篩選後匯入
- 排程：每天 23:30 (Asia/Taipei) 跑生成 job，00:00 切換為「今日故事」
- 失敗處理：cron 內 retry 3 次，全部失敗則發 Discord webhook，app 端顯示「今日故事準備中」+ 引導到歷史頁
- App 端：Explore 首頁頂端 pinned 卡片 + 點進去詳細頁 + 歷史頁（無限往回翻）

### 不包含（明確排除）
- 個人化推薦（同一天全球同一則）
- 使用者互動（評論、收藏、分享每日故事）—— MVP 不做
- 推播通知（先做卡片就好）
- 圖片授權資訊抓取（MVP 先存 image_url，授權資訊之後再加）
- 其他語言（先做 zh-TW + en，其他語言之後再擴）

## 系統架構

```
┌─────────────────────────────────────────────────────┐
│ VPS (Python + FastAPI + cron)                       │
│                                                     │
│  daily_story_job (cron 每天 23:30 Asia/Taipei)      │
│  ├─ 從 daily_story_places 挑下一個 unused 景點       │
│  ├─ 抓 Wikipedia 內容 (英文作 ground truth)         │
│  ├─ 抓對應語言 Wikipedia URL (langlinks)            │
│  ├─ 對 zh-TW 與 en 各呼叫 Gemini 一次               │
│  ├─ 寫入 Supabase daily_stories                     │
│  ├─ UPDATE daily_story_places.used_at = now()       │
│  └─ 失敗 retry 3 次 → 全失敗發 Discord webhook       │
│                                                     │
│  FastAPI app (預留給未來其他 API)                    │
└─────────────────────────────────────────────────────┘
                ↓ service_role key (寫入)
        ┌──────────────────┐
        │   Supabase DB    │
        │  - daily_story_  │
        │      places      │
        │  - daily_stories │
        └──────────────────┘
                ↑ anon key (僅 SELECT)
        ┌──────────────────┐
        │  Flutter App     │
        │  Explore 首頁     │
        │  pinned card     │
        │  + 詳細頁 + 歷史 │
        └──────────────────┘
```

**RLS 設計**：
- Server 用 `service_role` key（繞過 RLS，可寫入）
- App 用 `anon` key（受 RLS 限制，只能 SELECT）
- 達成「app 只能讀、server 才能寫」的需求

## 資料表 Schema

```sql
-- 景點主表 (admin 透過 Supabase Dashboard 維護)
create table public.daily_story_places (
  id uuid primary key default gen_random_uuid(),
  name text not null,                    -- 英文景點名（內部識別用）
  wikipedia_title_en text not null,      -- 英文 Wikipedia 條目標題
  country text not null,                 -- 例: "Italy"
  is_active boolean not null default true, -- 篩掉的設 false
  used_at timestamptz,                   -- null = 從未用過；用過會記時間
  created_at timestamptz not null default now()
);
create index on public.daily_story_places (is_active, used_at nulls first, created_at);

-- 每日故事 (server 寫入,一天兩個 row：每語言一個)
create table public.daily_stories (
  id uuid primary key default gen_random_uuid(),
  publish_date date not null,            -- 故事在哪天「登場」(Asia/Taipei 換日)
  language text not null,                -- 'zh-TW' or 'en'
  place_id uuid not null references public.daily_story_places(id),
  place_name text not null,              -- 在地化的名稱
  place_location text not null,          -- 在地化的地點
  era text not null,                     -- 故事年代
  story text not null,                   -- 主體故事 (300-500 字)
  image_url text,                        -- Wikipedia 圖片直連 URL
  image_attribution text,                -- 圖片授權 (MVP 留空)
  wikipedia_url text not null,           -- 對應語言 Wikipedia 連結
  created_at timestamptz not null default now(),
  unique (publish_date, language)        -- 同一天同一語言只一則
);
create index on public.daily_stories (publish_date desc, language);

-- RLS
alter table public.daily_story_places enable row level security;
alter table public.daily_stories enable row level security;

-- daily_stories: anon 可讀「今天 (含) 之前」的故事
create policy "anon can read published stories"
  on public.daily_stories for select to anon, authenticated
  using (publish_date <= (current_date at time zone 'Asia/Taipei')::date);

-- daily_story_places: 不開放 anon (沒有 policy = 預設拒絕)
```

**設計理由**：
- `unique (publish_date, language)`：保證一天一語一則，重複跑 cron 不會生重複
- `publish_date <= today` 的 RLS：未來若改成預生 N 天份也不會被 app 端提前看到
- `image_url` 直接存 Wikipedia 圖片 URL：Wikipedia 圖片有自己的 CDN，不需重新上傳
- `place_name`/`place_location`/`era` 也跟著語言存：景點名與地點的中英文翻譯，由 Gemini 在生故事時一起回傳

## Server 端：daily_story_job 流程

### Step 1：挑景點
```
SELECT id, wikipedia_title_en
FROM daily_story_places
WHERE is_active = true AND used_at IS NULL
ORDER BY created_at
LIMIT 1;
```
- 全部用過後（query 回 0 行）：`ORDER BY used_at ASC` 重新挑最舊的，並更新 `used_at`

### Step 2：抓 Wikipedia 英文內容（作為 ground truth）
- `GET https://en.wikipedia.org/api/rest_v1/page/summary/{title}` → 拿 `extract`（前段純文字概要）+ `thumbnail.source`（圖片 URL）
- 若 extract 太短（< 500 字），改抓 `GET .../api/rest_v1/page/html/{title}` 或 MediaWiki API 取更完整內容

### Step 3：找對應語言 Wikipedia URL
- 用 MediaWiki API `?action=query&prop=langlinks&titles={title}&lllang=zh` 取 zh 條目標題
- zh 有：`wikipedia_url = https://zh.wikipedia.org/wiki/{zh_title}`
- zh 沒有：fallback 用英文 URL

### Step 4：對每個語言呼叫 Gemini
- SDK：`google-genai`（新版 Python SDK）
- Model：`gemini-2.5-flash`（快、便宜、品質夠）
- Temperature：0.3（低創造性、忠實 grounding）
- 用 `response_mime_type="application/json"` + `response_schema` 強制 JSON 輸出

**Prompt 結構**：
```
System / Instructions:
You are a historian. You will write a true historical short story about
a famous landmark, based STRICTLY on the Wikipedia content provided.
Do NOT introduce any historical facts, names, or events that do not
appear in the source material. If the source is insufficient for a
specific claim, omit it rather than invent.

User:
Source material (Wikipedia extract for "{wikipedia_title_en}"):
<<< {wikipedia_extract} >>>

Write a 300-500 character true historical story in {language_name}.
Requirements:
- Include at least one specific year or era (e.g., "70-80 CE")
- Include at least one real historical figure named in the source
- Describe one concrete historical event from the source
- End with the place name, location, and approximate era

Output JSON:
{
  "place_name": "Localized place name",
  "place_location": "Localized location (e.g., country/city)",
  "era": "Approximate era of the story",
  "story": "The 300-500 char story body"
}
```

### Step 5：寫入 Supabase
```
INSERT INTO daily_stories
  (publish_date, language, place_id, place_name, place_location, era,
   story, image_url, wikipedia_url)
VALUES (...);
```
- `publish_date` = 隔天的日期（cron 在 23:30 跑，故事屬於明天 00:00 開始的那天）

### Step 6：Mark used
```
UPDATE daily_story_places SET used_at = now() WHERE id = ?;
```

### 失敗處理
- 整個 job 包在 try/except 裡
- Retry 3 次（指數 backoff，例如 1s / 5s / 30s），每次都重新從 Step 1 跑（避免半完成狀態）
- 全失敗 → POST 到 Discord webhook：
  ```json
  {
    "content": "🚨 daily_story_job failed for date YYYY-MM-DD\n```\n<error message + stack trace>\n```"
  }
  ```
- App 端依然優雅降級（看不到當天故事，但能看歷史）

## App 端：Flutter 整合

### 新增 Feature module
```
lib/features/daily_story/
├── data/
│   └── daily_story_supabase_service.dart   # Supabase query
├── domain/
│   ├── models/
│   │   └── daily_story.dart                # Domain model
│   ├── services/
│   │   └── daily_story_service.dart
│   └── use_cases/
│       └── get_today_story_use_case.dart
├── presentation/
│   ├── controllers/
│   │   └── daily_story_controller.dart     # Riverpod notifier
│   ├── screens/
│   │   ├── daily_story_detail_screen.dart  # 詳細頁
│   │   └── daily_story_history_screen.dart # 歷史列表頁
│   └── widgets/
│       └── daily_story_card.dart           # Explore 首頁的 pinned 卡片
└── providers.dart
```

### Domain Model
```dart
class DailyStory {
  final String id;
  final DateTime publishDate;
  final String language;          // 'zh-TW' / 'en'
  final String placeName;
  final String placeLocation;
  final String era;
  final String story;
  final String? imageUrl;
  final String wikipediaUrl;
}
```

### 顯示邏輯
- **Explore 首頁卡片** (`DailyStoryCard`)：
  - 縮圖（image_url）+ 「今日故事」標籤 + place_name + story 前一兩句作為 preview
  - 點擊 → 進入詳細頁
  - Loading 狀態：skeleton
  - 沒有今日故事（cron 失敗 / 還沒 publish）：顯示「今日故事準備中，看看過去的故事」+ 按鈕進入歷史頁
- **詳細頁** (`DailyStoryDetailScreen`)：
  - 大圖 + place_name + place_location + era + 完整 story
  - 底部「閱讀更多 (Wikipedia)」按鈕 → external launch wikipedia_url
  - 右上角「歷史」按鈕 → 進入歷史頁
- **歷史頁** (`DailyStoryHistoryScreen`)：
  - `ListView.builder` 列出過去所有故事（按日期 desc）
  - 用 paginated query（一次 20 筆）

### Query
- 今日故事：`SELECT * FROM daily_stories WHERE publish_date <= today AND language = ? ORDER BY publish_date DESC LIMIT 1`
- 歷史頁：分頁查詢，依 publish_date desc

### 語言切換
- 直接用使用者目前的 app locale（`zh-TW` / `en`）對應 query 的 `language` 欄位
- 若使用者切換語言，重新 query 對應語言的故事

## 景點清單初始化（一次性）

1. Server 寫一個 `scripts/import_world_heritage.py` 腳本：
   - 從 Wikipedia 抓 `Category:World Heritage Sites` 或 UNESCO 官方資料的條目清單
   - 過濾掉非景點型條目（純自然、無歷史故事的）
   - 輸出成 CSV：`name, wikipedia_title_en, country`
2. 你（人工）審一輪 CSV，剔除不適合的
3. 把 CSV `\copy` 進 `daily_story_places`

預期 200~400 個景點，足以跑將近一年。之後新增景點：直接在 Supabase Dashboard 手動 INSERT。

## 部署

- VPS 上：
  - Docker compose（推薦）或 systemd service 跑 FastAPI（uvicorn）
  - cron job：`30 23 * * * /path/to/python /app/jobs/daily_story_job.py`（時區設定 `TZ=Asia/Taipei`）
- 環境變數（VPS `.env`）：
  ```
  SUPABASE_URL=...
  SUPABASE_SERVICE_ROLE_KEY=...
  GEMINI_API_KEY=...
  DISCORD_WEBHOOK_URL=...
  ```
- 部署細節（具體 Docker 設定、CI/CD）留到實作 plan 階段

## 不確定但可接受的取捨

| 項目 | 選擇 | 取捨 |
|---|---|---|
| Wikipedia 內容是否足夠 | 用英文 extract（前段概要） | 若太短，改抓更詳細的 HTML 內容 |
| Gemini 偶爾還是會幻覺 | Prompt 強制限制 + temperature 0.3 | 不打算做事後驗證，相信 grounding |
| zh wiki 可能沒對應條目 | Fallback 到英文 URL | 多數知名景點都有 zh 條目 |
| 故事字數 300-500 | 透過 prompt 軟性要求 | Gemini 不一定嚴格遵守，可接受 |
| 圖片授權資訊 | MVP 不抓 | Wikipedia 圖片是 CC BY-SA，未來補上 attribution |

## 後續擴充（不在本 spec 範圍）

- 推播通知（每天定時推「今日故事：xxx」）
- 「一年前的今天」回顧
- 使用者收藏、分享某則故事
- 多語言擴充（日、韓等）
- 圖片授權資訊自動抓取
