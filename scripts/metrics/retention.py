# scripts/metrics/retention.py
"""Day-1 / Day-7 retention from GA4 cohort reports, keyed by cohort date.

Uses GA4's cohort report: one daily cohort per first-session date, tracking
``cohortActiveUsers`` across day offsets 0..7. Day-1 retention is
``activeUsers(day 1) / activeUsers(day 0)`` and Day-7 is
``activeUsers(day 7) / activeUsers(day 0)``.

A cohort's later offsets fill in as days pass (a cohort's D7 is only known 7
days after it starts), so the source re-fetches a recent window each run to
refresh maturing cohorts — the merge in the accumulator overwrites a cohort's
row when it is re-fetched.
"""
from __future__ import annotations

from metrics._common import DailySource, MetricsConfig

# How many days back to (re-)compute cohorts each run, so D7 has time to mature.
_WINDOW_DAYS = 14

_DAILY_HEADERS = [
    "date",  # cohort's first-session date
    "cohort_size",  # active users on day 0
    "d1_retained",
    "d1_rate",
    "d7_retained",
    "d7_rate",
]


def parse_cohorts(resp: dict) -> dict[str, dict[int, int]]:
    """Map a cohort runReport into ``{cohort_date: {nth_day: active_users}}``.

    The cohort dimension carries the ISO date we named each cohort after; the
    ``cohortNthDay`` dimension is the day offset (``"0000"`` style or plain).
    """
    out: dict[str, dict[int, int]] = {}
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        cohort = dims[0] if dims else ""
        if not cohort:
            continue
        try:
            nth = int(dims[1]) if len(dims) > 1 and dims[1] != "" else 0
            active = int(mets[0]) if mets and mets[0] != "" else 0
        except ValueError:
            continue
        out.setdefault(cohort, {})[nth] = active
    return out


def _rate(day0: int, dayn: int) -> str:
    """dayn ÷ day0 as a 3-dp string, or blank when the cohort is empty."""
    if day0 <= 0:
        return ""
    return f"{dayn / day0:.3f}"


def to_rows(cohorts: dict[str, dict[int, int]]) -> list[list[str]]:
    """Render cohorts into per-cohort-date rows with D1/D7 retention."""
    rows: list[list[str]] = []
    for cohort_date in sorted(cohorts):
        by_day = cohorts[cohort_date]
        day0 = by_day.get(0, 0)
        d1 = by_day.get(1, 0)
        d7 = by_day.get(7, 0)
        rows.append(
            [
                cohort_date,
                str(day0),
                str(d1),
                _rate(day0, d1),
                str(d7),
                _rate(day0, d7),
            ]
        )
    return rows


def _run_cohort_report(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API cohort report: one daily cohort per start date."""
    from datetime import date, timedelta

    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        Cohort, CohortSpec, CohortsRange, DateRange, Dimension, Metric,
        RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    start_d = date.fromisoformat(start)
    end_d = date.fromisoformat(end)
    cohorts = []
    cursor = start_d
    while cursor <= end_d:
        iso = cursor.isoformat()
        cohorts.append(
            Cohort(
                name=iso,
                dimension="firstSessionDate",
                date_range=DateRange(start_date=iso, end_date=iso),
            )
        )
        cursor += timedelta(days=1)

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=[Dimension(name="cohort"), Dimension(name="cohortNthDay")],
        metrics=[Metric(name="cohortActiveUsers")],
        cohort_spec=CohortSpec(
            cohorts=cohorts,
            cohorts_range=CohortsRange(
                granularity="DAILY", start_offset=0, end_offset=7
            ),
        ),
        limit=100000,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-cohort-date D1/D7 retention rows over the recent window.

    Ignores the engine's requested `start` and always recomputes the last
    `_WINDOW_DAYS` ending at `end`, so maturing cohorts refresh their D7.
    """
    from datetime import date, timedelta

    property_id = cfg.ga4_property_id_app or cfg.ga4_property_id_web
    end_d = date.fromisoformat(end)
    window_start = (end_d - timedelta(days=_WINDOW_DAYS - 1)).isoformat()
    resp = _run_cohort_report(property_id, window_start, end)
    return to_rows(parse_cohorts(resp))


SOURCE = DailySource(
    name="retention",
    filename="retention.csv",
    headers=_DAILY_HEADERS,
    required=("ga4_property_id_app",),
    fetch=fetch_daily,
    ready=lambda cfg: bool(cfg.ga4_property_id_app or cfg.ga4_property_id_web),
)
