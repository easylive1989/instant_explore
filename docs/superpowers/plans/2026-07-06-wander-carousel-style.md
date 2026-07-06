# Wander 風格 IG Carousel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增第二種可選的 IG carousel 風格「wander」（第三人稱人物敘事 + 暗色壓字，7–9 頁、每頁一張背景照），本機渲染 → Supabase Storage → Discord 審核 → 21:00 publisher 發布。

**Architecture:** 新風格是獨立模組 `social/wander/`（Jinja2 + Playwright，沿用 `social/card/` 的模式），輸出 JPEG。本機 script 上傳 `ig-cards` bucket 並在 `social_posts` 建 pending row（新欄位 `slide_urls`/`caption`）；server 端 publisher 只加一個「預渲染分支」：當天有帶 `slide_urls` 的 carousel row 就讀那則 Discord 圖組訊息的 ✅/❌ 直接發布，否則走現行流程（行為不變）。

**Tech Stack:** Python 3.11+、Jinja2、Playwright（chromium）、Pillow、Supabase（Postgres + Storage）、Discord Bot API、Meta Graph API。

**Spec:** `docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md`

## Global Constraints

- 圖片尺寸 1080×1350（同現有卡片）；發布檔為 JPEG。
- IG carousel 上限 10 張；Discord 附件單檔上限以 9.5MB 為安全值（沿用 `send_reel_for_review.py` 的 `MAX_ATTACHMENT_BYTES` 慣例）。
- `social/card/`（預設風格）的行為必須 byte-for-byte 不變；預設流程既有測試的**斷言不得修改**（必要時允許在 fixture 補 mock 預設值，見 Task 7 Step 4）。
- 預渲染 row 存在時 publisher **不得** fall through 到預設流程，且 `daily_stories` 當天 zh-TW row 須同步標為對應狀態。
- backend 測試：`cd backend && uv run pytest tests/<file> -v`；scripts 測試：`cd scripts && uv run pytest tests/<file> -v`。
- 新表/新欄位遵循本專案慣例：`social_posts` 已有 table-level `GRANT ... TO service_role`（`20260705120000`），新欄位自動涵蓋，migration 註解需說明這點。
- 字型重用 `social/card/template/fonts/`（family 名：`Noto Serif TC`、`EB Garamond`、`Cormorant Garamond`），不新增字型檔。
- Commit 訊息結尾加 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`。
- 在 feature branch `feat/wander-carousel` 上開發（master 目前乾淨）。

## File Structure

```
backend/src/lorescape_backend/social/wander/
├── __init__.py          # re-export：WanderSlide, WanderCarousel, load_carousel, render_carousel
├── content.py           # dataclasses + slides.json/caption.txt 載入與驗證（Task 1）
├── template.py          # Jinja2 render_html + hl 高亮 filter（Task 2）
├── template/
│   ├── wander.html.j2   # 四種 layout：cover / beat / bright / ending（Task 2）
│   └── wander.css       # 視覺系統：overlay、雙色字、金框、落款（Task 2）
└── renderer.py          # Playwright JPEG 渲染 + auto-fit + CLI（Task 3）

backend/src/lorescape_backend/social/
├── card_storage.py      # 加 upload_card_image（content-type 參數化）（Task 4）
├── post_log.py          # record_review_pending 加 slide_urls/caption（Task 6）
└── publisher.py         # 加 _handle_prerendered 分支 + CLI main（Task 7）

backend/src/lorescape_backend/daily_story/
└── discord_review.py    # 加 send_images_for_review（多附件單訊息）（Task 5）

supabase/migrations/
└── 20260706000000_add_prerendered_carousel_to_social_posts.sql（Task 6）

scripts/
├── send_carousel_for_review.py   # 上傳 bucket + Discord 送審 + pending row（Task 8）
└── archive_ig_cards.py           # 每月歸檔：下載到本機後刪 bucket 物件（Task 9）

backend/tests/
├── test_wander_content.py / test_wander_template.py / test_wander_renderer.py
├── test_card_storage.py（擴充）/ test_discord_review.py（擴充）
├── test_post_log.py（擴充）/ test_publisher_prerendered.py
scripts/tests/
├── test_send_carousel_for_review.py / test_archive_ig_cards.py

.claude/skills/lorescape-wander-carousel/SKILL.md   # 手動流程 + 文案規則（Task 10）
```

---

### Task 1: Wander 內容模型（`content.py`）

**Files:**
- Create: `backend/src/lorescape_backend/social/wander/__init__.py`
- Create: `backend/src/lorescape_backend/social/wander/content.py`
- Test: `backend/tests/test_wander_content.py`

**Interfaces:**
- Produces: `WanderSlide`（frozen dataclass：`layout: str`、`photo: str`、`lines: tuple[str, ...]`、`title: str | None`、`title_en: str | None`、`tag_zh: str | None`、`tag_en: str | None`、`highlights: tuple[str, ...]`、`text_position: str`、`overlay: str`）、`WanderCarousel`（`date: str`、`caption: str`、`slides: tuple[WanderSlide, ...]`）、`load_carousel(day_dir: Path) -> WanderCarousel`、`WanderContentError(ValueError)`。
- 慣例：`lines` 裡的空字串 `""` 代表「分隔符」（模板渲染成裝飾線）。

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_wander_content.py
"""wander/content.py — slides.json + caption.txt 載入與驗證."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from lorescape_backend.social.wander.content import (
    WanderContentError,
    load_carousel,
)

VALID = {
    "slides": [
        {
            "layout": "cover",
            "photo": "dress.jpg",
            "tag_zh": "奧地利旅行",
            "tag_en": "Austria",
            "title": "茜茜公主",
            "title_en": "Empress Sisi",
            "lines": ["原本安排訂婚的，", "其實是她的姊姊。", "", "沒想到，"],
        },
        {
            "layout": "beat",
            "photo": "room.jpg",
            "text_position": "left",
            "title": "16 歲時，",
            "lines": ["西西公主嫁入奧地利皇室。"],
            "highlights": ["奧地利皇室"],
            "overlay": "darker",
        },
        {
            "layout": "bright",
            "photo": "palace.jpg",
            "lines": ["比起留在皇宮，", "她更喜歡旅行。"],
        },
        {
            "layout": "ending",
            "photo": "salon.jpg",
            "lines": ["人生難免有許多身不由己。"],
        },
    ]
}


def _write_day_dir(tmp_path: Path, payload: dict, caption: str = "cap") -> Path:
    (tmp_path / "slides.json").write_text(
        json.dumps(payload, ensure_ascii=False), encoding="utf-8"
    )
    (tmp_path / "caption.txt").write_text(caption, encoding="utf-8")
    return tmp_path


def test_load_carousel_parses_slides_and_caption(tmp_path):
    day_dir = _write_day_dir(tmp_path, VALID, caption="今天的故事 #lorescape")
    carousel = load_carousel(day_dir)
    assert carousel.caption == "今天的故事 #lorescape"
    assert carousel.date == tmp_path.name
    assert len(carousel.slides) == 4
    cover = carousel.slides[0]
    assert cover.layout == "cover"
    assert cover.title == "茜茜公主"
    assert cover.lines[2] == ""          # 分隔符慣例
    beat = carousel.slides[1]
    assert beat.text_position == "left"
    assert beat.highlights == ("奧地利皇室",)
    assert beat.overlay == "darker"


def test_defaults_are_dark_overlay_and_left_text(tmp_path):
    day_dir = _write_day_dir(tmp_path, VALID)
    bright = load_carousel(day_dir).slides[2]
    assert bright.overlay == "dark"
    assert bright.text_position == "left"
    assert bright.highlights == ()


@pytest.mark.parametrize(
    "mutate, message_part",
    [
        (lambda p: p["slides"][0].pop("photo"), "photo"),
        (lambda p: p["slides"][0].update(layout="hero"), "layout"),
        (lambda p: p["slides"][1].update(text_position="middle"),
         "text_position"),
        (lambda p: p["slides"][1].update(overlay="red"), "overlay"),
        (lambda p: p["slides"][0].update(lines=[]), "lines"),
        (lambda p: p.update(slides=[]), "slides"),
        (lambda p: p.update(
            slides=[dict(p["slides"][1]) for _ in range(11)]), "10"),
    ],
)
def test_invalid_payload_raises(tmp_path, mutate, message_part):
    payload = json.loads(json.dumps(VALID))
    mutate(payload)
    day_dir = _write_day_dir(tmp_path, payload)
    with pytest.raises(WanderContentError, match=message_part):
        load_carousel(day_dir)


def test_missing_caption_file_raises(tmp_path):
    (tmp_path / "slides.json").write_text(
        json.dumps(VALID, ensure_ascii=False), encoding="utf-8"
    )
    with pytest.raises(WanderContentError, match="caption"):
        load_carousel(tmp_path)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_wander_content.py -v`
Expected: FAIL（`ModuleNotFoundError: lorescape_backend.social.wander`）

- [ ] **Step 3: Write minimal implementation**

```python
# backend/src/lorescape_backend/social/wander/__init__.py
"""Wander-style IG carousel (dark photo-overlay, person-narrative)."""
from .content import (  # noqa: F401
    WanderCarousel,
    WanderContentError,
    WanderSlide,
    load_carousel,
)
```

```python
# backend/src/lorescape_backend/social/wander/content.py
"""Content payload for the wander-style IG carousel.

A day's carousel lives in one directory (`marketing/outputs/daily_carousel/
<date>/`) holding `slides.json` (7–9 slide beats, written by Claude and
reviewed by the operator) and `caption.txt` (the IG caption). `load_carousel`
validates everything up-front so bad content fails before rendering.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

LAYOUTS = ("cover", "beat", "bright", "ending")
TEXT_POSITIONS = ("left", "right", "top", "center")
OVERLAYS = ("dark", "darker", "light")

# IG carousel hard limit.
MAX_SLIDES = 10


class WanderContentError(ValueError):
    """slides.json / caption.txt is missing or malformed."""


@dataclass(frozen=True)
class WanderSlide:
    """One carousel page: a photo, a layout variant and its copy.

    An empty string in `lines` marks a decorative separator between
    line groups (rendered as a thin gold rule).
    """

    layout: str
    photo: str
    lines: tuple[str, ...]
    title: str | None = None
    title_en: str | None = None
    tag_zh: str | None = None
    tag_en: str | None = None
    highlights: tuple[str, ...] = ()
    text_position: str = "left"
    overlay: str = "dark"


@dataclass(frozen=True)
class WanderCarousel:
    """A full day's wander carousel: ordered slides plus the IG caption."""

    date: str
    caption: str
    slides: tuple[WanderSlide, ...]


def load_carousel(day_dir: Path) -> WanderCarousel:
    """Load and validate `<day_dir>/slides.json` + `<day_dir>/caption.txt`.

    `day_dir` is named after the publish date (YYYY-MM-DD); the directory
    name becomes `WanderCarousel.date`.
    """
    slides_path = day_dir / "slides.json"
    caption_path = day_dir / "caption.txt"
    if not slides_path.is_file():
        raise WanderContentError(f"slides.json not found in {day_dir}")
    if not caption_path.is_file():
        raise WanderContentError(f"caption.txt not found in {day_dir}")

    caption = caption_path.read_text(encoding="utf-8").strip()
    if not caption:
        raise WanderContentError("caption.txt is empty")

    try:
        payload = json.loads(slides_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise WanderContentError(f"slides.json is not valid JSON: {exc}")

    raw_slides = payload.get("slides")
    if not raw_slides:
        raise WanderContentError("slides.json has no slides")
    if len(raw_slides) > MAX_SLIDES:
        raise WanderContentError(
            f"IG allows at most {MAX_SLIDES} slides, got {len(raw_slides)}"
        )

    slides = tuple(
        _parse_slide(raw, index) for index, raw in enumerate(raw_slides, 1)
    )
    return WanderCarousel(date=day_dir.name, caption=caption, slides=slides)


def _parse_slide(raw: dict[str, Any], index: int) -> WanderSlide:
    layout = raw.get("layout")
    if layout not in LAYOUTS:
        raise WanderContentError(
            f"slide {index}: layout must be one of {LAYOUTS}, got {layout!r}"
        )
    photo = raw.get("photo")
    if not photo:
        raise WanderContentError(f"slide {index}: photo is required")
    lines = raw.get("lines")
    if not lines:
        raise WanderContentError(f"slide {index}: lines must be non-empty")
    text_position = raw.get("text_position", "left")
    if text_position not in TEXT_POSITIONS:
        raise WanderContentError(
            f"slide {index}: text_position must be one of {TEXT_POSITIONS},"
            f" got {text_position!r}"
        )
    overlay = raw.get("overlay", "dark")
    if overlay not in OVERLAYS:
        raise WanderContentError(
            f"slide {index}: overlay must be one of {OVERLAYS},"
            f" got {overlay!r}"
        )
    return WanderSlide(
        layout=layout,
        photo=photo,
        lines=tuple(lines),
        title=raw.get("title"),
        title_en=raw.get("title_en"),
        tag_zh=raw.get("tag_zh"),
        tag_en=raw.get("tag_en"),
        highlights=tuple(raw.get("highlights") or ()),
        text_position=text_position,
        overlay=overlay,
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_wander_content.py -v`
Expected: PASS（全部）

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/wander/ backend/tests/test_wander_content.py
git commit -m "feat(wander): content model for wander-style carousel

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Wander 模板（`template.py` + `wander.html.j2` + `wander.css`）

**Files:**
- Create: `backend/src/lorescape_backend/social/wander/template.py`
- Create: `backend/src/lorescape_backend/social/wander/template/wander.html.j2`
- Create: `backend/src/lorescape_backend/social/wander/template/wander.css`
- Test: `backend/tests/test_wander_template.py`

**Interfaces:**
- Consumes: `WanderSlide`（Task 1）。
- Produces: `render_html(slide: WanderSlide, *, photo_uri: str, base_url: str = "") -> str`、`template_dir() -> Path`。HTML 特徵（renderer 與測試依賴）：根節點 `.ws-card.ws-card--<layout>.ws-overlay--<overlay>`；auto-fit 目標帶 class `.ws-fit`；高亮詞包在 `<em class="hl">`；每頁有 `.ws-brandmark`（內容 `Lorescape`；ending 頁以 CSS 隱藏）。

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_wander_template.py
"""wander/template.py — 純 HTML 渲染（不開瀏覽器）."""
from __future__ import annotations

from lorescape_backend.social.wander.content import WanderSlide
from lorescape_backend.social.wander.template import render_html

COVER = WanderSlide(
    layout="cover",
    photo="dress.jpg",
    tag_zh="奧地利旅行",
    tag_en="Austria",
    title="茜茜公主",
    title_en="Empress Sisi",
    lines=("原本安排訂婚的，", "其實是她的姊姊。", "", "沒想到，"),
)

BEAT = WanderSlide(
    layout="beat",
    photo="room.jpg",
    title="16 歲時，",
    lines=("西西公主嫁入奧地利皇室。",),
    highlights=("奧地利皇室",),
    text_position="right",
    overlay="darker",
)


def test_cover_contains_title_tag_and_script_subtitle():
    html = render_html(COVER, photo_uri="file:///photos/dress.jpg")
    assert "ws-card--cover" in html
    assert "茜茜公主" in html
    assert "Empress Sisi" in html
    assert "奧地利旅行" in html
    assert "file:///photos/dress.jpg" in html


def test_separator_line_renders_as_ws_sep_not_paragraph():
    html = render_html(COVER, photo_uri="x")
    assert html.count('class="ws-sep"') == 1


def test_highlight_words_are_wrapped_in_em_hl():
    html = render_html(BEAT, photo_uri="x")
    assert '<em class="hl">奧地利皇室</em>' in html


def test_beat_carries_layout_overlay_and_position_classes():
    html = render_html(BEAT, photo_uri="x")
    assert "ws-card--beat" in html
    assert "ws-overlay--darker" in html
    assert "ws-body--right" in html
    assert "ws-fit" in html


def test_every_slide_has_lorescape_brandmark():
    for slide in (COVER, BEAT):
        assert "ws-brandmark" in render_html(slide, photo_uri="x")
        assert "Lorescape" in render_html(slide, photo_uri="x")


def test_ending_has_brand_block():
    ending = WanderSlide(
        layout="ending", photo="salon.jpg",
        lines=("人生難免有許多身不由己。",),
    )
    html = render_html(ending, photo_uri="x")
    assert "ws-endbrand" in html
    assert "AI 旅行說書人" in html
    assert "下載連結在個人簡介" in html


def test_html_is_escaped_but_highlights_stay_markup():
    slide = WanderSlide(
        layout="beat", photo="x.jpg",
        lines=('<script>alert(1)</script>',),
    )
    html = render_html(slide, photo_uri="x")
    assert "<script>alert" not in html
    assert "&lt;script&gt;" in html
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_wander_template.py -v`
Expected: FAIL（`ImportError: render_html`）

- [ ] **Step 3: Write `template.py`**

```python
# backend/src/lorescape_backend/social/wander/template.py
"""Pure Jinja2 HTML rendering for the wander-style slide (no browser)."""
from __future__ import annotations

from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape
from markupsafe import Markup, escape

from .content import WanderSlide

_TEMPLATE_DIR = Path(__file__).resolve().parent / "template"


def _mark_highlights(text: str, highlights: tuple[str, ...]) -> Markup:
    """Escape `text`, then wrap each highlight word in `<em class="hl">`.

    Escaping happens first so the replacement operates on the same form the
    page will show; highlight words themselves are escaped the same way.
    """
    escaped = str(escape(text))
    for word in highlights or ():
        escaped_word = str(escape(word))
        escaped = escaped.replace(
            escaped_word, f'<em class="hl">{escaped_word}</em>'
        )
    return Markup(escaped)


_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATE_DIR)),
    autoescape=select_autoescape(["html", "j2"]),
)
_env.filters["hl"] = _mark_highlights


def render_html(
    slide: WanderSlide, *, photo_uri: str, base_url: str = ""
) -> str:
    """Render one slide to an HTML string.

    `photo_uri` is the background photo as an absolute URI (`file://` when
    rendering locally). `base_url` is injected as `<base href>` so
    wander.css and the shared fonts resolve when loaded in a browser.
    """
    tmpl = _env.get_template("wander.html.j2")
    return tmpl.render(slide=slide, photo_uri=photo_uri, base_url=base_url)


def template_dir() -> Path:
    """Absolute path to the template directory (used by the renderer)."""
    return _TEMPLATE_DIR
```

- [ ] **Step 4: Write `wander.html.j2`**

```html
<!doctype html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8" />
{# base_url is injected by the Playwright renderer so wander.css and the
   shared card fonts resolve via file://. Unit tests pass "". #}
<base href="{{ base_url }}" />
<link rel="stylesheet" href="wander.css" />
</head>
<body>
<div class="ws-card ws-card--{{ slide.layout }} ws-overlay--{{ slide.overlay }}">
  <div class="ws-photo" style="background-image: url('{{ photo_uri | safe }}');"></div>
  <div class="ws-tint"></div>
  <div class="ws-frame"></div>

  {% if slide.layout == 'cover' %}
  <div class="ws-cover ws-fit">
    <div class="ws-tag">
      <span class="ws-tag__zh">{{ slide.tag_zh }}</span>
      <span class="ws-tag__en">{{ slide.tag_en }}</span>
    </div>
    <h1 class="ws-title-xl">{{ slide.title }}</h1>
    {% if slide.title_en %}<p class="ws-script">{{ slide.title_en }}</p>{% endif %}
    <div class="ws-orn">♛</div>
    <div class="ws-lines">
      {% for line in slide.lines %}
        {% if line %}<p class="ws-line">{{ line | hl(slide.highlights) }}</p>
        {% else %}<div class="ws-sep"></div>{% endif %}
      {% endfor %}
    </div>
  </div>

  {% elif slide.layout == 'ending' %}
  <div class="ws-body ws-body--{{ slide.text_position }} ws-fit">
    {% if slide.title %}<h2 class="ws-title">{{ slide.title | hl(slide.highlights) }}</h2>
    <div class="ws-rule"></div>{% endif %}
    <div class="ws-lines">
      {% for line in slide.lines %}
        {% if line %}<p class="ws-line">{{ line | hl(slide.highlights) }}</p>
        {% else %}<div class="ws-sep"></div>{% endif %}
      {% endfor %}
    </div>
  </div>
  <div class="ws-endbrand">
    <div class="ws-endbrand__rule"></div>
    <p class="ws-endbrand__name">Lorescape</p>
    <p class="ws-endbrand__tag">AI 旅行說書人</p>
    <p class="ws-endbrand__cta">下載連結在個人簡介 ↓</p>
  </div>

  {% else %}{# beat / bright #}
  <div class="ws-body ws-body--{{ 'center' if slide.layout == 'bright' else slide.text_position }} ws-fit">
    {% if slide.title %}<h2 class="ws-title">{{ slide.title | hl(slide.highlights) }}</h2>
    <div class="ws-rule"></div>{% endif %}
    <div class="ws-lines">
      {% for line in slide.lines %}
        {% if line %}<p class="ws-line">{{ line | hl(slide.highlights) }}</p>
        {% else %}<div class="ws-sep"></div>{% endif %}
      {% endfor %}
    </div>
  </div>
  {% endif %}

  <div class="ws-brandmark">Lorescape</div>
</div>
</body>
</html>
```

- [ ] **Step 5: Write `wander.css`**

```css
/* Wander-style slide: 1080×1350, dark photo overlay, ivory/gold serif type.
   Fonts are shared with the default card style (../../card/template/fonts). */
@import url("../../card/template/fonts/fonts.css");

:root {
  --ink: #f0e8d6;
  --ink-dim: rgba(240, 232, 214, 0.82);
  --gold: #c8a468;
  --gold-line: rgba(200, 164, 104, 0.55);
  --serif-tc: 'Noto Serif TC', serif;
  --serif-en: 'EB Garamond', serif;
  --script: 'Cormorant Garamond', serif;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

.ws-card {
  position: relative;
  width: 1080px;
  height: 1350px;
  overflow: hidden;
  background: #161009;
  font-family: var(--serif-tc);
  color: var(--ink);
}

/* ---- photo + tint + frame ---- */
.ws-photo {
  position: absolute; inset: 0;
  background-size: cover;
  background-position: center;
}
.ws-tint {
  position: absolute; inset: 0;
  background: linear-gradient(
    180deg,
    rgba(24, 17, 10, 0.62),
    rgba(24, 17, 10, 0.50) 45%,
    rgba(24, 17, 10, 0.74)
  );
}
.ws-overlay--darker .ws-tint {
  background: linear-gradient(
    180deg,
    rgba(20, 14, 8, 0.76),
    rgba(20, 14, 8, 0.66) 50%,
    rgba(20, 14, 8, 0.86)
  );
}
.ws-overlay--light .ws-tint {
  background: linear-gradient(
    180deg,
    rgba(240, 232, 216, 0.60),
    rgba(240, 232, 216, 0.30) 55%,
    rgba(240, 232, 216, 0.52)
  );
}
/* Light pages flip to dark-gold ink for contrast. */
.ws-overlay--light {
  --ink: #4c3b22;
  --ink-dim: rgba(76, 59, 34, 0.85);
  --gold: #8a6a34;
  --gold-line: rgba(138, 106, 52, 0.55);
}
.ws-frame {
  position: absolute; inset: 26px;
  border: 1px solid var(--gold-line);
}
.ws-card--cover .ws-frame { display: none; }

/* ---- shared type ---- */
em.hl { font-style: normal; color: var(--gold); }
.ws-rule { width: 64px; border-top: 2px solid var(--gold); opacity: 0.85; }
.ws-sep {
  width: 56px; height: 0;
  border-top: 1px solid var(--gold-line);
  margin: calc(26px * var(--fit, 1)) 0;
}
.ws-lines { display: flex; flex-direction: column; }
.ws-line {
  font-size: calc(40px * var(--fit, 1));
  line-height: 1.9;
  letter-spacing: 0.08em;
  font-weight: 600;
  color: var(--ink);
}
.ws-title {
  font-size: calc(64px * var(--fit, 1));
  font-weight: 900;
  line-height: 1.4;
  letter-spacing: 0.06em;
}

/* ---- beat / bright / ending text plate ---- */
.ws-body {
  --fit: 1;
  position: absolute;
  display: flex; flex-direction: column;
  gap: calc(30px * var(--fit));
  max-height: 860px;
  overflow: hidden;
}
.ws-body--left  { left: 96px;  top: 300px; width: 560px; }
.ws-body--right { right: 96px; top: 300px; width: 560px; }
.ws-body--top   { left: 110px; right: 110px; top: 150px; }
.ws-body--center {
  left: 120px; right: 120px; top: 170px;
  text-align: center; align-items: center;
}
.ws-body--center .ws-sep { margin-left: auto; margin-right: auto; }

/* ---- cover ---- */
.ws-cover {
  --fit: 1;
  position: absolute;
  left: 84px; top: 96px; width: 600px;
  display: flex; flex-direction: column;
  max-height: 1130px;
  overflow: hidden;
}
.ws-tag { display: flex; align-items: baseline; gap: 18px; }
.ws-tag__zh {
  font-size: 30px; letter-spacing: 0.42em; font-weight: 700;
}
.ws-tag__en {
  font-family: var(--serif-en);
  font-size: 24px; letter-spacing: 0.3em; font-style: italic;
  color: var(--ink-dim);
}
.ws-title-xl {
  margin-top: 100px;
  font-size: calc(150px * var(--fit));
  font-weight: 900;
  letter-spacing: 0.05em;
  line-height: 1.15;
}
.ws-script {
  font-family: var(--script);
  font-style: italic;
  font-size: calc(56px * var(--fit));
  color: var(--gold);
  margin-top: 6px;
}
.ws-orn {
  display: flex; align-items: center; gap: 18px;
  color: var(--gold);
  font-size: 32px;
  margin: 44px 0 36px;
}
.ws-orn::before, .ws-orn::after {
  content: "";
  flex: 0 0 56px;
  border-top: 1px solid var(--gold-line);
}

/* ---- ending brand block ---- */
.ws-endbrand {
  position: absolute;
  left: 96px; bottom: 96px;
  display: flex; flex-direction: column; gap: 12px;
}
.ws-endbrand__rule {
  width: 64px; border-top: 2px solid var(--gold);
  margin-bottom: 10px;
}
.ws-endbrand__name {
  font-family: var(--serif-en);
  font-size: 58px; letter-spacing: 0.14em; font-weight: 600;
}
.ws-endbrand__tag { font-size: 30px; letter-spacing: 0.2em; color: var(--ink-dim); }
.ws-endbrand__cta { font-size: 28px; letter-spacing: 0.12em; color: var(--gold); margin-top: 14px; }

/* ---- brandmark（每頁落款；ending 由品牌區取代） ---- */
.ws-brandmark {
  position: absolute; left: 0; right: 0; bottom: 46px;
  text-align: center;
  font-family: var(--serif-en);
  font-size: 24px; letter-spacing: 0.34em;
  color: var(--ink-dim);
}
.ws-card--ending .ws-brandmark { display: none; }
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_wander_template.py -v`
Expected: PASS（全部）

- [ ] **Step 7: Commit**

```bash
git add backend/src/lorescape_backend/social/wander/template.py \
        backend/src/lorescape_backend/social/wander/template/ \
        backend/tests/test_wander_template.py
git commit -m "feat(wander): Jinja2 template + CSS for wander-style slides

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Wander renderer（Playwright JPEG + auto-fit + CLI）

**Files:**
- Create: `backend/src/lorescape_backend/social/wander/renderer.py`
- Modify: `backend/src/lorescape_backend/social/wander/__init__.py`
- Test: `backend/tests/test_wander_renderer.py`

**Interfaces:**
- Consumes: `WanderCarousel`/`WanderSlide`/`load_carousel`（Task 1）、`render_html`/`template_dir`（Task 2）。
- Produces: `render_slide(slide: WanderSlide, *, photos_dir: Path) -> bytes`（JPEG）、`render_carousel(carousel: WanderCarousel, *, photos_dir: Path) -> list[bytes]`、CLI `python -m lorescape_backend.social.wander.renderer <day_dir> <photos_dir>`（輸出 `<day_dir>/slide_NN.jpg`）。

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_wander_renderer.py
"""wander/renderer.py — Playwright JPEG 渲染（真的開 chromium，同 card 慣例）."""
from __future__ import annotations

from io import BytesIO
from pathlib import Path

import pytest
from PIL import Image

from lorescape_backend.social.wander.content import (
    WanderCarousel,
    WanderContentError,
    WanderSlide,
)
from lorescape_backend.social.wander.renderer import (
    render_carousel,
    render_slide,
)


@pytest.fixture(scope="module")
def photos_dir(tmp_path_factory) -> Path:
    """兩張小 JPEG 當背景照."""
    photos = tmp_path_factory.mktemp("photos")
    for name, color in (("a.jpg", (120, 40, 40)), ("b.jpg", (40, 40, 120))):
        Image.new("RGB", (320, 400), color).save(photos / name, "JPEG")
    return photos


BEAT = WanderSlide(
    layout="beat", photo="a.jpg", title="16 歲時，",
    lines=("西西公主嫁入奧地利皇室。", "卻沒有帶來她想像中的幸福。"),
)


@pytest.fixture(scope="module")
def beat_jpeg(photos_dir) -> bytes:
    return render_slide(BEAT, photos_dir=photos_dir)


def test_render_slide_returns_1080_by_1350_jpeg(beat_jpeg):
    image = Image.open(BytesIO(beat_jpeg))
    image.verify()
    assert image.format == "JPEG"
    assert Image.open(BytesIO(beat_jpeg)).size == (1080, 1350)


def test_render_slide_missing_photo_raises(photos_dir):
    slide = WanderSlide(layout="beat", photo="nope.jpg", lines=("x",))
    with pytest.raises(WanderContentError, match="nope.jpg"):
        render_slide(slide, photos_dir=photos_dir)


def test_render_carousel_returns_one_jpeg_per_slide(photos_dir):
    carousel = WanderCarousel(
        date="2026-07-06", caption="cap",
        slides=(
            BEAT,
            WanderSlide(layout="bright", photo="b.jpg",
                        lines=("比起留在皇宮，", "她更喜歡旅行。")),
        ),
    )
    jpegs = render_carousel(carousel, photos_dir=photos_dir)
    assert len(jpegs) == 2
    for jpeg in jpegs:
        assert Image.open(BytesIO(jpeg)).size == (1080, 1350)


def test_long_copy_shrinks_via_fit_instead_of_overflowing(photos_dir):
    """長文觸發 auto-fit：仍要輸出完整尺寸的圖（不炸版）."""
    long_slide = WanderSlide(
        layout="beat", photo="a.jpg", title="長文測試，",
        lines=tuple(f"這是一句用來把版面塞爆的長句子第 {i} 行。"
                    for i in range(14)),
    )
    jpeg = render_slide(long_slide, photos_dir=photos_dir)
    assert Image.open(BytesIO(jpeg)).size == (1080, 1350)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_wander_renderer.py -v`
Expected: FAIL（`ImportError: render_slide`）

- [ ] **Step 3: Write `renderer.py`**

```python
# backend/src/lorescape_backend/social/wander/renderer.py
"""Playwright-based renderer for wander-style slides.

Same pattern as card/renderer.py: a headless Chromium with a 1080×1350
viewport loads the Jinja2 HTML from a temp file inside the template dir
(so file:// relative paths resolve), applies the auto-fit pass, then
screenshots as JPEG (publish format — smaller files for the monthly
archive).

CLI (manual daily flow):
    uv run python -m lorescape_backend.social.wander.renderer \
        <day_dir> <photos_dir>
writes <day_dir>/slide_01.jpg … using <day_dir>/slides.json + caption.txt.
"""
from __future__ import annotations

import sys
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from playwright.sync_api import sync_playwright

from .content import (
    WanderCarousel,
    WanderContentError,
    WanderSlide,
    load_carousel,
)
from .template import render_html, template_dir

_CARD_WIDTH = 1080
_CARD_HEIGHT = 1350
_JPEG_QUALITY = 88

# Same shrink-to-fit approach as card/renderer.py, targeting the wander
# text plate (.ws-fit caps its height in wander.css; overflow is measurable).
_FIT_SCRIPT = """
(opts) => {
  const plate = document.querySelector('.ws-fit');
  if (!plate) return 1;
  const initial = parseFloat(
    getComputedStyle(plate).getPropertyValue('--fit'),
  );
  let fit = Number.isFinite(initial) ? initial : 1;
  let guard = 0;
  while (
    plate.scrollHeight > plate.clientHeight &&
    fit > opts.floor &&
    guard < 80
  ) {
    fit = Math.round((fit - opts.step) * 1000) / 1000;
    plate.style.setProperty('--fit', String(fit));
    guard += 1;
  }
  return fit;
}
"""

_FIT_OPTS = {"floor": 0.6, "step": 0.02}


def _photo_uri(photos_dir: Path, photo: str) -> str:
    path = photos_dir / photo
    if not path.is_file():
        raise WanderContentError(f"photo not found: {path}")
    return path.resolve().as_uri()


@contextmanager
def _html_file(slide: WanderSlide, *, photos_dir: Path) -> Iterator[Path]:
    """Render slide HTML to a temp file inside the template dir.

    Living in the template dir keeps wander.css / shared fonts loadable as
    sibling file:// resources (same reasoning as card/renderer.py).
    """
    base_url = template_dir().as_uri() + "/"
    html = render_html(
        slide,
        photo_uri=_photo_uri(photos_dir, slide.photo),
        base_url=base_url,
    )
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".html",
        dir=str(template_dir()),
        encoding="utf-8",
        delete=False,
    ) as tmp:
        tmp.write(html)
        tmp_path = Path(tmp.name)
    try:
        yield tmp_path
    finally:
        tmp_path.unlink(missing_ok=True)


def _screenshot_slide(browser, tmp_path: Path) -> bytes:
    page = browser.new_page(
        viewport={"width": _CARD_WIDTH, "height": _CARD_HEIGHT},
        device_scale_factor=1.0,
    )
    try:
        page.goto(tmp_path.as_uri(), wait_until="networkidle")
        page.evaluate(_FIT_SCRIPT, _FIT_OPTS)
        return page.screenshot(
            type="jpeg", quality=_JPEG_QUALITY, full_page=False
        )
    finally:
        page.close()


def render_slide(slide: WanderSlide, *, photos_dir: Path) -> bytes:
    """Render one slide to JPEG bytes (1080×1350)."""
    with _html_file(slide, photos_dir=photos_dir) as tmp_path:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            try:
                return _screenshot_slide(browser, tmp_path)
            finally:
                browser.close()


def render_carousel(
    carousel: WanderCarousel, *, photos_dir: Path
) -> list[bytes]:
    """Render every slide to JPEG bytes; one browser reused across slides."""
    jpegs: list[bytes] = []
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        try:
            for slide in carousel.slides:
                with _html_file(slide, photos_dir=photos_dir) as tmp_path:
                    jpegs.append(_screenshot_slide(browser, tmp_path))
        finally:
            browser.close()
    return jpegs


def main(argv: list[str]) -> int:
    """CLI: render a day dir's slides.json into slide_NN.jpg files."""
    if len(argv) != 2:
        print(
            "usage: python -m lorescape_backend.social.wander.renderer "
            "<day_dir> <photos_dir>",
            file=sys.stderr,
        )
        return 2
    day_dir = Path(argv[0])
    photos_dir = Path(argv[1])
    try:
        carousel = load_carousel(day_dir)
        jpegs = render_carousel(carousel, photos_dir=photos_dir)
    except WanderContentError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    for index, jpeg in enumerate(jpegs, 1):
        out = day_dir / f"slide_{index:02d}.jpg"
        out.write_bytes(jpeg)
        print(f"wrote {out} ({len(jpeg)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
```

- [ ] **Step 4: Extend `__init__.py` re-exports**

```python
# backend/src/lorescape_backend/social/wander/__init__.py
"""Wander-style IG carousel (dark photo-overlay, person-narrative)."""
from .content import (  # noqa: F401
    WanderCarousel,
    WanderContentError,
    WanderSlide,
    load_carousel,
)
from .renderer import render_carousel, render_slide  # noqa: F401
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_wander_renderer.py -v`
Expected: PASS（chromium 需已安裝，同既有 `test_card_renderer.py` 的環境前提）

- [ ] **Step 6: 人工目視檢查（不擋 commit，但要做）**

用 Task 1 測試裡的 VALID 內容做一個實際 day_dir + 幾張照片跑 CLI，打開輸出 JPEG 確認：邊框、金色高亮、落款、cover 大標位置合理。視覺微調（字級/位置）直接改 `wander.css`，不需改測試。

- [ ] **Step 7: Commit**

```bash
git add backend/src/lorescape_backend/social/wander/ backend/tests/test_wander_renderer.py
git commit -m "feat(wander): Playwright JPEG renderer + CLI

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: `card_storage.upload_card_image`（content-type 參數化）

**Files:**
- Modify: `backend/src/lorescape_backend/social/card_storage.py`
- Test: `backend/tests/test_card_storage.py`（新增 test，不動既有）

**Interfaces:**
- Produces: `upload_card_image(supabase, image_bytes: bytes, *, path: str, content_type: str) -> str`（回傳 public URL）。既有 `upload_card_png` 改為委派給它，簽名與行為不變。

- [ ] **Step 1: Write the failing test**（加到 `backend/tests/test_card_storage.py` 檔尾）

```python
def test_upload_card_image_uses_given_content_type():
    supabase = MagicMock()
    bucket = supabase.storage.from_.return_value
    bucket.get_public_url.return_value = "https://x/ig-cards/wander/d/s.jpg"

    from lorescape_backend.social.card_storage import upload_card_image

    url = upload_card_image(
        supabase, b"jpegbytes",
        path="wander/2026-07-06/slide_01.jpg",
        content_type="image/jpeg",
    )

    assert url == "https://x/ig-cards/wander/d/s.jpg"
    supabase.storage.from_.assert_called_with("ig-cards")
    bucket.upload.assert_called_once_with(
        path="wander/2026-07-06/slide_01.jpg",
        file=b"jpegbytes",
        file_options={"content-type": "image/jpeg", "upsert": "true"},
    )
```

（若檔案尚未 import `MagicMock`，在測試檔頂部補 `from unittest.mock import MagicMock`。）

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_card_storage.py -v`
Expected: 新 test FAIL（`ImportError: upload_card_image`），既有 test PASS

- [ ] **Step 3: Implement**（改寫 `card_storage.py` 的函式區）

```python
def upload_card_image(
    supabase, image_bytes: bytes, *, path: str, content_type: str
) -> str:
    """Upload image bytes to `ig-cards/<path>` and return the public URL.

    Upsert keeps re-runs idempotent: the same path overwrites the previous
    object and keeps the same public URL.
    """
    bucket = supabase.storage.from_(BUCKET_NAME)
    bucket.upload(
        path=path,
        file=image_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )
    return bucket.get_public_url(path)


def upload_card_png(supabase, png_bytes: bytes, *, path: str) -> str:
    """Upload PNG bytes to `ig-cards/<path>` and return the public URL.

    `path` should be of the form `<publish_date>/<row_id>.png`. The caller
    chooses the path so that the URL is deterministic for a given row.
    """
    return upload_card_image(
        supabase, png_bytes, path=path, content_type="image/png"
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_card_storage.py -v`
Expected: PASS（全部，含既有）

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/card_storage.py backend/tests/test_card_storage.py
git commit -m "feat(social): generalize card storage upload to any image type

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: `discord_review.send_images_for_review`（一則訊息多附件）

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/discord_review.py`
- Test: `backend/tests/test_discord_review.py`（新增 test，不動既有）

**Interfaces:**
- Consumes: 既有 `_add_self_reaction`、`_bot_headers`、`DISCORD_API`、`APPROVE_EMOJI`/`REJECT_EMOJI`。
- Produces: `send_images_for_review(*, bot_token: str, channel_id: str, images: list[bytes], publish_date: str) -> str`（回傳 message id；附件檔名 `ig-carousel-<date>-01.jpg` …；訊息文字沿用 `_REVIEW_INSTRUCTION`，加註 wander 字樣）。

- [ ] **Step 1: Write the failing test**（加到 `backend/tests/test_discord_review.py`；沿用該檔既有的 `requests_mock` / mock 模式 — 動工前先讀該檔開頭確認 fixture 寫法，下面以 `requests_mock` 為例）

```python
def test_send_images_for_review_posts_one_message_with_all_files(
    requests_mock,
):
    from lorescape_backend.daily_story import discord_review

    channel = "chan-1"
    post = requests_mock.post(
        f"{discord_review.DISCORD_API}/channels/{channel}/messages",
        json={"id": "msg-9"},
    )
    requests_mock.put(requests_mock.ANY, status_code=204)

    message_id = discord_review.send_images_for_review(
        bot_token="tok",
        channel_id=channel,
        images=[b"jpeg-1", b"jpeg-2", b"jpeg-3"],
        publish_date="2026-07-06",
    )

    assert message_id == "msg-9"
    body = post.last_request.body
    # multipart body 內要有三個檔案欄位與檔名
    assert b'name="files[0]"' in body
    assert b'name="files[2]"' in body
    assert b"ig-carousel-2026-07-06-01.jpg" in body
    assert b"ig-carousel-2026-07-06-03.jpg" in body


def test_send_images_for_review_seeds_both_reactions(requests_mock):
    from lorescape_backend.daily_story import discord_review

    channel = "chan-1"
    requests_mock.post(
        f"{discord_review.DISCORD_API}/channels/{channel}/messages",
        json={"id": "msg-9"},
    )
    put = requests_mock.put(requests_mock.ANY, status_code=204)

    discord_review.send_images_for_review(
        bot_token="tok", channel_id=channel,
        images=[b"x"], publish_date="2026-07-06",
    )

    assert put.call_count == 2  # ✅ 與 ❌
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_discord_review.py -v`
Expected: 新 test FAIL（`AttributeError: send_images_for_review`），既有 PASS

- [ ] **Step 3: Implement**（加在 `send_video_for_review` 之後）

```python
_CAROUSEL_REVIEW_INSTRUCTION = (
    "Wander carousel — React ✅ to publish at 21:00 Asia/Taipei · ❌ to skip"
)


def send_images_for_review(
    *,
    bot_token: str,
    channel_id: str,
    images: list[bytes],
    publish_date: str,
) -> str:
    """Post a pre-rendered carousel (all slides in ONE message), seed ✅/❌.

    One message keeps a single message id for the publish job to poll.
    Discord allows up to 10 attachments per message — the IG carousel
    limit is also 10, so callers never exceed it.
    """
    files: dict = {
        "payload_json": (
            None,
            json.dumps({"content": _CAROUSEL_REVIEW_INSTRUCTION}),
            "application/json",
        ),
    }
    for index, image_bytes in enumerate(images):
        files[f"files[{index}]"] = (
            f"ig-carousel-{publish_date}-{index + 1:02d}.jpg",
            image_bytes,
            "image/jpeg",
        )
    headers = {
        "Authorization": f"Bot {bot_token}",
        "User-Agent": "lorescape-daily-story (https://github.com, 0.1.0)",
    }
    response = requests.post(
        f"{DISCORD_API}/channels/{channel_id}/messages",
        headers=headers,
        files=files,
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    message_id = response.json()["id"]
    for emoji in (APPROVE_EMOJI, REJECT_EMOJI):
        _add_self_reaction(
            bot_token=bot_token,
            channel_id=channel_id,
            message_id=message_id,
            emoji=emoji,
        )
    return message_id
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_discord_review.py -v`
Expected: PASS（全部）

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/discord_review.py backend/tests/test_discord_review.py
git commit -m "feat(discord): multi-image review message for pre-rendered carousels

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: DB migration + `post_log.record_review_pending` 擴充

**Files:**
- Create: `supabase/migrations/20260706000000_add_prerendered_carousel_to_social_posts.sql`
- Modify: `backend/src/lorescape_backend/social/post_log.py`
- Test: `backend/tests/test_post_log.py`（新增 test，不動既有）

**Interfaces:**
- Produces: `social_posts.slide_urls jsonb`（非 NULL = 預渲染 carousel）、`social_posts.caption text`；`record_review_pending(supabase, *, publish_date, media_type, discord_message_id, slide_urls: list[str] | None = None, caption: str | None = None)`。

- [ ] **Step 1: Write the migration**

```sql
-- Pre-rendered (wander-style) carousel support.
--
-- The local send-for-review script uploads the day's rendered slides to
-- the public `ig-cards` bucket and records their URLs + IG caption here.
-- A carousel row with non-NULL slide_urls tells the 21:00 publish job to
-- publish these exact images (gated by ✅/❌ on discord_message_id) and
-- to skip the default in-server card rendering entirely.
--
-- No new GRANT needed: 20260705120000 granted table-level
-- select/insert/update/delete on social_posts to service_role, which
-- covers columns added later.
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS slide_urls JSONB,
  ADD COLUMN IF NOT EXISTS caption TEXT;
```

- [ ] **Step 2: Write the failing test**（加到 `backend/tests/test_post_log.py`）

```python
def test_record_review_pending_carries_slide_urls_and_caption():
    supabase = MagicMock()
    table = supabase.table.return_value

    from lorescape_backend.social import post_log

    post_log.record_review_pending(
        supabase,
        publish_date="2026-07-06",
        media_type="carousel",
        discord_message_id="msg-1",
        slide_urls=["https://x/1.jpg", "https://x/2.jpg"],
        caption="今天的故事",
    )

    payload = table.upsert.call_args.args[0]
    assert payload["slide_urls"] == ["https://x/1.jpg", "https://x/2.jpg"]
    assert payload["caption"] == "今天的故事"
    assert payload["status"] == "pending"


def test_record_review_pending_defaults_keep_reel_payload_nullable():
    supabase = MagicMock()
    table = supabase.table.return_value

    from lorescape_backend.social import post_log

    post_log.record_review_pending(
        supabase,
        publish_date="2026-07-06",
        media_type="reel",
        discord_message_id="msg-2",
    )

    payload = table.upsert.call_args.args[0]
    assert payload["slide_urls"] is None
    assert payload["caption"] is None
```

（同樣視該檔既有寫法補 `from unittest.mock import MagicMock`。）

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_post_log.py -v`
Expected: 新 test FAIL（`TypeError: unexpected keyword argument 'slide_urls'`）

- [ ] **Step 4: Implement**（改 `record_review_pending`）

```python
def record_review_pending(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    discord_message_id: str,
    slide_urls: list[str] | None = None,
    caption: str | None = None,
) -> None:
    """Upsert a 'pending' row pointing at the Discord review message.

    For pre-rendered carousels, `slide_urls` carries the uploaded slide
    URLs and `caption` the reviewed IG caption; the 21:00 publish job then
    publishes these exact images. Re-sending for review resets any prior
    state so the publish job re-reads the new message's reactions.
    """
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": "pending",
        "discord_message_id": discord_message_id,
        "slide_urls": slide_urls,
        "caption": caption,
        "ig_post_id": None,
        "error": None,
        "published_at": None,
    }
    (
        supabase.table(TABLE_NAME)
        .upsert(payload, on_conflict="publish_date,media_type")
        .execute()
    )
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_post_log.py -v`
Expected: PASS（全部）

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260706000000_add_prerendered_carousel_to_social_posts.sql \
        backend/src/lorescape_backend/social/post_log.py backend/tests/test_post_log.py
git commit -m "feat(db): slide_urls + caption on social_posts for pre-rendered carousels

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: Publisher 預渲染分支

**Files:**
- Modify: `backend/src/lorescape_backend/social/publisher.py`
- Test: `backend/tests/test_publisher_prerendered.py`（新檔；不動既有 `test_publisher.py`）

**Interfaces:**
- Consumes: `post_log.get_post` / `mark_status` / `record_post`（Task 6 欄位）、`discord_review.check_reaction`、`instagram.publish_carousel`。
- Produces: `run_publish_job(config, target_date=None, *, dry_run: bool = False)`（新增 `dry_run`，只作用於預渲染分支）；內部 `_handle_prerendered(supabase, config, target_date, *, dry_run) -> bool`（True = 當天已由預渲染分支處理，呼叫端直接 return）；`_sync_story_state(supabase, date_str, new_state)`；模組新增 CLI `python -m lorescape_backend.social.publisher [YYYY-MM-DD] [--dry-run]`。

**行為規格（來自 spec）：**
- carousel row 存在且 `slide_urls` 非空 → 一律由本分支處理，**不 fall through**。
- terminal（published/rejected/skipped）→ 不動作。
- `pending`/`failed` → 讀該訊息 ✅/❌：✅ 發布（成功 `published`、失敗 `failed`+webhook 通知）；❌ `rejected`；無反應 `skipped`（carousel 只有 21:00 一個 pass）。
- 每個 decision 同步 `daily_stories`（當天、zh-TW、仍在 pending 的 row）為對應狀態（published/rejected/skipped/failed）。
- `review_enabled` 為 False 或 row 沒有 message id → 留在 pending（可修復後重跑），仍回傳 True。
- `dry_run=True` → 只印 decision / URLs / caption，不發布不改狀態。

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_publisher_prerendered.py
"""publisher._handle_prerendered — 預渲染（wander）carousel 的發布分支."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

import pytest

from lorescape_backend.social.publisher import run_publish_job

TARGET = date(2026, 7, 6)
DATE_STR = "2026-07-06"
URLS = ["https://x/wander/2026-07-06/slide_01.jpg",
        "https://x/wander/2026-07-06/slide_02.jpg"]


def _prerendered_row(**overrides):
    base = dict(
        publish_date=DATE_STR,
        media_type="carousel",
        status="pending",
        discord_message_id="msg-c-1",
        slide_urls=list(URLS),
        caption="今天的故事 #lorescape",
    )
    base.update(overrides)
    return base


@pytest.fixture
def mocks(fake_config):
    with (
        patch("lorescape_backend.social.publisher.create_client"),
        patch("lorescape_backend.social.publisher.post_log") as post_log,
        patch(
            "lorescape_backend.social.publisher.discord_review"
            ".check_reaction"
        ) as check,
        patch(
            "lorescape_backend.social.publisher.instagram.publish_carousel"
        ) as ig_pub,
        patch(
            "lorescape_backend.social.publisher._sync_story_state"
        ) as sync_state,
        patch(
            "lorescape_backend.social.publisher._load_pending_rows"
        ) as load_rows,
        patch(
            "lorescape_backend.social.publisher.discord_notify"
            ".notify_failure"
        ) as notify,
    ):
        class Namespace:
            pass

        ns = Namespace()
        ns.post_log = post_log
        ns.check = check
        ns.ig_pub = ig_pub
        ns.sync_state = sync_state
        ns.load_rows = load_rows
        ns.notify = notify
        ns.config = fake_config
        yield ns


def test_approved_prerendered_publishes_urls_with_stored_caption(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "post-1"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_called_once()
    kwargs = mocks.ig_pub.call_args.kwargs
    assert kwargs["image_urls"] == URLS
    assert kwargs["caption"] == "今天的故事 #lorescape"
    mocks.post_log.record_post.assert_called_once()
    assert mocks.post_log.record_post.call_args.kwargs["status"] == "published"
    mocks.sync_state.assert_called_once()
    assert mocks.sync_state.call_args.args[2] == "published"
    mocks.load_rows.assert_not_called()  # 絕不 fall through


def test_rejected_prerendered_marks_rejected_and_syncs(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "rejected"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.mark_status.assert_called_once()
    assert mocks.post_log.mark_status.call_args.kwargs["status"] == "rejected"
    assert mocks.sync_state.call_args.args[2] == "rejected"
    mocks.load_rows.assert_not_called()


def test_no_reaction_marks_skipped(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "none"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_not_called()
    assert mocks.post_log.mark_status.call_args.kwargs["status"] == "skipped"
    assert mocks.sync_state.call_args.args[2] == "skipped"


@pytest.mark.parametrize("status", ["published", "rejected", "skipped"])
def test_terminal_prerendered_row_is_untouched_and_blocks_default(
    mocks, status
):
    mocks.post_log.get_post.return_value = _prerendered_row(status=status)

    run_publish_job(mocks.config, TARGET)

    mocks.check.assert_not_called()
    mocks.ig_pub.assert_not_called()
    mocks.load_rows.assert_not_called()


def test_publish_failure_records_failed_and_notifies(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.side_effect = RuntimeError("boom")

    run_publish_job(mocks.config, TARGET)

    assert mocks.post_log.record_post.call_args.kwargs["status"] == "failed"
    assert mocks.sync_state.call_args.args[2] == "failed"
    mocks.notify.assert_called_once()


def test_failed_prerendered_row_retries_when_approved(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row(status="failed")
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "post-2"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_called_once()


def test_row_without_slide_urls_falls_through_to_default_flow(mocks):
    """一般 carousel outcome row（slide_urls 為 NULL）不觸發預渲染分支."""
    mocks.post_log.get_post.return_value = _prerendered_row(slide_urls=None)
    mocks.load_rows.return_value = []

    run_publish_job(mocks.config, TARGET)

    mocks.load_rows.assert_called_once()
    mocks.ig_pub.assert_not_called()


def test_dry_run_prints_without_publishing(mocks, capsys):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"

    run_publish_job(mocks.config, TARGET, dry_run=True)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.record_post.assert_not_called()
    mocks.sync_state.assert_not_called()
    out = capsys.readouterr().out
    assert "approved" in out
    assert URLS[0] in out
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_publisher_prerendered.py -v`
Expected: FAIL（`_sync_story_state` 不存在 / `dry_run` unexpected keyword）

- [ ] **Step 3: Implement**（`publisher.py`）

3a. `run_publish_job` 開頭插入分支（在 `create_client` 之後、`_load_pending_rows` 之前），並加 `dry_run` 參數：

```python
def run_publish_job(
    config: Config,
    target_date: date | None = None,
    *,
    dry_run: bool = False,
) -> None:
    """Process all pending daily_stories rows for the given date (default: today).

    When a pre-rendered (wander-style) carousel was sent for review for
    this date, that review alone decides the day's carousel and the
    default rendering flow is skipped entirely. `dry_run` only affects
    the pre-rendered branch (prints the decision without publishing).
    """
    if target_date is None:
        target_date = date.today()

    supabase = create_client(config.supabase_url, config.supabase_service_role_key)

    if _handle_prerendered(supabase, config, target_date, dry_run=dry_run):
        return

    rows = _load_pending_rows(supabase, target_date)
    ...  # 以下既有內容不動
```

3b. 模組尾端（`_update_state` 之後）加：

```python
def _handle_prerendered(
    supabase, config: Config, target_date: date, *, dry_run: bool = False
) -> bool:
    """Publish a pre-rendered carousel if one was sent for review today.

    Returns True when a pre-rendered row exists (slide_urls non-empty) —
    the caller must then skip the default flow entirely, regardless of
    the outcome here.
    """
    date_str = target_date.isoformat()
    row = post_log.get_post(supabase, date_str, "carousel")
    if row is None or not row.get("slide_urls"):
        return False

    status = row.get("status")
    if status in ("published", "rejected", "skipped"):
        logger.info(
            "Pre-rendered carousel for %s already '%s'; nothing to do",
            date_str, status,
        )
        return True

    message_id = row.get("discord_message_id")
    if not message_id or not config.review_enabled:
        logger.warning(
            "Pre-rendered carousel for %s has no reviewable message "
            "(message_id=%s, review_enabled=%s); leaving pending",
            date_str, message_id, config.review_enabled,
        )
        return True

    decision = discord_review.check_reaction(
        bot_token=config.discord_bot_token,  # type: ignore[arg-type]
        channel_id=config.discord_review_channel_id,  # type: ignore[arg-type]
        message_id=message_id,
        approver_ids=config.discord_approver_ids,
    )
    slide_urls = list(row["slide_urls"])
    ig_caption = row.get("caption") or ""

    if dry_run:
        print(f"[dry-run] decision: {decision}")
        for url in slide_urls:
            print(f"[dry-run] slide:   {url}")
        print(f"[dry-run] caption:\n{ig_caption}")
        return True

    if decision == "rejected":
        post_log.mark_status(
            supabase, publish_date=date_str, media_type="carousel",
            status="rejected",
        )
        _sync_story_state(supabase, date_str, "rejected")
        return True
    if decision == "none":
        post_log.mark_status(
            supabase, publish_date=date_str, media_type="carousel",
            status="skipped",
        )
        _sync_story_state(supabase, date_str, "skipped")
        return True

    # decision == "approved"
    if not config.instagram_enabled:
        logger.warning(
            "Instagram not configured; leaving pre-rendered carousel pending"
        )
        return True
    try:
        ig_post_id = instagram.publish_carousel(
            ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
            access_token=config.meta_page_access_token,  # type: ignore[arg-type]
            image_urls=slide_urls,
            caption=ig_caption,
        )
    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Pre-rendered carousel publish failed for %s",
                         date_str)
        post_log.record_post(
            supabase, publish_date=date_str, media_type="carousel",
            status="failed", error=_truncate(str(exc), 1000),
        )
        _sync_story_state(supabase, date_str, "failed")
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=date_str,
                error_message=f"Pre-rendered carousel publish failed: {exc}",
                traceback_str="",
            )
        return True

    post_log.record_post(
        supabase, publish_date=date_str, media_type="carousel",
        status="published", ig_post_id=ig_post_id,
    )
    _sync_story_state(supabase, date_str, "published")
    logger.info("Published pre-rendered carousel for %s: %s",
                date_str, ig_post_id)
    return True


def _sync_story_state(supabase, date_str: str, new_state: str) -> None:
    """Mirror the pre-rendered carousel outcome onto the day's story row.

    Only rows still in 'pending' are touched, so a story already resolved
    by other means keeps its state; this prevents the next-day back-fill
    flow from re-sending an already-decided day.
    """
    (
        supabase.table("daily_stories")
        .update({
            "review_state": new_state,
            "reviewed_at": datetime.now(timezone.utc).isoformat(),
        })
        .eq("publish_date", date_str)
        .eq("language", PUBLISH_LANGUAGE)
        .eq("review_state", "pending")
        .execute()
    )


def main() -> None:
    """CLI: `python -m lorescape_backend.social.publisher [date] [--dry-run]`."""
    import argparse

    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", help="Publish date YYYY-MM-DD (default: today)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Pre-rendered branch only: print decision/slides/caption "
             "without publishing",
    )
    args = parser.parse_args()

    config = Config.from_env()
    target = date.fromisoformat(args.date) if args.date else date.today()
    run_publish_job(config, target, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run new + existing publisher tests**

Run: `cd backend && uv run pytest tests/test_publisher_prerendered.py tests/test_publisher.py tests/test_publisher_daemon.py -v`
Expected: 全部 PASS。注意：若 `test_publisher.py` 的既有測試 mock 了整個 `post_log` 模組，`post_log.get_post` 會回傳 truthy 的 MagicMock，導致新分支被誤觸發而既有測試失敗。此時的修法是在該測試檔的 mock fixture 補一行預設值 `post_log.get_post.return_value = None`（讓既有測試明確走預設流程）— 只加 setup，不改任何既有斷言。

- [ ] **Step 5: Run full backend suite**

Run: `cd backend && uv run pytest`
Expected: 全部 PASS

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/social/publisher.py backend/tests/test_publisher_prerendered.py backend/tests/test_publisher.py
git commit -m "feat(publisher): pre-rendered wander carousel branch + CLI

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: `scripts/send_carousel_for_review.py`

**Files:**
- Create: `scripts/send_carousel_for_review.py`
- Test: `scripts/tests/test_send_carousel_for_review.py`

**Interfaces:**
- Consumes: `card_storage.upload_card_image`（Task 4）、`discord_review.send_images_for_review`（Task 5）、`post_log.record_review_pending`（Task 6）。
- Produces: CLI `cd scripts && uv run python -m send_carousel_for_review [YYYY-MM-DD]`：讀 `marketing/outputs/daily_carousel/<date>/slide_*.jpg` + `caption.txt` → 上傳 bucket（`wander/<date>/slide_NN.jpg`）→ Discord 送審 → pending row。

- [ ] **Step 1: Write the failing test**

```python
# scripts/tests/test_send_carousel_for_review.py
"""send_carousel_for_review — 上傳 bucket + Discord 送審 + pending row."""
from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

import send_carousel_for_review as mod


@pytest.fixture
def day_dir(tmp_path, monkeypatch) -> Path:
    day = tmp_path / "2026-07-06"
    day.mkdir()
    for i in (1, 2):
        (day / f"slide_{i:02d}.jpg").write_bytes(b"jpeg" + bytes([i]))
    (day / "caption.txt").write_text("今天的故事", encoding="utf-8")
    monkeypatch.setattr(mod, "DAILY_CAROUSEL_DIR", tmp_path)
    return day


@pytest.fixture
def env(monkeypatch):
    config = MagicMock()
    config.discord_bot_token = "tok"
    config.discord_review_channel_id = "chan"
    with (
        patch.object(mod, "load_dotenv"),
        patch.object(mod.Config, "from_env", return_value=config),
        patch.object(mod, "create_client") as create_client,
        patch.object(mod.card_storage, "upload_card_image") as upload,
        patch.object(
            mod.discord_review, "send_images_for_review",
            return_value="msg-1",
        ) as send,
        patch.object(mod.post_log, "record_review_pending") as pending,
    ):
        upload.side_effect = (
            lambda supabase, data, *, path, content_type:
            f"https://x/ig-cards/{path}"
        )

        class Namespace:
            pass

        ns = Namespace()
        ns.upload = upload
        ns.send = send
        ns.pending = pending
        yield ns


def test_uploads_slides_sends_review_and_records_pending(day_dir, env):
    assert mod.main(["2026-07-06"]) == 0

    assert env.upload.call_count == 2
    first = env.upload.call_args_list[0]
    assert first.kwargs["path"] == "wander/2026-07-06/slide_01.jpg"
    assert first.kwargs["content_type"] == "image/jpeg"

    env.send.assert_called_once()
    assert len(env.send.call_args.kwargs["images"]) == 2

    env.pending.assert_called_once()
    kwargs = env.pending.call_args.kwargs
    assert kwargs["media_type"] == "carousel"
    assert kwargs["discord_message_id"] == "msg-1"
    assert kwargs["slide_urls"] == [
        "https://x/ig-cards/wander/2026-07-06/slide_01.jpg",
        "https://x/ig-cards/wander/2026-07-06/slide_02.jpg",
    ]
    assert kwargs["caption"] == "今天的故事"


def test_missing_slides_dir_fails(env, tmp_path, monkeypatch):
    monkeypatch.setattr(mod, "DAILY_CAROUSEL_DIR", tmp_path)
    assert mod.main(["2026-07-06"]) == 1
    env.upload.assert_not_called()


def test_oversized_slide_fails_before_upload(day_dir, env, monkeypatch):
    monkeypatch.setattr(mod, "MAX_ATTACHMENT_BYTES", 3)
    assert mod.main(["2026-07-06"]) == 1
    env.pending.assert_not_called()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd scripts && uv run pytest tests/test_send_carousel_for_review.py -v`
Expected: FAIL（`ModuleNotFoundError: send_carousel_for_review`）

- [ ] **Step 3: Implement**

```python
# scripts/send_carousel_for_review.py
"""Send a wander-style carousel to Discord for review + stage it for publish.

Reads marketing/outputs/daily_carousel/<date>/slide_*.jpg + caption.txt
(rendered by `python -m lorescape_backend.social.wander.renderer`), uploads
the slides to the public `ig-cards` bucket (wander/<date>/slide_NN.jpg),
posts them all in ONE Discord review message seeded with ✅/❌, and upserts
a 'pending' social_posts row carrying the message id, the slide URLs and
the caption. The VPS 21:00 publish job then publishes exactly these images
once an approver reacts ✅ — the default carousel rendering is skipped for
that day.

Run from scripts/:

    uv run python -m send_carousel_for_review             # today
    uv run python -m send_carousel_for_review 2026-07-06
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_review
from lorescape_backend.social import card_storage, post_log

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_CAROUSEL_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_carousel"

# Discord attachment cap on a non-boosted server (per file), with headroom —
# same convention as send_reel_for_review.py. Rendered slides are ~1 MB so
# hitting this means something went wrong upstream.
MAX_ATTACHMENT_BYTES = int(9.5 * 1024 * 1024)


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "backend" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", default=date.today().isoformat(),
        help="Publish date YYYY-MM-DD (default: today)",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    if not (config.discord_bot_token and config.discord_review_channel_id):
        print(
            "Discord review not configured: set DISCORD_BOT_TOKEN and "
            "DISCORD_REVIEW_CHANNEL_ID in backend/.env",
            file=sys.stderr,
        )
        return 1

    day_dir = DAILY_CAROUSEL_DIR / args.date
    slide_paths = sorted(day_dir.glob("slide_*.jpg"))
    caption_path = day_dir / "caption.txt"
    if not slide_paths:
        print(f"no slide_*.jpg found in {day_dir}", file=sys.stderr)
        return 1
    if not caption_path.is_file():
        print(f"caption.txt not found in {day_dir}", file=sys.stderr)
        return 1
    caption = caption_path.read_text(encoding="utf-8").strip()

    slide_bytes = [p.read_bytes() for p in slide_paths]
    for path, data in zip(slide_paths, slide_bytes):
        if len(data) > MAX_ATTACHMENT_BYTES:
            print(
                f"{path.name} is {len(data)} bytes — over the Discord "
                f"attachment limit; re-render with lower quality",
                file=sys.stderr,
            )
            return 1

    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    slide_urls = [
        card_storage.upload_card_image(
            supabase, data,
            path=f"wander/{args.date}/{path.name}",
            content_type="image/jpeg",
        )
        for path, data in zip(slide_paths, slide_bytes)
    ]

    message_id = discord_review.send_images_for_review(
        bot_token=config.discord_bot_token,
        channel_id=config.discord_review_channel_id,
        images=slide_bytes,
        publish_date=args.date,
    )
    post_log.record_review_pending(
        supabase,
        publish_date=args.date,
        media_type="carousel",
        discord_message_id=message_id,
        slide_urls=slide_urls,
        caption=caption,
    )
    print(
        f"Sent {len(slide_urls)} slides for review: message_id={message_id}"
        f" — react ✅ before 21:00 Asia/Taipei to publish."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd scripts && uv run pytest tests/test_send_carousel_for_review.py -v`
Expected: PASS（全部）

- [ ] **Step 5: Commit**

```bash
git add scripts/send_carousel_for_review.py scripts/tests/test_send_carousel_for_review.py
git commit -m "feat(scripts): send wander carousel for Discord review

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: `scripts/archive_ig_cards.py`（每月歸檔）

**Files:**
- Create: `scripts/archive_ig_cards.py`
- Test: `scripts/tests/test_archive_ig_cards.py`

**Interfaces:**
- Produces: CLI `cd scripts && uv run python -m archive_ig_cards [YYYY-MM]`（預設上個月）：把 `ig-cards` bucket 中該月的物件（頂層 `<YYYY-MM-DD>/…` 與 `wander/<YYYY-MM-DD>/…` 兩種 prefix）下載到 `marketing/outputs/ig_cards_archive/<YYYY-MM>/<原路徑>`，逐檔下載成功後才刪 bucket 物件；任一檔失敗即中止且不刪任何東西。

- [ ] **Step 1: Write the failing test**

```python
# scripts/tests/test_archive_ig_cards.py
"""archive_ig_cards — 下載整月 ig-cards 物件到本機後刪 bucket 端."""
from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

import archive_ig_cards as mod


def _entry(name: str) -> dict:
    return {"name": name}


@pytest.fixture
def bucket(tmp_path, monkeypatch):
    monkeypatch.setattr(mod, "ARCHIVE_DIR", tmp_path)
    bucket = MagicMock()

    # bucket.list(prefix)：頂層列日期夾與 wander 夾；夾內列檔案
    def list_side_effect(prefix=""):
        listing = {
            "": [_entry("2026-06-05"), _entry("2026-07-01"),
                 _entry("wander")],
            "wander": [_entry("2026-06-06")],
            "2026-06-05": [_entry("a-0.png"), _entry("a-1.png")],
            "wander/2026-06-06": [_entry("slide_01.jpg")],
        }
        return listing.get(prefix, [])

    bucket.list.side_effect = list_side_effect
    bucket.download.side_effect = lambda path: b"data:" + path.encode()

    supabase = MagicMock()
    supabase.storage.from_.return_value = bucket
    with (
        patch.object(mod, "load_dotenv"),
        patch.object(mod.Config, "from_env", return_value=MagicMock()),
        patch.object(mod, "create_client", return_value=supabase),
    ):
        yield bucket


def test_archives_and_deletes_only_target_month(bucket, tmp_path):
    assert mod.main(["2026-06"]) == 0

    downloaded = sorted(
        p.relative_to(tmp_path).as_posix()
        for p in tmp_path.rglob("*") if p.is_file()
    )
    assert downloaded == [
        "2026-06/2026-06-05/a-0.png",
        "2026-06/2026-06-05/a-1.png",
        "2026-06/wander/2026-06-06/slide_01.jpg",
    ]
    removed = bucket.remove.call_args.args[0]
    assert sorted(removed) == [
        "2026-06-05/a-0.png",
        "2026-06-05/a-1.png",
        "wander/2026-06-06/slide_01.jpg",
    ]


def test_download_failure_aborts_without_deleting(bucket):
    bucket.download.side_effect = RuntimeError("net down")
    assert mod.main(["2026-06"]) == 1
    bucket.remove.assert_not_called()


def test_month_with_no_objects_is_a_noop(bucket):
    assert mod.main(["2026-01"]) == 0
    bucket.remove.assert_not_called()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd scripts && uv run pytest tests/test_archive_ig_cards.py -v`
Expected: FAIL（`ModuleNotFoundError: archive_ig_cards`）

- [ ] **Step 3: Implement**

```python
# scripts/archive_ig_cards.py
"""Archive a month of published IG card images out of Supabase Storage.

Downloads every `ig-cards` object for the given month (default: last
month) to marketing/outputs/ig_cards_archive/<YYYY-MM>/, preserving the
bucket-relative path, then deletes the bucket objects. Both layouts are
covered: the default style's top-level `<date>/…` and the wander style's
`wander/<date>/…`. Any download failure aborts BEFORE deleting anything,
so re-running is always safe. Instagram keeps its own copy of published
media — the bucket objects are only needed until publish.

After it finishes, back the archive folder up (e.g. Google Drive) at your
leisure; it is plain files on disk.

Run from scripts/:

    uv run python -m archive_ig_cards             # last month
    uv run python -m archive_ig_cards 2026-06
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config

REPO_ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_DIR = REPO_ROOT / "marketing" / "outputs" / "ig_cards_archive"
BUCKET_NAME = "ig-cards"


def _last_month() -> str:
    today = date.today()
    year, month = (today.year, today.month - 1) if today.month > 1 \
        else (today.year - 1, 12)
    return f"{year:04d}-{month:02d}"


def _month_object_paths(bucket, month: str) -> list[str]:
    """Bucket-relative paths of every object belonging to `month`."""
    paths: list[str] = []
    for entry in bucket.list(""):
        name = entry["name"]
        if name.startswith(month):                      # 2026-06-05/...
            paths.extend(
                f"{name}/{child['name']}" for child in bucket.list(name)
            )
        elif name == "wander":                          # wander/2026-06-06/...
            for day in bucket.list("wander"):
                if day["name"].startswith(month):
                    prefix = f"wander/{day['name']}"
                    paths.extend(
                        f"{prefix}/{child['name']}"
                        for child in bucket.list(prefix)
                    )
    return paths


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "backend" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "month", nargs="?", default=_last_month(),
        help="Month to archive, YYYY-MM (default: last month)",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    bucket = supabase.storage.from_(BUCKET_NAME)

    paths = _month_object_paths(bucket, args.month)
    if not paths:
        print(f"no ig-cards objects for {args.month}; nothing to archive")
        return 0

    month_dir = ARCHIVE_DIR / args.month
    try:
        for path in paths:
            data = bucket.download(path)
            target = month_dir / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            print(f"archived {path} ({len(data)} bytes)")
    except Exception as exc:  # noqa: BLE001 — abort keeps bucket intact
        print(
            f"download failed ({exc}); aborting WITHOUT deleting anything",
            file=sys.stderr,
        )
        return 1

    bucket.remove(paths)
    print(
        f"done: {len(paths)} objects archived to {month_dir} and removed "
        f"from the bucket — back the folder up to Google Drive when ready."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd scripts && uv run pytest tests/test_archive_ig_cards.py -v`
Expected: PASS（全部）

- [ ] **Step 5: Commit**

```bash
git add scripts/archive_ig_cards.py scripts/tests/test_archive_ig_cards.py
git commit -m "feat(scripts): monthly ig-cards archive to local disk

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 10: 操作 skill + 文件 + 部署清單

**Files:**
- Create: `.claude/skills/lorescape-wander-carousel/SKILL.md`
- Modify: `backend/README.md`（publish 流程段落加 wander 分支說明）

**Interfaces:**
- Consumes: Task 3 CLI、Task 8 script、Task 7 的發布語意。

- [ ] **Step 1: Write the skill**

`.claude/skills/lorescape-wander-carousel/SKILL.md` 內容（frontmatter + 正文）：

```markdown
---
name: lorescape-wander-carousel
description: Use when the user wants to publish a wander-style (dark
  photo-overlay, person-narrative) IG carousel for a Lorescape daily story —
  e.g. 「今天用 wander 風格發」,「做 wander 圖組」,「茜茜公主那種風格」.
  Covers writing the 7–9 slide beats, rendering, local preview, and sending
  for Discord review. Requires a user-provided photos folder.
---

# Wander 風格 IG Carousel

發布日的 carousel 改用 wander 風格（第三人稱人物敘事 + 暗色壓字）。
送審後 21:00 自動發布；當天預設風格 carousel 會被跳過。
設計 spec：docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md

## 流程

1. **向使用者要**：日期（預設今天）、照片資料夾路徑（5–9 張同景點實拍）、
   故事角度（哪個人物/事件）。
2. **寫文案** `marketing/outputs/daily_carousel/<date>/slides.json` +
   `caption.txt`，**給使用者審稿，改到同意為止**（見下方文案規則）。
3. **渲染**：
   `cd backend && uv run python -m lorescape_backend.social.wander.renderer \
      ../marketing/outputs/daily_carousel/<date> <photos_dir>`
   請使用者打開 `slide_*.jpg` 目視確認；要調整就改 slides.json 重渲染。
4. **送審**：
   `cd scripts && uv run python -m send_carousel_for_review <date>`
   提醒使用者到 Discord 按 ✅（21:00 Asia/Taipei 前）。
5. ❌ 或不按 = 當天 carousel 不發（不會 fallback 到預設風格）。

## 文案規則（slides.json）

- 7–9 頁；每頁 2–4 短句（`lines`），句尾逗號製造翻頁懸念；
  `lines` 中空字串 `""` = 裝飾分隔線。
- 節拍順序：cover 鉤子（含一次反轉）→ beat 起伏 → beat 衝突 →
  beat 彩蛋（第一人稱「最讓我意外的是…」）→ beat 轉折 →
  bright 主題頁（呼應旅行/自由，配最亮的照片）→ ending
  （結局 + 「她」→「我們」的讀者投射；品牌區塊模板自帶）。
- 人稱：以「她/他」為主；「我」只出現在彩蛋頁與結局詮釋。
- `highlights` 每頁最多 2 個金色強調詞；一個主題詞（如「自由」）
  貫穿全篇。
- 照片配頁跟情緒走：悲劇配最暗的照片（`overlay: "darker"`）、
  bright 頁配唯一明亮照（`overlay: "light"`）。
- layout 欄位：`cover`（需 tag_zh/tag_en/title/title_en）、
  `beat`（可選 title、text_position: left|right|top）、`bright`、`ending`。
- caption.txt：既有貼文 caption 慣例（故事鉤子 + hashtags + @love.lorescape）。

## slides.json 範例（節錄）

    {
      "slides": [
        {"layout": "cover", "photo": "dress.jpg",
         "tag_zh": "奧地利旅行", "tag_en": "Austria",
         "title": "茜茜公主", "title_en": "Empress Sisi",
         "lines": ["原本安排訂婚的，", "其實是她的姊姊。", "",
                    "沒想到，", "皇帝卻對西西公主一見鍾情。"]},
        {"layout": "beat", "photo": "gym.jpg", "text_position": "left",
         "title": "最讓我意外的是⋯", "highlights": ["運動器材"],
         "lines": ["她的房間裡，", "竟然設有運動器材。"]},
        {"layout": "bright", "photo": "palace.jpg",
         "lines": ["比起留在皇宮，", "她更喜歡旅行。"]},
        {"layout": "ending", "photo": "salon.jpg",
         "lines": ["人生難免有許多身不由己。", "",
                    "旅行，不只是走進一個地方。", "也是透過一段故事，",
                    "遇見不同的人生。"]}
      ]
    }

## 每月歸檔

月初跑 `cd scripts && uv run python -m archive_ig_cards`（上個月），
完成後提醒使用者把 `marketing/outputs/ig_cards_archive/<YYYY-MM>/`
備份到 Google Drive。
```

- [ ] **Step 2: Update `backend/README.md`**

在 publisher / 21:00 job 的說明段落（`backend/README.md` 開頭的 job 描述附近）加一段：

```markdown
### Pre-rendered (wander-style) carousel

If `scripts/send_carousel_for_review.py` staged a pre-rendered carousel for
the day (a `social_posts` carousel row with non-NULL `slide_urls`), the
21:00 job publishes exactly those images gated by ✅/❌ on that review
message, and the default card rendering is skipped for the day. ❌ or no
reaction means no carousel that day (no fallback). The day's
`daily_stories` row is synced to the same terminal state. See
`.claude/skills/lorescape-wander-carousel/SKILL.md` for the operator flow
and `docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md`
for the design.
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/lorescape-wander-carousel/ backend/README.md
git commit -m "docs(wander): operator skill + README for wander carousel flow

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 4: 部署 + 端到端驗證清單（需要使用者配合的手動步驟）**

1. Migration：`supabase db push`（或既有部署慣例）套用 `20260706000000_…`。
2. Backend 部署到 VPS（既有流程：pull + `docker compose up -d --build`）。
3. 端到端 dry-run：挑一個測試日期，本機跑完渲染 + `send_carousel_for_review`，
   在 VPS 容器內跑
   `docker exec lorescape-publisher python -m lorescape_backend.social.publisher <date> --dry-run`
   確認 decision / slide URLs（用瀏覽器打開確認可達）/ caption 正確。
4. Discord 按 ✅ 後實發一篇（或直接重跑不帶 `--dry-run`），確認 IG 上的圖序、
   畫質與 caption。
5. 首次實發後，把該日期記錄到 marketing 的內容記錄（沿用現行習慣）。

---

## Self-Review 紀錄

- **Spec coverage**：風格規格（Task 2 CSS/模板 + Task 10 文案規則）、
  渲染模組（Task 1–3）、送審 script（Task 8）、migration（Task 6）、
  publisher 分支含狀態同步與不 fall through（Task 7）、歸檔（Task 9）、
  操作流程文件（Task 10）、錯誤處理（Task 1 驗證、Task 3 缺照片、
  Task 8 缺檔/超大、Task 7 發布失敗、Task 9 中止不刪）、
  測試策略（各 task 的 TDD 步驟 + Task 10 端到端）。spec 的
  dry-run 驗證由 Task 7 的 CLI `--dry-run` 支援。無缺口。
- **Placeholder scan**：無 TBD/TODO；所有程式步驟含完整程式碼。
- **Type consistency**：`WanderSlide`/`WanderCarousel` 欄位在 Task 1–3、
  模板變數、CLI 之間一致；`upload_card_image(..., content_type=...)`
  在 Task 4/8 一致；`record_review_pending(..., slide_urls, caption)` 在
  Task 6/7/8 一致；`send_images_for_review(..., images, publish_date)` 在
  Task 5/8 一致；publisher 分支讀的欄位（`slide_urls`、`caption`、
  `discord_message_id`、`status`）與 Task 6 migration/payload 一致。
```
