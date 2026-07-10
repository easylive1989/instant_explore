"""Shared primitives for metrics fetchers: config, date ranges, IO helpers."""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path
from typing import Callable

REPO_ROOT = Path(__file__).resolve().parents[2]


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


KeyIndex = int | tuple[int, ...]


def row_key(row: list[str], key_index: KeyIndex):
    """Extract a row's merge key: one column, or a tuple of columns.

    A tuple `key_index` yields a composite key (e.g. media id + observation
    date), letting a source store several rows that share any single column.
    """
    if isinstance(key_index, tuple):
        return tuple(row[i] for i in key_index)
    return row[key_index]


def key_width(key_index: KeyIndex) -> int:
    """Highest column index a key touches, for bounds-checking rows."""
    return max(key_index) if isinstance(key_index, tuple) else key_index


def merge_rows(
    existing: list[list[str]],
    new_rows: list[list[str]],
    key_index: KeyIndex = 0,
    sort_index: KeyIndex | None = None,
) -> list[list[str]]:
    """Merge `new_rows` into `existing`, keyed by a column, then sort.

    Rows sharing a key with `new_rows` are overwritten (re-fetching a day or
    post refreshes it). `key_index` may be a tuple of columns for a composite
    key. The result is ordered by `sort_index` when given (e.g. publish date
    for per-post rows), otherwise by the key — either way the dataset stays
    deterministically ordered. Storage-agnostic: callers supply the existing
    rows and persist the result however they like.
    """
    order = sort_index if sort_index is not None else key_index
    width = max(key_width(key_index), key_width(order))
    merged: dict = {
        row_key(row, key_index): row for row in existing if len(row) > width
    }
    for row in new_rows:
        merged[row_key(row, key_index)] = row
    return sorted(merged.values(), key=lambda row: row_key(row, order))


def missing_days(
    existing: set[str],
    end: str,
    first_backfill: int = 30,
) -> list[str]:
    """Return ISO dates to fetch so the dataset reaches `end` (yesterday).

    With no existing data the window starts `first_backfill` days back to
    seed a baseline; otherwise it resumes the day after the latest record.
    Days already present are skipped, so a re-run with nothing new returns
    an empty list.
    """
    end_d = date.fromisoformat(end)
    if existing:
        latest = max(date.fromisoformat(day) for day in existing)
        start_d = latest + timedelta(days=1)
    else:
        start_d = end_d - timedelta(days=first_backfill - 1)
    days: list[str] = []
    cursor = start_d
    while cursor <= end_d:
        iso = cursor.isoformat()
        if iso not in existing:
            days.append(iso)
        cursor += timedelta(days=1)
    return days


def rows_to_md_table(headers: list[str], rows: list[list[str]]) -> str:
    """Render a GitHub markdown table; placeholder when empty."""
    if not rows:
        return "_(no rows)_"
    head = "| " + " | ".join(headers) + " |"
    sep = "| " + " | ".join("---" for _ in headers) + " |"
    body = "\n".join("| " + " | ".join(r) + " |" for r in rows)
    return f"{head}\n{sep}\n{body}"


@dataclass(frozen=True)
class MetricsConfig:
    """Metrics-specific configuration read from environment."""

    ga4_property_id_web: str | None = None
    ga4_property_id_app: str | None = None
    gsc_site_url: str | None = None
    ig_user_id: str | None = None
    meta_page_access_token: str | None = None
    revenuecat_api_key: str | None = None
    revenuecat_project_id: str | None = None

    @classmethod
    def from_env(cls) -> "MetricsConfig":
        get = os.environ.get
        return cls(
            ga4_property_id_web=get("GA4_PROPERTY_ID_WEB") or None,
            ga4_property_id_app=get("GA4_PROPERTY_ID_APP") or None,
            gsc_site_url=get("GSC_SITE_URL") or None,
            ig_user_id=get("IG_USER_ID") or None,
            meta_page_access_token=get("META_PAGE_ACCESS_TOKEN") or None,
            revenuecat_api_key=get("REVENUECAT_V2_API_KEY") or None,
            revenuecat_project_id=get("REVENUECAT_PROJECT_ID") or None,
        )


@dataclass(frozen=True)
class DailySource:
    """Descriptor for one source accumulated into a fixed daily dataset.

    The backfill engine reads `filename`, finds the gap up to yesterday, and
    calls `fetch(cfg, start, end)` once for the whole window — date-keyed
    sources return one row per day, while media-keyed sources (`keyed_by_date`
    is False) are always re-fetched over a recent window (`refresh_days`, or
    the run's backfill horizon when unset). A media-keyed source may key rows
    on a composite `key_index` (e.g. media id + observation date) to keep a
    per-post daily time series rather than a single overwriting snapshot; like
    a snapshot source, past days it missed cannot be recovered.

    Snapshot sources (`snapshot` is True) expose only a live "now" reading
    with no recoverable history (e.g. RevenueCat's overview metrics): the
    engine records a single row stamped against `end` and never backfills
    days that were missed.
    """

    name: str
    filename: str
    headers: list[str]
    required: tuple[str, ...]
    fetch: Callable[["MetricsConfig", str, str], list[list[str]]]
    key_index: KeyIndex = 0
    sort_index: KeyIndex | None = None
    keyed_by_date: bool = True
    snapshot: bool = False
    refresh_days: int | None = None
    ready: Callable[["MetricsConfig"], bool] | None = None

    def missing_config(self, cfg: "MetricsConfig") -> list[str]:
        """Return the names of required config fields that are unset."""
        return [field_name for field_name in self.required
                if not getattr(cfg, field_name)]

    def is_ready(self, cfg: "MetricsConfig") -> bool:
        """Whether the source has enough config to attempt a fetch.

        Defaults to "every required field set"; sources where any one of
        several fields suffices (e.g. GA4's web/app properties) supply a
        custom `ready` predicate.
        """
        if self.ready is not None:
            return self.ready(cfg)
        return not self.missing_config(cfg)


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
