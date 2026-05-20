# IG 圖卡發文 — Phase 2：daily_stories Schema + Gemini Prompt

**Date:** 2026-05-21
**Status:** Design — draft for approval
**Scope:** 後端 schema 與 Gemini prompt 改動，使 `daily_stories` row（搭配對應 `daily_story_places` row）直接包含 Phase 1 `CardContent` 所需所有欄位。不動 renderer、不動 publisher、不串 IG。

---

## 背景

Phase 1 已交付 `render_card(CardContent) -> bytes`。`CardContent` 需要的欄位中，目前 `daily_stories` 只覆蓋了一部分（`place_name`, `place_location`, `era`, `story`）。其餘欄位（中文標題、副標、分段內文、pull quote、attribution、羅馬紀年、英文書脊、城市單字、經緯度…）目前無處取得。

Phase 2 把缺的欄位補進 schema 並由 Gemini prompt 一次產出，讓 Phase 3 publisher 不必再做額外的查詢或推導。

整體 phase 拆解見 Phase 1 spec（`docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md`）的「背景」段落。

## 目標

1. `daily_story_places` 擴充，承載「對該景點而言永遠成立、不該由 LLM 每天重生」的圖卡靜態資料（英文書脊、城市單字、經緯度）。
2. `daily_stories` 擴充，承載「每天故事內容才產出」的圖卡動態資料（標題、分段、pull quote、紀年）。
3. Gemini prompt（zh-TW 路徑）改寫成同時產出上述動態欄位。
4. `story_writer.StoryRow` 與 `insert_story()` 支援新欄位寫入。
5. 提供現有「啟用中」景點的 backfill 資料（活躍 places 的靜態欄位手動填）。

## 非目標 (Phase 2 不做)

- 動 `social/card/` 任何程式碼（renderer 是 Phase 1，圖卡組裝是 Phase 3）。
- 寫「daily_stories row → CardContent」的 mapping helper（Phase 3）。
- 串 publisher / IG API（Phase 3）。
- 圖卡的英文版（Phase 1 只跑 ch-only；Phase 2 對 `en` 語言不加任何卡片欄位、prompt 不變）。
- 自動 backfill 歷史 `daily_stories` rows——新欄位皆 nullable，舊資料維持 NULL，Phase 3 publisher 遇到 NULL 就跳過 IG 發文。

## Schema 變更

### `daily_story_places` — 新增 5 個欄位（全 nullable）

| 欄位                | 型別      | 範例                       | 用途                                 |
|-------------------|---------|--------------------------|------------------------------------|
| `card_location_en`  | `text`    | `TOUR EIFFEL · PARIS`      | CardContent.location_en（書脊直書 + footer 左） |
| `card_city_ch`      | `text`    | `巴`                       | CardContent.city_ch（直書單字浮水印）           |
| `card_city_en`      | `text`    | `PARIS`                    | CardContent.city_en（footer 右）              |
| `latitude`          | `numeric` | `48.8584`                  | 算 location_coord 字串用                       |
| `longitude`         | `numeric` | `2.2945`                   | 算 location_coord 字串用                       |

理由：

- 同一景點不論哪天產 story、產幾次，這 5 個值都相同。放 `daily_stories` 等同於請 Gemini 每次重生一份「同樣」的值，會發散且驗證成本高。
- 全部 nullable：migration 即時可用，現有 rows 不受影響；publisher 透過 NULL 判斷該景點是否可發 IG。
- `latitude`/`longitude` 採 `numeric` 而非 `text`，預留未來地圖整合，也好做 lint 檢查。
- `card_location_coord` 字串（"48.8584°N · 2.2945°E"）**不**存 DB；Phase 3 mapping helper 從 lat/lng 即時格式化（避免 DB 內出現可由其他欄位推導的衍生資料）。
- `CardContent.location_ch`（"艾菲爾鐵塔．巴黎"）也**不**存 DB；Phase 3 由 `place_name + "．" + place_location` 組合（既有欄位就夠用）。

### `daily_stories` — 新增 6 個欄位（全 nullable）

| 欄位                              | 型別        | 範例                                                 | 用途                                  |
|---------------------------------|-----------|----------------------------------------------------|-------------------------------------|
| `card_title_ch`                   | `text`      | `討厭鐵塔的文學大師`                                 | CardContent.title_ch                  |
| `card_title_sub_ch`               | `text`      | `莫泊桑的「專屬午餐位」`                             | CardContent.title_ch_sub              |
| `card_paragraphs_ch`              | `text[]`    | `['…', '…', '…']`                                  | CardContent.paragraphs_ch（3 段）     |
| `card_pull_quote_ch`              | `text`      | `「因為在這裡吃飯，是全巴黎唯一一個我『看不見』艾菲爾鐵塔的地方。」` | CardContent.pull_quote_ch             |
| `card_pull_quote_attrib_ch`       | `text`      | `—— 莫泊桑，一八八九`                                | CardContent.pull_quote_attrib_ch      |
| `card_anno_roman`                 | `text`      | `MDCCCLXXXIX`                                      | CardContent.anno_roman（紀年羅馬數字） |

理由：

- 內容導向、依當天 story 而異，本來就是 LLM 的工作。
- `card_paragraphs_ch` 用 PostgreSQL `text[]` 而非 jsonb：純字串陣列、固定維度，`text[]` 較輕。
- 既有 `story` 欄位**保留**，由 writer 以 `"\n\n".join(card_paragraphs_ch)` 自動填入，舊讀者（app UI、Threads）不受影響。
- 全部 nullable：英文 row 與舊 row 都自然不填。
- 一律加 `card_` 前綴：明確表示「為了 IG 圖卡渲染」，避免與既有 `story`、`era` 等欄位混淆。

### Migration 檔

單一 SQL 檔，同時改兩張表：

```
supabase/migrations/20260521000000_add_card_fields_to_daily_stories.sql
```
(實際時間戳由 `supabase migration new` 產生，命名遵循既有檔的 `YYYYMMDDhhmmss` 慣例)

只包含 `alter table … add column …` 語句，無 backfill / 無資料修改。本機與遠端皆 idempotent（既有 rows 收到 NULL）。

### 索引

不另加索引。Phase 3 publisher 已有 `daily_stories_review_state_idx`，那個 index 足夠快速找出 `pending` rows；publisher 取得 row 後再 NULL-check 卡片欄位即可，不需要 partial index。

## Gemini Prompt 變更（zh-TW 限定）

### Response schema

新增 fields（只在 zh-TW 路徑啟用）：

```python
ZH_CARD_SCHEMA_FIELDS = {
    "card_title_ch":              {"type": "STRING"},
    "card_title_sub_ch":          {"type": "STRING"},
    "card_paragraphs_ch": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
    "card_pull_quote_ch":         {"type": "STRING"},
    "card_pull_quote_attrib_ch":  {"type": "STRING"},
    "card_anno_roman":            {"type": "STRING"},
}
```

`prompts.py` 改成：

```python
def build_response_schema(language: str) -> dict: ...
def build_user_prompt(*, language: str, ...) -> str: ...
```

兩者皆對 `language` 分流：`zh-TW` 走「圖卡版」（含上述 6 欄）；`en` 走原本版本（不變）。`gemini_client.generate_story()` 接 `response_schema` 已是參數化，呼叫端傳對應 schema 即可。

### Prompt 文字（zh-TW 新增段落，置於既有規則後）

逐欄給範例與長度約束，要點：

- `card_title_ch`：≤ 14 字、抓故事核心張力的中文主標，不重複 `place_name`。
- `card_title_sub_ch`：≤ 20 字，補足主標的子題，可含全形引號。
- `card_paragraphs_ch`：**剛好 3 段**，每段 60–100 字繁體中文；首段以「具體場景、具體年份、具體人物」開場（為了 drop-cap 美感，首字最好為有實體意義的漢字而非「在」「當」等虛字）。
- `card_pull_quote_ch`：1 句故事中最具張力的引文（最好是真實出處而非虛構）。需用全形引號 `「」` 或 `『』` 包覆。
- `card_pull_quote_attrib_ch`：以全形破折號 `——` 開頭、補出處與年份（年份用中文數字，例：`—— 莫泊桑，一八八九`）。
- `card_anno_roman`：故事發生年代的羅馬數字（西元年），例如 1889 → `MDCCCLXXXIX`。若是區間，取代表性單一年份。

### 與既有 `story` 欄位的關係

- `story` 不再由 Gemini 單獨產出。
- writer 端把 `card_paragraphs_ch` 用 `"\n\n"` 串接後填入 `story`，保持舊讀者相容。
- Response schema 中**移除** zh-TW 的 `story` field（en 路徑保留）。Prompt 的「700-1200 字故事」指引改成「3 段共 180-300 字繁體中文敘事 (`card_paragraphs_ch`)」。
- `threads_summary` 不變（仍由 Gemini 產出，仍存原欄位）。

## Story writer 變更

### `StoryRow` dataclass

```python
@dataclass(frozen=True)
class StoryRow:
    # 既有欄位 …
    place_id: str
    place_name: str
    place_location: str
    era: str
    story: str
    image_url: str | None
    wikipedia_url: str
    threads_summary: str
    hashtags: tuple[str, ...] = field(default_factory=tuple)

    # 新增（皆 Optional，僅 zh-TW row 會填）
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None
```

`insert_story()` 在 `asdict` 之後處理 `card_paragraphs_ch` 的 tuple → list 轉換（Postgres 端為 `text[]`）。

### Job 端組裝

`daily_story/job.py` 在 zh-TW 路徑：

1. 呼叫 `generate_story(..., response_schema=build_response_schema("zh-TW"))`
2. 從 `GeneratedStory` 取出 `card_paragraphs_ch` 等欄位
3. 把 `story = "\n\n".join(card_paragraphs_ch)` 填入 `StoryRow.story`
4. 其餘 card 欄位直接帶入 `StoryRow`

英文路徑完全不變。

### `GeneratedStory` dataclass

新增 `Optional` 欄位以對應 schema，預設 `None`（en 路徑不填）：

```python
@dataclass(frozen=True)
class GeneratedStory:
    place_name: str
    place_location: str
    era: str
    story: str | None  # zh-TW 不直接由 Gemini 產，由 writer 組裝；en 仍由 Gemini 產
    threads_summary: str
    hashtags: tuple[str, ...]
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None
```

## Backfill 既有 places

`daily_story_places` 目前已有若干 `is_active=true` 的 rows。`card_*` + `latitude/longitude` 在 migration 後初始為 NULL。

策略：

- Migration 不做資料 backfill（保持 idempotent 與可回滾）。
- 另存一份**手動 backfill 指引**到 `docs/operations/2026-05-21-backfill-card-fields-for-places.md`，列出每個 active place 的 5 個值，操作者透過 Supabase Dashboard SQL editor 執行 `update`。
- Phase 3 publisher 在嘗試發 IG 前 NULL-check：任一卡片欄位為 NULL → 寫 `publish_error='card_fields_missing'`、`review_state='failed'`，不擋同日 Threads 發文（Threads 不需要這些欄位）。

Phase 2 PR 不一定要把 backfill 跑完——只要文件存在、publisher（Phase 3）的 NULL-check 能 graceful skip 即可。

## 測試策略

**Unit tests（純函式，無 IO）：**
- `test_prompts.py`
  - `build_response_schema("zh-TW")` 包含 6 個新欄位、不含 `story`
  - `build_response_schema("en")` 與目前 `GEMINI_RESPONSE_SCHEMA` 形狀相同
  - `build_user_prompt(language="zh-TW", ...)` 文字中含「card_title_ch」「card_paragraphs_ch」等欄位指引
  - `build_user_prompt(language="en", ...)` 不含 card 欄位字串
- `test_gemini_client.py`
  - `GeneratedStory` 從含新欄位的 JSON 解析成功，tuple 轉換正確
- `test_story_writer.py`
  - `StoryRow` 帶新欄位 → `insert_story` 傳給 supabase 的 payload 包含 `card_paragraphs_ch` 為 list（非 tuple）
  - 舊用法（只填既有欄位）的 payload 仍合法
- `test_job.py`
  - zh-TW 路徑：mock `generate_story` 回傳 `paragraphs`，job 組裝出的 `StoryRow.story = "\n\n".join(...)`
  - en 路徑：mock `generate_story` 不回 card 欄位，組成的 row 中 card 欄位皆 None

**Migration smoke test（半手動）：**
- `supabase db reset` 在本機跑得過、schema 含新欄位
- 倒入一筆現有 `daily_stories` 樣本資料、`update` 新增的卡片欄位、再 `select` 驗證 `text[]` 序列化正確

**手動 end-to-end（PR review 前）：**
- 跑一次 `python -m lorescape_backend.daily_story` 對一個 zh-TW place
- 在 Supabase Dashboard 看到 row 含合理的 `card_*` 值
- 把 row 內容手動轉成 `CardContent` dataclass，用 Phase 1 的 `render_card()` 跑出 PNG，視覺對照 Phase 1 截圖

不在 Phase 2 做：
- 自動 mapping helper test（屬 Phase 3）
- Golden Gemini response test（pin 一份 LLM 輸出當 fixture）——LLM 輸出本就會浮動，pin 沒意義；改靠 schema 驗證

## 依賴

- 不新增 Python 套件。
- 不新增 Docker layer。

## 風險與權衡

1. **Gemini 對「3 段、每段字數」的遵守度** — temperature=0.3 + 結構化 schema 已能拉低變異，但少數情況 LLM 可能給 2 段或 4 段。`minItems=3, maxItems=3` 由 Gemini API 強制，理論上會 retry 自己；若不行，job 端可在解析時補一個 `len(...) != 3` 的 fallback log + 略過卡片欄位（讓 Phase 3 graceful skip）。
2. **Backfill 沒做完就不能發 IG** — 接受。Phase 2 不擋 Threads；publisher (Phase 3) NULL-check 是把關。
3. **Schema 欄位多** — `daily_stories` 已是寬表，再加 6 欄。可接受，因為都是字串 + 小 array。未來若擴 en/雙語版，預期再加同等量 `card_*_en` 欄位，到時可考慮 jsonb 化；現階段 YAGNI。
4. **若 Phase 1 之後 CardContent 介面要改** — 因為新欄位用 `card_` 前綴並對 1:1 對應 `CardContent` field，name drift 仍可能發生。Phase 3 mapping helper 是唯一翻譯點，到時調整即可。

## 參考檔案

- Phase 1 spec：`docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md`
- 既有 schema：`supabase/migrations/20260510000000_create_daily_story_tables.sql`、`20260512220131_add_publish_columns_to_daily_stories.sql`
- 既有 prompt：`backend/src/lorescape_backend/daily_story/prompts.py`
- 既有 gemini client：`backend/src/lorescape_backend/daily_story/gemini_client.py`
- 既有 writer：`backend/src/lorescape_backend/daily_story/story_writer.py`
- 既有 job：`backend/src/lorescape_backend/daily_story/job.py`
