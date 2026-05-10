# Daily Place Story — P2: Backend Cron Job Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 VPS 上跑一個 Python cron job，每天 23:30 (Asia/Taipei) 從 Wikipedia 抓內容、用 Gemini 生成 zh-TW + en 兩語言的歷史故事、寫入 Supabase `daily_stories` 表。失敗時 Discord webhook 通知。

**Architecture:** 純 Python `src/` layout 套件。每個外部相依（Wikipedia、Gemini、Supabase、Discord）一個 module，搭配 unit tests with mocks。`job.py` 串起整個流程，含 retry 邏輯。CLI 入口讓 system cron 直接呼叫。最小 FastAPI scaffold 留給未來 API（spec 要求）。

**Tech Stack:** Python 3.11+、`google-genai` SDK、`supabase` SDK、`requests`、`fastapi` + `uvicorn`(僅 scaffold)、`pytest` + `pytest-mock` + `requests-mock`、Docker (optional)。

**Source spec:** `docs/superpowers/specs/2026-05-10-daily-place-story-design.md`
**Depends on:** P1 (Supabase tables + 景點清單) — assumes `daily_story_places` 已有資料、`daily_stories` 表已建好。

---

## File Structure

```
backend/                                       # NEW directory at repo root
├── README.md                                  # NEW: dev + deploy guide
├── pyproject.toml                             # NEW: project config + deps
├── .env.example                               # NEW: required env vars
├── .gitignore                                 # NEW: .venv, __pycache__, .env
├── Dockerfile                                 # NEW: minimal Python image
├── docker-compose.yml                         # NEW: FastAPI service for VPS
├── deploy/
│   └── crontab.example                        # NEW: example cron line
├── src/
│   └── lorescape_backend/
│       ├── __init__.py
│       ├── config.py                          # env vars → Config dataclass
│       ├── api.py                             # minimal FastAPI app (/health)
│       └── daily_story/
│           ├── __init__.py
│           ├── __main__.py                    # CLI entrypoint
│           ├── job.py                         # orchestrator + retry
│           ├── place_picker.py                # Supabase: pick + mark used
│           ├── wikipedia.py                   # REST API: summary + langlinks
│           ├── prompts.py                     # Gemini prompt + JSON schema
│           ├── gemini_client.py               # google-genai wrapper
│           ├── story_writer.py                # Supabase: insert daily_stories
│           └── discord_notify.py              # webhook POST
└── tests/
    ├── __init__.py
    ├── conftest.py                            # shared fixtures
    ├── test_config.py
    ├── test_wikipedia.py
    ├── test_prompts.py
    ├── test_place_picker.py
    ├── test_story_writer.py
    ├── test_discord_notify.py
    ├── test_gemini_client.py
    └── test_job.py
```

**檔案分工原則**：
- 一個 module 一個責任、一個 test 檔。每個 module 預期 < 100 行。
- 外部相依（HTTP、SDK）封在 module 裡，job orchestrator 只跟我們自己的 module 互動。
- `Config` dataclass 注入到所有需要 env vars 的地方（避免直接讀 `os.environ`）。
- 測試一律用 mock — 不打外部 API。

---

## Task 1: Project scaffold

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/.env.example`
- Create: `backend/.gitignore`
- Create: `backend/README.md`
- Create: `backend/src/lorescape_backend/__init__.py`
- Create: `backend/src/lorescape_backend/daily_story/__init__.py`
- Create: `backend/tests/__init__.py`
- Create: `backend/tests/conftest.py`

- [ ] **Step 1: 建 `backend/pyproject.toml`**

```toml
[project]
name = "lorescape-backend"
version = "0.1.0"
description = "VPS backend for Lorescape (daily story cron + future APIs)"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115,<1",
    "uvicorn[standard]>=0.32,<1",
    "supabase>=2.10,<3",
    "google-genai>=0.8,<2",
    "requests>=2.32,<3",
    "python-dotenv>=1,<2",
]

[project.optional-dependencies]
dev = [
    "pytest>=8,<9",
    "pytest-mock>=3.14,<4",
    "requests-mock>=1.12,<2",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
pythonpath = ["src"]
testpaths = ["tests"]
```

- [ ] **Step 2: 建 `backend/.env.example`**

```
# Supabase (use the SERVICE_ROLE key — bypasses RLS for writes)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Gemini (Google AI Studio key)
GEMINI_API_KEY=your_gemini_api_key

# Discord webhook for failure alerts (optional but recommended)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

- [ ] **Step 3: 建 `backend/.gitignore`**

```
.venv/
__pycache__/
*.egg-info/
.pytest_cache/
.env
```

- [ ] **Step 4: 建 `backend/README.md`** (placeholder; 詳細部署在 Task 12)

```markdown
# Lorescape Backend

VPS backend for Lorescape:
- **Daily story cron job** (P2) — generates daily place narratives via Gemini, writes to Supabase
- **FastAPI app** (placeholder) — will host future APIs

See `docs/superpowers/specs/2026-05-10-daily-place-story-design.md` for the full spec.

## Local development

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env  # then fill in real values
pytest
```

## Run the cron job manually (for testing)

```bash
python -m lorescape_backend.daily_story         # for tomorrow (default)
python -m lorescape_backend.daily_story 2026-05-15  # for specific date
```

## Run the FastAPI dev server

```bash
uvicorn lorescape_backend.api:app --reload --port 8000
```

(Deployment instructions live further down — added in Task 12.)
```

- [ ] **Step 5: 建空的 `__init__.py` 檔案**

```bash
touch backend/src/lorescape_backend/__init__.py
touch backend/src/lorescape_backend/daily_story/__init__.py
touch backend/tests/__init__.py
```

- [ ] **Step 6: 建 `backend/tests/conftest.py`**

```python
"""Shared pytest fixtures."""
from __future__ import annotations

import pytest

from lorescape_backend.config import Config


@pytest.fixture
def fake_config() -> Config:
    """A Config with dummy non-empty values for testing."""
    return Config(
        supabase_url="https://test.supabase.co",
        supabase_service_role_key="test_service_role_key",
        gemini_api_key="test_gemini_key",
        discord_webhook_url="https://discord.com/api/webhooks/test",
    )
```

(Note: this fixture imports `Config` from a module written in Task 2. The conftest will be importable but tests that use `fake_config` will only work after Task 2.)

- [ ] **Step 7: 建立 venv, 安裝, sanity check**

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -q -e ".[dev]"
python -c "import fastapi, supabase, google.genai, requests; print('imports ok')"
pytest --version
```
Expected: `imports ok` printed; pytest version printed.

If `google.genai` import fails, the SDK package name might differ. Check: `pip show google-genai` should give an import name. Adjust if needed and report.

- [ ] **Step 8: Commit**

```bash
git add backend/
git commit -m "feat(backend): scaffold backend project (pyproject, env example, readme)"
```

---

## Task 2: Config module

**Files:**
- Create: `backend/src/lorescape_backend/config.py`
- Create: `backend/tests/test_config.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_config.py
import os
import pytest

from lorescape_backend.config import Config


def test_from_env_loads_all_required(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord/wh")

    config = Config.from_env()

    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "key1"
    assert config.gemini_api_key == "key2"
    assert config.discord_webhook_url == "https://discord/wh"


def test_from_env_discord_webhook_optional(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")
    monkeypatch.delenv("DISCORD_WEBHOOK_URL", raising=False)

    config = Config.from_env()
    assert config.discord_webhook_url is None


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")

    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()
```

- [ ] **Step 2: Run tests — verify failures**

```bash
cd backend && source .venv/bin/activate && pytest tests/test_config.py -v
```
Expected: ImportError or 3 errors (Config not defined yet).

- [ ] **Step 3: Implement `backend/src/lorescape_backend/config.py`**

```python
"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    supabase_url: str
    supabase_service_role_key: str
    gemini_api_key: str
    discord_webhook_url: str | None  # optional

    @classmethod
    def from_env(cls) -> "Config":
        def required(name: str) -> str:
            value = os.environ.get(name)
            if not value:
                raise RuntimeError(f"Missing required env var: {name}")
            return value

        return cls(
            supabase_url=required("SUPABASE_URL"),
            supabase_service_role_key=required("SUPABASE_SERVICE_ROLE_KEY"),
            gemini_api_key=required("GEMINI_API_KEY"),
            discord_webhook_url=os.environ.get("DISCORD_WEBHOOK_URL") or None,
        )
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_config.py -v
```
Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/config.py backend/tests/test_config.py
git commit -m "feat(backend): add Config dataclass loaded from env vars"
```

---

## Task 3: Wikipedia module

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/wikipedia.py`
- Create: `backend/tests/test_wikipedia.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_wikipedia.py
import pytest
import requests_mock

from lorescape_backend.daily_story.wikipedia import (
    WikipediaSummary,
    fetch_summary,
    fetch_langlink_url,
)


SUMMARY_RESPONSE = {
    "title": "Colosseum",
    "extract": "The Colosseum is an oval amphitheatre in the centre of Rome.",
    "thumbnail": {"source": "https://upload.wikimedia.org/colosseum.jpg"},
    "content_urls": {
        "desktop": {"page": "https://en.wikipedia.org/wiki/Colosseum"}
    },
}


def test_fetch_summary_returns_extract_image_and_url():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Colosseum",
            json=SUMMARY_RESPONSE,
        )
        summary = fetch_summary("Colosseum")

    assert summary == WikipediaSummary(
        title="Colosseum",
        extract="The Colosseum is an oval amphitheatre in the centre of Rome.",
        image_url="https://upload.wikimedia.org/colosseum.jpg",
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )


def test_fetch_summary_handles_missing_thumbnail():
    response_no_thumb = {**SUMMARY_RESPONSE}
    response_no_thumb.pop("thumbnail")
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Colosseum",
            json=response_no_thumb,
        )
        summary = fetch_summary("Colosseum")
    assert summary.image_url is None


def test_fetch_summary_url_encodes_title_with_spaces():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Mont-Saint-Michel%20and%20its%20Bay",
            json={**SUMMARY_RESPONSE, "title": "Mont-Saint-Michel and its Bay"},
        )
        summary = fetch_summary("Mont-Saint-Michel and its Bay")
    assert summary.title == "Mont-Saint-Michel and its Bay"


LANGLINK_RESPONSE_WITH_ZH = {
    "query": {
        "pages": {
            "12345": {
                "pageid": 12345,
                "ns": 0,
                "title": "Colosseum",
                "langlinks": [{"lang": "zh", "*": "羅馬鬥獸場"}],
            }
        }
    }
}


def test_fetch_langlink_url_returns_target_lang_wiki_url():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/w/api.php",
            json=LANGLINK_RESPONSE_WITH_ZH,
        )
        url = fetch_langlink_url("Colosseum", "zh")
    assert url == "https://zh.wikipedia.org/wiki/%E7%BE%85%E9%A6%AC%E9%AC%A5%E7%8D%B8%E5%A0%B4"


def test_fetch_langlink_url_returns_none_when_no_langlink():
    response = {
        "query": {
            "pages": {
                "12345": {"pageid": 12345, "ns": 0, "title": "X"}
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=response)
        assert fetch_langlink_url("X", "zh") is None
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_wikipedia.py -v
```
Expected: ImportError or 5 errors.

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/wikipedia.py`**

```python
"""Wikipedia REST/MediaWiki API client.

Two endpoints used:
- REST `/page/summary/{title}` for extract + thumbnail (English ground truth)
- MediaWiki `?action=query&prop=langlinks` for target-language article URLs
"""
from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import quote

import requests

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_REST_BASE = "https://en.wikipedia.org/api/rest_v1"
_API_URL = "https://en.wikipedia.org/w/api.php"


@dataclass(frozen=True)
class WikipediaSummary:
    title: str
    extract: str
    image_url: str | None
    en_url: str


def fetch_summary(title: str) -> WikipediaSummary:
    """Fetch the English Wikipedia summary for `title`.

    `title` may contain spaces; the path segment is URL-encoded.
    """
    encoded = quote(title, safe="")
    response = requests.get(
        f"{_REST_BASE}/page/summary/{encoded}",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    return WikipediaSummary(
        title=data["title"],
        extract=data.get("extract", ""),
        image_url=(data.get("thumbnail") or {}).get("source"),
        en_url=data["content_urls"]["desktop"]["page"],
    )


def fetch_langlink_url(title: str, target_lang: str) -> str | None:
    """Find the URL of `title`'s article in `target_lang` (e.g. 'zh').

    Returns None if no langlink to that language exists.
    Constructs the URL deterministically from the langlink title — does NOT
    rely on the API returning a `url` field.
    """
    response = requests.get(
        _API_URL,
        params={
            "action": "query",
            "format": "json",
            "titles": title,
            "prop": "langlinks",
            "lllang": target_lang,
            "redirects": 1,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        for link in page.get("langlinks", []):
            target_title = link.get("*") or link.get("title")
            if not target_title:
                continue
            return _wiki_url(target_lang, target_title)
    return None


def _wiki_url(lang: str, title: str) -> str:
    return f"https://{lang}.wikipedia.org/wiki/{quote(title.replace(' ', '_'))}"
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_wikipedia.py -v
```
Expected: 5 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/wikipedia.py backend/tests/test_wikipedia.py
git commit -m "feat(backend): add Wikipedia client (summary + langlinks)"
```

---

## Task 4: Prompts module

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/prompts.py`
- Create: `backend/tests/test_prompts.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_prompts.py
from lorescape_backend.daily_story.prompts import (
    GEMINI_RESPONSE_SCHEMA,
    SYSTEM_INSTRUCTION,
    build_user_prompt,
)


def test_build_user_prompt_includes_extract_and_language_name_zh_tw():
    prompt = build_user_prompt(
        wikipedia_title="Colosseum",
        wikipedia_extract="Built in 70-80 CE by Vespasian.",
        language="zh-TW",
    )
    assert "Colosseum" in prompt
    assert "Built in 70-80 CE by Vespasian." in prompt
    assert "Traditional Chinese" in prompt or "zh-TW" in prompt


def test_build_user_prompt_includes_language_name_en():
    prompt = build_user_prompt(
        wikipedia_title="Colosseum",
        wikipedia_extract="Built in 70-80 CE.",
        language="en",
    )
    assert "English" in prompt


def test_build_user_prompt_lists_required_fields():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    for field in ("place_name", "place_location", "era", "story"):
        assert field in prompt


def test_build_user_prompt_states_anti_hallucination_constraint():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    # Should mention real historical figure / specific year / concrete event
    lower = prompt.lower()
    assert "historical figure" in lower or "real" in lower
    assert "year" in lower or "era" in lower


def test_system_instruction_forbids_inventing_facts():
    lower = SYSTEM_INSTRUCTION.lower()
    assert "strictly" in lower or "do not introduce" in lower or "do not invent" in lower


def test_response_schema_requires_four_fields():
    required = GEMINI_RESPONSE_SCHEMA.get("required", [])
    assert set(required) == {"place_name", "place_location", "era", "story"}


def test_build_user_prompt_raises_on_unknown_language():
    import pytest
    with pytest.raises(KeyError):
        build_user_prompt(wikipedia_title="X", wikipedia_extract="Y", language="ja")
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_prompts.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/prompts.py`**

```python
"""Gemini prompt + structured-output schema for daily story generation.

Goal: minimise hallucination by forcing the model to ground its output
strictly in the provided Wikipedia extract.
"""
from __future__ import annotations


SYSTEM_INSTRUCTION = (
    "You are a historian. You will write a true historical short story about a "
    "famous landmark, based STRICTLY on the Wikipedia content provided. "
    "Do NOT introduce any historical facts, names, or events that do not "
    "appear in the source material. If the source is insufficient for a "
    "specific claim, omit it rather than invent."
)


# JSON schema for Gemini structured output.
# Uses uppercase types per google-genai schema conventions.
GEMINI_RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "place_name": {"type": "STRING"},
        "place_location": {"type": "STRING"},
        "era": {"type": "STRING"},
        "story": {"type": "STRING"},
    },
    "required": ["place_name", "place_location", "era", "story"],
}


_LANGUAGE_NAMES = {
    "zh-TW": "Traditional Chinese (zh-TW)",
    "en": "English (en)",
}


def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair."""
    language_name = _LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    return (
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):\n'
        f"<<<\n{wikipedia_extract}\n>>>\n\n"
        f"Write a 300-500 character true historical story in {language_name}.\n"
        "Requirements:\n"
        '- Include at least one specific year or era (e.g., "70-80 CE")\n'
        "- Include at least one real historical figure named in the source\n"
        "- Describe one concrete historical event from the source\n"
        "- End with the place name, location, and approximate era\n\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name\n"
        "- place_location: localized location (e.g., country/city)\n"
        "- era: approximate era of the story\n"
        "- story: the 300-500 char story body\n"
    )
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_prompts.py -v
```
Expected: 7 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/prompts.py backend/tests/test_prompts.py
git commit -m "feat(backend): add Gemini prompt + JSON schema for daily story"
```

---

## Task 5: Place picker module

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/place_picker.py`
- Create: `backend/tests/test_place_picker.py`

- [ ] **Step 1: Write failing tests**

The Supabase Python SDK uses a chained query builder. Mock at the `Client` level by chaining attribute/method returns.

```python
# backend/tests/test_place_picker.py
from unittest.mock import MagicMock, ANY

import pytest

from lorescape_backend.daily_story.place_picker import (
    PickedPlace,
    pick_next_place,
    mark_place_used,
)


def _mock_supabase_with_query_result(rows: list[dict]) -> MagicMock:
    """Build a chained-mock Supabase client whose .table().select()....execute()
    chain returns a response with `data = rows`."""
    response = MagicMock()
    response.data = rows
    chain = MagicMock()
    chain.select.return_value = chain
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.order.return_value = chain
    chain.limit.return_value = chain
    chain.update.return_value = chain
    chain.execute.return_value = response
    client = MagicMock()
    client.table.return_value = chain
    return client


def test_pick_next_place_picks_unused_active_when_present():
    client = _mock_supabase_with_query_result(
        [{"id": "p1", "wikipedia_title_en": "Colosseum"}]
    )

    place = pick_next_place(client)

    assert place == PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    # Verify the right table was queried first
    client.table.assert_any_call("daily_story_places")


def test_pick_next_place_returns_none_when_no_places():
    """If neither unused nor recyclable rows exist, return None.

    To simulate this, we configure the chain so .execute() always returns empty.
    """
    client = _mock_supabase_with_query_result([])

    assert pick_next_place(client) is None


def test_pick_next_place_recycles_oldest_when_all_used(mocker):
    """When the unused query returns empty, the picker should fall back to the
    oldest used active place (re-cycle)."""
    response_empty = MagicMock()
    response_empty.data = []
    response_recycle = MagicMock()
    response_recycle.data = [{"id": "p_old", "wikipedia_title_en": "Old Place"}]

    chain = MagicMock()
    chain.select.return_value = chain
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.order.return_value = chain
    chain.limit.return_value = chain
    # First call → empty (unused query); second call → recycle result
    chain.execute.side_effect = [response_empty, response_recycle]

    client = MagicMock()
    client.table.return_value = chain

    place = pick_next_place(client)
    assert place == PickedPlace(id="p_old", wikipedia_title_en="Old Place")


def test_mark_place_used_calls_update_with_now_timestamp():
    client = _mock_supabase_with_query_result([])
    mark_place_used(client, "p1")

    client.table.assert_called_with("daily_story_places")
    chain = client.table.return_value
    chain.update.assert_called_once()
    payload = chain.update.call_args[0][0]
    assert "used_at" in payload
    # Should be ISO-8601 UTC timestamp
    assert "T" in payload["used_at"]
    chain.eq.assert_called_with("id", "p1")
    chain.execute.assert_called()
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_place_picker.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/place_picker.py`**

```python
"""Pick the next place for a daily story.

Strategy:
1. Try to pick an active, never-used place (used_at IS NULL), oldest first.
2. If all are used, pick the active place with the oldest used_at (re-cycle).
3. After the story is generated, call `mark_place_used` to update used_at.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass(frozen=True)
class PickedPlace:
    id: str
    wikipedia_title_en: str


def pick_next_place(supabase) -> PickedPlace | None:
    """Returns the next place, or None if no active places exist."""
    # 1. Never-used active places, oldest first
    response = (
        supabase.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .eq("is_active", True)
        .is_("used_at", "null")
        .order("created_at")
        .limit(1)
        .execute()
    )
    if response.data:
        row = response.data[0]
        return PickedPlace(id=row["id"], wikipedia_title_en=row["wikipedia_title_en"])

    # 2. Recycle: oldest used_at among active places
    response = (
        supabase.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .eq("is_active", True)
        .order("used_at")
        .limit(1)
        .execute()
    )
    if response.data:
        row = response.data[0]
        return PickedPlace(id=row["id"], wikipedia_title_en=row["wikipedia_title_en"])

    return None


def mark_place_used(supabase, place_id: str) -> None:
    """Set used_at = now() on the given place."""
    now_iso = datetime.now(timezone.utc).isoformat()
    (
        supabase.table("daily_story_places")
        .update({"used_at": now_iso})
        .eq("id", place_id)
        .execute()
    )
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_place_picker.py -v
```
Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/place_picker.py backend/tests/test_place_picker.py
git commit -m "feat(backend): add place picker (unused first, recycle oldest used)"
```

---

## Task 6: Story writer module

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/story_writer.py`
- Create: `backend/tests/test_story_writer.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_story_writer.py
from datetime import date
from unittest.mock import MagicMock

from lorescape_backend.daily_story.story_writer import StoryRow, insert_story


def test_insert_story_upserts_with_publish_date_language_conflict_key():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 11),
        language="zh-TW",
        place_id="place-1",
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        story="...",
        image_url="https://upload.wikimedia.org/x.jpg",
        wikipedia_url="https://zh.wikipedia.org/wiki/...",
    )

    insert_story(client, row)

    client.table.assert_called_with("daily_stories")
    chain.upsert.assert_called_once()
    payload = chain.upsert.call_args[0][0]
    assert payload == {
        "publish_date": "2026-05-11",
        "language": "zh-TW",
        "place_id": "place-1",
        "place_name": "羅馬競技場",
        "place_location": "義大利羅馬",
        "era": "公元 70-80 年",
        "story": "...",
        "image_url": "https://upload.wikimedia.org/x.jpg",
        "wikipedia_url": "https://zh.wikipedia.org/wiki/...",
    }
    # Verify on_conflict kwarg
    assert chain.upsert.call_args.kwargs.get("on_conflict") == "publish_date,language"


def test_insert_story_handles_null_image_url():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    insert_story(
        client,
        StoryRow(
            publish_date=date(2026, 5, 11),
            language="en",
            place_id="p",
            place_name="X",
            place_location="Y",
            era="Z",
            story="...",
            image_url=None,
            wikipedia_url="https://en.wikipedia.org/wiki/X",
        ),
    )

    payload = chain.upsert.call_args[0][0]
    assert payload["image_url"] is None
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_story_writer.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/story_writer.py`**

```python
"""Insert daily story rows into Supabase."""
from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date


@dataclass(frozen=True)
class StoryRow:
    publish_date: date
    language: str
    place_id: str
    place_name: str
    place_location: str
    era: str
    story: str
    image_url: str | None
    wikipedia_url: str


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language))."""
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_story_writer.py -v
```
Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/story_writer.py backend/tests/test_story_writer.py
git commit -m "feat(backend): add daily_stories upsert writer"
```

---

## Task 7: Discord notify module

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/discord_notify.py`
- Create: `backend/tests/test_discord_notify.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_discord_notify.py
import requests_mock

from lorescape_backend.daily_story.discord_notify import notify_failure


WEBHOOK = "https://discord.com/api/webhooks/123/abc"


def test_notify_failure_posts_content_with_date_error_traceback():
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=204)
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str="Traceback (most recent call last):\n  ...",
        )
    assert m.called
    body = m.last_request.json()
    content = body["content"]
    assert "2026-05-11" in content
    assert "boom" in content
    assert "Traceback" in content


def test_notify_failure_truncates_long_traceback_to_safe_size():
    huge_tb = "x" * 5000
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=204)
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str=huge_tb,
        )
    body = m.last_request.json()
    # Discord content max is 2000 chars; payload must be under it.
    assert len(body["content"]) <= 2000


def test_notify_failure_does_not_raise_on_http_error():
    """Network error must not crash the calling process — it's already failing."""
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=500)
        # Should not raise
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str="...",
        )
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_discord_notify.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/discord_notify.py`**

```python
"""Discord webhook notifier for failure alerts."""
from __future__ import annotations

import logging

import requests

logger = logging.getLogger(__name__)

# Discord content limit is 2000 chars; reserve some headroom for the prefix.
_MAX_CONTENT = 1900
_PREFIX_BUDGET = 200  # rough budget for the date/error prefix


def notify_failure(
    *, webhook_url: str, date_str: str, error_message: str, traceback_str: str
) -> None:
    """POST a failure summary to Discord.

    Truncates the traceback to keep the total payload under Discord's 2000-char
    limit. Swallows HTTP errors — the caller is already handling a failure and
    we don't want to crash on top of that.
    """
    prefix = f"🚨 daily_story_job failed for date {date_str}\n"
    body = f"{error_message}\n\n{traceback_str}"
    available = _MAX_CONTENT - len(prefix) - len("```\n\n```")
    truncated = body[:available]
    content = f"{prefix}```\n{truncated}\n```"

    try:
        requests.post(webhook_url, json={"content": content}, timeout=10)
    except Exception:  # noqa: BLE001 — last-resort notifier
        logger.exception("Failed to POST Discord notification")
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_discord_notify.py -v
```
Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/discord_notify.py backend/tests/test_discord_notify.py
git commit -m "feat(backend): add Discord webhook notifier for job failures"
```

---

## Task 8: Gemini client module

**⚠️ Before implementing:** verify the `google-genai` Python SDK API matches what's written below. Use WebFetch on https://ai.google.dev/gemini-api/docs/text-generation?hl=en (Python tab) and structured-output docs at https://ai.google.dev/gemini-api/docs/structured-output. If the API differs, adapt the implementation but keep the same function signature for the tests.

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/gemini_client.py`
- Create: `backend/tests/test_gemini_client.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_gemini_client.py
import json
from unittest.mock import MagicMock, patch

from lorescape_backend.daily_story.gemini_client import (
    GeneratedStory,
    generate_story,
)


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_parses_json_response(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "羅馬競技場",
            "place_location": "義大利羅馬",
            "era": "公元 70-80 年",
            "story": "...",
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    result = generate_story(
        api_key="key",
        system_instruction="sys",
        user_prompt="user",
        response_schema={"type": "OBJECT"},
    )

    assert result == GeneratedStory(
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        story="...",
    )
    mock_client_cls.assert_called_once_with(api_key="key")
    call_kwargs = mock_client.models.generate_content.call_args.kwargs
    assert call_kwargs["model"] == "gemini-2.5-flash"


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_passes_system_instruction_and_temperature(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {"place_name": "X", "place_location": "Y", "era": "Z", "story": "S"}
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    generate_story(
        api_key="key",
        system_instruction="my-system",
        user_prompt="my-user",
        response_schema={"type": "OBJECT", "required": ["story"]},
    )

    kwargs = mock_client.models.generate_content.call_args.kwargs
    config = kwargs["config"]
    # The config object must convey the system instruction, temperature, JSON
    # mime type, and schema. Implementation may use either GenerateContentConfig
    # or a dict — we read attributes via getattr/dict access tolerantly.
    if isinstance(config, dict):
        assert config["system_instruction"] == "my-system"
        assert config["temperature"] == 0.3
        assert config["response_mime_type"] == "application/json"
        assert config["response_schema"]["required"] == ["story"]
    else:
        assert config.system_instruction == "my-system"
        assert config.temperature == 0.3
        assert config.response_mime_type == "application/json"
        assert config.response_schema["required"] == ["story"]
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_gemini_client.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/gemini_client.py`**

```python
"""Gemini API wrapper using google-genai SDK with structured JSON output."""
from __future__ import annotations

import json
from dataclasses import dataclass

from google import genai
from google.genai import types

GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_TEMPERATURE = 0.3


@dataclass(frozen=True)
class GeneratedStory:
    place_name: str
    place_location: str
    era: str
    story: str


def generate_story(
    *,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: dict,
) -> GeneratedStory:
    """Call Gemini and parse the JSON response into a GeneratedStory."""
    client = genai.Client(api_key=api_key)

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=GEMINI_TEMPERATURE,
        response_mime_type="application/json",
        response_schema=response_schema,
    )

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[user_prompt],
        config=config,
    )

    data = json.loads(response.text)
    return GeneratedStory(
        place_name=data["place_name"],
        place_location=data["place_location"],
        era=data["era"],
        story=data["story"],
    )
```

If the import path or API differs from current SDK, adjust accordingly but keep `generate_story(...)` signature stable.

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_gemini_client.py -v
```
Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/gemini_client.py backend/tests/test_gemini_client.py
git commit -m "feat(backend): add Gemini client wrapper with structured JSON output"
```

---

## Task 9: Job orchestrator + retry

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/job.py`
- Create: `backend/tests/test_job.py`

- [ ] **Step 1: Write failing tests**

```python
# backend/tests/test_job.py
from datetime import date
from unittest.mock import MagicMock, call, patch

import pytest

from lorescape_backend.daily_story.job import LANGUAGES, run_once, run_with_retry
from lorescape_backend.daily_story.gemini_client import GeneratedStory
from lorescape_backend.daily_story.place_picker import PickedPlace
from lorescape_backend.daily_story.wikipedia import WikipediaSummary


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_happy_path_calls_each_step(
    mark_used,
    insert_story,
    generate_story,
    fetch_langlink,
    fetch_summary,
    pick_next,
    create_client,
    fake_config,
):
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum",
        extract="Built 70-80 CE.",
        image_url="https://upload.wikimedia.org/x.jpg",
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    fetch_langlink.side_effect = lambda title, lang: (
        f"https://{lang}.wikipedia.org/wiki/{title}"
    )
    generate_story.side_effect = [
        GeneratedStory("羅馬競技場", "義大利羅馬", "公元 70-80 年", "中文故事"),
        GeneratedStory("Colosseum", "Rome, Italy", "70-80 CE", "english story"),
    ]

    run_once(fake_config, date(2026, 5, 11))

    pick_next.assert_called_once()
    fetch_summary.assert_called_once_with("Colosseum")
    # Two languages: should fetch langlinks and Gemini twice each
    assert fetch_langlink.call_count == 2
    assert generate_story.call_count == 2
    assert insert_story.call_count == 2
    # Place gets marked used exactly once
    mark_used.assert_called_once()
    args, _ = mark_used.call_args
    assert args[1] == "p1"


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
def test_run_once_raises_when_no_place(pick_next, create_client, fake_config):
    pick_next.return_value = None
    with pytest.raises(RuntimeError, match="No active places"):
        run_once(fake_config, date(2026, 5, 11))


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_falls_back_to_en_url_when_no_langlink(
    mark_used,
    insert_story,
    generate_story,
    fetch_langlink,
    fetch_summary,
    pick_next,
    create_client,
    fake_config,
):
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum",
        extract="Built 70-80 CE.",
        image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    # Simulate: zh has no langlink, en is just the same article
    fetch_langlink.return_value = None
    generate_story.return_value = GeneratedStory("X", "Y", "Z", "S")

    run_once(fake_config, date(2026, 5, 11))

    # Each insert_story call should have wikipedia_url == en_url (fallback)
    for c in insert_story.call_args_list:
        row = c.args[1]
        assert row.wikipedia_url == "https://en.wikipedia.org/wiki/Colosseum"


@patch("lorescape_backend.daily_story.job.time.sleep")  # speed up retry
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_succeeds_first_attempt(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.return_value = None
    run_with_retry(fake_config, date(2026, 5, 11))
    assert run_once_mock.call_count == 1
    notify.assert_not_called()


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_retries_on_failure_then_succeeds(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.side_effect = [RuntimeError("fail1"), None]
    run_with_retry(fake_config, date(2026, 5, 11))
    assert run_once_mock.call_count == 2
    notify.assert_not_called()


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_notifies_discord_after_all_retries_fail(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.side_effect = RuntimeError("boom")
    with pytest.raises(RuntimeError, match="boom"):
        run_with_retry(fake_config, date(2026, 5, 11))

    # Default: 4 attempts (1 + 3 retries)
    assert run_once_mock.call_count == 4
    notify.assert_called_once()
    kwargs = notify.call_args.kwargs
    assert kwargs["webhook_url"] == fake_config.discord_webhook_url
    assert kwargs["date_str"] == "2026-05-11"
    assert "boom" in kwargs["error_message"]


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_skips_discord_when_no_webhook_configured(
    notify, run_once_mock, sleep
):
    from lorescape_backend.config import Config

    config_no_webhook = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url=None,
    )
    run_once_mock.side_effect = RuntimeError("boom")
    with pytest.raises(RuntimeError):
        run_with_retry(config_no_webhook, date(2026, 5, 11))
    notify.assert_not_called()


def test_languages_list_matches_spec():
    assert LANGUAGES == ["zh-TW", "en"]
```

- [ ] **Step 2: Run tests — verify failures**

```bash
pytest tests/test_job.py -v
```

- [ ] **Step 3: Implement `backend/src/lorescape_backend/daily_story/job.py`**

```python
"""Daily story job: pick → fetch → generate → write, with retry + Discord."""
from __future__ import annotations

import logging
import time
import traceback
from datetime import date

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import (
    discord_notify,
    gemini_client,
    place_picker,
    prompts,
    story_writer,
    wikipedia,
)

logger = logging.getLogger(__name__)

LANGUAGES = ["zh-TW", "en"]
RETRY_DELAYS = [1, 5, 30]  # delays before retries 1, 2, 3 → 4 total attempts


def run_once(config: Config, target_date: date) -> None:
    """Run the daily story job once. Raises on any failure."""
    supabase = create_client(config.supabase_url, config.supabase_service_role_key)

    place = place_picker.pick_next_place(supabase)
    if not place:
        raise RuntimeError("No active places available in daily_story_places")

    summary = wikipedia.fetch_summary(place.wikipedia_title_en)

    for language in LANGUAGES:
        target_lang = language.split("-")[0]  # 'zh-TW' → 'zh', 'en' → 'en'
        wiki_url = (
            wikipedia.fetch_langlink_url(place.wikipedia_title_en, target_lang)
            or summary.en_url
        )

        story = gemini_client.generate_story(
            api_key=config.gemini_api_key,
            system_instruction=prompts.SYSTEM_INSTRUCTION,
            user_prompt=prompts.build_user_prompt(
                wikipedia_title=place.wikipedia_title_en,
                wikipedia_extract=summary.extract,
                language=language,
            ),
            response_schema=prompts.GEMINI_RESPONSE_SCHEMA,
        )

        story_writer.insert_story(
            supabase,
            story_writer.StoryRow(
                publish_date=target_date,
                language=language,
                place_id=place.id,
                place_name=story.place_name,
                place_location=story.place_location,
                era=story.era,
                story=story.story,
                image_url=summary.image_url,
                wikipedia_url=wiki_url,
            ),
        )

    place_picker.mark_place_used(supabase, place.id)


def run_with_retry(config: Config, target_date: date) -> None:
    """Run the job with retry-with-backoff. Notify Discord on final failure."""
    last_exc: Exception | None = None
    total_attempts = len(RETRY_DELAYS) + 1

    for attempt in range(total_attempts):
        try:
            run_once(config, target_date)
            logger.info(
                "daily_story_job succeeded for %s on attempt %d",
                target_date.isoformat(), attempt + 1,
            )
            return
        except Exception as exc:  # noqa: BLE001 — orchestrator catches all
            last_exc = exc
            logger.warning("Attempt %d failed: %s", attempt + 1, exc)
            if attempt < total_attempts - 1:
                time.sleep(RETRY_DELAYS[attempt])

    # All attempts failed
    assert last_exc is not None
    logger.error("All %d attempts failed", total_attempts, exc_info=last_exc)
    if config.discord_webhook_url:
        discord_notify.notify_failure(
            webhook_url=config.discord_webhook_url,
            date_str=target_date.isoformat(),
            error_message=str(last_exc),
            traceback_str="".join(
                traceback.format_exception(type(last_exc), last_exc, last_exc.__traceback__)
            ),
        )
    raise last_exc
```

- [ ] **Step 4: Run tests — verify pass**

```bash
pytest tests/test_job.py -v
```
Expected: 7 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/job.py backend/tests/test_job.py
git commit -m "feat(backend): add job orchestrator with retry and Discord notify"
```

---

## Task 10: CLI entrypoint

**Files:**
- Create: `backend/src/lorescape_backend/daily_story/__main__.py`

- [ ] **Step 1: Write the entrypoint**

```python
"""CLI entrypoint: `python -m lorescape_backend.daily_story [YYYY-MM-DD]`.

If a date argument is given, run for that date.
Otherwise default to tomorrow (cron runs at 23:30 to publish for next day).
"""
from __future__ import annotations

import logging
import sys
from datetime import date, timedelta

from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import run_with_retry


def main(argv: list[str]) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    config = Config.from_env()

    if argv:
        target = date.fromisoformat(argv[0])
    else:
        target = date.today() + timedelta(days=1)

    run_with_retry(config, target)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 2: Quick smoke check (without external services)**

```bash
cd backend && source .venv/bin/activate
# Should error because env vars are not set
python -m lorescape_backend.daily_story 2>&1 | head -3
```
Expected: a `RuntimeError: Missing required env var: SUPABASE_URL` line. (Confirms entrypoint runs and Config validation works.)

- [ ] **Step 3: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/__main__.py
git commit -m "feat(backend): add CLI entrypoint for daily_story job"
```

---

## Task 11: FastAPI minimal scaffold + Dockerfile + compose

**Files:**
- Create: `backend/src/lorescape_backend/api.py`
- Create: `backend/Dockerfile`
- Create: `backend/docker-compose.yml`

- [ ] **Step 1: Write `backend/src/lorescape_backend/api.py`**

```python
"""Minimal FastAPI app — placeholder for future endpoints.

For now, exposes only `/health` so the deployment can be monitored.
"""
from __future__ import annotations

from fastapi import FastAPI

app = FastAPI(title="Lorescape Backend", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 2: Quick smoke check**

```bash
cd backend && source .venv/bin/activate
uvicorn lorescape_backend.api:app --port 8765 &
sleep 2
curl -s http://localhost:8765/health
kill %1
```
Expected: `{"status":"ok"}`.

- [ ] **Step 3: Write `backend/Dockerfile`**

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

EXPOSE 8000

# Default command runs the FastAPI app.
# The cron job is invoked separately (see docker-compose / system cron).
CMD ["uvicorn", "lorescape_backend.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 4: Write `backend/docker-compose.yml`**

```yaml
services:
  api:
    build: .
    image: lorescape-backend:latest
    container_name: lorescape-backend
    restart: unless-stopped
    ports:
      - "8000:8000"
    env_file: .env
    # Healthcheck via the /health endpoint
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval: 30s
      timeout: 5s
      retries: 3
```

- [ ] **Step 5: Smoke-build the Docker image**

```bash
cd backend
docker build -t lorescape-backend:smoke-test .
```
Expected: builds successfully without errors. The build will install all dependencies (this can take 60-120 seconds).

If Docker is not installed/running, STOP and report DONE_WITH_CONCERNS — note that Dockerfile is written but unverified.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/api.py backend/Dockerfile backend/docker-compose.yml
git commit -m "feat(backend): add minimal FastAPI scaffold + Dockerfile + compose"
```

---

## Task 12: Deployment guide + crontab

**Files:**
- Create: `backend/deploy/crontab.example`
- Modify: `backend/README.md` (append deployment section)

- [ ] **Step 1: Write `backend/deploy/crontab.example`**

```cron
# Lorescape daily_story_job — run every day at 23:30 Asia/Taipei.
# The job generates stories for "tomorrow" so they are visible at 00:00.
#
# Install with:
#   crontab -e
# then paste the lines below.

TZ=Asia/Taipei

# Plain Python (system cron + venv)
30 23 * * * cd /opt/lorescape-backend && /opt/lorescape-backend/.venv/bin/python -m lorescape_backend.daily_story >> /var/log/lorescape/daily_story.log 2>&1

# Or, via Docker:
# 30 23 * * * docker exec lorescape-backend python -m lorescape_backend.daily_story >> /var/log/lorescape/daily_story.log 2>&1
```

- [ ] **Step 2: Append deployment section to `backend/README.md`**

Add the following at the end of the existing README (preserve everything above):

```markdown

---

## Deploying to a VPS

Two supported topologies. Pick whichever fits your VPS layout.

### Option A — system Python + cron (lowest ceremony)

```bash
# On the VPS (assumes a Debian/Ubuntu-style host with python3.11)
sudo mkdir -p /opt/lorescape-backend
sudo chown $USER:$USER /opt/lorescape-backend
git clone https://github.com/easylive1989/instant_explore /tmp/instant_explore
cp -r /tmp/instant_explore/backend/* /opt/lorescape-backend/
cd /opt/lorescape-backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Configure secrets
cp .env.example .env
$EDITOR .env  # fill in real values

# Smoke test (will fail on Wikipedia/Gemini/Supabase if env vars are wrong)
python -m lorescape_backend.daily_story 2030-01-01

# Install the cron schedule
sudo mkdir -p /var/log/lorescape
sudo chown $USER:$USER /var/log/lorescape
crontab -l 2>/dev/null > /tmp/cron.bak || true
cat /opt/lorescape-backend/deploy/crontab.example >> /tmp/cron.bak
crontab /tmp/cron.bak
crontab -l  # verify
```

### Option B — Docker Compose

```bash
# On the VPS
git clone https://github.com/easylive1989/instant_explore /opt/instant_explore
cd /opt/instant_explore/backend
cp .env.example .env
$EDITOR .env  # fill in real values

docker compose up -d --build
docker compose ps
curl http://localhost:8000/health
# Expected: {"status":"ok"}

# Install cron to call the container
crontab -e
# Add the Docker line from deploy/crontab.example
```

### After deployment — manual smoke test

Force a one-off run for tomorrow's date and check Supabase:

```bash
# Option A
cd /opt/lorescape-backend && source .venv/bin/activate
python -m lorescape_backend.daily_story $(date -v+1d +%Y-%m-%d)  # macOS
# or: python -m lorescape_backend.daily_story $(date -d tomorrow +%Y-%m-%d)  # Linux

# Option B
docker exec lorescape-backend python -m lorescape_backend.daily_story $(date -d tomorrow +%Y-%m-%d)
```

Then in Supabase Dashboard SQL Editor:

```sql
SELECT publish_date, language, place_name, era, length(story) AS story_len
FROM public.daily_stories
ORDER BY publish_date DESC, language
LIMIT 4;
```

Expected: two rows (`zh-TW` + `en`) for tomorrow's date with `story_len` ≈ 300-500.

### Discord webhook (optional but recommended)

If `DISCORD_WEBHOOK_URL` is set in `.env`, all-retries-failed will post a message to the channel. To test the wiring without breaking anything:

```bash
# Run with an intentionally wrong Supabase URL to force failure
SUPABASE_URL=https://invalid.local python -m lorescape_backend.daily_story 2099-01-01
```

You should see the Discord message appear after ~36 seconds (1+5+30 backoff).
```

- [ ] **Step 3: Commit**

```bash
git add backend/deploy/crontab.example backend/README.md
git commit -m "docs(backend): add VPS deployment guide and crontab example"
```

---

## Self-Review Checklist

After implementing the whole P2 plan:

- [ ] **Spec coverage**:
  - Cron 23:30 Asia/Taipei, publish_date = tomorrow ✓ (Task 9 + 10 + 12)
  - Both languages generated ✓ (Task 9 LANGUAGES = ["zh-TW", "en"])
  - Wikipedia ground truth ✓ (Task 3 fetch_summary)
  - Gemini structured JSON ✓ (Task 4 + 8)
  - Supabase upsert (idempotent) ✓ (Task 6)
  - Place picking + mark used ✓ (Task 5)
  - Retry 3 → Discord ✓ (Task 9)
  - service_role key ✓ (Task 2 + 9)
- [ ] **Tests pass**: `cd backend && pytest -v` shows everything green.
- [ ] **No placeholders**: all code in plan is concrete; no TODO/TBD left.
- [ ] **Manual smoke**: at least one real run against staging/prod confirms the pipeline works end-to-end.

## After P2

- Verify a real generated story in `daily_stories` looks right (length, accuracy, language).
- Hand off to **P3 (Flutter UI)** — the app can now read real data from Supabase.
