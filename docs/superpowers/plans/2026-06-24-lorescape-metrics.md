# Lorescape Metrics Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `lorescape-metrics` skill that manually fetches Lorescape product metrics (GSC search, GA4 web+app, IG) via official APIs and captures App Store / Play numbers via a browser flow, writing accumulating report files under `docs/metrics/<date>/`.

**Architecture:** A Python package `backend/scripts/metrics/` with a transport/transform split — each source has a pure `parse_*` function (unit-tested against fixture dicts) and a `fetch_*` function that calls the live API and returns a uniform `SourceResult`. An orchestrator `report.py` gathers all enabled sources, isolates failures as `skipped`, and writes `summary.md` + per-source CSVs. App Store / Play is handled by the skill driving Chrome (MCP), appending a section to `summary.md`. A single `SKILL.md` documents triggering, sub-commands, and per-source prerequisites.

**Tech Stack:** Python 3.11, `uv`, `requests` (IG), `google-api-python-client` + `google-auth` (GSC + GA4 Admin), `google-analytics-data` (GA4 Data API), `python-dotenv`, `pytest` + `pytest-mock`. Chrome via the `claude-in-chrome` MCP for the stores fallback.

## Global Constraints

- All Python runs from `backend/` via `uv run python -m scripts.metrics.<module>`.
- Tests live in `backend/tests/` and import production code as `from scripts.metrics import ...`; run with `uv run pytest`.
- Line length ≤ 100 chars; `from __future__ import annotations` at top of every module (matches existing scripts).
- Secrets/IDs come from `backend/.env` via `python-dotenv`; never hardcode. New env names: `GA4_PROPERTY_ID_WEB`, `GA4_PROPERTY_ID_APP`, `GSC_SITE_URL` (IG reuses existing `IG_USER_ID` / `META_PAGE_ACCESS_TOKEN`).
- Google API client libraries are imported **lazily inside fetch functions**, so modules import cleanly (and parsers stay testable) even before deps are installed.
- A failing source must never abort the run: catch its exception and return `SourceResult(ok=False, skipped_reason=...)`.
- Reports write to `docs/metrics/<end-date>/` (committed to git for trend history).
- Default date range: last 7 days ending yesterday (GA4/GSC data lags ~1 day).

---

### Task 1: Package scaffold + `_common.py` primitives

**Files:**
- Create: `backend/scripts/metrics/__init__.py`
- Create: `backend/scripts/metrics/_common.py`
- Test: `backend/tests/metrics/__init__.py`, `backend/tests/metrics/test_common.py`

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - `@dataclass(frozen=True) MetricsConfig` with fields: `ga4_property_id_web: str | None`, `ga4_property_id_app: str | None`, `gsc_site_url: str | None`, `ig_user_id: str | None`, `meta_page_access_token: str | None`; classmethod `from_env() -> MetricsConfig`.
  - `@dataclass SourceResult` with fields: `name: str`, `ok: bool`, `skipped_reason: str | None = None`, `summary_lines: list[str] = []`, `csv_headers: list[str] = []`, `csv_rows: list[list[str]] = []`. Helper `SourceResult.skipped(name, reason) -> SourceResult`.
  - `date_range(days: int = 7, start: str | None = None, end: str | None = None) -> tuple[str, str]` returning ISO `YYYY-MM-DD` strings. If `start`/`end` given, use them; else end = today − 1 day, start = end − (days − 1).
  - `report_dir(end_date: str, root: Path) -> Path` returns `root / "docs" / "metrics" / end_date` (does **not** create it).
  - `rows_to_md_table(headers: list[str], rows: list[list[str]]) -> str` — GitHub markdown table; returns `"_(no rows)_"` when `rows` is empty.
  - `write_csv(path: Path, headers: list[str], rows: list[list[str]]) -> None` — creates parent dirs, writes UTF-8 CSV.
  - `today_iso(clock: date | None = None) -> str` — wraps `date.today()` but accepts an injected `date` for tests.

- [ ] **Step 1: Write the failing tests**

```python
# backend/tests/metrics/test_common.py
from __future__ import annotations

from datetime import date
from pathlib import Path

from scripts.metrics import _common as c


def test_date_range_defaults_to_last_7_days_ending_yesterday():
    start, end = c.date_range(days=7, clock=date(2026, 6, 24))
    assert end == "2026-06-23"
    assert start == "2026-06-17"


def test_date_range_explicit_start_end_overrides_days():
    start, end = c.date_range(days=7, start="2026-01-01", end="2026-01-31")
    assert (start, end) == ("2026-01-01", "2026-01-31")


def test_report_dir_builds_dated_path_without_creating():
    root = Path("/repo")
    out = c.report_dir("2026-06-23", root=root)
    assert out == Path("/repo/docs/metrics/2026-06-23")
    assert not out.exists()


def test_rows_to_md_table_renders_pipes():
    md = c.rows_to_md_table(["q", "clicks"], [["taipei", "12"]])
    assert "| q | clicks |" in md
    assert "| taipei | 12 |" in md


def test_rows_to_md_table_empty_rows():
    assert c.rows_to_md_table(["q"], []) == "_(no rows)_"


def test_write_csv_roundtrip(tmp_path):
    p = tmp_path / "sub" / "out.csv"
    c.write_csv(p, ["a", "b"], [["1", "2"], ["3", "4"]])
    text = p.read_text(encoding="utf-8")
    assert "a,b" in text
    assert "3,4" in text


def test_source_result_skipped_factory():
    r = c.SourceResult.skipped("gsc", "no creds")
    assert r.ok is False
    assert r.skipped_reason == "no creds"
    assert r.csv_rows == []
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/metrics/test_common.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.metrics'`.

- [ ] **Step 3: Write `_common.py` and the package `__init__` files**

```python
# backend/scripts/metrics/__init__.py
"""Lorescape product-metrics fetchers (GSC, GA4, IG) and report orchestrator."""
```

```python
# backend/tests/metrics/__init__.py
```

```python
# backend/scripts/metrics/_common.py
"""Shared primitives for metrics fetchers: config, date ranges, IO helpers."""
from __future__ import annotations

import csv
import os
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]


def today_iso(clock: date | None = None) -> str:
    """Return today's date as ISO, allowing an injected clock for tests."""
    return (clock or date.today()).isoformat()


def date_range(
    days: int = 7,
    start: str | None = None,
    end: str | None = None,
    clock: date | None = None,
) -> tuple[str, str]:
    """Return (start, end) ISO dates. Explicit start/end win; else last
    `days` days ending yesterday."""
    if start and end:
        return start, end
    end_d = (clock or date.today()) - timedelta(days=1)
    start_d = end_d - timedelta(days=days - 1)
    return start_d.isoformat(), end_d.isoformat()


def report_dir(end_date: str, root: Path = REPO_ROOT) -> Path:
    """Return docs/metrics/<end_date> under `root` (not created)."""
    return root / "docs" / "metrics" / end_date


def rows_to_md_table(headers: list[str], rows: list[list[str]]) -> str:
    """Render a GitHub markdown table; placeholder when empty."""
    if not rows:
        return "_(no rows)_"
    head = "| " + " | ".join(headers) + " |"
    sep = "| " + " | ".join("---" for _ in headers) + " |"
    body = "\n".join("| " + " | ".join(r) + " |" for r in rows)
    return f"{head}\n{sep}\n{body}"


def write_csv(path: Path, headers: list[str], rows: list[list[str]]) -> None:
    """Write a UTF-8 CSV, creating parent directories."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(headers)
        writer.writerows(rows)


@dataclass(frozen=True)
class MetricsConfig:
    """Metrics-specific configuration read from environment."""

    ga4_property_id_web: str | None = None
    ga4_property_id_app: str | None = None
    gsc_site_url: str | None = None
    ig_user_id: str | None = None
    meta_page_access_token: str | None = None

    @classmethod
    def from_env(cls) -> "MetricsConfig":
        get = os.environ.get
        return cls(
            ga4_property_id_web=get("GA4_PROPERTY_ID_WEB") or None,
            ga4_property_id_app=get("GA4_PROPERTY_ID_APP") or None,
            gsc_site_url=get("GSC_SITE_URL") or None,
            ig_user_id=get("IG_USER_ID") or None,
            meta_page_access_token=get("META_PAGE_ACCESS_TOKEN") or None,
        )


@dataclass
class SourceResult:
    """Uniform result from one metrics source."""

    name: str
    ok: bool
    skipped_reason: str | None = None
    summary_lines: list[str] = field(default_factory=list)
    csv_headers: list[str] = field(default_factory=list)
    csv_rows: list[list[str]] = field(default_factory=list)

    @classmethod
    def skipped(cls, name: str, reason: str) -> "SourceResult":
        return cls(name=name, ok=False, skipped_reason=reason)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/metrics/test_common.py -v`
Expected: PASS (7 passed).

- [ ] **Step 5: Commit**

```bash
git add backend/scripts/metrics/__init__.py backend/scripts/metrics/_common.py \
        backend/tests/metrics/__init__.py backend/tests/metrics/test_common.py
git commit -m "feat(metrics): scaffold metrics package with _common primitives"
```

---

### Task 2: `report.py` orchestrator skeleton (`--check`, assembly, file writing)

**Files:**
- Create: `backend/scripts/metrics/report.py`
- Test: `backend/tests/metrics/test_report.py`

**Interfaces:**
- Consumes: `MetricsConfig`, `SourceResult`, `date_range`, `report_dir`, `rows_to_md_table`, `write_csv` from Task 1.
- Produces:
  - `Source = Callable[[MetricsConfig, str, str], SourceResult]` — a fetcher signature `(cfg, start, end) -> SourceResult`.
  - `SOURCES: dict[str, Source]` — registry, empty for now; later tasks append `"gsc"`, `"ga4"`, `"ig"`.
  - `build_summary(results: list[SourceResult], start: str, end: str) -> str` — markdown report body.
  - `check_lines(cfg: MetricsConfig, names: list[str]) -> list[str]` — one line per source describing config readiness (no network).
  - `run(cfg, names, start, end, root) -> Path` — runs each named source, writes `summary.md` + `<name>.csv`, returns the report dir.
  - `main(argv: list[str] | None = None) -> int` — argparse CLI: `--days`, `--start`, `--end`, `--only a,b`, `--check`.

- [ ] **Step 1: Write the failing tests**

```python
# backend/tests/metrics/test_report.py
from __future__ import annotations

from scripts.metrics import report
from scripts.metrics._common import MetricsConfig, SourceResult


def _ok_source(name):
    return lambda cfg, s, e: SourceResult(
        name=name, ok=True, summary_lines=[f"{name}: 10 clicks"],
        csv_headers=["k", "v"], csv_rows=[["a", "1"]],
    )


def test_build_summary_lists_ok_and_skipped():
    results = [
        SourceResult(name="gsc", ok=True, summary_lines=["clicks: 42"]),
        SourceResult.skipped("ig", "missing token"),
    ]
    md = report.build_summary(results, "2026-06-17", "2026-06-23")
    assert "2026-06-17" in md and "2026-06-23" in md
    assert "clicks: 42" in md
    assert "skipped" in md.lower() and "missing token" in md


def test_check_lines_reports_missing_config():
    cfg = MetricsConfig(gsc_site_url=None, ig_user_id="x",
                        meta_page_access_token="y")
    lines = report.check_lines(cfg, ["gsc", "ig"])
    joined = "\n".join(lines)
    assert "gsc" in joined and "ig" in joined
    assert "missing" in joined.lower()  # gsc has no site url


def test_run_writes_summary_and_csv(tmp_path, monkeypatch):
    monkeypatch.setitem(report.SOURCES, "demo", _ok_source("demo"))
    out = report.run(MetricsConfig(), ["demo"], "2026-06-17",
                     "2026-06-23", root=tmp_path)
    assert (out / "summary.md").exists()
    assert (out / "demo.csv").read_text(encoding="utf-8").count("a,1") == 1
    report.SOURCES.pop("demo", None)


def test_main_check_does_not_write(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(report, "_repo_root", lambda: tmp_path)
    rc = report.main(["--check", "--only", "gsc"])
    assert rc == 0
    assert not (tmp_path / "docs" / "metrics").exists()
    assert "gsc" in capsys.readouterr().out
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/metrics/test_report.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.metrics.report'`.

- [ ] **Step 3: Write `report.py`**

```python
# backend/scripts/metrics/report.py
"""Orchestrate metrics sources into a dated report under docs/metrics/."""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Callable

from dotenv import load_dotenv

from scripts.metrics._common import (
    REPO_ROOT,
    MetricsConfig,
    SourceResult,
    date_range,
    report_dir,
    rows_to_md_table,
    write_csv,
)

Source = Callable[[MetricsConfig, str, str], SourceResult]

# Later tasks register "gsc", "ga4", "ig" here.
SOURCES: dict[str, Source] = {}

# Minimum config each source needs to even attempt a fetch.
_REQUIRED: dict[str, tuple[str, ...]] = {
    "gsc": ("gsc_site_url",),
    "ga4": ("ga4_property_id_web",),
    "ig": ("ig_user_id", "meta_page_access_token"),
}


def _repo_root() -> Path:
    return REPO_ROOT


def check_lines(cfg: MetricsConfig, names: list[str]) -> list[str]:
    """One readiness line per source; pure, no network."""
    lines: list[str] = []
    for name in names:
        required = _REQUIRED.get(name, ())
        missing = [f for f in required if not getattr(cfg, f)]
        if missing:
            lines.append(f"- {name}: missing config → {', '.join(missing)}")
        else:
            lines.append(f"- {name}: ready")
    return lines


def build_summary(results: list[SourceResult], start: str, end: str) -> str:
    """Render the cross-source markdown summary."""
    out = [f"# Lorescape 數據報告 {start} → {end}", ""]
    for r in results:
        out.append(f"## {r.name}")
        if not r.ok:
            out.append(f"- skipped: {r.skipped_reason}")
            out.append("")
            continue
        out.extend(f"- {line}" for line in r.summary_lines)
        if r.csv_rows:
            out.append("")
            out.append(rows_to_md_table(r.csv_headers, r.csv_rows[:10]))
        out.append("")
    return "\n".join(out)


def run(
    cfg: MetricsConfig,
    names: list[str],
    start: str,
    end: str,
    root: Path,
) -> Path:
    """Fetch each named source, write summary.md + per-source CSVs."""
    results: list[SourceResult] = []
    for name in names:
        fetch = SOURCES.get(name)
        if fetch is None:
            results.append(SourceResult.skipped(name, "not implemented"))
            continue
        try:
            results.append(fetch(cfg, start, end))
        except Exception as exc:  # isolate per-source failures
            results.append(SourceResult.skipped(name, f"error: {exc}"))

    out_dir = report_dir(end, root=root)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.md").write_text(
        build_summary(results, start, end), encoding="utf-8"
    )
    for r in results:
        if r.ok and r.csv_rows:
            write_csv(out_dir / f"{r.name}.csv", r.csv_headers, r.csv_rows)
    return out_dir


def main(argv: list[str] | None = None) -> int:
    load_dotenv(_repo_root() / "backend" / ".env")
    parser = argparse.ArgumentParser(description="Fetch Lorescape metrics.")
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--start")
    parser.add_argument("--end")
    parser.add_argument("--only", help="comma-separated subset of sources")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)

    cfg = MetricsConfig.from_env()
    all_names = list(SOURCES.keys()) or ["gsc", "ga4", "ig"]
    names = args.only.split(",") if args.only else all_names
    start, end = date_range(days=args.days, start=args.start, end=args.end)

    if args.check:
        print(f"range: {start} → {end}")
        print("\n".join(check_lines(cfg, names)))
        return 0

    out_dir = run(cfg, names, start, end, root=_repo_root())
    print(f"report written: {out_dir / 'summary.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/metrics/test_report.py -v`
Expected: PASS (4 passed).

- [ ] **Step 5: Verify the CLI skeleton runs**

Run: `cd backend && uv run python -m scripts.metrics.report --check --only gsc,ga4,ig`
Expected: prints `range: ... → ...` then a readiness line per source (all "missing config" until `.env` is populated). No files written.

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/metrics/report.py backend/tests/metrics/test_report.py
git commit -m "feat(metrics): add report orchestrator with --check and file writing"
```

---

### Task 3: GSC source (Search Console API) + Google deps

**Files:**
- Create: `backend/scripts/metrics/gsc.py`
- Create: `.claude/skills/lorescape-metrics/references/google-setup.md`
- Modify: `backend/pyproject.toml` (add Google deps)
- Modify: `backend/scripts/metrics/report.py` (register `"gsc"`)
- Test: `backend/tests/metrics/test_gsc.py`

**Interfaces:**
- Consumes: `MetricsConfig`, `SourceResult` from Task 1; `SOURCES` registry from Task 2.
- Produces:
  - `parse_search_analytics(resp: dict) -> list[list[str]]` — turns a Search Console `searchanalytics.query` response into rows `[key, clicks, impressions, ctr%, position]` (testable, no network).
  - `summarize(rows: list[list[str]]) -> list[str]` — totals line(s).
  - `fetch_gsc(cfg, start, end) -> SourceResult` — calls the API; returns `SourceResult.skipped("gsc", ...)` when `cfg.gsc_site_url` is missing or the call fails.

- [ ] **Step 1: Add Google dependencies**

Run:
```bash
cd backend && uv add "google-api-python-client>=2,<3" "google-auth>=2,<3" \
  "google-analytics-data>=0.18,<1"
```
Expected: `pyproject.toml` gains the three deps; `uv.lock` updates.

- [ ] **Step 2: Write the failing tests**

```python
# backend/tests/metrics/test_gsc.py
from __future__ import annotations

from scripts.metrics import gsc
from scripts.metrics._common import MetricsConfig


SAMPLE = {
    "rows": [
        {"keys": ["taipei 101"], "clicks": 12, "impressions": 300,
         "ctr": 0.04, "position": 5.2},
        {"keys": ["lorescape"], "clicks": 8, "impressions": 50,
         "ctr": 0.16, "position": 1.1},
    ]
}


def test_parse_search_analytics_maps_rows():
    rows = gsc.parse_search_analytics(SAMPLE)
    assert rows[0] == ["taipei 101", "12", "300", "4.00%", "5.2"]
    assert rows[1][0] == "lorescape"


def test_parse_search_analytics_empty():
    assert gsc.parse_search_analytics({}) == []


def test_summarize_totals_clicks_and_impressions():
    rows = gsc.parse_search_analytics(SAMPLE)
    lines = gsc.summarize(rows)
    assert any("20" in ln for ln in lines)  # 12 + 8 clicks


def test_fetch_gsc_skips_without_site_url():
    r = gsc.fetch_gsc(MetricsConfig(gsc_site_url=None), "2026-06-17",
                      "2026-06-23")
    assert r.ok is False
    assert "GSC_SITE_URL" in (r.skipped_reason or "")
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/metrics/test_gsc.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.metrics.gsc'`.

- [ ] **Step 4: Write `gsc.py`**

```python
# backend/scripts/metrics/gsc.py
"""Google Search Console search-analytics source."""
from __future__ import annotations

from scripts.metrics._common import MetricsConfig, SourceResult

_HEADERS = ["query", "clicks", "impressions", "ctr", "position"]


def parse_search_analytics(resp: dict) -> list[list[str]]:
    """Map a searchanalytics.query response into string rows."""
    rows: list[list[str]] = []
    for row in resp.get("rows", []):
        keys = row.get("keys", [""])
        rows.append([
            keys[0],
            str(int(row.get("clicks", 0))),
            str(int(row.get("impressions", 0))),
            f"{row.get('ctr', 0.0) * 100:.2f}%",
            f"{row.get('position', 0.0):.1f}",
        ])
    return rows


def summarize(rows: list[list[str]]) -> list[str]:
    """Total clicks and impressions across rows."""
    clicks = sum(int(r[1]) for r in rows)
    impressions = sum(int(r[2]) for r in rows)
    return [
        f"總點擊 {clicks}、總曝光 {impressions}（top {len(rows)} queries）",
    ]


def _service():
    """Build the Search Console API client using ADC (lazy import)."""
    import google.auth
    from googleapiclient.discovery import build

    creds, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/webmasters.readonly"]
    )
    return build("searchconsole", "v1", credentials=creds,
                 cache_discovery=False)


def fetch_gsc(cfg: MetricsConfig, start: str, end: str) -> SourceResult:
    """Fetch top queries for the configured site over [start, end]."""
    if not cfg.gsc_site_url:
        return SourceResult.skipped("gsc", "missing GSC_SITE_URL in .env")
    try:
        service = _service()
        resp = service.searchanalytics().query(
            siteUrl=cfg.gsc_site_url,
            body={
                "startDate": start,
                "endDate": end,
                "dimensions": ["query"],
                "rowLimit": 25,
            },
        ).execute()
    except Exception as exc:
        return SourceResult.skipped("gsc", f"API error: {exc}")

    rows = parse_search_analytics(resp)
    return SourceResult(
        name="gsc", ok=True, summary_lines=summarize(rows),
        csv_headers=_HEADERS, csv_rows=rows,
    )
```

- [ ] **Step 5: Register the source in `report.py`**

Add to `backend/scripts/metrics/report.py` after the `SOURCES` declaration:

```python
from scripts.metrics.gsc import fetch_gsc

SOURCES["gsc"] = fetch_gsc
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/metrics/test_gsc.py tests/metrics/test_report.py -v`
Expected: PASS (all green; the `not implemented` path for gsc no longer triggers).

- [ ] **Step 7: Write the Google setup reference doc**

```markdown
<!-- .claude/skills/lorescape-metrics/references/google-setup.md -->
# Google API 一次性設定（GSC + GA4）

GSC 與 GA4 都用 Application Default Credentials (ADC)，由使用者本機一次性登入。

## 1. 登入並授權 scope

在 Claude Code 對話框輸入（`!` 會在本機 session 執行）：

    ! gcloud auth application-default login --scopes=openid,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/webmasters.readonly

登入帳號須對下列資源有讀取權限：
- Search Console 中的目標網站（property）
- 目標 GA4 property

## 2. 填入 backend/.env

    GSC_SITE_URL=https://lorescape.app/        # 或 sc-domain:lorescape.app
    GA4_PROPERTY_ID_WEB=<numeric property id>   # landing (G-TCYSEZX8T6 對應的 property)
    GA4_PROPERTY_ID_APP=<numeric property id>   # Firebase app (instant-explore-7b442)

## 3. 找出 GA4 numeric property ID

- GA4 後台 → 管理 → 資源設定 → 「資源 ID」（純數字）。
- 或讓 skill 用 GA4 Admin API 自動列出（見 ga4.py 的 `--list-properties`）。
- `GSC_SITE_URL` 必須與 Search Console 顯示的 property 完全一致（含 `https://`、
  結尾斜線，或 `sc-domain:` 前綴）。
```

- [ ] **Step 8: Commit**

```bash
git add backend/pyproject.toml backend/uv.lock backend/scripts/metrics/gsc.py \
        backend/scripts/metrics/report.py backend/tests/metrics/test_gsc.py \
        .claude/skills/lorescape-metrics/references/google-setup.md
git commit -m "feat(metrics): add GSC search-analytics source + Google setup doc"
```

---

### Task 4: GA4 source (Data API, web + app properties)

**Files:**
- Create: `backend/scripts/metrics/ga4.py`
- Modify: `backend/scripts/metrics/report.py` (register `"ga4"`)
- Test: `backend/tests/metrics/test_ga4.py`

**Interfaces:**
- Consumes: `MetricsConfig`, `SourceResult`; `SOURCES` registry.
- Produces:
  - `parse_run_report(resp: dict, label: str) -> list[list[str]]` — maps a GA4 `runReport` JSON-ish dict into rows `[label, dimension, metric1, metric2]`. Pure.
  - `fetch_ga4(cfg, start, end) -> SourceResult` — runs a report for each configured property (`ga4_property_id_web` labelled `web`, `ga4_property_id_app` labelled `app`); skips if neither is set; merges rows; one source result.

- [ ] **Step 1: Write the failing tests**

```python
# backend/tests/metrics/test_ga4.py
from __future__ import annotations

from scripts.metrics import ga4
from scripts.metrics._common import MetricsConfig


SAMPLE = {
    "rows": [
        {"dimensionValues": [{"value": "google / organic"}],
         "metricValues": [{"value": "120"}, {"value": "45"}]},
        {"dimensionValues": [{"value": "(direct) / (none)"}],
         "metricValues": [{"value": "80"}, {"value": "30"}]},
    ]
}


def test_parse_run_report_prefixes_label():
    rows = ga4.parse_run_report(SAMPLE, "web")
    assert rows[0] == ["web", "google / organic", "120", "45"]
    assert rows[1][1] == "(direct) / (none)"


def test_parse_run_report_empty():
    assert ga4.parse_run_report({}, "web") == []


def test_fetch_ga4_skips_without_any_property():
    r = ga4.fetch_ga4(MetricsConfig(ga4_property_id_web=None,
                                    ga4_property_id_app=None),
                      "2026-06-17", "2026-06-23")
    assert r.ok is False
    assert "GA4_PROPERTY_ID" in (r.skipped_reason or "")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/metrics/test_ga4.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.metrics.ga4'`.

- [ ] **Step 3: Write `ga4.py`**

```python
# backend/scripts/metrics/ga4.py
"""GA4 Data API source for landing (web) and app properties."""
from __future__ import annotations

from scripts.metrics._common import MetricsConfig, SourceResult

_HEADERS = ["stream", "source_medium", "active_users", "new_users"]


def parse_run_report(resp: dict, label: str) -> list[list[str]]:
    """Map a runReport response dict into labelled string rows."""
    rows: list[list[str]] = []
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        rows.append([label, *dims, *mets])
    return rows


def _run_report(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API and return a plain dict (lazy import)."""
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start, end_date=end)],
        dimensions=[Dimension(name="sessionSourceMedium")],
        metrics=[Metric(name="activeUsers"), Metric(name="newUsers")],
        limit=25,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_ga4(cfg: MetricsConfig, start: str, end: str) -> SourceResult:
    """Fetch active/new users by source-medium for each GA4 property."""
    properties = [
        ("web", cfg.ga4_property_id_web),
        ("app", cfg.ga4_property_id_app),
    ]
    configured = [(label, pid) for label, pid in properties if pid]
    if not configured:
        return SourceResult.skipped(
            "ga4", "missing GA4_PROPERTY_ID_WEB/APP in .env"
        )

    rows: list[list[str]] = []
    summary: list[str] = []
    for label, pid in configured:
        try:
            resp = _run_report(pid, start, end)
        except Exception as exc:
            summary.append(f"{label}: API error: {exc}")
            continue
        prop_rows = parse_run_report(resp, label)
        rows.extend(prop_rows)
        users = sum(int(r[2]) for r in prop_rows if r[2].isdigit())
        summary.append(f"{label} active users {users}（{len(prop_rows)} 來源）")

    if not rows and summary:
        return SourceResult.skipped("ga4", "; ".join(summary))
    return SourceResult(
        name="ga4", ok=True, summary_lines=summary,
        csv_headers=_HEADERS, csv_rows=rows,
    )
```

- [ ] **Step 4: Register the source in `report.py`**

Add after the GSC registration:

```python
from scripts.metrics.ga4 import fetch_ga4

SOURCES["ga4"] = fetch_ga4
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/metrics/test_ga4.py -v`
Expected: PASS (3 passed).

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/metrics/ga4.py backend/scripts/metrics/report.py \
        backend/tests/metrics/test_ga4.py
git commit -m "feat(metrics): add GA4 Data API source for web + app properties"
```

---

### Task 5: IG source (Instagram Graph API)

**Files:**
- Create: `backend/scripts/metrics/ig.py`
- Modify: `backend/scripts/metrics/report.py` (register `"ig"`)
- Test: `backend/tests/metrics/test_ig.py`

**Interfaces:**
- Consumes: `MetricsConfig`, `SourceResult`; `SOURCES` registry.
- Produces:
  - `parse_account_insights(resp: dict) -> list[list[str]]` — maps an IG `insights` response into rows `[metric, value]`. Pure.
  - `parse_profile(resp: dict) -> list[str]` — followers/media-count summary lines. Pure.
  - `fetch_ig(cfg, start, end) -> SourceResult` — uses `requests` against the Graph API; skips when `ig_user_id`/`meta_page_access_token` missing.

- [ ] **Step 1: Write the failing tests**

```python
# backend/tests/metrics/test_ig.py
from __future__ import annotations

from scripts.metrics import ig
from scripts.metrics._common import MetricsConfig


INSIGHTS = {
    "data": [
        {"name": "reach", "values": [{"value": 1500}]},
        {"name": "profile_views", "values": [{"value": 90}]},
    ]
}
PROFILE = {"followers_count": 320, "media_count": 48}


def test_parse_account_insights_rows():
    rows = ig.parse_account_insights(INSIGHTS)
    assert ["reach", "1500"] in rows
    assert ["profile_views", "90"] in rows


def test_parse_profile_lines():
    lines = ig.parse_profile(PROFILE)
    assert any("320" in ln for ln in lines)
    assert any("48" in ln for ln in lines)


def test_fetch_ig_skips_without_credentials():
    r = ig.fetch_ig(MetricsConfig(ig_user_id=None,
                                  meta_page_access_token=None),
                    "2026-06-17", "2026-06-23")
    assert r.ok is False
    assert "IG" in (r.skipped_reason or "").upper()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/metrics/test_ig.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.metrics.ig'`.

- [ ] **Step 3: Write `ig.py`**

```python
# backend/scripts/metrics/ig.py
"""Instagram Graph API source (account insights + profile)."""
from __future__ import annotations

import requests

from scripts.metrics._common import MetricsConfig, SourceResult

_GRAPH = "https://graph.facebook.com/v21.0"
_HEADERS = ["metric", "value"]


def parse_account_insights(resp: dict) -> list[list[str]]:
    """Map an IG account insights response into [metric, value] rows."""
    rows: list[list[str]] = []
    for item in resp.get("data", []):
        values = item.get("values", [])
        value = values[0].get("value", "") if values else ""
        rows.append([item.get("name", ""), str(value)])
    return rows


def parse_profile(resp: dict) -> list[str]:
    """Summary lines for follower / media counts."""
    return [
        f"粉絲數 {resp.get('followers_count', 'n/a')}",
        f"貼文數 {resp.get('media_count', 'n/a')}",
    ]


def fetch_ig(cfg: MetricsConfig, start: str, end: str) -> SourceResult:
    """Fetch IG profile + account reach/profile_views for the period."""
    if not (cfg.ig_user_id and cfg.meta_page_access_token):
        return SourceResult.skipped(
            "ig", "missing IG_USER_ID / META_PAGE_ACCESS_TOKEN in .env"
        )
    token = cfg.meta_page_access_token
    uid = cfg.ig_user_id
    try:
        profile = requests.get(
            f"{_GRAPH}/{uid}",
            params={"fields": "followers_count,media_count",
                    "access_token": token},
            timeout=30,
        ).json()
        insights = requests.get(
            f"{_GRAPH}/{uid}/insights",
            params={"metric": "reach,profile_views", "period": "day",
                    "since": start, "until": end, "access_token": token},
            timeout=30,
        ).json()
    except Exception as exc:
        return SourceResult.skipped("ig", f"API error: {exc}")

    if "error" in profile or "error" in insights:
        err = profile.get("error") or insights.get("error")
        return SourceResult.skipped("ig", f"Graph API error: {err}")

    rows = parse_account_insights(insights)
    return SourceResult(
        name="ig", ok=True,
        summary_lines=parse_profile(profile),
        csv_headers=_HEADERS, csv_rows=rows,
    )
```

- [ ] **Step 4: Register the source in `report.py`**

Add after the GA4 registration:

```python
from scripts.metrics.ig import fetch_ig

SOURCES["ig"] = fetch_ig
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/metrics/ -v`
Expected: PASS (all metrics tests green).

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/metrics/ig.py backend/scripts/metrics/report.py \
        backend/tests/metrics/test_ig.py
git commit -m "feat(metrics): add Instagram Graph API source"
```

---

### Task 6: SKILL.md + stores browser-fallback reference

**Files:**
- Create: `.claude/skills/lorescape-metrics/SKILL.md`
- Create: `.claude/skills/lorescape-metrics/references/stores-browser.md`

**Interfaces:**
- Consumes: the `report.py` CLI and reference docs from prior tasks. No code, no tests — this is the user-facing skill wiring.

- [ ] **Step 1: Write `SKILL.md`**

```markdown
<!-- .claude/skills/lorescape-metrics/SKILL.md -->
---
name: lorescape-metrics
description: Use when the user wants to pull Lorescape product metrics into a saved report — Google Search Console search traffic, GA4 landing + app traffic, Instagram reach/followers, or App Store / Play downloads & ratings. Triggers on 「產品數據報告」「這週/這月數據」「抓 GSC / 搜尋流量」「GA4 / landing / App 流量」「IG 數據 / 觸及」「App 下載 / 評分」. API-first (GSC/GA4/IG); App Store / Play captured via the Chrome browser. Writes to docs/metrics/<date>/. Local, read-only, does not touch the server.
---

# Lorescape 數據抓取報告

手動把 Lorescape 各來源的產品數據抓成報告檔，存到
`docs/metrics/<結束日>/`（`summary.md` + 各來源 `.csv`）。
API 為主（GSC / GA4 / IG），App Store / Play 用瀏覽器抓。

## 前置條件

- **Google（GSC + GA4）**：見 `references/google-setup.md`（一次性 ADC 登入 +
  在 `backend/.env` 填 `GSC_SITE_URL` / `GA4_PROPERTY_ID_WEB` /
  `GA4_PROPERTY_ID_APP`）。
- **IG**：沿用 `backend/.env` 既有的 `IG_USER_ID` / `META_PAGE_ACCESS_TOKEN`。
- **App Store / Play**：使用者已在 Chrome 登入 App Store Connect 與 Play
  Console，見 `references/stores-browser.md`。

## 步驟

1. 跟使用者確認區間（預設近 7 天，可用 `--days 28` 或 `--start/--end`）與
   要抓哪些來源（預設全部）。

2. **先 dry-run** 檢查設定與憑證（不抓資料）：

       cd backend && uv run python -m scripts.metrics.report --check

   把每個來源的 ready / missing 狀態念給使用者；缺設定的先補。

3. 抓 API 來源並產生報告：

       cd backend && uv run python -m scripts.metrics.report --days 7

   只抓單一來源時用 `--only`，例如 `--only ig` 或 `--only gsc,ga4`。
   完成後讀出 `docs/metrics/<結束日>/summary.md` 的重點給使用者。

4. **App Store / Play（瀏覽器）**：依使用者要求，按
   `references/stores-browser.md` 用 Chrome 抓下載數與評分，截圖存到
   報告資料夾，並把數字附加成 `summary.md` 的「## stores」段落。

## 注意

- 全程本機、唯讀，不寫 Supabase、不碰 server 排程。
- 某來源缺憑證或失敗時，報告會標 `skipped: <原因>` 並照常產出其他來源，
  不需整批重跑。
```

- [ ] **Step 2: Write `references/stores-browser.md`**

```markdown
<!-- .claude/skills/lorescape-metrics/references/stores-browser.md -->
# App Store / Play 瀏覽器抓取

App Store Connect 與 Play Console 第一版用 Chrome 自動化抓（沿用使用者
已登入的 session）。用 `claude-in-chrome` MCP 工具操作。

## 流程

1. 先 `tabs_context_mcp` 看現有分頁；用 `tabs_create_mcp` 開新分頁。
2. **App Store Connect**：開
   `https://appstoreconnect.apple.com/analytics` →
   選 Lorescape app → 區間對齊報告的 start/end → 讀「下載次數」與
   App Store 評分。用 `read_page` / 截圖取值。
3. **Play Console**：開 `https://play.google.com/console` →
   選 app → 「統計資料」讀安裝數，「評分」讀平均星等與評論數。
4. 把抓到的數字附加到 `docs/metrics/<結束日>/summary.md` 的
   `## stores` 段落，截圖存同資料夾（如 `stores-appstore.png`）。

## 注意

- 若未登入或要求二階段驗證，提醒使用者手動登入後再繼續，不要嘗試輸入密碼。
- 不要點任何會跳出 confirm/alert 對話框的按鈕（會卡住擴充功能）。
- 數字以網頁顯示為準，純人工核對，不寫回任何後端。
```

- [ ] **Step 3: Verify skill files are well-formed**

Run: `head -5 .claude/skills/lorescape-metrics/SKILL.md`
Expected: shows the YAML frontmatter with `name: lorescape-metrics` and a `description:` line.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/lorescape-metrics/SKILL.md \
        .claude/skills/lorescape-metrics/references/stores-browser.md
git commit -m "feat(metrics): add lorescape-metrics skill + stores browser flow"
```

---

### Task 7: Full-suite verification + `.gitignore` / docs check

**Files:**
- Modify (if needed): `backend/.env.example` (document new keys)
- Test: run the whole metrics suite.

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Add the new env keys to `.env.example`**

Append to `backend/.env.example` (create the lines if the file exists; skip if there is no such file):

```bash
# Metrics skill (lorescape-metrics)
GSC_SITE_URL=
GA4_PROPERTY_ID_WEB=
GA4_PROPERTY_ID_APP=
```

- [ ] **Step 2: Run the full metrics test suite**

Run: `cd backend && uv run pytest tests/metrics/ -v`
Expected: PASS — all tests across `test_common`, `test_report`, `test_gsc`, `test_ga4`, `test_ig`.

- [ ] **Step 3: Run the broader backend suite to confirm no regressions**

Run: `cd backend && uv run pytest -q`
Expected: PASS — existing tests unaffected (new package is additive).

- [ ] **Step 4: Smoke-test the CLI `--check` end to end**

Run: `cd backend && uv run python -m scripts.metrics.report --check`
Expected: prints the date range and one readiness line per source. With a populated `.env`, sources show `ready`; otherwise `missing config`.

- [ ] **Step 5: Commit**

```bash
git add backend/.env.example
git commit -m "chore(metrics): document metrics env keys in .env.example"
```

---

## Notes for the implementer

- **Live API verification is out of band.** The unit tests cover parsing and skip-paths only; confirming real GSC/GA4/IG responses requires the user's ADC login and `.env` values, which the skill walks through at run time. Do not block plan completion on live calls.
- **GA4 property auto-detection** (listing properties via the Admin API) is documented in `google-setup.md` as a manual step; a `--list-properties` helper can be added later if the user wants it (YAGNI for v1 — they can read the ID from the GA4 admin screen).
- **Stores** intentionally has no Python module or test — it is a browser-driven skill step, per the design's "API 為主、網頁為輔".
