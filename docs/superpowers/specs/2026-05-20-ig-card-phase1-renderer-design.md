# IG 圖卡發文 — Phase 1：Card Renderer MVP

**Date:** 2026-05-20
**Status:** Design — draft for approval
**Scope:** Backend-only Python module that renders the E0c card design as a 1080×1350 PNG. No DB, no Gemini, no IG publishing.

---

## 背景

使用者希望每日故事審核通過後，自動將故事內容渲染為符合「E0 · 朱印方塊（Eiffel · 中文版）」設計的圖卡並貼到 IG Feed。整體 feature 拆為 4 個獨立 spec，本 spec 為 Phase 1：

- **Phase 0** — IG token 取得與設定（已 specced：`docs/superpowers/specs/2026-05-20-ig-auto-post-token-setup-design.md`）
- **Phase 1（本 spec）** — Card renderer MVP（純渲染、無資料層）
- **Phase 2** — `daily_stories` schema 擴充 + Gemini prompt 改寫，使 row 直接包含圖卡所需所有欄位
- **Phase 3** — Publisher 串接渲染器 + Supabase Storage 上傳，並把圖卡 URL 用於 IG Feed 發文

Phases 1–3 各自一個 PR；Phase 0 由使用者瀏覽器手動跑，不阻擋 Phase 1/2 開發。

## Phase 1 目標

提供一個 Python 函式 `render_card(content) -> bytes`，吃下符合 E0c 設計所需的純資料 dataclass，回傳一張 1080×1350 PNG 的 bytes。

成功判準（Phase 1 alone）：
1. 用 spec 提供的 Eiffel demo 資料呼叫 `render_card()` → 得到 1080×1350 PNG
2. 視覺上跟設計檔 `IG Card Variants.html` 內的 **E0c · 朱印方塊（Eiffel · 中文版）** 一致：
   - 上半 760px 景點照（朱紅 + 墨色雙色調濾鏡 + grain）
   - **無章節 eyebrow（已從原設計移除）**
   - 紀年 (anno) + 經緯度仍在右上
   - 書脊 (spine) 英文地名仍在左側直書
   - 純中文標題 + 中文副標
   - 下半米色紙質排版、單欄、E0c 朱印方塊 folio band（朱紅菱形 + 雙水平規線）
   - 首段中文 drop-cap
   - 中文 pull quote + 中文 attribution
   - 底部 footer（不重疊內文）
   - 純中文模式

## 非目標 (Phase 1 不做)

- 任何 Supabase / `daily_stories` schema 改動 → Phase 2
- 任何 Gemini prompt 改動 → Phase 2
- 任何 publisher 串接、IG API 呼叫 → Phase 3
- Unsplash API 串接（photo_url 由 caller 提供任意公開 URL；本 phase 用 hardcoded Unsplash demo URL 驗證）
- IG token 設定 → Phase 0
- 雙語 / 純英版面（本 phase 只實作純中文 `lang="ch"`，未來 phase 才考慮擴充）
- 章節 eyebrow（依使用者決議「全面移除章節」）
- 自動化視覺迴歸測試 / pixel-diff（跨平台 font rendering 差異大，本 phase 改用「手動視覺檢查 + 結構性測試」，見「測試策略」段落）

## 系統架構

新增單一 Python 子套件 `backend/src/lorescape_backend/social/card/`，與既有 `social/instagram.py` / `social/publisher.py` 並列、但本 phase 完全不被任何既有模組 import。

```
backend/src/lorescape_backend/social/card/
├── __init__.py          # 對外只暴露 CardContent + render_card
├── renderer.py          # Playwright orchestration
├── content.py           # CardContent dataclass + 驗證
└── template/
    ├── card.html        # Jinja2 template
    ├── card.css         # 整併自原始 card.css + card.text.css + card.photo.css，僅留 E0c (seal) + ZH-only
    └── fonts/           # 本地化 .woff2 字型檔（見「字型」段落）
        ├── CormorantGaramond-Italic500.woff2
        ├── EBGaramond-Regular.woff2
        ├── EBGaramond-Italic.woff2
        ├── NotoSerifTC-Regular.woff2
        ├── NotoSerifTC-Medium.woff2
        └── NotoSerifTC-Black.woff2
```

**對外 API：**

```python
# backend/src/lorescape_backend/social/card/__init__.py
from .content import CardContent
from .renderer import render_card

__all__ = ["CardContent", "render_card"]
```

```python
# backend/src/lorescape_backend/social/card/content.py
from dataclasses import dataclass

@dataclass(frozen=True)
class CardContent:
    """Content payload for the E0c IG card (Chinese-only)."""

    title_ch: str             # 主標題：討厭鐵塔的文學大師
    title_ch_sub: str         # 副標題：莫泊桑的「專屬午餐位」
    location_ch: str          # 地點中文：艾菲爾鐵塔．巴黎
    location_en: str          # 書脊 + 頁腳左用：TOUR EIFFEL · PARIS
    location_coord: str       # 經緯度：48.8584°N · 2.2945°E
    anno_roman: str           # 紀年羅馬數字：MDCCCLXXXIX
    city_ch: str              # 城市單字：巴
    city_en: str              # 城市英文大寫：PARIS
    paragraphs_ch: tuple[str, ...]  # 3-4 段中文敘事，首段首字會自動成為 drop-cap
    pull_quote_ch: str        # 中文 pull quote（含全形引號）
    pull_quote_attrib_ch: str # 中文 attribution（如 ── 莫泊桑，一八八九）
    photo_url: str            # 公開可達的圖片 URL（任意 https URL）
```

```python
# backend/src/lorescape_backend/social/card/renderer.py
def render_card(content: CardContent) -> bytes:
    """Render the E0c card to PNG bytes (1080×1350)."""
```

**渲染流程：**
1. 用 Jinja2 把 `CardContent` 套進 `card.html` 產出 HTML 字串
2. 開 Playwright headless Chromium，viewport 設 1080×1350，device scale factor 1.0
3. `page.set_content(html, wait_until="networkidle")` 載入 — 字型用本地 `file://` 路徑，無需網路
4. `page.screenshot(full_page=False, type="png", omit_background=False)` 取得 PNG bytes
5. 關閉瀏覽器，回傳 bytes

## 字型策略

設計使用 Google Fonts：`Cormorant Garamond`（italic 500）、`EB Garamond`（400, italic 400）、`Noto Serif TC`（400, 500, 900）。

採 **bundle 本地字型** 策略：
- 字型檔下載一次，commit 進 `social/card/template/fonts/` 目錄
- `card.css` 改用 `@font-face` 載入 `file://` 路徑（或 template 渲染時注入絕對路徑）
- 不依賴執行時網路、不依賴 Google Fonts CDN

授權：上述三者皆為 SIL OFL / Apache 2.0，可自由 redistribute（需保留 `LICENSE.txt` 在字型目錄）。

字型檔位置：用 `fonts.google.com` 下載各 weight 的 `.woff2`，commit 進 repo。

## E0c 設計細節（從 chat 萃取）

來源檔：`/tmp/ig-design/lorescape-ig/project/{card.jsx, card.css, card.text.css, card.photo.css, data.js}`

實作差異要點：
- `lang="ch"` 模式 → 套用 `.ls-text--single.is-ch`，單欄、字級放大、`padding: 52px 110px 40px`
- `folio="seal"` 模式 → 套用 `.ls-folio--seal`：
  - 雙水平規線（`border-top` + `border-bottom`）
  - 中央 14×14px 朱紅菱形 (`.ls-folio__seal`，`transform: rotate(45deg)`)，外層 `box-shadow: 0 0 0 4px var(--paper)` 製造浮雕感
- `.ls-foot` 從 `position: absolute` 改成 grid flow（`grid-column: 1 / -1; margin-top: 28px; border-top: 1px solid var(--rule-soft)`），避免內容增長時與底部重疊
- `.ls-eyebrow`（左上角章節）整塊**移除**（依使用者決議）

Demo 資料（用於開發 + Phase 1 驗證）：

```python
EIFFEL_DEMO = CardContent(
    title_ch="討厭鐵塔的文學大師",
    title_ch_sub="莫泊桑的「專屬午餐位」",
    location_ch="艾菲爾鐵塔．巴黎",
    location_en="TOUR EIFFEL · PARIS",
    location_coord="48.8584°N · 2.2945°E",
    anno_roman="MDCCCLXXXIX",
    city_ch="巴",
    city_en="PARIS",
    paragraphs_ch=(
        "西元一八八九年艾菲爾鐵塔甫落成，巴黎的文化圈一致憤怒，"
        "視它為破壞天際線的鋼鐵怪物。其中最痛恨它的，是法國短篇"
        "小說大師——莫泊桑。",
        "莫泊桑曾與多位藝術家聯名抗議，稱鐵塔為「孤獨而荒謬的瞭"
        "望塔」。然而巴黎市民很快發現一個矛盾的景象：每日中午，"
        "莫泊桑準時出現在鐵塔二樓的餐廳。",
        "有人忍不住問他：「您不是最討厭這座塔嗎？」他一邊切著牛"
        "排，沒好氣地回答──",
    ),
    pull_quote_ch="「因為在這裡吃飯，是全巴黎唯一一個我『看不見』艾菲爾鐵塔的地方。」",
    pull_quote_attrib_ch="—— 莫泊桑，一八八九",
    photo_url="https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1400&q=80&auto=format&fit=crop",
)
```

## 測試策略

**結構性測試（自動化 / 跨平台可靠）：**
- `render_card(EIFFEL_DEMO)` 回傳的 bytes 是合法 PNG（用 PIL `Image.open(BytesIO(bytes))`）
- 解碼後尺寸為 `1080 × 1350`
- 模式為 `RGB` 或 `RGBA`（任一可）
- Jinja2 template 對 demo 資料渲染後的 HTML 包含預期字串（標題、首段、引文、attribution）

**視覺檢查（手動，由開發者執行）：**
- 跑一個小 CLI：`python -m lorescape_backend.social.card.renderer eiffel` → 寫出 `/tmp/eiffel.png`
- 開啟 PNG，視覺對照 chat 中 E0c · Eiffel 中文版的截圖（chat 描述見背景段落）
- Phase 1 PR 須附 demo PNG 圖檔給 reviewer 對照

**不在 Phase 1 做：**
- Golden-file pixel diff（font rendering 跨平台差異大，不穩）
- End-to-end IG publishing test

## 依賴

新增到 `backend/pyproject.toml`：
- `playwright>=1.45,<2`
- `jinja2>=3.1,<4`
- `pillow>=10,<12`（測試用，驗證 PNG metadata）

新增到 `backend/Dockerfile`：
- 安裝 Playwright Chromium：`uv run playwright install --with-deps chromium`
- 預期 image 增大約 ~250MB

## 風險與權衡

1. **Docker image 變大 (~250MB)** — Playwright + Chromium 體積大。可考慮多階段 build 或 base image 換 `mcr.microsoft.com/playwright/python`，但本 phase 為求最小變動先採直接 `pip install` 路徑，部署慢一點可接受。
2. **首次 cold-start 渲染慢** — Chromium 啟動約 0.5–2s。每天只跑一次 publish，可接受。如未來高頻使用，可改 Playwright `browser_context` 重用或 persistent browser。
3. **字型 commit 進 repo（~1MB）** — 取捨：repo 變大 vs 渲染穩定 vs 部署簡單。選擇穩定優先。
4. **PNG bytes 在記憶體** — 1080×1350 PNG 約 < 1MB，記憶體無壓力，不需 stream 到檔案。

## 參考檔案 / 設計來源

- 設計來源：`/tmp/ig-design/lorescape-ig/project/{card.jsx, card.css, card.text.css, card.photo.css}`
- 對話脈絡：`/tmp/ig-design/lorescape-ig/chats/chat1.md`（含 E0c 決策過程）
- 既有後端結構：`backend/src/lorescape_backend/social/{publisher,instagram,caption}.py`
- 既有 Dockerfile：`backend/Dockerfile`
- 既有 pyproject：`backend/pyproject.toml`
