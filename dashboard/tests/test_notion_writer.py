"""notion_writer 的 blocks 組裝與整頁重寫測試。"""
import requests_mock as rm_lib

from lorescape_dashboard.notion_writer import build_blocks, update_page

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
                "id": "F9", "title": "景點 SEO 著陸頁", "epic": "E1",
                "status": "進行中", "done": False,
                "tasks": [
                    {"done": True, "text": "T1: 建 place 路由"},
                    {"done": False, "text": "T3: 回看 GSC"},
                ],
                "tasks_done": 1, "tasks_total": 2,
            }
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
             "skipped": 0, "duration_seconds": 180.0, "coverage_percent": 71.2,
             "analyze": {"ok": True, "summary": "No issues found!"}, "failures": []},
            {"suite": "backend", "total": 415, "passed": 414, "failed": 1,
             "skipped": 0, "duration_seconds": 30.0,
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


def _types(blocks):
    return [b["type"] for b in blocks]


class TestBuildBlocks:
    def test_頂部為健康燈號_column_list(self):
        blocks = build_blocks(DATA)
        assert blocks[0]["type"] == "column_list"
        columns = blocks[0]["column_list"]["children"]
        assert len(columns) >= 3
        assert all(c["type"] == "column" for c in columns)

    def test_含所有區塊標題(self):
        blocks = build_blocks(DATA)
        headings = [
            b["heading_1"]["rich_text"][0]["text"]["content"]
            for b in blocks
            if b["type"] == "heading_1"
        ]
        joined = "".join(headings)
        for keyword in ["Epic", "Backlog", "部署", "測試", "E2E", "產品數據", "每日故事"]:
            assert keyword in joined, keyword

    def test_表格_ragged_rows_補齊到表寬(self):
        # Sheets API 會裁掉尾端空欄；metrics recent_rows 可能比 headers 短
        data = {
            **DATA,
            "metrics": {
                "tabs": [
                    {
                        "name": "stores", "latest_date": "2026-07-10",
                        "headers": ["date", "a", "b", "note"],
                        "stats": {"a": {"latest": 1.0, "week_ago": None, "delta": None}},
                        "recent_rows": [["2026-07-10", "1"], ["2026-07-09", "1", "2", "n", "extra"]],
                    }
                ]
            },
        }
        blocks = build_blocks(data)
        tables = [b for b in blocks if b["type"] == "table"]
        stores = tables[-1]
        for row in stores["table"]["children"]:
            assert len(row["table_row"]["cells"]) == 4

    def test_部署表格寬度與服務數(self):
        blocks = build_blocks(DATA)
        table = next(b for b in blocks if b["type"] == "table")
        assert table["table"]["table_width"] == 4
        # header + 2 services
        assert len(table["table"]["children"]) == 3

    def test_backlog_feature_是_toggle_含_to_do(self):
        blocks = build_blocks(DATA)
        toggle = next(b for b in blocks if b["type"] == "toggle")
        children = toggle["toggle"]["children"]
        assert children[0]["type"] == "to_do"
        assert children[0]["to_do"]["checked"] is True

    def test_失敗測試列出名稱(self):
        blocks = build_blocks(DATA)
        texts = [
            rt["text"]["content"]
            for b in blocks
            if b["type"] == "bulleted_list_item"
            for rt in b["bulleted_list_item"]["rich_text"]
        ]
        assert any("test_bad" in t for t in texts)

    def test_區塊錯誤時顯示錯誤_callout(self):
        data = {**DATA, "metrics": None, "errors": {"metrics": "no credentials"}}
        blocks = build_blocks(data)
        callouts = [
            rt["text"]["content"]
            for b in blocks
            if b["type"] == "callout"
            for rt in b["callout"]["rich_text"]
        ]
        assert any("no credentials" in t for t in callouts)


class TestUpdatePage:
    def test_先清空再分批_append(self, requests_mock: rm_lib.Mocker):
        page_id = "39a8303f78f780f3bdc4d8e3eb1545a1"
        requests_mock.get(
            f"https://api.notion.com/v1/blocks/{page_id}/children",
            json={"results": [{"id": "b1"}, {"id": "b2"}], "has_more": False},
        )
        requests_mock.delete(rm_lib.ANY, json={})
        requests_mock.patch(
            f"https://api.notion.com/v1/blocks/{page_id}/children", json={}
        )

        blocks = [{"type": "paragraph", "paragraph": {"rich_text": []}}] * 90
        update_page("tok", page_id, blocks, chunk_size=40)

        deletes = [r for r in requests_mock.request_history if r.method == "DELETE"]
        appends = [r for r in requests_mock.request_history if r.method == "PATCH"]
        assert len(deletes) == 2
        assert len(appends) == 3  # 90 / 40 → 40+40+10
        assert appends[0].headers["Authorization"] == "Bearer tok"
        assert "Notion-Version" in appends[0].headers
