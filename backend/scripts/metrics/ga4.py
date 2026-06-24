# backend/scripts/metrics/ga4.py
"""GA4 Data API source for landing (web) and app properties."""
from __future__ import annotations

from scripts.metrics._common import MetricsConfig, SourceResult

_HEADERS = ["stream", "source_medium", "active_users", "new_users"]


def parse_run_report(resp: dict, label: str) -> list[list[str]]:
    """Map a runReport response dict into labelled string rows."""
    rows: list[list[str]] = []
    for row in resp.get("rows", []):
        dims = [d.get("value", "") for d in row.get("dimensionValues", [])]
        mets = [m.get("value", "") for m in row.get("metricValues", [])]
        rows.append([label, *dims, *mets])
    return rows


def _run_report(property_id: str, start: str, end: str) -> dict:
    """Call the GA4 Data API and return a plain dict (lazy import)."""
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest,
    )
    from google.protobuf.json_format import MessageToDict

    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start, end_date=end)],
        dimensions=[Dimension(name="sessionSourceMedium")],
        metrics=[Metric(name="activeUsers"), Metric(name="newUsers")],
        limit=25,
    )
    return MessageToDict(client.run_report(request)._pb)


def fetch_ga4(cfg: MetricsConfig, start: str, end: str) -> SourceResult:
    """Fetch active/new users by source-medium for each GA4 property."""
    properties = [
        ("web", cfg.ga4_property_id_web),
        ("app", cfg.ga4_property_id_app),
    ]
    configured = [(label, pid) for label, pid in properties if pid]
    if not configured:
        return SourceResult.skipped(
            "ga4", "missing GA4_PROPERTY_ID_WEB/APP in .env"
        )

    rows: list[list[str]] = []
    summary: list[str] = []
    errors = 0
    for label, pid in configured:
        try:
            resp = _run_report(pid, start, end)
        except Exception as exc:
            errors += 1
            summary.append(f"{label}: API error: {exc}")
            continue
        prop_rows = parse_run_report(resp, label)
        rows.extend(prop_rows)
        users = sum(int(r[2]) for r in prop_rows if r[2].isdigit())
        summary.append(f"{label} active users {users}（{len(prop_rows)} 來源）")

    if errors == len(configured):
        return SourceResult.skipped("ga4", "; ".join(summary))
    return SourceResult(
        name="ga4", ok=True, summary_lines=summary,
        csv_headers=_HEADERS, csv_rows=rows,
    )
