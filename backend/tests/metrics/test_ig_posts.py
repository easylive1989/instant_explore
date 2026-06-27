# backend/tests/metrics/test_ig_posts.py
from __future__ import annotations

from scripts.metrics import ig_posts
from scripts.metrics._common import MetricsConfig


REEL = {
    "id": "111",
    "permalink": "https://instagram.com/p/aaa",
    "timestamp": "2026-06-22T10:00:00+0000",
    "media_type": "VIDEO",
    "media_product_type": "REELS",
    "caption": "line one\nline two",
    "like_count": 30,
    "comments_count": 4,
}
IMAGE = {
    "id": "222",
    "permalink": "https://instagram.com/p/bbb",
    "timestamp": "2026-06-23T10:00:00+0000",
    "media_type": "IMAGE",
    "media_product_type": "FEED",
    "caption": "a photo",
    "like_count": 12,
    "comments_count": 1,
}
CORE = {
    "data": [
        {"name": "reach", "values": [{"value": 900}]},
        {"name": "saved", "values": [{"value": 7}]},
        {"name": "shares", "values": [{"value": 3}]},
        {"name": "total_interactions", "values": [{"value": 44}]},
    ]
}
VIDEO = {
    "data": [
        {"name": "plays", "values": [{"value": 1200}]},
        {"name": "ig_reels_avg_watch_time", "values": [{"value": 5400}]},
    ]
}


def test_is_video_detects_reels_and_video():
    assert ig_posts.is_video(REEL) is True
    assert ig_posts.is_video(IMAGE) is False


def test_insights_map_flattens_metrics():
    out = ig_posts.insights_map(CORE)
    assert out == {"reach": "900", "saved": "7", "shares": "3",
                   "total_interactions": "44"}


def test_parse_media_list_returns_items_and_cursor():
    resp = {"data": [REEL], "paging": {"next": "http://next",
                                       "cursors": {"after": "CUR"}}}
    items, after = ig_posts.parse_media_list(resp)
    assert items == [REEL]
    assert after == "CUR"


def test_parse_media_list_no_next_yields_none_cursor():
    resp = {"data": [REEL], "paging": {"cursors": {"after": "CUR"}}}
    _, after = ig_posts.parse_media_list(resp)
    assert after is None


def test_build_row_for_reel_includes_video_metrics():
    row = ig_posts.build_row(REEL, ig_posts.insights_map(CORE),
                             ig_posts.insights_map(VIDEO))
    assert row[0] == "111"
    assert row[1] == "2026-06-22"
    assert row[2] == "REELS"
    assert row[4] == "line one line two"  # newlines collapsed
    assert row[5] == "900"   # reach
    assert row[6] == "30"    # likes from media field
    assert row[11] == "1200"  # plays
    assert row[12] == "5400"  # avg_watch_time


def test_build_row_for_image_blanks_video_metrics():
    row = ig_posts.build_row(IMAGE, ig_posts.insights_map(CORE), {})
    assert row[2] == "IMAGE"
    assert row[11] == ""  # plays blank for non-video
    assert row[12] == ""


def test_media_in_window_stops_paging_past_start(monkeypatch):
    pages = [
        {"data": [IMAGE, REEL],
         "paging": {"next": "n", "cursors": {"after": "C1"}}},
        {"data": [{"id": "000", "timestamp": "2026-06-01T00:00:00+0000",
                   "media_type": "IMAGE", "media_product_type": "FEED"}],
         "paging": {}},
    ]
    calls = {"i": 0}

    def fake_page(cfg, after):
        page = pages[calls["i"]]
        calls["i"] += 1
        return page

    monkeypatch.setattr(ig_posts, "_media_page", fake_page)
    cfg = MetricsConfig(ig_user_id="1", meta_page_access_token="t")
    out = ig_posts.media_in_window(cfg, "2026-06-20", "2026-06-23")
    ids = [m["id"] for m in out]
    assert ids == ["222", "111"]  # old 000 excluded, paging stopped


def test_fetch_posts_degrades_on_insight_error(monkeypatch):
    monkeypatch.setattr(ig_posts, "media_in_window",
                        lambda cfg, s, e: [IMAGE])

    def boom(cfg, media_id, metrics):
        raise RuntimeError("api down")

    monkeypatch.setattr(ig_posts, "_media_insights", boom)
    cfg = MetricsConfig(ig_user_id="1", meta_page_access_token="t")
    rows = ig_posts.fetch_posts(cfg, "2026-06-20", "2026-06-23")
    assert len(rows) == 1
    assert rows[0][0] == "222"
    assert rows[0][5] == ""  # reach blank after failure
    assert rows[0][6] == "12"  # likes still from media field


def test_source_descriptor_is_media_keyed():
    assert ig_posts.SOURCE.name == "ig_posts"
    assert ig_posts.SOURCE.keyed_by_date is False
    assert ig_posts.SOURCE.key_index == 0
