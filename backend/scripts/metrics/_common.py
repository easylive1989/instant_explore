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
