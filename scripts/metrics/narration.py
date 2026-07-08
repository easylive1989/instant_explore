# scripts/metrics/narration.py
"""Narration listen-completion source from GA4, daily.

Lorescape's app fires four narration analytics events (see the frontend
`analytics` feature): ``narration_started`` / ``narration_progress`` /
``narration_completed`` / ``narration_abandoned``. This source queries GA4 for
their daily counts and derives a completion rate
(``completed / started``) so the metrics sheet lights up a listen-completion
view before traffic scales — no re-instrumentation, purely aggregating events
that already flow to GA4.

Completion rate is count-based (completed events ÷ started events), which uses
GA4's standard ``eventCount`` metric and needs no custom-metric registration.
"""
from __future__ import annotations

from metrics._common import DailySource, MetricsConfig

# The narration events we surface, in column order.
_STARTED = "narration_started"
_COMPLETED = "narration_completed"
_ABANDONED = "narration_abandoned"

_DAILY_HEADERS = [
    "date",
    "narration_started",
    "narration_completed",
    "narration_abandoned",
    "completion_rate",
]


def _iso_date(ga4_date: str) -> str:
    """Convert GA4's ``YYYYMMDD`` date dimension to ISO ``YYYY-MM-DD``."""
    if len(ga4_date) == 8 and ga4_date.isdigit():
        return f"{ga4_date[:4]}-{ga4_date[4:6]}-{ga4_date[6:]}"
    return ga4_date


def parse_daily(resp: dict) -> dict[str, dict[str, int]]:
    """Map a date+eventName runReport into ``{date: {event_name: count}}``.

    Only narration events are kept; other app events in the response are
    ignored so the source stays focused even when the query is unfiltered.
    """
    wanted = {_STARTED, _COMPLETED, _ABANDONED}
    out: dict[str, dict[str, int]] = {}
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        day = _iso_date(dims[0]) if dims else ""
        event = dims[1] if len(dims) > 1 else ""
        if event not in wanted or not day:
            continue
        try:
            count = int(mets[0]) if mets and mets[0] != "" else 0
        except ValueError:
            count = 0
        out.setdefault(day, {})[event] = count
    return out


def _completion_rate(started: int, completed: int) -> str:
    """Completed ÷ started as a 3-dp string, or blank when nothing started."""
    if started <= 0:
        return ""
    return f"{completed / started:.3f}"


def to_rows(per_day: dict[str, dict[str, int]]) -> list[list[str]]:
    """Render the parsed map into per-day rows with a derived completion rate."""
    rows: list[list[str]] = []
    for day in sorted(per_day):
        counts = per_day[day]
        started = counts.get(_STARTED, 0)
        completed = counts.get(_COMPLETED, 0)
        abandoned = counts.get(_ABANDONED, 0)
        rows.append(
            [
                day,
                str(started),
                str(completed),
                str(abandoned),
                _completion_rate(started, completed),
            ]
        )
    return rows


def _run_report_daily(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API with date + eventName dimensions, event counts."""
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start, end_date=end)],
        dimensions=[Dimension(name="date"), Dimension(name="eventName")],
        metrics=[Metric(name="eventCount")],
        limit=10000,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day narration counts + completion rate, keyed by date."""
    property_id = cfg.ga4_property_id_app or cfg.ga4_property_id_web
    resp = _run_report_daily(property_id, start, end)
    return to_rows(parse_daily(resp))


SOURCE = DailySource(
    name="narration",
    filename="narration.csv",
    headers=_DAILY_HEADERS,
    required=("ga4_property_id_app",),
    fetch=fetch_daily,
    ready=lambda cfg: bool(cfg.ga4_property_id_app or cfg.ga4_property_id_web),
)
