"""Accumulate App Store / Play store snapshots into the metrics sheet.

Unlike the API sources (``gsc`` / ``ga4`` / ``ig`` / ``ig_posts``), App Store
Connect and Play Console expose no headless API here, so their numbers are
read by hand from the browser and passed in as flags. This script upserts one
date-keyed row into the ``stores`` tab, reusing the same spreadsheet, service
account, and merge/de-dup behaviour as :mod:`metrics.report`. Re-running
for the same date overwrites that row.
"""
from __future__ import annotations

import argparse
import os

from dotenv import load_dotenv

from metrics._common import REPO_ROOT, date_range, merge_rows
from metrics.sheets import SheetClient

TAB = "stores"
HEADERS = [
    "date",
    "ios_downloads_30d",
    "ios_avg_rating",
    "ios_ratings_count",
    "ios_reviews_count",
    "android_installs",
    "android_avg_rating",
    "android_ratings_count",
    "note",
]


def _default_date() -> str:
    """Yesterday in ISO — the target end shared with the API sources."""
    _, end = date_range(days=1)
    return end


def build_row(args: argparse.Namespace) -> list[str]:
    """Map parsed flags to a row in ``HEADERS`` order (blanks for unset)."""
    return [
        args.date,
        args.ios_downloads,
        args.ios_rating,
        args.ios_ratings,
        args.ios_reviews,
        args.android_installs,
        args.android_rating,
        args.android_ratings,
        args.note,
    ]


def upsert(client: SheetClient, row: list[str]) -> int:
    """Merge `row` into the ``stores`` tab by date; return the row count."""
    existing = client.read_tab(TAB)
    rows = existing[1:] if existing else []
    merged = merge_rows(rows, [row], key_index=0)
    client.write_tab(TAB, [HEADERS, *merged])
    return len(merged)


def build_client() -> SheetClient:
    """Build the Sheets client from ``METRICS_SHEET_ID``."""
    sheet_id = os.environ.get("METRICS_SHEET_ID")
    if not sheet_id:
        raise SystemExit(
            "METRICS_SHEET_ID is not set in backend/.env; see "
            "docs/init/metrics-setup.md §D."
        )
    return SheetClient(sheet_id)


def main(argv: list[str] | None = None) -> int:
    load_dotenv(REPO_ROOT / "scripts" / ".env")
    parser = argparse.ArgumentParser(
        description="Record an App Store / Play snapshot into the sheet."
    )
    parser.add_argument("--date", default=None,
                        help="snapshot date, ISO (default: yesterday)")
    parser.add_argument("--ios-downloads", default="",
                        help="App Store Trends downloads, rolling 30 days")
    parser.add_argument("--ios-rating", default="",
                        help="App Store average rating (e.g. 5.0)")
    parser.add_argument("--ios-ratings", default="",
                        help="App Store number of ratings")
    parser.add_argument("--ios-reviews", default="",
                        help="App Store number of written reviews")
    parser.add_argument("--android-installs", default="",
                        help="Play Console installs (blank if not ready)")
    parser.add_argument("--android-rating", default="",
                        help="Play average rating")
    parser.add_argument("--android-ratings", default="",
                        help="Play number of ratings")
    parser.add_argument("--note", default="",
                        help="free-text note for the row")
    args = parser.parse_args(argv)
    args.date = args.date or _default_date()

    client = build_client()
    count = upsert(client, build_row(args))
    print(f"google sheet: {client.sheet_id}")
    print(f"- stores: upserted {args.date} ({count} row(s) total)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
