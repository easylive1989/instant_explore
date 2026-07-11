"""Scheduler 行程表：解析 SCHEDULE.md 三張例行工作表。"""
from __future__ import annotations

import re
from datetime import date

from ..config import REPO_ROOT

SCHEDULE_PATH = REPO_ROOT / "SCHEDULE.md"

_SECTION_KEYS = {"每日": "daily", "每週": "weekly", "每月": "monthly"}
_HEADING_RE = re.compile(r"^##\s*(每日|每週|每月)")
# 排程列：| 09:00 | 工作描述 | `/skill` |
_ROW_RE = re.compile(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$")


def parse_schedule(text: str) -> dict:
    """解析三個區段的三欄表；表頭列與分隔列略過。"""
    sections: dict = {"daily": [], "weekly": [], "monthly": []}
    current: str | None = None
    for line in text.splitlines():
        stripped = line.strip()
        heading = _HEADING_RE.match(stripped)
        if heading:
            current = _SECTION_KEYS[heading.group(1)]
            continue
        if stripped.startswith("## "):
            current = None
            continue
        m = _ROW_RE.match(stripped)
        if not m or current is None:
            continue
        time_ = m.group(1)
        if time_ == "時間" or set(time_) <= {"-", ":"}:
            continue
        sections[current].append(
            {"time": time_, "task": m.group(2), "command": m.group(3)}
        )
    return sections


def compute_for_date(sections: dict, d: date) -> list[dict]:
    """指定日期的待辦：每日項全列；週一加週表；1 號加月表。"""
    items = [{**i, "cadence": "每日"} for i in sections["daily"]]
    if d.weekday() == 0:
        items += [{**i, "cadence": "每週"} for i in sections["weekly"]]
    if d.day == 1:
        items += [{**i, "cadence": "每月"} for i in sections["monthly"]]
    return items


def compute_today(sections: dict, today: date) -> list[dict]:
    """今日待辦（compute_for_date 的薄包裝）。"""
    return compute_for_date(sections, today)


def collect() -> dict:
    if not SCHEDULE_PATH.exists():
        raise RuntimeError(f"行程表不存在：{SCHEDULE_PATH}")
    sections = parse_schedule(SCHEDULE_PATH.read_text(encoding="utf-8"))
    return {"today": compute_today(sections, date.today()), **sections}
