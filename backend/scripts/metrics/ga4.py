# backend/scripts/metrics/ga4.py
"""GA4 Data API source split by platform (web / iOS / Android), daily.

Lorescape's web, iOS and Android streams live in one GA4 property, so the
daily report queries that single property with a ``platform`` dimension to
break active/new users out per platform (App = iOS + Android).
"""
from __future__ import annotations

from scripts.metrics._common import DailySource, MetricsConfig

_PLATFORMS = ("web", "ios", "android")
_DAILY_HEADERS = [
    "date",
    "web_active_users", "web_new_users",
    "ios_active_users", "ios_new_users",
    "android_active_users", "android_new_users",
]


def _iso_date(ga4_date: str) -> str:
    """Convert GA4's ``YYYYMMDD`` date dimension to ISO ``YYYY-MM-DD``."""
    if len(ga4_date) == 8 and ga4_date.isdigit():
        return f"{ga4_date[:4]}-{ga4_date[4:6]}-{ga4_date[6:]}"
    return ga4_date


def _platform_key(value: str) -> str:
    """Normalize GA4's platform value (``web``/``iOS``/``Android``)."""
    return value.strip().lower()


def parse_daily(resp: dict) -> dict[str, dict[str, tuple[str, str]]]:
    """Map a date+platform runReport into ``{date: {platform: (active, new)}}``."""
    out: dict[str, dict[str, tuple[str, str]]] = {}
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        day = _iso_date(dims[0]) if dims else ""
        platform = _platform_key(dims[1]) if len(dims) > 1 else ""
        active = mets[0] if len(mets) > 0 else ""
        new = mets[1] if len(mets) > 1 else ""
        out.setdefault(day, {})[platform] = (active, new)
    return out


def to_rows(per_day: dict[str, dict[str, tuple[str, str]]]) -> list[list[str]]:
    """Render the parsed map into wide per-day rows (web/ios/android)."""
    rows: list[list[str]] = []
    for day in sorted(per_day):
        platforms = per_day[day]
        row = [day]
        for platform in _PLATFORMS:
            active, new = platforms.get(platform, ("", ""))
            row.extend([active, new])
        rows.append(row)
    return rows


def _run_report_daily(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API with date + platform dimensions."""
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start, end_date=end)],
        dimensions=[Dimension(name="date"), Dimension(name="platform")],
        metrics=[Metric(name="activeUsers"), Metric(name="newUsers")],
        limit=10000,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day active/new users split by platform, keyed by date."""
    property_id = cfg.ga4_property_id_web or cfg.ga4_property_id_app
    resp = _run_report_daily(property_id, start, end)
    return to_rows(parse_daily(resp))


SOURCE = DailySource(
    name="ga4",
    filename="ga4.csv",
    headers=_DAILY_HEADERS,
    required=("ga4_property_id_web", "ga4_property_id_app"),
    fetch=fetch_daily,
    ready=lambda cfg: bool(cfg.ga4_property_id_web or cfg.ga4_property_id_app),
)
