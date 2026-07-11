"""解析 BACKLOG.md：Epic（含檢核倒數）、待部署段落、features/tasks。"""
from __future__ import annotations

import re
from datetime import date

from ..config import BACKLOG_PATH

_EPIC_RE = re.compile(r"^## Epic (E\d+): (.+)$")
_FEATURE_RE = re.compile(r"^## (F\d+): (.+?)(?:\s*\(epic:\s*(E\d+)\))?$")
_PENDING_RE = re.compile(r"^## (.*待部署.*)$")
_CHECKBOX_RE = re.compile(r"^- \[( |x)\] (.+)$")
_DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")


def _field(lines: list[str], name: str) -> str | None:
    prefix = f"- {name}: "
    for line in lines:
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return None


def _checkboxes(lines: list[str]) -> list[dict]:
    """段落內頂層 checkbox 項目（縮排的子項目不算）。"""
    items = []
    for line in lines:
        m = _CHECKBOX_RE.match(line)
        if m:
            items.append({"done": m.group(1) == "x", "text": m.group(2).strip()})
    return items


def _split_sections(text: str) -> list[tuple[str, list[str]]]:
    sections: list[tuple[str, list[str]]] = []
    current: list[str] | None = None
    for line in text.splitlines():
        if line.startswith("## "):
            current = []
            sections.append((line, current))
        elif current is not None:
            current.append(line)
    return sections


def parse_backlog(text: str, today: date | None = None) -> dict:
    today = today or date.today()
    epics: list[dict] = []
    features: list[dict] = []
    pending_deploy: dict | None = None

    for heading, lines in _split_sections(text):
        if m := _EPIC_RE.match(heading):
            checkpoints = []
            for item in _checkboxes(lines):
                if dm := _DATE_RE.search(item["text"]):
                    due = date.fromisoformat(dm.group(1))
                    checkpoints.append(
                        {
                            "date": dm.group(1),
                            "text": item["text"],
                            "done": item["done"],
                            "days_left": (due - today).days,
                        }
                    )
            epics.append(
                {
                    "id": m.group(1),
                    "title": m.group(2).strip(),
                    "status": _field(lines, "狀態"),
                    "goal": _field(lines, "目標"),
                    "checkpoints": checkpoints,
                }
            )
        elif m := _PENDING_RE.match(heading):
            pending_deploy = {
                "title": m.group(1).strip(),
                "items": _checkboxes(lines),
            }
        elif m := _FEATURE_RE.match(heading):
            status = _field(lines, "狀態") or ""
            tasks = _checkboxes(lines)
            features.append(
                {
                    "id": m.group(1),
                    "title": m.group(2).strip(),
                    "epic": m.group(3),
                    "status": status,
                    "done": status.startswith("已完成"),
                    "tasks": tasks,
                    "tasks_done": sum(t["done"] for t in tasks),
                    "tasks_total": len(tasks),
                }
            )

    for epic in epics:
        own = [f for f in features if f["epic"] == epic["id"]]
        epic["features_total"] = len(own)
        epic["features_done"] = sum(f["done"] for f in own)

    return {
        "epics": epics,
        "pending_deploy": pending_deploy,
        "features": features,
    }


def collect() -> dict:
    """讀取 repo 的 BACKLOG.md 並解析。"""
    return parse_backlog(BACKLOG_PATH.read_text(encoding="utf-8"))
