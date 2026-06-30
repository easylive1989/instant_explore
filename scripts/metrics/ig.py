# scripts/metrics/ig.py
"""Instagram Graph API source: daily account insights + profile snapshot."""
from __future__ import annotations

from datetime import date, timedelta

import requests

from metrics._common import DailySource, MetricsConfig

_GRAPH = "https://graph.facebook.com/v21.0"
_DAILY_HEADERS = [
    "date", "reach", "profile_views", "followers_count", "media_count",
]


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


def _profile(cfg: MetricsConfig) -> dict:
    """Fetch the current follower / media-count snapshot."""
    return requests.get(
        f"{_GRAPH}/{cfg.ig_user_id}",
        params={"fields": "followers_count,media_count",
                "access_token": cfg.meta_page_access_token},
        timeout=30,
    ).json()


def _account_insights_day(cfg: MetricsConfig, day: str) -> dict:
    """Fetch one day's reach / profile_views as unambiguous daily totals.

    Querying ``[day, day+1)`` with ``metric_type=total_value`` returns the
    total for exactly that calendar day, sidestepping the timezone
    ambiguity of the time-series ``end_time`` boundaries.
    """
    nxt = (date.fromisoformat(day) + timedelta(days=1)).isoformat()
    return requests.get(
        f"{_GRAPH}/{cfg.ig_user_id}/insights",
        params={"metric": "reach,profile_views", "period": "day",
                "metric_type": "total_value", "since": day, "until": nxt,
                "access_token": cfg.meta_page_access_token},
        timeout=30,
    ).json()


def fetch_daily(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-day account metrics over [start, end], keyed by date.

    `reach` and `profile_views` are true daily totals; `followers_count`
    and `media_count` are only available as a live snapshot, so they are
    recorded against the latest day (`end`) and left blank for backfilled
    historical days.
    """
    profile = _profile(cfg)
    followers = str(profile.get("followers_count", ""))
    media = str(profile.get("media_count", ""))
    rows: list[list[str]] = []
    cursor = date.fromisoformat(start)
    last = date.fromisoformat(end)
    while cursor <= last:
        day = cursor.isoformat()
        totals = dict(parse_account_insights(_account_insights_day(cfg, day)))
        is_latest = day == end
        rows.append([
            day,
            totals.get("reach", ""),
            totals.get("profile_views", ""),
            followers if is_latest else "",
            media if is_latest else "",
        ])
        cursor += timedelta(days=1)
    return rows


SOURCE = DailySource(
    name="ig",
    filename="ig.csv",
    headers=_DAILY_HEADERS,
    required=("ig_user_id", "meta_page_access_token"),
    fetch=fetch_daily,
)
