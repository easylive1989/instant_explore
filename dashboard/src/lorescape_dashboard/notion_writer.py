"""把各 collector 的資料組成 Notion blocks，整頁重寫到面板頁。"""
from __future__ import annotations

import re

import requests

_API = "https://api.notion.com/v1"
_VERSION = "2022-06-28"

# ---------- rich text / block 小工具 ----------


def _rt(text: str, bold: bool = False, color: str = "default") -> dict:
    item: dict = {"type": "text", "text": {"content": text[:2000]}}
    if bold or color != "default":
        item["annotations"] = {"bold": bold, "color": color}
    return item


def _heading(text: str) -> dict:
    return {"type": "heading_1", "heading_1": {"rich_text": [_rt(text)]}}


def _sub_heading(text: str) -> dict:
    return {"type": "heading_3", "heading_3": {"rich_text": [_rt(text)]}}


def _paragraph(*rich_text: dict) -> dict:
    return {"type": "paragraph", "paragraph": {"rich_text": list(rich_text)}}


def _callout(rich_text: list[dict], emoji: str, color: str = "gray_background") -> dict:
    return {
        "type": "callout",
        "callout": {
            "rich_text": rich_text,
            "icon": {"type": "emoji", "emoji": emoji},
            "color": color,
        },
    }


def _bullet(text: str, color: str = "default") -> dict:
    return {
        "type": "bulleted_list_item",
        "bulleted_list_item": {"rich_text": [_rt(text, color=color)]},
    }


def _to_do(text: str, checked: bool) -> dict:
    return {
        "type": "to_do",
        "to_do": {"rich_text": [_rt(text)], "checked": checked},
    }


def _divider() -> dict:
    return {"type": "divider", "divider": {}}


def _table(headers: list[str], rows: list[list[str]]) -> dict:
    def row(cells: list[str]) -> dict:
        return {
            "type": "table_row",
            "table_row": {"cells": [[_rt(str(c))] for c in cells]},
        }

    return {
        "type": "table",
        "table": {
            "table_width": len(headers),
            "has_column_header": True,
            "children": [row(headers), *(row(r) for r in rows)],
        },
    }


def _columns(children_groups: list[list[dict]]) -> dict:
    return {
        "type": "column_list",
        "column_list": {
            "children": [
                {"type": "column", "column": {"children": group}}
                for group in children_groups
            ]
        },
    }


def _strip_md(text: str) -> str:
    return re.sub(r"\*\*(.+?)\*\*", r"\1", text).replace("`", "")


def _num(value: float | None) -> str:
    if value is None:
        return "–"
    return str(int(value)) if value == int(value) else str(value)


def _delta(value: float | None) -> str:
    if value is None:
        return ""
    if value > 0:
        return f" ▲ +{_num(value)}"
    if value < 0:
        return f" ▼ {_num(value)}"
    return " •0"


def _error_callout(section: str, message: str) -> dict:
    return _callout(
        [_rt(f"{section} 收集失敗：", bold=True), _rt(message)],
        "❌",
        "red_background",
    )


# ---------- 各區塊 ----------


def _overview(data: dict) -> list[dict]:
    cards: list[list[dict]] = []

    tests = data.get("tests")
    if tests:
        failed = sum(s.get("failed", 0) for s in tests["suites"])
        total = sum(s.get("total", 0) for s in tests["suites"])
        emoji, color = ("✅", "green_background") if failed == 0 else ("❌", "red_background")
        cards.append([_callout([_rt("測試 ", bold=True), _rt(f"{emoji} {total - failed}/{total}")], "🧪", color)])

    deploys = data.get("deploys")
    if deploys:
        behind = [s["behind_master"] for s in deploys["services"] if s.get("behind_master")]
        if behind:
            cards.append([_callout([_rt("部署 ", bold=True), _rt(f"⚠️ 最多落後 {max(behind)} commits")], "🚀", "yellow_background")])
        else:
            cards.append([_callout([_rt("部署 ", bold=True), _rt("✅ 與 master 同步")], "🚀", "green_background")])

    story = data.get("daily_story")
    if story:
        if story["all_published"]:
            text, color = "✅ 已發布", "green_background"
        elif story["posts"]:
            text, color = "🕘 進行中", "yellow_background"
        else:
            text, color = "❌ 尚無記錄", "red_background"
        cards.append([_callout([_rt("今日故事 ", bold=True), _rt(text)], "📅", color)])

    backlog = data.get("backlog")
    if backlog and backlog["epics"]:
        checkpoints = [c for e in backlog["epics"] for c in e["checkpoints"] if not c["done"]]
        if checkpoints:
            days = min(c["days_left"] for c in checkpoints)
            cards.append([_callout([_rt("Epic 檢核 ", bold=True), _rt(f"⏳ 倒數 {days} 天")], "🗺", "blue_background")])

    blocks: list[dict] = []
    if len(cards) >= 2:
        blocks.append(_columns(cards))
    elif cards:
        blocks.extend(cards[0])
    blocks.append(_paragraph(_rt(f"最後更新：{data['generated_at']}", color="gray")))
    return blocks


def _epic_section(backlog: dict) -> list[dict]:
    blocks = [_heading("🗺 Epic 進度")]
    for epic in backlog["epics"]:
        done, total = epic["features_done"], epic["features_total"]
        bar = "▓" * done + "░" * max(total - done, 0)
        blocks.append(
            _paragraph(
                _rt(f"{epic['id']} {epic['title']}", bold=True),
                _rt(f"（{epic['status'] or '?'}）　{bar} {done}/{total} features"),
            )
        )
        if epic["goal"]:
            blocks.append(_paragraph(_rt(f"目標：{epic['goal']}", color="gray")))
        for cp in epic["checkpoints"]:
            if cp["done"]:
                continue
            color = "red_background" if cp["days_left"] <= 7 else "blue_background"
            blocks.append(
                _callout([_rt(f"檢核點 {cp['date']}（倒數 {cp['days_left']} 天）：{cp['text']}")], "⏳", color)
            )
    return blocks


def _backlog_section(backlog: dict) -> list[dict]:
    blocks = [_heading("📋 Backlog")]

    pending = backlog.get("pending_deploy")
    if pending and any(not i["done"] for i in pending["items"]):
        blocks.append(
            _callout([_rt(_strip_md(pending["title"]), bold=True)], "⚠️", "yellow_background")
        )
        blocks.extend(
            _to_do(_strip_md(i["text"]), i["done"]) for i in pending["items"]
        )

    for feature in backlog["features"]:
        emoji = "✅" if feature["done"] else "🔨"
        epic_tag = f"（epic: {feature['epic']}）" if feature["epic"] else ""
        title = (
            f"{emoji} {feature['id']} {feature['title']}{epic_tag} — "
            f"{feature['status'] or '?'}（{feature['tasks_done']}/{feature['tasks_total']}）"
        )
        toggle_children = [
            _to_do(_strip_md(t["text"]), t["done"]) for t in feature["tasks"]
        ] or [_paragraph(_rt("（無 tasks）", color="gray"))]
        blocks.append(
            {"type": "toggle", "toggle": {"rich_text": [_rt(title)], "children": toggle_children}}
        )
    return blocks


def _deploys_section(deploys: dict) -> list[dict]:
    rows = []
    for s in deploys["services"]:
        if s["deployed_at"] is None:
            rows.append([s["service"], "（無成功部署記錄）", "–", "–"])
            continue
        behind = s["behind_master"]
        rows.append(
            [
                s["service"],
                s["deployed_at"].replace("T", " ").replace("Z", " UTC"),
                s["commit"],
                "✅ 同步" if behind == 0 else f"⚠️ 落後 {behind}",
            ]
        )
    return [
        _heading("🚀 部署狀態"),
        _table(["服務", "最後部署", "commit", "vs master"], rows),
    ]


def _tests_section(tests: dict) -> list[dict]:
    rows = []
    failures: list[dict] = []
    for s in tests["suites"]:
        coverage = s.get("coverage_percent")
        analyze = s.get("analyze")
        extra = []
        if coverage is not None:
            extra.append(f"cov {coverage}%")
        if analyze:
            extra.append("analyze ✅" if analyze["ok"] else "analyze ❌")
        status = "✅" if s["failed"] == 0 else f"❌ {s['failed']} 失敗"
        rows.append(
            [
                s["suite"],
                f"{s['passed']}/{s['total']}",
                status,
                f"{round(s['duration_seconds'])}s",
                "、".join(extra) or "–",
            ]
        )
        failures.extend(s.get("failures", []))

    blocks = [
        _heading("🧪 自動化測試"),
        _table(["套件", "通過", "狀態", "耗時", "其他"], rows),
    ]
    if failures:
        blocks.append(_paragraph(_rt("失敗案例：", bold=True)))
        for f in failures[:20]:
            error_head = (f.get("error") or "").splitlines()[0] if f.get("error") else ""
            blocks.append(_bullet(f"{f['name']} — {error_head}", color="red"))
    return blocks


def _e2e_section(e2e: dict) -> list[dict]:
    blocks = [_heading(f"🎯 E2E 測試案例（{e2e['total']}）")]
    for group in e2e["groups"]:
        blocks.append(_paragraph(_rt(group["file"], bold=True), _rt(f"　{group['group']}", color="gray")))
        blocks.extend(_bullet(c) for c in group["cases"])
    return blocks


# 每個來源挑面板頭條欄位；未列出的來源取前三個數值欄
_HEADLINES = {
    "gsc": ["clicks", "impressions"],
    "ga4": ["web_active_users", "ios_active_users", "android_active_users"],
    "ig": ["reach", "followers_count"],
    "revenuecat": ["mrr", "active_subscriptions", "active_trials"],
    "stores": ["ios_downloads_30d", "android_installs"],
    "narration": ["completion_rate"],
    "retention": ["cohort_size", "d1_rate", "d7_rate"],
}


def _metrics_section(metrics: dict) -> list[dict]:
    blocks = [_heading("📈 產品數據（近 30 天）")]
    for tab in metrics["tabs"]:
        if "error" in tab:
            blocks.append(_error_callout(tab["name"], tab["error"]))
            continue
        blocks.append(_sub_heading(f"{tab['name']}（至 {tab['latest_date']}）"))

        headline_cols = [
            c for c in _HEADLINES.get(tab["name"], list(tab["stats"])[:3])
            if c in tab["stats"]
        ]
        cards = [
            [
                _callout(
                    [
                        _rt(f"{col}\n", bold=True),
                        _rt(f"{_num(tab['stats'][col]['latest'])}{_delta(tab['stats'][col]['delta'])}"),
                    ],
                    "📊",
                )
            ]
            for col in headline_cols
        ]
        if len(cards) >= 2:
            blocks.append(_columns(cards))
        elif cards:
            blocks.extend(cards[0])

        blocks.append(_table(tab["headers"], tab["recent_rows"]))
    return blocks


def _daily_story_section(story: dict) -> list[dict]:
    blocks = [_heading(f"📅 每日故事（{story['date']}）")]
    if not story["posts"]:
        blocks.append(_callout([_rt("今天還沒有 daily story 記錄")], "❌", "red_background"))
        return blocks
    status_emoji = {
        "published": ("✅", "green_background"),
        "scheduled": ("🕘", "yellow_background"),
        "pending": ("⏳", "yellow_background"),
        "failed": ("❌", "red_background"),
        "rejected": ("🚫", "red_background"),
        "skipped": ("⏭", "gray_background"),
    }
    for post in story["posts"]:
        emoji, color = status_emoji.get(post["status"], ("•", "gray_background"))
        parts = [f"{post['media_type']}：{post['status']}"]
        if post.get("published_at"):
            parts.append(f"發布於 {post['published_at'][:16].replace('T', ' ')} UTC")
        elif post.get("scheduled_at"):
            parts.append(f"排程 {post['scheduled_at'][:16].replace('T', ' ')} UTC")
        if post.get("error"):
            parts.append(f"錯誤：{post['error']}")
        blocks.append(_callout([_rt("　".join(parts))], emoji, color))
    return blocks


# ---------- 組頁與寫入 ----------


def build_blocks(data: dict) -> list[dict]:
    """把所有 collector 資料組成整頁 blocks（pure function）。"""
    errors = data.get("errors", {})
    blocks = _overview(data)

    sections: list[tuple[str, str, object]] = [
        ("backlog", "🗺 Epic 進度", lambda d: _epic_section(d) + _backlog_section(d)),
        ("deploys", "🚀 部署狀態", _deploys_section),
        ("tests", "🧪 自動化測試", _tests_section),
        ("e2e", "🎯 E2E 測試案例", _e2e_section),
        ("metrics", "📈 產品數據", _metrics_section),
        ("daily_story", "📅 每日故事", _daily_story_section),
    ]
    for key, title, builder in sections:
        blocks.append(_divider())
        section_data = data.get(key)
        if section_data:
            blocks.extend(builder(section_data))
        else:
            blocks.append(_heading(title))
            blocks.append(_error_callout(key, errors.get(key, "沒有資料（該 collector 未執行）")))
    return blocks


def _headers(token: str) -> dict:
    return {
        "Authorization": f"Bearer {token}",
        "Notion-Version": _VERSION,
        "Content-Type": "application/json",
    }


def update_page(token: str, page_id: str, blocks: list[dict], chunk_size: int = 40) -> None:
    """整頁重寫：archive 既有 children 後分批 append。"""
    headers = _headers(token)

    child_ids: list[str] = []
    cursor: str | None = None
    while True:
        params = {"page_size": 100}
        if cursor:
            params["start_cursor"] = cursor
        resp = requests.get(
            f"{_API}/blocks/{page_id}/children", headers=headers, params=params, timeout=30
        )
        resp.raise_for_status()
        payload = resp.json()
        child_ids.extend(b["id"] for b in payload.get("results", []))
        if not payload.get("has_more"):
            break
        cursor = payload.get("next_cursor")

    for block_id in child_ids:
        requests.delete(f"{_API}/blocks/{block_id}", headers=headers, timeout=30).raise_for_status()

    for start in range(0, len(blocks), chunk_size):
        resp = requests.patch(
            f"{_API}/blocks/{page_id}/children",
            headers=headers,
            json={"children": blocks[start : start + chunk_size]},
            timeout=60,
        )
        resp.raise_for_status()
