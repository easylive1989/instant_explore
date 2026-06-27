"""Google Search Console search-analytics source (daily site totals)."""
from __future__ import annotations

from scripts.metrics._common import DailySource, MetricsConfig

_DAILY_HEADERS = ["date", "clicks", "impressions", "ctr", "position"]


def _service():
    """Build the Search Console API client using ADC (lazy import)."""
    import google.auth
    from googleapiclient.discovery import build

    creds, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/webmasters.readonly"]
    )
    return build("searchconsole", "v1", credentials=creds,
                 cache_discovery=False)


def parse_daily(resp: dict) -> list[list[str]]:
    """Map a date-dimensioned searchanalytics response into daily rows.

    Each row is ``[date, clicks, impressions, ctr, position]`` — the site
    totals for that day, suitable for accumulation keyed by date.
    """
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


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day site totals over [start, end] for daily accumulation."""
    service = _service()
    resp = service.searchanalytics().query(
        siteUrl=cfg.gsc_site_url,
        body={
            "startDate": start,
            "endDate": end,
            "dimensions": ["date"],
            "rowLimit": 1000,
        },
    ).execute()
    return parse_daily(resp)


SOURCE = DailySource(
    name="gsc",
    filename="gsc.csv",
    headers=_DAILY_HEADERS,
    required=("gsc_site_url",),
    fetch=fetch_daily,
)
