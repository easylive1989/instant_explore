# backend/scripts/metrics/ig.py
"""Instagram Graph API source (account insights + profile)."""
from __future__ import annotations

import requests

from scripts.metrics._common import MetricsConfig, SourceResult

_GRAPH = "https://graph.facebook.com/v21.0"
_HEADERS = ["metric", "value"]


def parse_account_insights(resp: dict) -> list[list[str]]:
    """Map an IG account insights response into [metric, value] rows.

    Handles both the time-series shape (``values``) and the newer
    ``total_value`` shape returned when ``metric_type=total_value``.
    """
    rows: list[list[str]] = []
    for item in resp.get("data", []):
        if "total_value" in item:
            value = item["total_value"].get("value", "")
        else:
            values = item.get("values", [])
            value = values[0].get("value", "") if values else ""
        rows.append([item.get("name", ""), str(value)])
    return rows


def parse_profile(resp: dict) -> list[str]:
    """Summary lines for follower / media counts."""
    return [
        f"粉絲數 {resp.get('followers_count', 'n/a')}",
        f"貼文數 {resp.get('media_count', 'n/a')}",
    ]


def fetch_ig(cfg: MetricsConfig, start: str, end: str) -> SourceResult:
    """Fetch IG profile + account reach/profile_views for the period."""
    if not (cfg.ig_user_id and cfg.meta_page_access_token):
        return SourceResult.skipped(
            "ig", "missing IG_USER_ID / META_PAGE_ACCESS_TOKEN in .env"
        )
    token = cfg.meta_page_access_token
    uid = cfg.ig_user_id
    try:
        profile = requests.get(
            f"{_GRAPH}/{uid}",
            params={"fields": "followers_count,media_count",
                    "access_token": token},
            timeout=30,
        ).json()
        insights = requests.get(
            f"{_GRAPH}/{uid}/insights",
            params={"metric": "reach,profile_views", "period": "day",
                    "metric_type": "total_value",
                    "since": start, "until": end, "access_token": token},
            timeout=30,
        ).json()
    except Exception as exc:
        return SourceResult.skipped("ig", f"API error: {exc}")

    if "error" in profile or "error" in insights:
        err = profile.get("error") or insights.get("error")
        return SourceResult.skipped("ig", f"Graph API error: {err}")

    rows = parse_account_insights(insights)
    return SourceResult(
        name="ig", ok=True,
        summary_lines=parse_profile(profile),
        csv_headers=_HEADERS, csv_rows=rows,
    )
