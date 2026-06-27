# backend/scripts/metrics/ga4.py
"""GA4 Data API source for landing (web) and app properties (daily)."""
from __future__ import annotations

from scripts.metrics._common import DailySource, MetricsConfig

_DAILY_HEADERS = [
    "date",
    "web_active_users", "web_new_users",
    "app_active_users", "app_new_users",
]


def _iso_date(ga4_date: str) -> str:
    """Convert GA4's ``YYYYMMDD`` date dimension to ISO ``YYYY-MM-DD``."""
    if len(ga4_date) == 8 and ga4_date.isdigit():
        return f"{ga4_date[:4]}-{ga4_date[4:6]}-{ga4_date[6:]}"
    return ga4_date


def parse_daily_property(resp: dict) -> dict[str, tuple[str, str]]:
    """Map a date-dimensioned runReport into ``{iso_date: (active, new)}``."""
    out: dict[str, tuple[str, str]] = {}
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        day = _iso_date(dims[0]) if dims else ""
        active = mets[0] if len(mets) > 0 else ""
        new = mets[1] if len(mets) > 1 else ""
        out[day] = (active, new)
    return out


def merge_daily(
    web: dict[str, tuple[str, str]],
    app: dict[str, tuple[str, str]],
) -> list[list[str]]:
    """Combine per-property daily maps into wide rows keyed by date."""
    rows: list[list[str]] = []
    for day in sorted(set(web) | set(app)):
        w_active, w_new = web.get(day, ("", ""))
        a_active, a_new = app.get(day, ("", ""))
        rows.append([day, w_active, w_new, a_active, a_new])
    return rows


def _run_report_daily(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API with a date dimension for daily totals."""
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start, end_date=end)],
        dimensions=[Dimension(name="date")],
        metrics=[Metric(name="activeUsers"), Metric(name="newUsers")],
        limit=1000,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day active/new users for web and app, keyed by date."""
    web = (parse_daily_property(_run_report_daily(cfg.ga4_property_id_web,
                                                  start, end))
           if cfg.ga4_property_id_web else {})
    app = (parse_daily_property(_run_report_daily(cfg.ga4_property_id_app,
                                                  start, end))
           if cfg.ga4_property_id_app else {})
    return merge_daily(web, app)


SOURCE = DailySource(
    name="ga4",
    filename="ga4.csv",
    headers=_DAILY_HEADERS,
    required=("ga4_property_id_web", "ga4_property_id_app"),
    fetch=fetch_daily,
    ready=lambda cfg: bool(cfg.ga4_property_id_web or cfg.ga4_property_id_app),
)
