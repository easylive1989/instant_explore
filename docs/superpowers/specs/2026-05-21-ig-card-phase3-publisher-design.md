# IG 圖卡發文 — Phase 3：Publisher 串接 + Supabase Storage

**Date:** 2026-05-21
**Status:** Design — draft for approval
**Scope:** 把 Phase 1 renderer 接到 21:00 publisher：從 zh-TW row + place row 組 `CardContent` → 渲染 PNG → 上傳 Supabase Storage 取得 public URL → 用該 URL（與 zh-TW 中文 caption）發 IG。Threads 路徑不動。

---

## 背景

- Phase 1 已交付 `render_card(CardContent) -> bytes`。
- Phase 2 已交付 `daily_stories.card_*` 與 `daily_story_places.card_*/latitude/longitude` 欄位（zh-TW row 才填）。
- 現行 publisher (`backend/src/lorescape_backend/social/publisher.py`) 只讀 en row、用 `daily_stories.image_url`（Wikipedia 圖片）當 IG 圖片。
- Phase 3 把 IG 圖片切換成「自家渲染的圖卡」、IG caption 切換成中文（en 仍負責 Threads）。Threads 行為完全不動。

整體 4 phase 拆解見 `docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md` 背景段落。

## 目標

1. 提供 `build_card_content(daily_story_row, place_row) -> CardContent | None`，把 zh-TW row + place row 對映到 `CardContent`；任一必要欄位為 NULL 回傳 `None`（讓 publisher 優雅跳過 IG）。
2. 提供 `upload_card_png(supabase, png_bytes, *, path) -> str`，把 PNG 上傳到公開 Supabase Storage bucket，回傳可被 Meta servers 直接 GET 的 URL。
3. 改寫 publisher：除了現有 en row，另載 zh-TW row 與對應 place row；當 CardContent 可組出來時，渲染 → 上傳 → 以該 URL 與「中文 caption」呼叫 `instagram.publish`。
4. 中文 IG caption 沿用既有 `build_full_caption(StoryCopy)`，欄位餵 zh-TW row 的資料（place_name/era/story/threads_summary/hashtags 都已是中文）。
5. NULL-check：CardContent 組不出來 → IG 跳過、Threads 維持（en 路徑），事件寫入 log；row 狀態仍依 Threads 結果落為 `published` / `failed`。

## 非目標 (Phase 3 不做)

- Threads 的圖片或文字改動。Threads 與 en row 維持現狀。
- 自動清理舊 PNG（保留作為 audit trail；單張 ~1MB，量極小）。
- 圖卡英文版（Phase 1 spec 已排除）。
- Discord review 流程改動（仍 review en row 一次，IG 不另開 review；en 通過即放行 IG）。
- 自動建立 storage bucket（首次部署操作者透過 Supabase Dashboard 建好 + 設成 public，文件另出）。
- 變更 caption 模板長度限制 / 排版（YAGNI；當前 2200 char IG limit 對中文足夠）。

## 系統架構

```
21:00 cron → publisher.run_publish_job(date)
  └─ for each pending (en) row:
       1. discord_review.check_reaction → approved/rejected/none
       2. if approved:
            ├─ load zh-TW row for same date         (NEW)
            ├─ load place row by place_id            (NEW)
            ├─ build_card_content(zh_row, place_row) (NEW; returns None if any field missing)
            ├─ threads.publish(en row content)       (existing, unchanged)
            └─ if card_content is not None:
                 ├─ render_card(card_content)          (Phase 1 renderer)
                 ├─ upload_card_png(supabase, png, path=...)  (NEW; returns public URL)
                 └─ instagram.publish(image_url=card_url, caption=zh-TW caption) (existing API, new inputs)
       3. update review_state + ig_post_id + threads_post_id + publish_error
```

### 新模組

```
backend/src/lorescape_backend/social/
├── card/
│   └── mapper.py              # build_card_content(daily_story_row, place_row) -> CardContent | None  (NEW)
└── card_storage.py            # upload_card_png(supabase, png, *, path) -> str public URL              (NEW)
```

**為什麼 mapper 在 card 子套件**：它把 DB 視角轉成 `CardContent` 領域物件，緊密屬於 card 模組，不該汙染 publisher。
**為什麼 card_storage 不放 card/**：上傳行為與圖卡內容無關，只是「PNG bytes → Supabase URL」的基礎設施；放 `social/` 頂層讓未來 caption 圖、Threads 圖等也能重用。

### 對外 API

```python
# social/card/mapper.py
def build_card_content(
    daily_story_row: dict, place_row: dict
) -> CardContent | None:
    """Compose CardContent from a zh-TW daily_stories row joined with its
    daily_story_places row. Returns None if any required field is missing.
    """
```

```python
# social/card_storage.py
def upload_card_png(
    supabase, png_bytes: bytes, *, path: str
) -> str:
    """Upload PNG bytes to the public `ig-cards` bucket at `path`. Returns the
    public URL that Meta servers can fetch.

    Overwrites if the path already exists (allows republishing the same date).
    """
```

## Mapping 規則 (`build_card_content`)

| `CardContent` 欄位         | 來源                                                                   |
|--------------------------|----------------------------------------------------------------------|
| `title_ch`                 | `daily_stories.card_title_ch`                                          |
| `title_ch_sub`             | `daily_stories.card_title_sub_ch`                                      |
| `location_ch`              | `daily_stories.place_name + "．" + daily_stories.place_location`         |
| `location_en`              | `daily_story_places.card_location_en`                                  |
| `location_coord`           | 由 `daily_story_places.latitude/longitude` 即時格式化（見下）              |
| `anno_roman`               | `daily_stories.card_anno_roman`                                        |
| `city_ch`                  | `daily_story_places.card_city_ch`                                      |
| `city_en`                  | `daily_story_places.card_city_en`                                      |
| `paragraphs_ch`            | `tuple(daily_stories.card_paragraphs_ch)` (`text[]` → tuple)            |
| `pull_quote_ch`            | `daily_stories.card_pull_quote_ch`                                     |
| `pull_quote_attrib_ch`     | `daily_stories.card_pull_quote_attrib_ch`                              |
| `photo_url`                | `daily_stories.image_url` (Wikipedia 圖；Phase 1 既有資料，不另查)              |

### `location_coord` 格式化

```python
def _format_coord(latitude: float, longitude: float) -> str:
    lat_dir = "N" if latitude >= 0 else "S"
    lng_dir = "E" if longitude >= 0 else "W"
    return f"{abs(latitude):.4f}°{lat_dir} · {abs(longitude):.4f}°{lng_dir}"
# 48.8584, 2.2945 → "48.8584°N · 2.2945°E"
# -33.8688, 151.2093 → "33.8688°S · 151.2093°E"
```

### NULL-check 邏輯

`build_card_content` 對下列來源全部做 truthy check（空字串、None、空 list、缺少 lat 或 lng 都算缺）：

`card_title_ch, card_title_sub_ch, card_paragraphs_ch, card_pull_quote_ch, card_pull_quote_attrib_ch, card_anno_roman` (from daily_stories)
`card_location_en, card_city_ch, card_city_en, latitude, longitude` (from daily_story_places)
`place_name, place_location, image_url` (from daily_stories)

任一缺漏 → return None，publisher 不會嘗試 IG。

## Storage uploader (`upload_card_png`)

### Bucket 設定（手動，首次部署）

- Bucket 名稱：`ig-cards`
- 類型：**public** bucket（Meta servers 必須以匿名身分 GET）
- File size limit：5 MB（單張圖卡 < 1 MB，留 buffer）
- Allowed MIME：`image/png`

doc：`docs/operations/2026-05-21-ig-cards-bucket-setup.md`（Phase 3 新增）

### 上傳邏輯

```python
def upload_card_png(supabase, png_bytes: bytes, *, path: str) -> str:
    storage = supabase.storage.from_("ig-cards")
    storage.upload(
        path=path,
        file=png_bytes,
        file_options={"content-type": "image/png", "upsert": "true"},
    )
    return storage.get_public_url(path)
```

`upsert=True` 讓同日重跑 publisher 可覆寫上次的 PNG（重渲染後 URL 不變，IG 也只發一次 —— publisher 由 review_state='pending' 守門）。

### Path 慣例

```
<publish_date>/<daily_stories.id>.png      # 例：2026-05-22/3f8a1e9b-....png
```

用 daily_stories row id（uuid）而非 place_id，因為同一景點未來可能在不同日期被選中，分日避免相撞。

### 取得 public URL

`storage.get_public_url(path)` 回傳 `https://<project>.supabase.co/storage/v1/object/public/ig-cards/<path>`。Meta API 接受。

## Publisher 改動 (`social/publisher.py`)

### Row 載入

`_load_pending_rows` 仍只回 en row。新增 helper `_load_zh_tw_row(supabase, target_date)` 與 `_load_place_row(supabase, place_id)`，在 `_try_publish` 內叫。

### `_try_publish` 重寫

```python
def _try_publish(supabase, config: Config, en_row: dict) -> None:
    story_copy_en = caption.StoryCopy(... from en_row ...)   # for Threads
    threads_text = caption.build_threads_caption(story=story_copy_en, ...)

    zh_row = _load_zh_tw_row(supabase, en_row["publish_date"])
    place_row = _load_place_row(supabase, en_row["place_id"])

    card_content = None
    if zh_row is not None and place_row is not None:
        card_content = mapper.build_card_content(zh_row, place_row)

    if card_content is not None:
        story_copy_ig = caption.StoryCopy(
            place_name=zh_row["place_name"],
            era=zh_row["era"],
            story=zh_row["story"],
            threads_summary=zh_row["threads_summary"] or "",
            hashtags=tuple(zh_row.get("hashtags") or ()),
        )
        ig_text = caption.build_full_caption(
            story=story_copy_ig,
            brand_handle=config.brand_handle_ig,
            cta_text=config.cta_text,
        )
    else:
        ig_text = None  # will skip IG

    threads_post_id = ig_post_id = None
    publish_error = None
    try:
        if config.threads_enabled:
            threads_post_id = threads.publish(... en row data ...)

        if card_content is not None and config.instagram_enabled:
            png = render_card(card_content)
            path = f"{en_row['publish_date']}/{zh_row['id']}.png"
            card_url = card_storage.upload_card_png(supabase, png, path=path)
            ig_post_id = instagram.publish(
                ig_user_id=...,
                access_token=...,
                image_url=card_url,
                caption=ig_text,
            )
        elif card_content is None:
            logger.info(
                "Row %s missing card content; skipping IG", en_row["id"]
            )
            publish_error = "ig_skipped_missing_card_content"
        else:
            logger.info("Instagram not configured; skipping IG publish")

    except Exception as exc:
        # ... existing error path: review_state='failed', publish_error=str(exc), notify Discord ...
        return

    _update_state(
        supabase, en_row, "published",
        extra={
            "threads_post_id": threads_post_id,
            "ig_post_id": ig_post_id,
            "publish_error": publish_error,  # None unless IG skipped
        },
    )
```

要點：

- IG 圖片 100% 改用 card URL，不再 fallback 到 `image_url`（Wikipedia 圖）。如果 card content 缺，整個 IG 跳過，**不**降級成發 Wikipedia 圖。
- Threads caption 來源仍是 en row（不動既有測試）。
- IG caption 來源是 zh-TW row（中文）。`build_full_caption` 不需要改 —— 它對欄位內容語言不敏感。`BRAND_TAGS` 維持英文。
- `cta_text` 與 `brand_handle_ig` 來自既有 config。如果之後想分中英文，再加 `cta_text_ig_zh` 之類欄位（Phase 3 不做）。
- 既有 `image_url`-based 邏輯（`if config.instagram_enabled and row.get("image_url")`）**移除**。IG 是否發只取決於 card_content 可否組出。
- `publish_error` 在 IG 成功跳過時填 `ig_skipped_missing_card_content`，row 仍 `published`（因為 Threads 可能成功）。實際失敗（exception）才 `failed`。

### 「IG only enabled」 / 「only Threads enabled」 邊界

維持與目前一致的優雅降級：

| `threads_enabled` | `instagram_enabled` | card_content | 行為                                            |
|-------------------|---------------------|--------------|----------------------------------------------|
| ✓                 | ✓                   | ✓            | Threads + IG 都發；published                    |
| ✓                 | ✓                   | ✗            | Only Threads；published；publish_error 記錄跳過 IG  |
| ✓                 | ✗                   | -            | Only Threads；published                         |
| ✗                 | ✓                   | ✓            | Only IG；published                              |
| ✗                 | ✓                   | ✗            | 都不發；skipped（沒事可做）                         |
| ✗                 | ✗                   | -            | 都不發；skipped                                    |

## Config 變更 (`config.py`)

不加新欄位。`instagram_enabled` 的判斷可能要從目前的「ig 變數齊全」改成「ig 變數齊全且 supabase storage 設好」—— 但 storage 設定無從 config 偵測，預設「ig_user_id + meta_page_access_token 都有就視為啟用」即可，bucket 沒設好的情況由 `upload_card_png` 拋例外觸發既有錯誤路徑。

## 錯誤路徑

- `upload_card_png` 失敗（network、bucket 不存在、權限錯）：raise → 既有 try/except 抓 → `review_state='failed'`、`publish_error=str(exc)`、Discord 通知。
- `render_card` 失敗（Chromium 異常）：同上。
- `instagram.publish` 失敗（Meta API 400）：同上。
- 已成功 upload 但 IG publish 失敗：bucket 留下了一張未被引用的 PNG。可接受（小檔、可手動清；publisher 重跑時會用同 path upsert 蓋過）。

## 測試策略

### `social/card/mapper.py` 單元測試（`tests/test_card_mapper.py`）

- happy path：完整 zh-TW row + place row → 回傳 `CardContent` 各欄位正確（特別檢查 `location_ch = 'X．Y'`、`location_coord` 北/南/東/西半球四個案例）。
- 任一 daily_stories card 欄位 NULL → 回傳 None。
- 任一 place_row card/lat/lng 欄位 NULL → 回傳 None。
- `card_paragraphs_ch` 是 list 時要被轉成 tuple。
- 邊界值：latitude=0、longitude=0 仍合法（赤道 / 本初子午線）；只有 `is None` 算缺。

### `social/card_storage.py` 單元測試（`tests/test_card_storage.py`）

- 用 mock supabase client 驗證：
  - `storage.from_("ig-cards")` 被叫
  - `upload(path=..., file=<bytes>, file_options={"content-type": "image/png", "upsert": "true"})` 被叫
  - 回傳值來自 `get_public_url(path)`
- 不接觸真實網路。

### `social/publisher.py` 擴充測試（`tests/test_publisher.py`）

新增情境：

- 既有 happy path：mock `_load_zh_tw_row`、`_load_place_row`、`mapper.build_card_content`、`render_card`、`upload_card_png`、`instagram.publish`，驗證 IG 收到的 image_url 是 card URL（非 Wikipedia 圖）、caption 用 zh-TW row 內容。
- zh-TW row 不存在 → IG skipped、Threads 仍跑、row 變 `published`、`publish_error='ig_skipped_missing_card_content'`。
- place_row 不存在 → 同上。
- `build_card_content` 回 None → 同上。
- `upload_card_png` 拋 exception → row 變 `failed`、`publish_error` 是該 exception 訊息、Discord 被通知。
- `render_card` 拋 exception → 同上。
- threads_enabled=False、IG enabled、card 完整 → Only IG 發、row 變 `published`。
- 既有 image_url-based skip 行為的測試（如果有）改成 card-content-based。

### 不在 Phase 3 做

- 真的呼叫 Meta API / Supabase Storage 的 e2e 整合測試（環境敏感、要 secret、易壞）。
- Renderer 的 golden-image diff（Phase 1 已決議跨平台不穩）。

## 部署 / 維運

### 首次部署檢查清單

1. Supabase Dashboard 建 `ig-cards` public bucket（依 `docs/operations/2026-05-21-ig-cards-bucket-setup.md` 步驟）。
2. 跑 Phase 2 backfill (`docs/operations/2026-05-21-backfill-card-fields-for-places.md`) 把現有 active places 的 5 個靜態欄位填好。
3. 確認 zh-TW row 內的 6 個 card 欄位有自動由 cron 產出（觀察 1 天）。
4. 21:00 cron 跑 → Discord ✅ → 看 `ig-cards/<date>/<id>.png` 是否被 upload、IG 是否真貼出來。

### 風險與權衡

1. **Bucket public 暴露歷史圖卡** — 接受。圖卡內容本來就是準備發 IG 的公開內容，沒隱私問題。
2. **Phase 2 backfill 沒做完就上 Phase 3** — IG 會大量跳過（log 海）但不會炸。Threads 不受影響。
3. **Meta servers 從 Supabase 拉圖時被 rate-limit / 抖動** — 每天只發一次，影響極小；若發生 IG publish 失敗 → 自動進 failed state + Discord 通知，下次手動重跑即可。
4. **`storage.from_(...).upload(...)` 的 supabase-py 介面** — 不同版本 SDK 簽名略有差異。implementation 時對著 `backend/.venv/.../supabase/...` 的實際 module API 寫；spec 不鎖定確切的 file_options 鍵名（`"upsert"` vs `"x-upsert"`），plan 階段確認。
5. **多帳號 IG / 多語版本** — 未來想發英文版圖卡時可在 mapper 加 language 分支、storage path 加語言前綴。Phase 3 只做 zh-TW。

## 依賴

- 不新增 Python 套件。`supabase-py` 已含 storage client。
- 不新增 Docker layer（Chromium 已在 Phase 1 裝好）。

## 參考檔案

- Phase 1 spec：`docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md`
- Phase 2 spec：`docs/superpowers/specs/2026-05-21-ig-card-phase2-schema-prompt-design.md`
- 既有 publisher：`backend/src/lorescape_backend/social/publisher.py`
- 既有 IG client：`backend/src/lorescape_backend/social/instagram.py`
- 既有 caption builder：`backend/src/lorescape_backend/social/caption.py`
- 既有 storage doc（不同 bucket，僅參考設定流程）：`supabase/STORAGE_SETUP.md`
