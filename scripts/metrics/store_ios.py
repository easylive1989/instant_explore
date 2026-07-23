"""App Store source: daily downloads (ASC Sales API) + rating snapshot.

Downloads come from App Store Connect's sales reports (DAILY/SALES/SUMMARY,
gzip TSV) and are backfillable about a year; a day's report only appears
around 05:00 PT the next day, so an unready tail is left for the next run.
The rating / review counts have no history — like `ig` they are snapshotted
onto the latest day only. Ratings come from the public iTunes lookup, which
is per-storefront (`LOOKUP_COUNTRY`), so it can lag ASC's worldwide figure.
"""
from __future__ import annotations

import csv
import gzip
import io
from datetime import date, timedelta

import requests

from metrics._asc import API as _ASC
from metrics._asc import token as _token
from metrics._common import DailySource, MetricsConfig

_LOOKUP = "https://itunes.apple.com/lookup"

# Lorescape's App Store numeric id (apps.apple.com/.../id6751904060).
APPLE_APP_ID = "6751904060"
# Storefront for the public rating snapshot (ratings are per-country).
LOOKUP_COUNTRY = "tw"

_DAILY_HEADERS = [
    "date", "downloads", "avg_rating", "ratings_count", "reviews_count",
]


def parse_sales_units(tsv: str, apple_id: str) -> int:
    """Sum first-download units for `apple_id` in a SALES/SUMMARY report.

    Product Type Identifiers starting with "1" are first-time downloads
    (1 / 1F / 1T / 1E…); updates (7…) and redownloads (3…) are excluded.
    """
    rows = list(csv.reader(io.StringIO(tsv), delimiter="\t"))
    if len(rows) < 2:
        return 0
    header = rows[0]
    type_i = header.index("Product Type Identifier")
    units_i = header.index("Units")
    app_i = header.index("Apple Identifier")
    total = 0
    for row in rows[1:]:
        if len(row) <= max(type_i, units_i, app_i):
            continue
        if row[app_i] == apple_id and row[type_i].startswith("1"):
            total += int(float(row[units_i]))
    return total


def parse_lookup(resp: dict) -> tuple[str, str]:
    """Extract (avg_rating, ratings_count) from an iTunes lookup response."""
    results = resp.get("results") or []
    if not results:
        return "", ""
    rating = results[0].get("averageUserRating")
    count = results[0].get("userRatingCount")
    return (
        f"{rating:.2f}" if rating is not None else "",
        str(count) if count is not None else "",
    )


def _sales_day(cfg: MetricsConfig, day: str) -> str | None:
    """Fetch one day's sales TSV: "" when no sales, None when not ready.

    Both cases come back as 404; only the no-sales one is a real zero. An
    unready report (today's data, or ASC still generating) returns None so
    the caller stops and leaves the gap for the next run.
    """
    resp = requests.get(
        f"{_ASC}/salesReports",
        headers={"Authorization": f"Bearer {_token(cfg)}"},
        params={
            "filter[frequency]": "DAILY",
            "filter[reportDate]": day,
            "filter[reportSubType]": "SUMMARY",
            "filter[reportType]": "SALES",
            "filter[vendorNumber]": cfg.asc_vendor_number,
        },
        timeout=60,
    )
    if resp.status_code == 200:
        return gzip.decompress(resp.content).decode("utf-8")
    if resp.status_code == 404:
        if "no sales" in resp.text.lower():
            return ""
        return None
    resp.raise_for_status()
    return None


def _lookup(cfg: MetricsConfig) -> dict:
    """Fetch the public storefront rating snapshot."""
    return requests.get(
        _LOOKUP,
        params={"id": APPLE_APP_ID, "country": LOOKUP_COUNTRY},
        timeout=30,
    ).json()


def _reviews_total(cfg: MetricsConfig) -> str:
    """Count written customer reviews via ASC (paging total, all countries)."""
    resp = requests.get(
        f"{_ASC}/apps/{APPLE_APP_ID}/customerReviews",
        headers={"Authorization": f"Bearer {_token(cfg)}"},
        params={"limit": 1},
        timeout=30,
    )
    if not resp.ok:
        return ""
    total = resp.json().get("meta", {}).get("paging", {}).get("total")
    return str(total) if total is not None else ""


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day download rows over [start, end], keyed by date.

    Ratings / review counts are live snapshots recorded only against the
    latest day. Days whose sales report isn't generated yet end the loop —
    they stay missing and are backfilled by a later run.
    """
    rows: list[list[str]] = []
    cursor = date.fromisoformat(start)
    last = date.fromisoformat(end)
    while cursor <= last:
        day = cursor.isoformat()
        tsv = _sales_day(cfg, day)
        if tsv is None:
            break
        downloads = str(parse_sales_units(tsv, APPLE_APP_ID))
        if day == end:
            rating, count = parse_lookup(_lookup(cfg))
            rows.append([day, downloads, rating, count, _reviews_total(cfg)])
        else:
            rows.append([day, downloads, "", "", ""])
        cursor += timedelta(days=1)
    return rows


SOURCE = DailySource(
    name="store_ios",
    filename="store_ios.csv",
    headers=_DAILY_HEADERS,
    required=("asc_key_id", "asc_issuer_id", "asc_key_path",
              "asc_vendor_number"),
    fetch=fetch_daily,
)
