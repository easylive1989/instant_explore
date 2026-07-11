"""notion_writer 的 blocks 組裝、feature 屬性映射與頁面同步測試。"""
import requests_mock as rm_lib

from lorescape_dashboard.notion_writer import (
    NotionClient,
    build_backlog_blocks,
    build_main_blocks,
    build_metrics_blocks,
    build_tests_blocks,
    feature_properties,
    metrics_db_properties,
    metrics_row_properties,
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


def _texts(blocks):
    out = []
    for b in blocks:
        payload = b.get(b["type"], {})
        for rt in payload.get("rich_text", []):
            out.append(rt["text"]["content"])
    return out


class TestBuildMainBlocks:
    def test_頂部為健康燈號_column_list(self):
        blocks = build_main_blocks(DATA)
        assert blocks[0]["type"] == "column_list"
        assert len(blocks[0]["column_list"]["children"]) >= 3

    def test_主頁只含總覽_部署_每日故事(self):
        blocks = build_main_blocks(DATA)
        joined = "".join(_texts(blocks))
        assert "部署狀態" in joined
        assert "每日故事" in joined
        assert "F9" not in joined  # backlog 細節不在主頁
        assert "gsc" not in joined  # metrics 細節不在主頁

    def test_部署表格寬度與服務數(self):
        blocks = build_main_blocks(DATA)
        table = next(b for b in blocks if b["type"] == "table")
        assert table["table"]["table_width"] == 4
        assert len(table["table"]["children"]) == 3  # header + 2 services


class TestBuildBacklogBlocks:
    def test_含_epic_進度與待部署(self):
        joined = "".join(_texts(build_backlog_blocks(DATA)))
        assert "E1" in joined
        assert "倒數 24 天" in joined
        assert "待部署" in joined

    def test_無資料時顯示錯誤_callout(self):
        data = {**DATA, "backlog": None, "errors": {"backlog": "boom"}}
        joined = "".join(_texts(build_backlog_blocks(data)))
        assert "boom" in joined


class TestBuildTestsBlocks:
    def test_統計表_失敗清單_e2e_案例(self):
        blocks = build_tests_blocks(DATA)
        joined = "".join(_texts(blocks))
        assert "test_bad" in joined
        assert "generate narration success" in joined
        table = next(b for b in blocks if b["type"] == "table")
        assert len(table["table"]["children"]) == 3  # header + 2 suites


class TestBuildMetricsBlocks:
    def test_數字卡_無表格_表格由_database_取代(self):
        blocks = build_metrics_blocks(DATA)
        assert any(b["type"] == "column_list" for b in blocks)
        assert not any(b["type"] == "table" for b in blocks)


class TestMetricsDb:
    def test_schema_數值欄為_number_note_為文字(self):
        props = metrics_db_properties(["date", "clicks", "note"])
        assert props["日期"] == {"title": {}}
        assert props["clicks"] == {"number": {}}
        assert props["note"] == {"rich_text": {}}

    def test_row_properties(self):
        props = metrics_row_properties(
            ["date", "clicks", "ctr", "note"], ["2026-07-10", "3", "0.50%", "hi"]
        )
        assert props["日期"]["title"][0]["text"]["content"] == "2026-07-10"
        assert props["clicks"]["number"] == 3.0
        assert props["ctr"]["number"] == 0.5
        assert props["note"]["rich_text"][0]["text"]["content"] == "hi"

    def test_ragged_row_缺欄與空值跳過(self):
        props = metrics_row_properties(["date", "clicks", "note"], ["2026-07-10", ""])
        assert "clicks" not in props
        assert "note" not in props


class TestFeatureProperties:
    def test_屬性映射(self):
        props = feature_properties(DATA["backlog"]["features"][0], "2026-07")
        assert props["Feature"]["title"][0]["text"]["content"] == "景點 SEO 著陸頁"
        assert props["編號"]["rich_text"][0]["text"]["content"] == "F9"
        assert props["編號數"]["number"] == 9
        assert props["Epic"]["select"]["name"] == "E1"
        assert props["狀態"]["select"]["name"] == "進行中"
        assert props["進度"]["rich_text"][0]["text"]["content"] == "1/2"

    def test_無_epic_時不設_select(self):
        feature = {**DATA["backlog"]["features"][0], "epic": None}
        assert feature_properties(feature, "2026-07")["Epic"] == {"select": None}

    def test_sprint_未完成跟著當前月(self):
        props = feature_properties(
            DATA["backlog"]["features"][0], "2026-08", existing_sprint="2026-07"
        )
        assert props["Sprint"]["select"]["name"] == "2026-08"
        assert props["本期"]["checkbox"] is True

    def test_本期_已完成過月後為_false(self):
        feature = {**DATA["backlog"]["features"][0], "done": True, "status": "已完成"}
        props = feature_properties(feature, "2026-08", existing_sprint="2026-07")
        assert props["本期"]["checkbox"] is False

    def test_sprint_已完成鎖在完成月_從狀態文字解析(self):
        feature = {
            **DATA["backlog"]["features"][0],
            "done": True, "status": "已完成（2026-06-08，全部子步驟完成）",
        }
        props = feature_properties(feature, "2026-07")
        assert props["Sprint"]["select"]["name"] == "2026-06"

    def test_sprint_已完成且既有值時不改動(self):
        feature = {**DATA["backlog"]["features"][0], "done": True, "status": "已完成"}
        props = feature_properties(feature, "2026-08", existing_sprint="2026-07")
        assert props["Sprint"]["select"]["name"] == "2026-07"

    def test_sprint_已完成無日期無既有值用當前月(self):
        feature = {**DATA["backlog"]["features"][0], "done": True, "status": "已完成"}
        props = feature_properties(feature, "2026-07")
        assert props["Sprint"]["select"]["name"] == "2026-07"


class TestNotionClient:
    def test_wipe_content_保留子頁面與資料庫(self, requests_mock: rm_lib.Mocker):
        requests_mock.get(
            "https://api.notion.com/v1/blocks/p1/children",
            json={
                "results": [
                    {"id": "b1", "type": "paragraph"},
                    {"id": "b2", "type": "child_page"},
                    {"id": "b3", "type": "child_database"},
                    {"id": "b4", "type": "table"},
                ],
                "has_more": False,
            },
        )
        requests_mock.delete(rm_lib.ANY, json={})
        NotionClient("tok").wipe_content("p1")
        deleted = [
            r.url.split("/")[-1]
            for r in requests_mock.request_history
            if r.method == "DELETE"
        ]
        assert deleted == ["b1", "b4"]

    def test_append_分批(self, requests_mock: rm_lib.Mocker):
        requests_mock.patch(
            "https://api.notion.com/v1/blocks/p1/children", json={}
        )
        blocks = [{"type": "paragraph", "paragraph": {"rich_text": []}}] * 90
        NotionClient("tok").append("p1", blocks, chunk_size=40)
        appends = [r for r in requests_mock.request_history if r.method == "PATCH"]
        assert len(appends) == 3
        assert appends[0].headers["Authorization"] == "Bearer tok"
        assert "Notion-Version" in appends[0].headers

    def test_find_child_page_以標題比對(self, requests_mock: rm_lib.Mocker):
        requests_mock.get(
            "https://api.notion.com/v1/blocks/p1/children",
            json={
                "results": [
                    {"id": "c1", "type": "child_page", "child_page": {"title": "📋 Backlog"}},
                ],
                "has_more": False,
            },
        )
        client = NotionClient("tok")
        assert client.find_child_page("p1", "📋 Backlog") == "c1"
        assert client.find_child_page("p1", "🧪 測試") is None
