# scripts/metrics/ig_posts.py
"""Instagram per-post (media) metrics: core interactions + Reels video."""
from __future__ import annotations

import requests

from metrics._common import DailySource, MetricsConfig

_GRAPH = "https://graph.facebook.com/v21.0"
_HEADERS = [
    "media_id", "date", "type", "permalink", "caption",
    "reach", "likes", "comments", "saved", "shares", "total_interactions",
    "views", "avg_watch_time",
]
_MEDIA_FIELDS = (
    "id,permalink,timestamp,media_type,media_product_type,"
    "caption,like_count,comments_count"
)
_CORE_METRICS = "reach,saved,shares,total_interactions"
# Graph API v21 dropped `plays`; `views` is the reel play count.
_VIDEO_METRICS = "views,ig_reels_avg_watch_time"
_CAPTION_LIMIT = 80


def is_video(media: dict) -> bool:
    """Whether a media item is a reel or other video (has play metrics)."""
    return (media.get("media_product_type") == "REELS"
            or media.get("media_type") == "VIDEO")


def insights_map(resp: dict) -> dict[str, str]:
    """Flatten a media-insights response into ``{metric: value}``.

    Handles both the ``total_value`` and time-series ``values`` shapes.
    """
    out: dict[str, str] = {}
    for item in resp.get("data", []):
        if "total_value" in item:
            value = item["total_value"].get("value", "")
        else:
            values = item.get("values", [])
            value = values[0].get("value", "") if values else ""
        out[item.get("name", "")] = str(value)
    return out


def parse_media_list(resp: dict) -> tuple[list[dict], str | None]:
    """Return (media items, next-page cursor) from a media-edge response."""
    items = resp.get("data", [])
    after = resp.get("paging", {}).get("cursors", {}).get("after")
    next_page = resp.get("paging", {}).get("next")
    return items, (after if next_page else None)


def build_row(media: dict, core: dict[str, str],
              video: dict[str, str]) -> list[str]:
    """Assemble one CSV row for a media item from its fields + insights."""
    media_type = ("REELS" if media.get("media_product_type") == "REELS"
                  else media.get("media_type", ""))
    caption = (media.get("caption") or "").replace("\n", " ").strip()
    video_post = is_video(media)
    return [
        media.get("id", ""),
        (media.get("timestamp") or "")[:10],
        media_type,
        media.get("permalink", ""),
        caption[:_CAPTION_LIMIT],
        core.get("reach", ""),
        str(media.get("like_count", "")),
        str(media.get("comments_count", "")),
        core.get("saved", ""),
        core.get("shares", ""),
        core.get("total_interactions", ""),
        video.get("views", "") if video_post else "",
        video.get("ig_reels_avg_watch_time", "") if video_post else "",
    ]


def _media_page(cfg: MetricsConfig, after: str | None) -> dict:
    """Fetch one page of the account's media edge (newest first)."""
    params = {"fields": _MEDIA_FIELDS, "limit": 50,
              "access_token": cfg.meta_page_access_token}
    if after:
        params["after"] = after
    return requests.get(
        f"{_GRAPH}/{cfg.ig_user_id}/media", params=params, timeout=30,
    ).json()


def _media_insights(cfg: MetricsConfig, media_id: str, metrics: str) -> dict:
    """Fetch the named insight metrics for a single media item."""
    return requests.get(
        f"{_GRAPH}/{media_id}/insights",
        params={"metric": metrics,
                "access_token": cfg.meta_page_access_token},
        timeout=30,
    ).json()


def media_in_window(cfg: MetricsConfig, start: str, end: str) -> list[dict]:
    """Page the media edge collecting items posted within [start, end].

    Media come newest-first, so paging stops once an item predates `start`.
    """
    collected: list[dict] = []
    after: str | None = None
    while True:
        items, after = parse_media_list(_media_page(cfg, after))
        stop = False
        for media in items:
            day = (media.get("timestamp") or "")[:10]
            if day < start:
                stop = True
                break
            if day <= end:
                collected.append(media)
        if stop or not after:
            break
    return collected


def fetch_posts(cfg: MetricsConfig, start: str, end: str) -> list[list[str]]:
    """Return per-post rows for media published within [start, end].

    Each post's core interactions are always fetched; videos/reels add
    play metrics. A per-post insights failure degrades to blank metrics
    rather than dropping the whole batch.
    """
    rows: list[list[str]] = []
    for media in media_in_window(cfg, start, end):
        media_id = media.get("id", "")
        try:
            core = insights_map(_media_insights(cfg, media_id, _CORE_METRICS))
        except Exception:
            core = {}
        video: dict[str, str] = {}
        if is_video(media):
            try:
                video = insights_map(
                    _media_insights(cfg, media_id, _VIDEO_METRICS)
                )
            except Exception:
                video = {}
        rows.append(build_row(media, core, video))
    return rows


SOURCE = DailySource(
    name="ig_posts",
    filename="ig_posts.csv",
    headers=_HEADERS,
    required=("ig_user_id", "meta_page_access_token"),
    fetch=fetch_posts,
    key_index=0,
    keyed_by_date=False,
)
