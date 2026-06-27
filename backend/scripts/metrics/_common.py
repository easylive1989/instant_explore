"""Shared primitives for metrics fetchers: config, date ranges, IO helpers."""
from __future__ import annotations

import csv
import os
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path
from typing import Callable

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


def daily_dir(root: Path = REPO_ROOT) -> Path:
    """Return docs/metrics/daily under `root` (not created).

    Holds the fixed, append-only datasets that accumulate one row per day
    (or per media id) across runs, unlike the dated `report_dir` snapshots.
    """
    return root / "docs" / "metrics" / "daily"


def read_daily_csv(path: Path) -> tuple[list[str], list[list[str]]]:
    """Read a daily dataset CSV, returning (headers, rows).

    A missing or empty file yields two empty lists so callers can treat a
    first run and an existing dataset uniformly.
    """
    if not path.exists():
        return [], []
    with path.open(encoding="utf-8", newline="") as fh:
        records = [row for row in csv.reader(fh) if row]
    if not records:
        return [], []
    return records[0], records[1:]


def existing_keys(path: Path, key_index: int = 0) -> set[str]:
    """Return the set of key-column values already stored in `path`."""
    _, rows = read_daily_csv(path)
    return {row[key_index] for row in rows if len(row) > key_index}


def upsert_daily_rows(
    path: Path,
    headers: list[str],
    new_rows: list[list[str]],
    key_index: int = 0,
) -> None:
    """Merge `new_rows` into the daily dataset at `path`, keyed by a column.

    Existing rows are loaded, rows sharing a key with `new_rows` are
    overwritten (re-fetching a day or post refreshes it), and the result is
    written back sorted by key so the file stays chronologically ordered.
    """
    _, existing = read_daily_csv(path)
    merged: dict[str, list[str]] = {
        row[key_index]: row for row in existing if len(row) > key_index
    }
    for row in new_rows:
        merged[row[key_index]] = row
    ordered = [merged[key] for key in sorted(merged)]
    write_csv(path, headers, ordered)


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


@dataclass(frozen=True)
class DailySource:
    """Descriptor for one source accumulated into a fixed daily dataset.

    The backfill engine reads `filename`, finds the gap up to yesterday, and
    calls `fetch(cfg, start, end)` once for the whole window — date-keyed
    sources return one row per day, while media-keyed sources (`keyed_by_date`
    is False) return one row per post and are always re-fetched over a recent
    window to refresh insights.
    """

    name: str
    filename: str
    headers: list[str]
    required: tuple[str, ...]
    fetch: Callable[["MetricsConfig", str, str], list[list[str]]]
    key_index: int = 0
    keyed_by_date: bool = True

    def missing_config(self, cfg: "MetricsConfig") -> list[str]:
        """Return the names of required config fields that are unset."""
        return [field_name for field_name in self.required
                if not getattr(cfg, field_name)]


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
