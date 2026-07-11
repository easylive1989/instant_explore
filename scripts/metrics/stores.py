"""Accumulate App Store / Play store snapshots into ``data/metrics/stores.csv``.

Unlike the API sources (``gsc`` / ``ga4`` / ``ig`` / ``ig_posts``), App Store
Connect and Play Console expose no headless API here, so their numbers are
read by hand from the browser and passed in as flags. This script upserts one
date-keyed row into ``stores.csv``, reusing the same merge/de-dup behaviour
as :mod:`metrics.report`. Re-running for the same date overwrites that row.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path

from dotenv import load_dotenv

from metrics._common import REPO_ROOT, date_range, merge_rows

CSV_PATH = REPO_ROOT / "data" / "metrics" / "stores.csv"
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


def upsert(path: Path, row: list[str]) -> int:
    """Merge `row` into ``stores.csv`` by date; return the row count."""
    rows: list[list[str]] = []
    if path.exists():
        with path.open(newline="", encoding="utf-8") as f:
            values = list(csv.reader(f))
        rows = values[1:] if values else []
    merged = merge_rows(rows, [row], key_index=0)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows([HEADERS, *merged])
    return len(merged)


def main(argv: list[str] | None = None) -> int:
    load_dotenv(REPO_ROOT / "scripts" / ".env")
    parser = argparse.ArgumentParser(
        description="Record an App Store / Play snapshot into stores.csv."
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

    count = upsert(CSV_PATH, build_row(args))
    print(f"csv: {CSV_PATH}")
    print(f"- stores: upserted {args.date} ({count} row(s) total)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
