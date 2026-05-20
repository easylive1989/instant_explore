# IG Card Phase 1 — Renderer MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Python module `lorescape_backend.social.card` that takes a `CardContent` dataclass and produces a 1080×1350 PNG matching the E0c (朱印方塊, Chinese-only) IG card design.

**Architecture:** Three layers. `content.py` defines the data shape. `template.py` does pure Jinja2 HTML rendering (cheap, unit-testable). `renderer.py` opens a Playwright headless Chromium, loads the HTML, and screenshots a 1080×1350 viewport. Fonts are bundled locally as `.woff2` files referenced via `@font-face` with `file://` URLs, so rendering is fully offline.

**Tech Stack:** Python 3.11, Playwright (headless Chromium), Jinja2, Pillow (for PNG validation), pytest.

**Spec:** `docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md`

**Branch:** `feature/ig-card-phase1-renderer`（per user's workflow: features go on a branch with PR）

---

## File Structure (target end-state)

```
backend/
├── src/lorescape_backend/social/card/
│   ├── __init__.py              # public API: CardContent, render_card
│   ├── content.py               # CardContent dataclass
│   ├── template.py              # Jinja2 render: render_html(content) -> str
│   ├── renderer.py              # Playwright wrapper: render_card(content) -> bytes
│   ├── _demo.py                 # EIFFEL_DEMO fixture (used by CLI + tests)
│   └── template/
│       ├── card.html.j2         # Jinja2 template (E0c, ZH-only)
│       ├── card.css             # combined CSS, E0c-only, no chapter
│       └── fonts/
│           ├── CormorantGaramond-Italic.woff2
│           ├── EBGaramond-Regular.woff2
│           ├── EBGaramond-Italic.woff2
│           ├── NotoSerifTC-Regular.woff2
│           ├── NotoSerifTC-Medium.woff2
│           ├── NotoSerifTC-Black.woff2
│           └── LICENSE.txt
├── scripts/
│   └── download_card_fonts.py   # one-off helper (committed for reproducibility)
├── tests/
│   ├── test_card_content.py
│   ├── test_card_template.py
│   └── test_card_renderer.py
├── Dockerfile                   # +1 line for `playwright install`
└── pyproject.toml               # +3 deps: playwright, jinja2, pillow(dev)
```

`__init__.py` only re-exports the public API; everything else stays internal. Tests live in the flat `backend/tests/` directory matching the repo's existing convention (no per-feature subdirs).

---

### Task 1: Create feature branch + package skeleton + `CardContent` dataclass

**Files:**
- Create: `backend/src/lorescape_backend/social/card/__init__.py`
- Create: `backend/src/lorescape_backend/social/card/content.py`
- Create: `backend/tests/test_card_content.py`

- [ ] **Step 1: Create feature branch from master**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git checkout master
git pull --ff-only
git checkout -b feature/ig-card-phase1-renderer
```

- [ ] **Step 2: Write failing test for `CardContent`**

Create `backend/tests/test_card_content.py`:

```python
"""CardContent dataclass tests."""
from __future__ import annotations

import pytest
from dataclasses import FrozenInstanceError

from lorescape_backend.social.card import CardContent


def _valid_payload() -> dict:
    return dict(
        title_ch="討厭鐵塔的文學大師",
        title_ch_sub="莫泊桑的「專屬午餐位」",
        location_ch="艾菲爾鐵塔．巴黎",
        location_en="TOUR EIFFEL · PARIS",
        location_coord="48.8584°N · 2.2945°E",
        anno_roman="MDCCCLXXXIX",
        city_ch="巴",
        city_en="PARIS",
        paragraphs_ch=("a", "b", "c"),
        pull_quote_ch="「q」",
        pull_quote_attrib_ch="—— x",
        photo_url="https://example.com/p.jpg",
    )


def test_card_content_holds_all_fields():
    payload = _valid_payload()
    content = CardContent(**payload)
    for key, expected in payload.items():
        assert getattr(content, key) == expected


def test_card_content_is_frozen():
    content = CardContent(**_valid_payload())
    with pytest.raises(FrozenInstanceError):
        content.title_ch = "modified"  # type: ignore[misc]


def test_card_content_paragraphs_is_tuple():
    """Tuple is hashable and immutable; ensures we don't accidentally pass a list."""
    content = CardContent(**_valid_payload())
    assert isinstance(content.paragraphs_ch, tuple)
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_content.py -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'lorescape_backend.social.card'`.

- [ ] **Step 4: Create package skeleton**

Create `backend/src/lorescape_backend/social/card/__init__.py`:

```python
"""IG card rendering for daily stories (E0c · 朱印方塊, Chinese-only)."""
from .content import CardContent

__all__ = ["CardContent"]
```

Create `backend/src/lorescape_backend/social/card/content.py`:

```python
"""Content payload for the E0c IG card."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CardContent:
    """Data needed to render one E0c (Chinese-only) IG card."""

    title_ch: str
    title_ch_sub: str
    location_ch: str
    location_en: str
    location_coord: str
    anno_roman: str
    city_ch: str
    city_en: str
    paragraphs_ch: tuple[str, ...]
    pull_quote_ch: str
    pull_quote_attrib_ch: str
    photo_url: str
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_content.py -v
```

Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/src/lorescape_backend/social/card/__init__.py \
        backend/src/lorescape_backend/social/card/content.py \
        backend/tests/test_card_content.py
git commit -m "feat(card): add CardContent dataclass for IG card rendering"
```

---

### Task 2: Add dependencies to `pyproject.toml`

**Files:**
- Modify: `backend/pyproject.toml`
- Modify: `backend/uv.lock` (auto-regenerated)

- [ ] **Step 1: Add new dependencies**

Edit `backend/pyproject.toml`. Find:

```toml
dependencies = [
    "fastapi>=0.115,<1",
    "uvicorn[standard]>=0.32,<1",
    "supabase>=2.10,<3",
    "google-genai>=0.8,<2",
    "requests>=2.32,<3",
    "python-dotenv>=1,<2",
    "apscheduler>=3.10,<4",
]
```

Replace with:

```toml
dependencies = [
    "fastapi>=0.115,<1",
    "uvicorn[standard]>=0.32,<1",
    "supabase>=2.10,<3",
    "google-genai>=0.8,<2",
    "requests>=2.32,<3",
    "python-dotenv>=1,<2",
    "apscheduler>=3.10,<4",
    "playwright>=1.45,<2",
    "jinja2>=3.1,<4",
]
```

Find:

```toml
[project.optional-dependencies]
dev = [
    "pytest>=8,<9",
    "pytest-mock>=3.14,<4",
    "requests-mock>=1.12,<2",
]
```

Replace with:

```toml
[project.optional-dependencies]
dev = [
    "pytest>=8,<9",
    "pytest-mock>=3.14,<4",
    "requests-mock>=1.12,<2",
    "pillow>=10,<12",
]
```

- [ ] **Step 2: Sync dependencies**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv sync
```

Expected: installs playwright, jinja2, pillow without errors. `uv.lock` updated.

- [ ] **Step 3: Install Playwright Chromium locally**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run playwright install chromium
```

Expected: Chromium downloaded into Playwright's cache (~150MB). One-time per dev machine.

- [ ] **Step 4: Verify imports work**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run python -c "import playwright; import jinja2; from PIL import Image; print('OK')"
```

Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/pyproject.toml backend/uv.lock
git commit -m "chore(deps): add playwright, jinja2, pillow for IG card renderer"
```

---

### Task 3: Bundle local fonts via a committed download script

**Files:**
- Create: `backend/scripts/download_card_fonts.py`
- Create (output of script): `backend/src/lorescape_backend/social/card/template/fonts/*.woff2`
- Create: `backend/src/lorescape_backend/social/card/template/fonts/LICENSE.txt`

We commit BOTH the script AND its output so the bundled fonts are reproducible later (re-run the script when fonts need updating).

- [ ] **Step 1: Write the download script**

Create `backend/scripts/download_card_fonts.py`:

```python
"""Download Google Fonts .woff2 files used by the IG card renderer.

Run once to populate backend/src/lorescape_backend/social/card/template/fonts/.
The downloaded files are committed to the repo so card rendering is fully
offline at runtime.

Usage:
    cd backend && uv run python scripts/download_card_fonts.py
"""
from __future__ import annotations

import re
from pathlib import Path

import requests

# Google Fonts CSS2 endpoint returns @font-face blocks pointing at .woff2 URLs.
# Using a modern UA so it serves .woff2 (not legacy formats).
CSS_URL = (
    "https://fonts.googleapis.com/css2"
    "?family=Cormorant+Garamond:ital,wght@1,500"
    "&family=EB+Garamond:ital,wght@0,400;1,400"
    "&family=Noto+Serif+TC:wght@400;500;900"
    "&display=swap"
)
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)

FONT_OUT_DIR = (
    Path(__file__).resolve().parent.parent
    / "src" / "lorescape_backend" / "social" / "card" / "template" / "fonts"
)

# Maps the (family, style, weight) inferred from the CSS to a stable filename.
FILENAME_MAP = {
    ("Cormorant Garamond", "italic", "500"): "CormorantGaramond-Italic.woff2",
    ("EB Garamond", "normal", "400"):        "EBGaramond-Regular.woff2",
    ("EB Garamond", "italic", "400"):        "EBGaramond-Italic.woff2",
    ("Noto Serif TC", "normal", "400"):      "NotoSerifTC-Regular.woff2",
    ("Noto Serif TC", "normal", "500"):      "NotoSerifTC-Medium.woff2",
    ("Noto Serif TC", "normal", "900"):      "NotoSerifTC-Black.woff2",
}


def main() -> None:
    FONT_OUT_DIR.mkdir(parents=True, exist_ok=True)

    resp = requests.get(CSS_URL, headers={"User-Agent": UA}, timeout=30)
    resp.raise_for_status()
    css = resp.text

    # Parse @font-face blocks. Each block has font-family, font-style,
    # font-weight, and an src url(...) format('woff2').
    blocks = re.findall(r"@font-face\s*\{([^}]+)\}", css)
    for block in blocks:
        fam = re.search(r"font-family:\s*'([^']+)'", block)
        style = re.search(r"font-style:\s*(\w+)", block)
        weight = re.search(r"font-weight:\s*(\d+)", block)
        url = re.search(r"url\((https://[^)]+)\)\s*format\('woff2'\)", block)
        if not (fam and style and weight and url):
            continue
        key = (fam.group(1), style.group(1), weight.group(1))
        target_name = FILENAME_MAP.get(key)
        if not target_name:
            continue
        font_url = url.group(1)
        target = FONT_OUT_DIR / target_name
        if target.exists():
            print(f"skip   {target_name} (already present)")
            continue
        print(f"fetch  {target_name}  ← {font_url}")
        font_resp = requests.get(font_url, headers={"User-Agent": UA}, timeout=60)
        font_resp.raise_for_status()
        target.write_bytes(font_resp.content)

    print(f"\nFonts saved to: {FONT_OUT_DIR}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the script to download fonts**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run python scripts/download_card_fonts.py
```

Expected output:
```
fetch  CormorantGaramond-Italic.woff2  ← https://fonts.gstatic.com/s/...
fetch  EBGaramond-Regular.woff2  ← ...
fetch  EBGaramond-Italic.woff2  ← ...
fetch  NotoSerifTC-Regular.woff2  ← ...
fetch  NotoSerifTC-Medium.woff2  ← ...
fetch  NotoSerifTC-Black.woff2  ← ...

Fonts saved to: /Users/paulwu/.../template/fonts
```

If any of the 6 mappings doesn't match a `@font-face` block (Google sometimes reformats CSS), inspect the CSS response and update `FILENAME_MAP`. The 6 expected files must all be present before continuing.

- [ ] **Step 3: Verify all 6 font files are present and non-empty**

```bash
ls -la /Users/paulwu/Documents/Github/instant_explore/backend/src/lorescape_backend/social/card/template/fonts/
```

Expected: 6 `.woff2` files, each >10KB.

- [ ] **Step 4: Add font LICENSE.txt**

Create `backend/src/lorescape_backend/social/card/template/fonts/LICENSE.txt`:

```
Bundled Google Fonts used by the IG card renderer:

  Cormorant Garamond  — SIL Open Font License 1.1
  EB Garamond         — SIL Open Font License 1.1
  Noto Serif TC       — SIL Open Font License 1.1

Full license text: https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL

Source: Google Fonts (https://fonts.google.com). Re-download via:
  backend/scripts/download_card_fonts.py
```

- [ ] **Step 5: Commit fonts + script**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/scripts/download_card_fonts.py \
        backend/src/lorescape_backend/social/card/template/fonts/
git commit -m "chore(card): bundle Google Fonts for offline IG card rendering"
```

---

### Task 4: HTML template (Jinja2) + pure `render_html` function

**Files:**
- Create: `backend/src/lorescape_backend/social/card/template/card.html.j2`
- Create: `backend/src/lorescape_backend/social/card/template.py`
- Create: `backend/src/lorescape_backend/social/card/_demo.py`
- Create: `backend/tests/test_card_template.py`
- Modify: `backend/src/lorescape_backend/social/card/__init__.py`

- [ ] **Step 1: Add `EIFFEL_DEMO` fixture (shared by tests + CLI)**

Create `backend/src/lorescape_backend/social/card/_demo.py`:

```python
"""Eiffel demo CardContent for development + manual visual checks."""
from .content import CardContent

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

- [ ] **Step 2: Write failing test for `render_html`**

Create `backend/tests/test_card_template.py`:

```python
"""Tests for Jinja2 HTML rendering (no Playwright)."""
from __future__ import annotations

from lorescape_backend.social.card import render_html
from lorescape_backend.social.card._demo import EIFFEL_DEMO


def test_render_html_contains_title():
    html = render_html(EIFFEL_DEMO)
    assert "討厭鐵塔的文學大師" in html
    assert "莫泊桑的「專屬午餐位」" in html


def test_render_html_contains_first_paragraph_with_dropcap_split():
    html = render_html(EIFFEL_DEMO)
    # First Chinese character of first paragraph becomes drop-cap
    assert "西" in html  # the dropcap char
    assert "元一八八九年艾菲爾鐵塔甫落成" in html  # the remainder


def test_render_html_contains_all_paragraphs():
    html = render_html(EIFFEL_DEMO)
    for paragraph in EIFFEL_DEMO.paragraphs_ch:
        # Each paragraph appears at least as substring of HTML (drop-cap
        # might split the first, so accept either the full or the tail).
        if paragraph is EIFFEL_DEMO.paragraphs_ch[0]:
            assert paragraph[1:] in html  # tail after drop-cap
        else:
            assert paragraph in html


def test_render_html_contains_pull_quote():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.pull_quote_ch in html
    assert EIFFEL_DEMO.pull_quote_attrib_ch in html


def test_render_html_contains_location_block():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.location_en in html       # spine label
    assert EIFFEL_DEMO.location_coord in html
    assert EIFFEL_DEMO.anno_roman in html


def test_render_html_contains_photo_url():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.photo_url in html


def test_render_html_links_local_css_and_fonts():
    html = render_html(EIFFEL_DEMO)
    # Stylesheet linked relative or via file:// — ok either way
    assert "card.css" in html
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_template.py -v
```

Expected: ImportError on `render_html`.

- [ ] **Step 4: Write the Jinja2 template**

Create `backend/src/lorescape_backend/social/card/template/card.html.j2`:

```jinja2
<!doctype html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8" />
{# `base_url` is injected by the Playwright renderer so relative paths
   (card.css, ./fonts/...) resolve via file://. Pure-HTML unit tests
   pass an empty string, which yields a no-op <base href="">. #}
<base href="{{ base_url }}" />
<link rel="stylesheet" href="card.css" />
</head>
<body>
<div class="ls-card">
  {# ============ PHOTO PLATE ============ #}
  <div class="ls-photo">
    <div class="ls-photo__img" style="background-image: url('{{ content.photo_url }}');"></div>
    <div class="ls-photo__tint"></div>
    <div class="ls-photo__grain"></div>

    <div class="ls-spine"><span>{{ content.location_en }}</span></div>

    <div class="ls-coord">
      <div class="ls-coord__year">Anno · {{ content.anno_roman }}</div>
      <div>{{ content.location_coord }}</div>
    </div>

    <div class="ls-title">
      <h1 class="ls-title__ch">{{ content.title_ch }}</h1>
      <p class="ls-title__ch-sub">{{ content.title_ch_sub }}</p>
    </div>
  </div>

  {# ============ TEXT PLATE (ZH-only, single column) ============ #}
  <div class="ls-text ls-text--single is-ch">
    <div class="ls-folio ls-folio--seal">
      <span class="ls-folio__num"><span class="ls-folio__seal"></span></span>
    </div>

    {% for paragraph in content.paragraphs_ch %}
      <div class="ls-verse {% if loop.first %}ls-verse--first{% endif %}">
        <div class="ls-verse__ch">
          <p class="ls-body-ch">
            {% if loop.first %}<span class="ls-dropcap">{{ paragraph[:1] }}</span>{{ paragraph[1:] }}{% else %}{{ paragraph }}{% endif %}
          </p>
        </div>
      </div>
    {% endfor %}

    <div class="ls-quote">
      <p class="ls-quote__ch">{{ content.pull_quote_ch }}</p>
      <p class="ls-quote__attrib">{{ content.pull_quote_attrib_ch }}</p>
    </div>

    <div class="ls-foot">
      <span>{{ content.location_ch }} · {{ content.city_ch }} {{ content.city_en }}</span>
      <span class="ls-foot__brand">Lorescape · 拾景</span>
    </div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 5: Write the `template.py` module**

Create `backend/src/lorescape_backend/social/card/template.py`:

```python
"""Pure Jinja2 HTML rendering for the IG card (no browser)."""
from __future__ import annotations

from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape

from .content import CardContent

_TEMPLATE_DIR = Path(__file__).resolve().parent / "template"

_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATE_DIR)),
    autoescape=select_autoescape(["html", "j2"]),
)


def render_html(content: CardContent, *, base_url: str = "") -> str:
    """Render the card to an HTML string. No browser involved.

    `base_url` is injected as `<base href=...>` so relative paths (card.css,
    ./fonts/...) resolve correctly when loaded in a browser. Unit tests can
    leave it empty.
    """
    tmpl = _env.get_template("card.html.j2")
    return tmpl.render(content=content, base_url=base_url)


def template_dir() -> Path:
    """Absolute path to the template directory (used by the Playwright renderer)."""
    return _TEMPLATE_DIR
```

- [ ] **Step 6: Re-export `render_html` from package `__init__.py`**

Replace `backend/src/lorescape_backend/social/card/__init__.py`:

```python
"""IG card rendering for daily stories (E0c · 朱印方塊, Chinese-only)."""
from .content import CardContent
from .template import render_html

__all__ = ["CardContent", "render_html"]
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_template.py -v
```

Expected: 7 tests PASS.

- [ ] **Step 8: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/src/lorescape_backend/social/card/template/card.html.j2 \
        backend/src/lorescape_backend/social/card/template.py \
        backend/src/lorescape_backend/social/card/_demo.py \
        backend/src/lorescape_backend/social/card/__init__.py \
        backend/tests/test_card_template.py
git commit -m "feat(card): add Jinja2 HTML template + render_html for E0c card"
```

---

### Task 5: CSS — E0c, single-column Chinese, no chapter, bundled fonts

**Files:**
- Create: `backend/src/lorescape_backend/social/card/template/card.css`

This is the largest single file. Adapt the three source CSS files from
`/tmp/ig-design/lorescape-ig/project/{card,card.text,card.photo}.css`,
keeping ONLY:
- Base card layout (1080×1350, grid, paper background, frame, grain)
- Photo plate styles MINUS the `.ls-eyebrow` block
- `.ls-text--single.is-ch` styles (single column, Chinese-only)
- `.ls-folio--seal` styles
- Drop-cap, body-ch, quote, foot styles

Removing: dinkus / hedera / double folio variants, English-side text styles, `.ls-eyebrow` (chapter), title_en / title_en_sub / verse_en / quote_en blocks.

- [ ] **Step 1: Create `card.css`**

Create `backend/src/lorescape_backend/social/card/template/card.css`:

```css
/* ============================================================
   Lorescape IG Card — E0c · 朱印方塊 · 中文版
   1080×1350 (4:5). Editorial × ancient-book. No chapter.
   ============================================================ */

@font-face {
  font-family: "Cormorant Garamond";
  font-style: italic;
  font-weight: 500;
  src: url("./fonts/CormorantGaramond-Italic.woff2") format("woff2");
  font-display: block;
}
@font-face {
  font-family: "EB Garamond";
  font-style: normal;
  font-weight: 400;
  src: url("./fonts/EBGaramond-Regular.woff2") format("woff2");
  font-display: block;
}
@font-face {
  font-family: "EB Garamond";
  font-style: italic;
  font-weight: 400;
  src: url("./fonts/EBGaramond-Italic.woff2") format("woff2");
  font-display: block;
}
@font-face {
  font-family: "Noto Serif TC";
  font-style: normal;
  font-weight: 400;
  src: url("./fonts/NotoSerifTC-Regular.woff2") format("woff2");
  font-display: block;
}
@font-face {
  font-family: "Noto Serif TC";
  font-style: normal;
  font-weight: 500;
  src: url("./fonts/NotoSerifTC-Medium.woff2") format("woff2");
  font-display: block;
}
@font-face {
  font-family: "Noto Serif TC";
  font-style: normal;
  font-weight: 900;
  src: url("./fonts/NotoSerifTC-Black.woff2") format("woff2");
  font-display: block;
}

:root {
  --paper:        #f3ead7;
  --paper-deep:   #e8dcc0;
  --ink:          #1a1410;
  --ink-soft:     #3a2e22;
  --ink-muted:    #6a5a44;
  --vermilion:    #b6321c;
  --vermilion-dk: #7a1f10;
  --rule:         rgba(26,20,16,0.55);
  --rule-soft:    rgba(26,20,16,0.22);
}

html, body {
  margin: 0;
  padding: 0;
  background: #000;
  font-family: "EB Garamond", "Noto Serif TC", serif;
  color: var(--ink);
}

/* ----------- Card ----------- */
.ls-card {
  width: 1080px;
  height: 1350px;
  position: relative;
  background: var(--paper);
  overflow: hidden;
  display: grid;
  grid-template-rows: 760px 1fr;
  isolation: isolate;
}

/* Subtle paper grain across whole card */
.ls-card::before {
  content: "";
  position: absolute;
  inset: 0;
  background-image:
    radial-gradient(rgba(120,90,50,0.10) 1px, transparent 1px),
    radial-gradient(rgba(80,60,40,0.08) 1px, transparent 1px);
  background-size: 3px 3px, 7px 7px;
  background-position: 0 0, 1px 2px;
  mix-blend-mode: multiply;
  pointer-events: none;
  z-index: 5;
}

/* Hairline inner border (古籍 frame) */
.ls-card::after {
  content: "";
  position: absolute;
  inset: 22px;
  border: 1px solid var(--rule);
  outline: 1px solid var(--rule-soft);
  outline-offset: 6px;
  pointer-events: none;
  z-index: 4;
}

/* ============================================================
   Photo plate
   ============================================================ */
.ls-photo {
  position: relative;
  overflow: hidden;
}
.ls-photo__img {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: saturate(0.92) contrast(1.02);
}
.ls-photo__tint {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(180deg,
      rgba(20,12,8,0.55) 0%,
      rgba(20,12,8,0.10) 35%,
      rgba(20,12,8,0.20) 65%,
      rgba(122,31,16,0.78) 100%);
  mix-blend-mode: multiply;
}
.ls-photo__grain {
  position: absolute;
  inset: 0;
  background-image:
    repeating-linear-gradient(0deg, rgba(0,0,0,0.06) 0 1px, transparent 1px 3px);
  mix-blend-mode: overlay;
  opacity: 0.5;
}

/* Coordinates — top-right */
.ls-coord {
  position: absolute;
  top: 60px;
  right: 60px;
  z-index: 3;
  text-align: right;
  color: var(--paper);
  font-family: "EB Garamond", serif;
  font-size: 13px;
  letter-spacing: 0.28em;
  line-height: 1.7;
  opacity: 0.85;
}
.ls-coord__year {
  font-style: italic;
  letter-spacing: 0.18em;
  font-size: 14px;
  opacity: 0.95;
}

/* Title block — bottom of photo */
.ls-title {
  position: absolute;
  left: 60px;
  right: 60px;
  bottom: 56px;
  z-index: 3;
  color: var(--paper);
}
.ls-title__ch {
  font-family: "Noto Serif TC", serif;
  font-weight: 900;
  font-size: 78px;
  line-height: 1.05;
  letter-spacing: 0.04em;
  margin: 0 0 12px 0;
  text-shadow: 0 2px 24px rgba(0,0,0,0.35);
}
.ls-title__ch-sub {
  font-family: "Noto Serif TC", serif;
  font-weight: 500;
  font-size: 26px;
  letter-spacing: 0.22em;
  opacity: 0.9;
  margin: 0;
}

/* Vertical book-spine label running up left edge of photo */
.ls-spine {
  position: absolute;
  top: 60px;
  bottom: 60px;
  left: 28px;
  width: 14px;
  z-index: 3;
  display: flex;
  align-items: center;
  justify-content: center;
}
.ls-spine span {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-family: "Noto Serif TC", serif;
  color: var(--paper);
  font-size: 12px;
  letter-spacing: 0.6em;
  opacity: 0.65;
}

/* ============================================================
   Text plate (lower half) — single Chinese column only
   ============================================================ */
.ls-text {
  position: relative;
  padding: 52px 110px 40px;
  display: grid;
  grid-template-columns: 1fr;
  row-gap: 0;
}

/* Folio band — E0c · seal · double rules + vermilion diamond */
.ls-folio.ls-folio--seal {
  position: absolute;
  top: -3px;
  left: 70px;
  right: 70px;
  height: 0;
  border-top: 1px solid var(--rule);
  border-bottom: 1px solid var(--rule);
  background: transparent;
  z-index: 2;
}
.ls-folio__num {
  position: absolute;
  top: -7px;
  left: 50%;
  transform: translateX(-50%);
  background: transparent;
  padding: 0;
  line-height: 1;
}
.ls-folio__seal {
  display: inline-block;
  width: 14px;
  height: 14px;
  background: var(--vermilion);
  transform: rotate(45deg);
  box-shadow: 0 0 0 4px var(--paper);
}

/* Verse rows — Chinese-only single column */
.ls-verse {
  display: contents;
}
.ls-verse__ch {
  padding-bottom: 22px;
}
.ls-verse:not(:last-child) .ls-verse__ch {
  border-bottom: 1px solid var(--rule-soft);
  margin-bottom: 18px;
}

/* Drop-cap for the first Chinese verse */
.ls-verse--first .ls-verse__ch {
  position: relative;
}
.ls-dropcap {
  float: left;
  font-family: "Noto Serif TC", serif;
  font-weight: 900;
  color: var(--vermilion);
  font-size: 78px;
  line-height: 0.85;
  padding: 6px 12px 0 0;
  margin-top: 4px;
}

/* Body text — Chinese only, larger than dual mode */
.ls-body-ch {
  font-family: "Noto Serif TC", serif;
  font-weight: 400;
  font-size: 19.5px;
  line-height: 1.85;
  color: var(--ink);
  letter-spacing: 0.02em;
  text-align: justify;
  text-justify: inter-character;
  margin: 0;
}

/* Pull-quote */
.ls-quote {
  grid-column: 1 / -1;
  margin-top: 8px;
  padding: 22px 0 0 0;
  border-top: 1px solid var(--rule-soft);
  text-align: center;
  position: relative;
}
.ls-quote::before {
  content: "❦";
  position: absolute;
  top: -14px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--paper);
  padding: 0 14px;
  color: var(--vermilion);
  font-size: 22px;
}
.ls-quote__ch {
  font-family: "Noto Serif TC", serif;
  font-weight: 500;
  font-size: 22px;
  line-height: 1.6;
  color: var(--vermilion-dk);
  letter-spacing: 0.06em;
  margin: 0 0 8px 0;
}
.ls-quote__attrib {
  font-family: "EB Garamond", serif;
  font-size: 12px;
  letter-spacing: 0.34em;
  text-transform: uppercase;
  color: var(--ink-muted);
  margin: 0;
}

/* Footer marginalia — grid-flow so it never overlaps body */
.ls-foot {
  grid-column: 1 / -1;
  margin-top: 28px;
  padding-top: 16px;
  border-top: 1px solid var(--rule-soft);
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-family: "EB Garamond", serif;
  font-size: 11px;
  letter-spacing: 0.34em;
  text-transform: uppercase;
  color: var(--ink-muted);
}
.ls-foot__brand {
  font-style: italic;
  font-size: 14px;
  letter-spacing: 0.12em;
  text-transform: none;
}
```

- [ ] **Step 2: Sanity check the file**

```bash
ls -la /Users/paulwu/Documents/Github/instant_explore/backend/src/lorescape_backend/social/card/template/card.css
```

Expected: file exists, > 4KB.

```bash
grep -c "@font-face" /Users/paulwu/Documents/Github/instant_explore/backend/src/lorescape_backend/social/card/template/card.css
```

Expected: `6`.

- [ ] **Step 3: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/src/lorescape_backend/social/card/template/card.css
git commit -m "feat(card): add E0c CSS (朱印方塊, Chinese-only, no chapter)"
```

---

### Task 6: Playwright renderer — `render_card(content) -> bytes`

**Files:**
- Create: `backend/src/lorescape_backend/social/card/renderer.py`
- Create: `backend/tests/test_card_renderer.py`
- Modify: `backend/src/lorescape_backend/social/card/__init__.py`

- [ ] **Step 1: Write failing test**

Create `backend/tests/test_card_renderer.py`:

```python
"""Integration test for the IG card Playwright renderer.

Requires Chromium installed locally:
    uv run playwright install chromium
"""
from __future__ import annotations

from io import BytesIO

import pytest
from PIL import Image

from lorescape_backend.social.card import render_card
from lorescape_backend.social.card._demo import EIFFEL_DEMO


@pytest.fixture(scope="module")
def png_bytes() -> bytes:
    return render_card(EIFFEL_DEMO)


def test_render_card_returns_bytes(png_bytes: bytes):
    assert isinstance(png_bytes, bytes)
    assert len(png_bytes) > 1000  # sanity floor — even a blank 1080×1350 is bigger


def test_render_card_output_decodes_as_png(png_bytes: bytes):
    image = Image.open(BytesIO(png_bytes))
    image.verify()
    assert image.format == "PNG"


def test_render_card_dimensions_are_1080_by_1350(png_bytes: bytes):
    image = Image.open(BytesIO(png_bytes))
    assert image.size == (1080, 1350)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_renderer.py -v
```

Expected: ImportError on `render_card`.

- [ ] **Step 3: Implement the renderer**

Create `backend/src/lorescape_backend/social/card/renderer.py`:

```python
"""Playwright-based IG card renderer.

Opens a headless Chromium with a 1080×1350 viewport, loads the Jinja2-
rendered HTML (CSS + local fonts referenced via file://), and screenshots
the page.

Synchronous API for ergonomics: callers should not have to worry about
async event loops just to render a single image.
"""
from __future__ import annotations

from pathlib import Path

from playwright.sync_api import sync_playwright

from .content import CardContent
from .template import render_html, template_dir

_CARD_WIDTH = 1080
_CARD_HEIGHT = 1350


def render_card(content: CardContent) -> bytes:
    """Render the E0c IG card to PNG bytes (1080×1350)."""
    base_url = template_dir().as_uri() + "/"  # file:///.../template/
    html = render_html(content, base_url=base_url)

    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        try:
            page = browser.new_page(
                viewport={"width": _CARD_WIDTH, "height": _CARD_HEIGHT},
                device_scale_factor=1.0,
            )
            # `<base href="...">` in the template makes card.css and the
            # bundled font files resolve under file:// — no temp file needed.
            page.set_content(html, wait_until="networkidle")
            return page.screenshot(type="png", full_page=False, omit_background=False)
        finally:
            browser.close()
```

- [ ] **Step 4: Re-export `render_card` from package `__init__.py`**

Replace `backend/src/lorescape_backend/social/card/__init__.py`:

```python
"""IG card rendering for daily stories (E0c · 朱印方塊, Chinese-only)."""
from .content import CardContent
from .renderer import render_card
from .template import render_html

__all__ = ["CardContent", "render_card", "render_html"]
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run pytest tests/test_card_renderer.py -v
```

Expected: 3 tests PASS. Note: first run may be slow (browser startup ~1-2s).

- [ ] **Step 6: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/src/lorescape_backend/social/card/renderer.py \
        backend/src/lorescape_backend/social/card/__init__.py \
        backend/tests/test_card_renderer.py
git commit -m "feat(card): add Playwright renderer that outputs 1080×1350 PNG"
```

---

### Task 7: Module CLI for manual visual inspection

**Files:**
- Modify: `backend/src/lorescape_backend/social/card/renderer.py` (add `__main__`)

- [ ] **Step 1: Add `__main__` block to renderer.py**

Edit `backend/src/lorescape_backend/social/card/renderer.py`. Append at the end of the file:

```python


def _cli() -> None:
    """Write the Eiffel demo card to /tmp/eiffel.png for visual inspection.

    Usage:
        uv run python -m lorescape_backend.social.card.renderer
    """
    from ._demo import EIFFEL_DEMO

    out = Path("/tmp/eiffel.png")
    out.write_bytes(render_card(EIFFEL_DEMO))
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    _cli()
```

- [ ] **Step 2: Run the CLI manually**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
uv run python -m lorescape_backend.social.card.renderer
```

Expected output:
```
wrote /tmp/eiffel.png (NNNNNN bytes)
```

- [ ] **Step 3: Verify dimensions**

```bash
uv run python -c "from PIL import Image; im = Image.open('/tmp/eiffel.png'); print(im.size, im.format)"
```

Expected: `(1080, 1350) PNG`.

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/src/lorescape_backend/social/card/renderer.py
git commit -m "feat(card): add CLI entrypoint for manual visual inspection"
```

---

### Task 8: Dockerfile — install Chromium for Playwright

**Files:**
- Modify: `backend/Dockerfile`

- [ ] **Step 1: Edit Dockerfile**

Replace `backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip && \
    pip install -e .

# Playwright Chromium + its required system libs (for IG card rendering).
# --with-deps lets Playwright apt-install whatever Chromium needs (libnss,
# libatk, fonts, etc.) on top of the python:3.11-slim base.
RUN playwright install --with-deps chromium

EXPOSE 8000

# Default command runs the FastAPI app.
# The cron job is invoked separately (see docker-compose / system cron).
CMD ["uvicorn", "lorescape_backend.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: Build the image locally to verify**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
docker build -t lorescape-backend:phase1-test .
```

Expected: build succeeds. Image size grows ~250MB compared to baseline.

- [ ] **Step 3: Smoke-test rendering inside the container**

```bash
docker run --rm -v /tmp/docker-card:/tmp lorescape-backend:phase1-test \
  python -m lorescape_backend.social.card.renderer
ls -la /tmp/docker-card/eiffel.png
```

Expected: file exists, >50KB.

(If you don't have Docker locally and only run on the VPS, this verification can be deferred — but ensure the Dockerfile syntax is correct via a `docker build --no-cache` somewhere before merging.)

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add backend/Dockerfile
git commit -m "build(backend): install Playwright Chromium for IG card rendering"
```

---

### Task 9: Manual visual inspection + iteration

This is a **gate, not a code task**. The structural tests pass, but the
real question is "does the PNG look like the E0c design from the chat?"

- [ ] **Step 1: Render the demo**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/backend
rm -f /tmp/eiffel.png
uv run python -m lorescape_backend.social.card.renderer
open /tmp/eiffel.png
```

- [ ] **Step 2: Eyeball-compare to the design intent**

Cross-check against the chat description in
`/tmp/ig-design/lorescape-ig/chats/chat1.md` (last assistant message about
E0c). Specifically verify:

  - [ ] 1080×1350 4:5 aspect
  - [ ] Upper 760px: full-bleed Eiffel photo with vermilion+ink duotone overlay
  - [ ] **No** chapter eyebrow in top-left (we removed it)
  - [ ] Top-right: "Anno · MDCCCLXXXIX" + coord
  - [ ] Left edge: vertical book-spine label "TOUR EIFFEL · PARIS"
  - [ ] Bottom of photo: "討厭鐵塔的文學大師" + "莫泊桑的「專屬午餐位」"
  - [ ] Lower half: cream paper, single-column Chinese
  - [ ] Folio band: two horizontal rules with a small vermilion diamond at the midpoint
  - [ ] First paragraph: vermilion drop-cap on "西"
  - [ ] Each paragraph separated by thin underline
  - [ ] Pull quote: vermilion, surrounded by `❦` ornament + top rule
  - [ ] Footer: location + Lorescape · 拾景, NOT overlapping the quote

- [ ] **Step 3: If anything is off, iterate**

If the visual doesn't match: tweak `card.css` or `card.html.j2`, re-run
Task 9 Step 1. Common issues:
  - Fonts not loading → check `card.css @font-face` URLs vs actual filenames in `template/fonts/`; check `<base href>` injection in `renderer.py`
  - Layout off → compare against the original `/tmp/ig-design/lorescape-ig/project/card.text.css` and `.photo.css`
  - Photo not appearing → check `photo_url` is reachable; Playwright's `wait_until="networkidle"` should already wait for it

Commit any visual fixes as separate `fix(card): ...` commits.

- [ ] **Step 4: Save the verified PNG for the PR**

```bash
cp /tmp/eiffel.png /tmp/ig-card-phase1-demo.png
```

Attach this PNG to the PR in Task 10.

---

### Task 10: Push branch + open PR

**Files:** none (git/gh only)

- [ ] **Step 1: Push the feature branch**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git push -u origin feature/ig-card-phase1-renderer
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create \
  --base master \
  --head feature/ig-card-phase1-renderer \
  --title "feat(card): IG card Phase 1 — Playwright-based renderer MVP" \
  --body "$(cat <<'EOF'
## Summary

Phase 1 of IG card auto-post feature. Adds a Python module
`lorescape_backend.social.card` that turns a `CardContent` dataclass into
a 1080×1350 PNG matching the E0c (朱印方塊, Chinese-only) design.

- New package `social/card/` with `CardContent`, `render_html`, `render_card`
- HTML/CSS adapted from Claude Design's `IG Card Variants.html` (E0c only)
- Bundled Google Fonts (.woff2) for offline rendering
- Playwright headless Chromium for PNG screenshotting
- Dockerfile updated to install Chromium

Pure rendering only — no DB / Gemini / publisher integration yet
(those land in Phases 2 and 3).

See:
- Spec: `docs/superpowers/specs/2026-05-20-ig-card-phase1-renderer-design.md`
- Plan: `docs/superpowers/plans/2026-05-20-ig-card-phase1-renderer.md`

## Test plan
- [ ] `uv run pytest tests/test_card_*.py` — all green
- [ ] `uv run python -m lorescape_backend.social.card.renderer` — produces `/tmp/eiffel.png` at 1080×1350
- [ ] Visual: opened PNG, matches E0c design (see attached `ig-card-phase1-demo.png`)
- [ ] `docker build` succeeds with new Chromium layer

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: Attach the demo PNG to the PR**

Drag-and-drop `/tmp/ig-card-phase1-demo.png` into the PR description in the
GitHub UI (CLI can't upload images directly).

- [ ] **Step 4: Hand off**

Report back: PR URL.

---

## Done criteria (matches spec §"Phase 1 目標")

- ✅ `render_card(EIFFEL_DEMO)` returns a 1080×1350 PNG bytes object
- ✅ Visual output matches the E0c · Eiffel · 中文版 design
- ✅ `uv run pytest tests/test_card_*.py` — all tests pass
- ✅ Dockerfile builds + Chromium is available at runtime
- ✅ No DB / Gemini / publisher changes (those are Phase 2/3)

## Out of scope (deferred to later phases)

- Phase 0: IG token setup (separate spec)
- Phase 2: `daily_stories` schema + Gemini prompt extension to produce the new card fields
- Phase 3: publisher wiring (render → upload to Supabase Storage → use that URL for IG post)
- Unsplash photo lookup (Phase 3 candidate)
- Bilingual / English-only card variants
- Carousel posts
