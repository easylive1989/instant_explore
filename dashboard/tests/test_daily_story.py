"""daily_story collector 測試。"""
from datetime import date

import requests_mock as rm_lib

from lorescape_dashboard.collectors.daily_story import fetch_today, shape_posts

TODAY = date(2026, 7, 11)


class TestShapePosts:
    def test_無_row_表示今日尚未產生(self):
        result = shape_posts([], TODAY)
        assert result == {
            "date": "2026-07-11",
            "posts": [],
            "all_published": False,
        }

    def test_彙整各媒材狀態(self):
        rows = [
            {
                "media_type": "carousel",
                "status": "published",
                "review_decision": "approved",
                "scheduled_at": "2026-07-11T13:00:00+00:00",
                "published_at": "2026-07-11T13:00:05+00:00",
                "ig_post_id": "179xx",
                "error": None,
            },
            {
                "media_type": "reel",
                "status": "pending",
                "review_decision": None,
                "scheduled_at": None,
                "published_at": None,
                "ig_post_id": None,
                "error": None,
            },
        ]
        result = shape_posts(rows, TODAY)
        assert result["all_published"] is False
        carousel = result["posts"][0]
        assert carousel["media_type"] == "carousel"
        assert carousel["status"] == "published"
        assert carousel["published_at"] == "2026-07-11T13:00:05+00:00"

    def test_全部發布才算_all_published(self):
        rows = [
            {"media_type": "carousel", "status": "published"},
            {"media_type": "reel", "status": "published"},
        ]
        assert shape_posts(rows, TODAY)["all_published"] is True


class TestFetchToday:
    def test_打_supabase_rest_並回傳_rows(self, requests_mock: rm_lib.Mocker):
        requests_mock.get(
            "https://xyz.supabase.co/rest/v1/social_posts",
            json=[{"media_type": "carousel", "status": "pending"}],
        )
        rows = fetch_today(
            "https://xyz.supabase.co", "service-key", TODAY
        )
        assert rows == [{"media_type": "carousel", "status": "pending"}]
        req = requests_mock.request_history[0]
        assert req.qs["publish_date"] == ["eq.2026-07-11"]
        assert req.headers["apikey"] == "service-key"
