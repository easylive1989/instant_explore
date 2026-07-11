"""render（HTML 產出）測試。"""
from lorescape_dashboard.render import (
    build_html,
    health_signals,
    sparkline_svg,
)

DATA = {
    "generated_at": "2026-07-11 21:30",
    "backlog": {
        "epics": [
            {
                "id": "E1", "title": "補齊漏斗上層流量", "status": "進行中",
                "goal": "流量到穩定兩位數/天",
                "checkpoints": [
                    {"date": "2026-08-04", "text": "2026-08-04 回顧", "done": False, "days_left": 24}
                ],
                "features_total": 7, "features_done": 6,
            }
        ],
        "pending_deploy": {
            "title": "⚠️ 待部署",
            "items": [{"done": False, "text": "**App**：重新 build 送審"}],
        },
        "features": [
            {
                "id": "F1", "title": "IG 導流 CTA", "epic": "E1",
                "status": "已完成", "done": True,
                "tasks": [{"done": True, "text": "T1: x"}],
                "tasks_done": 1, "tasks_total": 1,
            },
            {
                "id": "F9", "title": "景點 SEO 著陸頁", "epic": "E1",
                "status": "進行中（首批已上線 2026-07-09）", "done": False,
                "tasks": [
                    {"done": True, "text": "T1: 建 place 路由"},
                    {"done": False, "text": "T3: 回看 GSC"},
                ],
                "tasks_done": 1, "tasks_total": 2,
            },
        ],
    },
    "deploys": {
        "services": [
            {"service": "backend", "deployed_at": "2026-07-09T15:12:04Z",
             "commit": "252411a", "behind_master": 43, "run_url": "https://x/1"},
            {"service": "landing", "deployed_at": None, "commit": None,
             "behind_master": None, "run_url": None},
        ]
    },
    "tests": {
        "suites": [
            {"suite": "frontend", "total": 552, "passed": 552, "failed": 0,
             "skipped": 0, "duration_seconds": 62.0, "coverage_percent": 73.5,
             "analyze": {"ok": True, "summary": "No issues found!"}, "failures": []},
            {"suite": "backend", "total": 169, "passed": 168, "failed": 1,
             "skipped": 0, "duration_seconds": 1.0,
             "failures": [{"name": "tests.test_a::test_bad", "error": "assert 1 == 2"}]},
        ]
    },
    "e2e": {
        "groups": [
            {"group": "patrol (integration_test/)", "file": "integration_test/app_test.dart",
             "cases": ["generate narration success"]},
        ],
        "total": 1,
    },
    "metrics": {
        "tabs": [
            {
                "name": "gsc", "latest_date": "2026-07-08",
                "headers": ["date", "clicks", "impressions"],
                "stats": {
                    "clicks": {"latest": 0.0, "week_ago": 0.0, "delta": 0.0},
                    "impressions": {"latest": 3.0, "week_ago": 1.0, "delta": 2.0},
                },
                "recent_rows": [["2026-07-08", "0", "3"]],
                "rows_30d": [["2026-07-07", "0", "1"], ["2026-07-08", "0", "3"]],
            }
        ]
    },
    "daily_story": {
        "date": "2026-07-11",
        "posts": [
            {"media_type": "carousel", "status": "published",
             "published_at": "2026-07-11T00:42:48+00:00", "ig_post_id": "179",
             "scheduled_at": None, "error": None, "review_decision": "approved"},
        ],
        "all_published": True,
    },
    "errors": {},
}


class TestHealthSignals:
    def test_四個燈號(self):
        signals = health_signals(DATA)
        by_label = {s["label"]: s for s in signals}
        assert by_label["測試"]["level"] == "critical"  # 有 1 失敗
        assert "720/721" in by_label["測試"]["value"]
        assert by_label["部署"]["level"] == "warning"
        assert by_label["今日故事"]["level"] == "good"
        assert "24" in by_label["Epic 檢核"]["value"]

    def test_全綠情境(self):
        data = {
            **DATA,
            "tests": {"suites": [{**DATA["tests"]["suites"][0]}]},
            "deploys": {"services": [{**DATA["deploys"]["services"][0], "behind_master": 0}]},
        }
        by_label = {s["label"]: s for s in health_signals(data)}
        assert by_label["測試"]["level"] == "good"
        assert by_label["部署"]["level"] == "good"


class TestSparkline:
    def test_產生_svg_路徑(self):
        svg = sparkline_svg([("2026-07-07", 1.0), ("2026-07-08", 3.0)])
        assert "<svg" in svg and "polyline" in svg

    def test_單點或無點回空字串(self):
        assert sparkline_svg([("2026-07-08", 3.0)]) == ""
        assert sparkline_svg([]) == ""


class TestBuildHtml:
    def test_含各區塊與資料(self):
        html = build_html(DATA)
        for text in [
            "產品面板", "2026-07-11 21:30",  # 標題與時間
            "E1", "倒數 24 天",              # epic
            "F9", "景點 SEO 著陸頁",          # 看板卡
            "backend", "落後 43",             # 部署
            "552/552", "test_bad",            # 測試與失敗
            "generate narration success",     # e2e
            "impressions",                    # metrics
            "carousel",                       # daily story
        ]:
            assert text in html, text

    def test_看板_已完成與進行中分欄(self):
        html = build_html(DATA)
        assert "進行中" in html and "已完成" in html

    def test_區塊錯誤顯示錯誤卡(self):
        data = {**DATA, "metrics": None, "errors": {"metrics": "no credentials"}}
        assert "no credentials" in build_html(data)

    def test_html_跳脫(self):
        data = {
            **DATA,
            "tests": {
                "suites": [
                    {**DATA["tests"]["suites"][1],
                     "failures": [{"name": "t<script>", "error": "a<b & c"}]}
                ]
            },
        }
        html = build_html(data)
        assert "t<script>" not in html
        assert "t&lt;script&gt;" in html
