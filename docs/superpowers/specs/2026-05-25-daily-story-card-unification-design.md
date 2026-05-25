# Daily Story Card 統一渲染設計

**Date**: 2026-05-25
**Status**: Draft — awaiting user review
**Scope**: 把 `daily_stories.card_*` 欄位從 IG 圖卡專用升級為 IG + App + 雙語共用的主內容欄位

---

## 1. 背景與動機

目前 `daily_stories` 一列同時存兩種格式的故事：

- `story` (text)：純文字、所有語言、給 App + Threads 用
- `card_*_ch` (6 個欄位)：zh-TW only、給 IG card 渲染器用，包含主標、副標、3 段、pull quote、Roman 紀年

兩者同源（zh-TW path 把 `card_paragraphs_ch` 用 `\n\n` join 寫回 `story`），但 App 端只讀 `story`，看不到「主標 + 副標 + drop-cap + 引言」這套品牌化的視覺結構。使用者點開 IG 看到精緻的拾景品牌卡片，再點進 App 卻是平鋪的純文字，品牌一致性斷裂。

本設計把 card 欄位升級為核心內容欄位（雙語都產出、App 也用），並一次性回填所有舊列。

## 2. 目標

- App 詳細頁與首頁 preview 都用 card 風格渲染（主標 + 副標 + 段落 + 引言 + 紀年）
- 視覺鬆散還原 IG card 的拾景品牌調性（Noto Serif TC、drop-cap、照片疊文字、引言區塊）
- en path 也產出 card 欄位，雙語體驗一致
- 舊列（pre-card zh-TW + 所有 en）一次性回填
- 過渡期與欄位缺漏採智慧 fallback，不會出現「半套品牌版」的醜畫面

## 3. 設計決策（brainstorming 結論）

| 決策 | 選項 | 理由 |
| --- | --- | --- |
| en 是否也加 card 欄位 | **B：加** | 雙語體驗一致；schema 統一 |
| App 改造範圍 | **B：詳細頁 + 首頁 preview** | preview 用主標/副標比 placeName 平鋪有張力，但不放 drop-cap/Roman 等重元素 |
| 詳細頁視覺 | **B：鬆散還原 IG 風** | 拿到品牌感，不被像素級還原綁住 |
| 舊列回填 | **B：一次性腳本 + 覆寫 `story`** | `story` 永遠 = `card_paragraphs` join，schema 心智模型乾淨 |
| 欄位 NULL 時的 fallback | **C：故事核心欄位嚴格、裝飾欄位寬鬆** | 要嘛完整品牌版、要嘛乾淨舊版，不出現中間態 |

## 4. Schema 變更

### Migration: `20260525000000_unify_card_fields.sql`

```sql
alter table public.daily_stories
  rename column card_title_ch              to card_title;
alter table public.daily_stories
  rename column card_title_sub_ch          to card_title_sub;
alter table public.daily_stories
  rename column card_paragraphs_ch         to card_paragraphs;
alter table public.daily_stories
  rename column card_pull_quote_ch         to card_pull_quote;
alter table public.daily_stories
  rename column card_pull_quote_attrib_ch  to card_pull_quote_attrib;
-- card_anno_roman 已無 _ch 後綴，不動
```

**不動的欄位：**

- `daily_story_places.card_location_en` / `card_city_ch` / `card_city_en` / `latitude` / `longitude`：admin 策展，並列於同一 place 列，保留現有命名
- `story` / `place_name` / `place_location` / `era`：保留，App fallback 用
- RLS / index / check constraint：不受影響

## 5. Backend 變更

### 5.1 `prompts.py`

`_CARD_PROPERTIES`（原 `_ZH_CARD_PROPERTIES`，去掉 `_ch` 後綴）成為雙語共用：

```python
_CARD_PROPERTIES = {
    "card_title":              {"type": "STRING"},
    "card_title_sub":          {"type": "STRING"},
    "card_paragraphs": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3, "maxItems": 3,
    },
    "card_pull_quote":         {"type": "STRING"},
    "card_pull_quote_attrib":  {"type": "STRING"},
    "card_anno_roman":         {"type": "STRING"},
}
```

`build_response_schema(language)`：兩語言都回傳 `base + card`，base 都拿掉 `story`（雙語都從 paragraphs join 出來，邏輯統一）。

`_en_body()` 改寫，新增規則：
- 3 段、每段 60–100 英文 words
- drop-cap：第 1 字不可是 The/A/An/In/On/At 等虛詞
- pull quote 用 `"..."` 雙引號
- 出處用 em-dash `—`
- Roman 紀年規則（語言無關，與 zh-TW 共用）

### 5.2 `gemini_client.py`

`GeneratedStory` dataclass：

```python
@dataclass
class GeneratedStory:
    place_name: str
    place_location: str
    era: str
    threads_summary: str
    hashtags: list[str]
    card_title: str
    card_title_sub: str
    card_paragraphs: tuple[str, ...]
    card_pull_quote: str
    card_pull_quote_attrib: str
    card_anno_roman: str
    # 移除：story（雙語都從 card_paragraphs join 而來）
```

### 5.3 `story_writer.py` / `job.py`

`job.py` 拿掉 zh-TW 專屬分支，兩語言走同一邏輯：

```python
story_text = "\n\n".join(story.card_paragraphs)
```

`story_writer.insert_story` 的 payload 不再有 conditional：所有 card 欄位都列入。

### 5.4 `social/card/mapper.py`

只改 column 讀取名稱（`row["card_title_ch"]` → `row["card_title"]` 等）。IG card publisher 行為不變、仍只發 `language == 'zh-TW'` 的列（卡片字型/排版只測過中文）。

### 5.5 測試

更新：
- `test_prompts.py`：兩語言都驗 schema 含 card 欄位、`story` 已從 base 移除；驗 en `_en_body()` 含 drop-cap / pull quote / em-dash 規則字串
- `test_gemini_client.py`：`GeneratedStory` 解析新欄位
- `test_story_writer.py`：寫入 payload 含新欄位名
- `test_job.py`：兩語言都從 `card_paragraphs` join 出 `story_text`
- `test_card_mapper.py`：mapper 讀新欄位名
- `test_publisher.py`：仍只 publish zh-TW

新增：
- `test_backfill_card_fields.py`：fake Supabase + fake Gemini，驗只挑 NULL 列、冪等、`--dry-run` 不打 Gemini、單列失敗不終止

## 6. Frontend 變更

### 6.1 `DailyStory` 模型

```dart
class DailyStory extends Equatable {
  // 既有
  final DateTime publishDate;
  final String language;
  final String placeName;
  final String placeLocation;
  final String era;
  final String story;              // 留著當 fallback
  final String? imageUrl;
  final String wikipediaUrl;

  // 新增（story 層，全 nullable）
  final String? cardTitle;
  final String? cardTitleSub;
  final List<String>? cardParagraphs;
  final String? cardPullQuote;
  final String? cardPullQuoteAttrib;
  final String? cardAnnoRoman;

  // 新增（place 層 join，全 nullable）
  final String? cardLocationEn;
  final String? cardCityCh;
  final String? cardCityEn;
}
```

### 6.2 Repository: `supabase_daily_story_repository.dart`

`SELECT` 改成 join 並要求 place-level 欄位：

```dart
.select('*, daily_story_places!inner(card_location_en, card_city_ch, card_city_en)')
```

`_fromRow` 對應展開新欄位（含 null-safe parse）。

### 6.3 內容完整性判斷（Q5 Option C）

extension：

```dart
extension DailyStoryCardMode on DailyStory {
  bool get hasCardLayout =>
      cardTitle != null &&
      cardTitleSub != null &&
      cardParagraphs != null && cardParagraphs!.length == 3;
}
```

### 6.4 詳細頁 `daily_story_detail_screen.dart`

`Scaffold.body` 分流：

```dart
body: story.hasCardLayout
    ? _CardLayoutBody(story: story)
    : _LegacyLayoutBody(story: story),
```

`_CardLayoutBody` 分兩塊（呼應 IG card 的 photo plate + text plate）：

**`_PhotoPlate`（上半）**
- 背景：照片 fit cover + tint overlay（黑半透明），固定 16:9 或 3:4
- 右上：`Anno · {cardAnnoRoman}`（若 null 不顯示）
- 左下：spine 小字 `cardLocationEn`（uppercase + letter-spacing，若 null 不顯示）
- 底部：`cardTitle` 大字 + `cardTitleSub` 小字（核心欄位，永遠存在）

**`_TextPlate`（下半）**
- 3 段 Noto Serif TC（zh-TW）/ Noto Serif（en）
- 第 1 段首字 drop-cap（`RichText` + `WidgetSpan` 包大字 Container）
- pull quote 區塊：左右引號樣式 + 出處（若 `cardPullQuote` null 整塊不顯示）
- footer：`{placeLocation} · {cardCityCh} {cardCityEn}`，缺哪個拆哪個（cityCh + cityEn 都缺則 footer 只顯示 placeLocation）

`_LegacyLayoutBody`：保留現有 layout，原封不動（placeName + meta row + `_StoryBody` 切段）。

### 6.5 首頁 preview `daily_story_card.dart`

`_StoryCard` 同樣分流：

```dart
return story.hasCardLayout
    ? _CardPreviewCard(story: story, onTap: ...)
    : _LegacyPreviewCard(story: story, onTap: ...);  // 現有 _StoryCard
```

`_CardPreviewCard`：
- 圖片 16:9 banner（同既有）
- 主標：`cardTitle`（1 行 ellipsis）
- 副標：`cardTitleSub`（1 行 ellipsis）
- 摘要：`cardParagraphs[0]` 前 60 字 + …（2 行 ellipsis）
- CTA 不變
- 不放 Roman 紀年 / pull quote / drop-cap（保持輕量）

### 6.6 字型

`pubspec.yaml` 若尚未有 `google_fonts` 則加入。詳細頁 card 區塊使用 `GoogleFonts.notoSerifTc(...)`（zh-TW row）或 `GoogleFonts.notoSerif(...)`（en row）。

### 6.7 在地化

新 card layout 的可見文字全部來自 DB 欄位本身，不再有 "Location:" "Era:" 這類 meta label。既有 `daily_story.*` i18n key 只有 fallback layout 還會用。

### 6.8 Tests

依 `flutter-widget-tests` skill 風格：

`daily_story_detail_screen_test.dart`
- given 完整 card → 顯示 `_CardLayoutBody`、看得到主標 / 副標 / drop-cap 首字 / 3 段 / pull quote / Roman
- given `cardParagraphs` null → 回退 `_LegacyLayoutBody`
- given 完整 card 但 `cardPullQuote` null → card layout 但無 quote 區塊
- given `cardLocationEn` null → card layout 但無 spine
- footer 城市拼接：`(都有, 缺 en, 缺 ch, 都缺)` 四種輸出

`daily_story_card_test.dart`（preview）
- given 完整 card → 主標 = cardTitle、副標 = cardTitleSub、摘要 = paragraphs[0] 前 60 字
- given 不完整 → 走 legacy preview

`supabase_daily_story_repository_test.dart`：含 place-level join 的 row 能正確 parse、各 null 組合不 crash。

## 7. Backfill 腳本

新檔：`backend/scripts/backfill_card_fields.py`

**範圍**：`daily_stories` 中 `card_paragraphs IS NULL` 的所有列。

**流程**：

```
1. SELECT id, language, place_id FROM daily_stories WHERE card_paragraphs IS NULL
2. 對每列：
   a. SELECT wikipedia_title_en FROM daily_story_places WHERE id = place_id
   b. fetch Wikipedia extract（重用既有 wikipedia_client.py）
   c. gemini_client.generate_story(language, wikipedia_title, extract)
   d. UPDATE daily_stories SET
        card_title              = ...,
        card_title_sub          = ...,
        card_paragraphs         = ...,
        card_pull_quote         = ...,
        card_pull_quote_attrib  = ...,
        card_anno_roman         = ...,
        story                   = "\n\n".join(card_paragraphs),
        place_name              = story.place_name,
        place_location          = story.place_location,
        era                     = story.era
      WHERE id = ?
   e. print [N/total] {language} {publish_date} {place_name_en} OK
3. 最後印 summary：成功 X / 失敗 Y / 預估 Gemini token Z
```

**設計重點**：
- **冪等**：可重跑；已補的列不會再處理
- **失敗隔離**：單列失敗不終止；錯誤累積後一次印出（含 row id + message）；下次重跑會再選中
- **不動的欄位**：`threads_summary`、`hashtags`、`discord_message_id`、`review_state`、`published_at`、`threads_post_id`、`ig_post_id`、`publish_error`、`image_url`、`image_attribution`、`wikipedia_url`、`created_at`
- **執行方式**：本地 `uv run python -m scripts.backfill_card_fields`，吃環境變數（SUPABASE_URL、SUPABASE_SERVICE_ROLE_KEY、GEMINI_API_KEY）；不入 CI/cron
- **place 欄位不碰**：腳本跑完印提示「N 個 places 尚未填 card_location_en，請到 Supabase Dashboard 補齊」
- **`--dry-run`**：只 SELECT + 印「將處理 X 列」，不打 Gemini

## 8. 部署順序

```
Step 1：合併 PR（程式碼進 master，未 deploy）
Step 2：跑 migration（rename _ch → 無後綴）
Step 3：deploy backend 到 VPS（與 Step 2 背靠背）
Step 4：本地跑 backfill --dry-run 估列數與成本
Step 5：本地跑 backfill 真實寫入
Step 6：admin 在 Supabase Dashboard 補齊 places 的 card_location_en / card_city_* / lat-lng
Step 7：App 新版上架
```

**Step 2 ↔ Step 3 短視窗風險緩解**：
- 開始 Step 2 前確保新 backend image build 完、ready to ship
- migration 與 backend restart 串成單一 deploy script
- 避開 daily job cron 視窗（09:00 / 21:00 Asia/Taipei）

**為何 App store 的舊版本不會炸**：
- App 用 `select('*')`，自動拿到新欄位（不會因為欄位多了而 fail）
- App `_fromRow` 只 parse 它認識的欄位；新加的 card 欄位舊 App 直接 ignore
- 舊 App 繼續用 `story` 渲染舊 layout，不受影響

## 9. Out of scope

- IG card publisher 的視覺改造（只跟著 column rename，視覺不動）
- Threads publisher 流程（仍用 `threads_summary`，與本案無關）
- 第三語言（如日文）支援：schema 已可承載，但 prompt body 與 backfill 不在本案
- App 詳細頁的分享 / bookmark 按鈕（既有功能保留）
- 字型授權審核（Noto Serif TC 為 SIL OFL，已可商用）

## 10. 風險與緩解

| 風險 | 緩解 |
| --- | --- |
| Step 2/3 短視窗未對齊，daily job 失敗 | deploy script 串連；避開 cron 視窗；migration 後立即 restart |
| Backfill 成本超預期 | `--dry-run` 先估；單列失敗隔離，不會一次燒光 |
| Gemini 重生內容與舊版不同，使用者察覺 | 本案明確採用「`story` 永遠 = card_paragraphs join」，視為新版上線，不視為 bug |
| 新 place 加進來時 admin 忘了填 place-level 欄位 | App 採寬鬆退化，spine/footer 缺欄不顯示，不會崩 |
| en `drop-cap` 規則 prompt 不夠強，產生 "The..." 開頭 | test 驗 prompt 字串含規則；上線後監控前幾天輸出，必要時調 prompt |

## 11. 驗收清單（手動）

- [ ] migration 在 local supabase 跑通
- [ ] backfill `--dry-run` 列數符合預期
- [ ] backfill 真實寫入後，IG card publisher 仍能成功發 zh-TW 列
- [ ] App 模擬器 zh-TW locale → 看到新 card layout
- [ ] App 模擬器 en locale → 看到新 card layout
- [ ] 把某列 `card_paragraphs` 改 NULL → App 回退 legacy layout
- [ ] 把某 place 的 `card_location_en` 改 NULL → card layout 仍走，spine 不顯示
- [ ] App 舊版本（store 上的）讀 production DB → 仍正常顯示 legacy layout
