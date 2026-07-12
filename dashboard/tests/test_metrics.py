"""metrics collector 的整形測試。"""
from datetime import date

from lorescape_dashboard.collectors.metrics import (
    shape_ig_posts,
    shape_ig_reels,
    shape_tab,
)

VALUES = [
    ["date", "clicks", "impressions", "note"],
    ["2026-06-01", "1", "10", "old"],
    ["2026-07-04", "2", "20", ""],
    ["2026-07-09", "4", "38", ""],
    ["2026-07-10", "5", "50", "x"],
]

TODAY = date(2026, 7, 11)


class TestShapeTab:
    def test_最新值與一週前差異(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert tab["name"] == "gsc"
        assert tab["latest_date"] == "2026-07-10"
        clicks = tab["stats"]["clicks"]
        assert clicks["latest"] == 5.0
        # 一週前 = 2026-07-03，取當日或之前最近一列 → 2026-06-01
        assert clicks["week_ago"] == 1.0
        assert clicks["delta"] == 4.0

    def test_非數值欄位不進統計(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert "note" not in tab["stats"]

    def test_近七列供表格顯示_新到舊(self):
        tab = shape_tab("gsc", VALUES, today=TODAY, days=60)
        assert tab["headers"] == ["date", "clicks", "impressions", "note"]
        assert [r[0] for r in tab["recent_rows"]] == [
            "2026-07-10", "2026-07-09", "2026-07-04", "2026-06-01",
        ]

    def test_預設三十天窗排除更舊的列(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert [r[0] for r in tab["recent_rows"]] == [
            "2026-07-10", "2026-07-09", "2026-07-04",
        ]

    def test_rows_30d_為窗內全列_舊到新(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert [r[0] for r in tab["rows_30d"]] == [
            "2026-07-04", "2026-07-09", "2026-07-10",
        ]

    def test_只留近三十天的資料算統計(self):
        # 6/1 在 30 天外 → week_ago 找不到 30 天內更早的列時仍可用界外列補
        tab = shape_tab("gsc", VALUES, today=TODAY, days=7)
        assert [r[0] for r in tab["recent_rows"]] == ["2026-07-10", "2026-07-09", "2026-07-04"]

    def test_空分頁回_none(self):
        assert shape_tab("gsc", [], today=TODAY) is None
        assert shape_tab("gsc", [["date", "clicks"]], today=TODAY) is None

    def test_無效值容忍(self):
        values = [["date", "v"], ["2026-07-10", ""], ["2026-07-09", "3"]]
        tab = shape_tab("x", values, today=TODAY)
        assert tab["stats"]["v"]["latest"] is None


IG_POSTS = [
    ["media_id", "obs_date", "posted_date", "type", "permalink", "caption",
     "reach", "likes", "comments", "saved", "shares", "total_interactions",
     "views", "avg_watch_time"],
    ["111", "2026-07-09", "2026-07-03", "CAROUSEL_ALBUM", "https://ig/p/a", "紹修書院",
     "5", "2", "0", "0", "0", "2", "", ""],
    ["111", "2026-07-11", "2026-07-03", "CAROUSEL_ALBUM", "https://ig/p/a", "紹修書院",
     "8", "3", "0", "0", "0", "3", "", ""],
    ["222", "2026-07-11", "2026-07-08", "REELS", "https://ig/reel/b", "姬路城",
     "338", "6", "0", "0", "0", "6", "470", "7000"],
]


IG_REELS = [
    ["media_id", "checkpoint", "obs_date", "posted_date", "permalink", "caption",
     "views", "skip_rate_pct", "like_rate_pct"],
    ["901", "24h", "2026-07-06", "2026-07-05", "https://ig/reel/a", "康沃爾",
     "120", "60.0", "1.0"],
    ["901", "7d", "2026-07-12", "2026-07-05", "https://ig/reel/a", "康沃爾",
     "214", "63.7", "0.0"],
    ["902", "24h", "2026-07-12", "2026-07-11", "https://ig/reel/b", "富士山",
     "165", "68.2", "1.4"],
]


class TestShapeIgReels:
    def test_每支_reel_併成一列_各_checkpoint_一組(self):
        reels = shape_ig_reels(IG_REELS)
        cornwall = next(r for r in reels if r["media_id"] == "901")
        assert cornwall["caption"] == "康沃爾"
        assert cornwall["checkpoints"]["24h"]["views"] == "120"
        assert cornwall["checkpoints"]["7d"]["skip_rate_pct"] == "63.7"

    def test_缺的_checkpoint_不出現(self):
        reels = shape_ig_reels(IG_REELS)
        cornwall = next(r for r in reels if r["media_id"] == "901")
        assert "48h" not in cornwall["checkpoints"]

    def test_依發布日新到舊排序(self):
        reels = shape_ig_reels(IG_REELS)
        assert [r["posted_date"] for r in reels] == ["2026-07-11", "2026-07-05"]

    def test_空資料回空列表(self):
        assert shape_ig_reels([]) == []
        assert shape_ig_reels([IG_REELS[0]]) == []


class TestShapeIgPosts:
    def test_每貼文只留最新觀測日快照(self):
        posts = shape_ig_posts(IG_POSTS)
        assert len(posts) == 2
        first = next(p for p in posts if p["media_id"] == "111")
        assert first["obs_date"] == "2026-07-11"
        assert first["reach"] == "8"

    def test_依發文日新到舊排序(self):
        posts = shape_ig_posts(IG_POSTS)
        assert [p["posted_date"] for p in posts] == ["2026-07-08", "2026-07-03"]

    def test_空資料回空列表(self):
        assert shape_ig_posts([]) == []
        assert shape_ig_posts([IG_POSTS[0]]) == []
