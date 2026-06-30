# scripts/metrics/revenuecat.py
"""RevenueCat v2 source: a daily snapshot of the project's overview metrics.

RevenueCat's public API exposes only the *current* overview metrics — MRR,
active subscriptions/trials, and 28-day active users / new customers /
revenue / installs — with no daily historical time series. So this source
is a snapshot: each run records the live reading once, stamped against the
target day (`end`), and missed days cannot be recovered. The single row is
keyed by date so re-running on the same day overwrites it.
"""
from __future__ import annotations

import requests

from metrics._common import DailySource, MetricsConfig

_API = "https://api.revenuecat.com/v2"

# Overview metric ids (left) mapped to their sheet column (right). This is
# RevenueCat's full overview set; unknown extras are ignored and missing
# ones are left blank, so the column layout stays stable across runs.
_METRICS: list[tuple[str, str]] = [
    ("mrr", "mrr"),
    ("active_subscriptions", "active_subscriptions"),
    ("active_trials", "active_trials"),
    ("active_users", "active_users_28d"),
    ("new_customers", "new_customers_28d"),
    ("revenue", "revenue_28d"),
]
_DAILY_HEADERS = ["date", *[column for _, column in _METRICS]]


def parse_overview(resp: dict) -> dict[str, str]:
    """Map an overview response into ``{metric_id: value_as_str}``."""
    out: dict[str, str] = {}
    for metric in resp.get("metrics", []):
        metric_id = metric.get("id", "")
        if not metric_id:
            continue
        value = metric.get("value", "")
        out[metric_id] = "" if value is None else str(value)
    return out


def _overview(cfg: MetricsConfig) -> dict:
    """Fetch the current overview metrics for the configured project."""
    resp = requests.get(
        f"{_API}/projects/{cfg.revenuecat_project_id}/metrics/overview",
        headers={"Authorization": f"Bearer {cfg.revenuecat_api_key}",
                 "Accept": "application/json"},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def fetch_snapshot(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return a single overview-snapshot row keyed by `end`.

    `start` is ignored: the API only reports the live "now" reading, which is
    recorded against the target day so it lines up with the other tabs.
    """
    values = parse_overview(_overview(cfg))
    row = [end]
    row.extend(values.get(metric_id, "") for metric_id, _ in _METRICS)
    return [row]


SOURCE = DailySource(
    name="revenuecat",
    filename="revenuecat.csv",
    headers=_DAILY_HEADERS,
    required=("revenuecat_api_key", "revenuecat_project_id"),
    fetch=fetch_snapshot,
    snapshot=True,
)
