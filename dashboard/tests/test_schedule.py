"""schedule collector 的解析與今日待辦測試。"""
from datetime import date

import pytest

from lorescape_dashboard.collectors import schedule
from lorescape_dashboard.collectors.schedule import (
    compute_for_date,
    compute_today,
    parse_schedule,
)

SAMPLE = """\
# Lorescape Scheduler 行程表

說明文字，不解析。

## 每日

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 09:00 | 產生當日每日故事 → Discord 審核 → 發布 | `/lorescape-manual-daily-story` |
| 發布後 | wander 圖組 → 審核 → 發 IG | `/lorescape-wander-carousel` |

## 每週（週一）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 週報：分析最近 7 天數據 vs 前週 | `/marketing-weekly-audit` |

## 每月（1 號）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 月報：最近 30 天數據 vs 前月 | `/marketing-monthly-audit` |

註記：reels calendar 期末檢核跟「期別結束日」走，不綁月初。
"""


class TestParseSchedule:
    def test_解析三區段與欄位(self):
        sections = parse_schedule(SAMPLE)
        assert len(sections["daily"]) == 2
        assert len(sections["weekly"]) == 1
        assert len(sections["monthly"]) == 1
        assert sections["daily"][0] == {
            "time": "09:00",
            "task": "產生當日每日故事 → Discord 審核 → 發布",
            "command": "`/lorescape-manual-daily-story`",
        }

    def test_表頭分隔列與註記不被解析為項目(self):
        sections = parse_schedule(SAMPLE)
        all_items = sections["daily"] + sections["weekly"] + sections["monthly"]
        assert all(i["time"] not in ("時間", "---") for i in all_items)
        assert all("註記" not in i["task"] for i in all_items)


class TestComputeToday:
    def test_平日只列每日項(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 7, 14))  # 週二、非 1 號
        assert [i["cadence"] for i in items] == ["每日", "每日"]

    def test_週一加列週表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 7, 13))  # 週一
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週"]
        assert items[-1]["command"] == "`/marketing-weekly-audit`"

    def test_一號加列月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 8, 1))  # 週六、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每月"]


class TestComputeForDate:
    def test_平日只列每日項(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 7, 14))  # 週二、非 1 號
        assert [i["cadence"] for i in items] == ["每日", "每日"]

    def test_週一加列週表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 7, 13))  # 週一
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週"]

    def test_一號加列月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 8, 1))  # 週六、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每月"]

    def test_週一恰為一號同時加列週表與月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 6, 1))  # 週一、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週", "每月"]


class TestCollect:
    def test_檔案缺失時報錯(self, monkeypatch, tmp_path):
        monkeypatch.setattr(schedule, "SCHEDULE_PATH", tmp_path / "SCHEDULE.md")
        with pytest.raises(RuntimeError, match="行程表不存在"):
            schedule.collect()

    def test_讀檔並含今日待辦(self, monkeypatch, tmp_path):
        path = tmp_path / "SCHEDULE.md"
        path.write_text(SAMPLE, encoding="utf-8")
        monkeypatch.setattr(schedule, "SCHEDULE_PATH", path)
        result = schedule.collect()
        assert len(result["daily"]) == 2
        assert all(i["cadence"] == "每日" for i in result["today"][:2])


class TestRender:
    def _data(self) -> dict:
        sections = parse_schedule(SAMPLE)
        return {
            "errors": {},
            "collected_at": {},
            "generated_at": "2026-07-13 09:00",
            "schedule": {
                "today": compute_today(sections, date(2026, 7, 13)),
                **sections,
            },
        }

    def test_渲染今日待辦與三張表(self):
        from lorescape_dashboard import render

        html = render.section_body("schedule", self._data())
        assert "今日待辦" in html
        assert "產生當日每日故事" in html
        assert "marketing-weekly-audit" in html  # 週一含週表項
        assert "每月（1 號）" in html  # 完整表仍列出

    def test_registry_含_schedule(self):
        from lorescape_dashboard.cli import _registry

        assert "schedule" in _registry()
