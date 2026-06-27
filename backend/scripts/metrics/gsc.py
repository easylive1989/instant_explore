"""Google Search Console search-analytics source."""
from __future__ import annotations

from scripts.metrics._common import DailySource, MetricsConfig, SourceResult

_HEADERS = ["query", "clicks", "impressions", "ctr", "position"]
_DAILY_HEADERS = ["date", "clicks", "impressions", "ctr", "position"]


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
