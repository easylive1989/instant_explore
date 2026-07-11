"""把 collector 資料同步到 Notion：主頁總覽 + 子頁面 + databases（持續累積）。

結構（首次執行自動建立，之後重用）：
- 主頁：子頁面導覽（頂部）+ 健康燈號 + 部署狀態 + 每日故事
- 📋 Backlog 子頁：Features database（看板用；Sprint 屬性避免 Done 堆積）
  + Epic 進度 + 待部署
- 🧪 測試 子頁：套件統計 + 失敗清單 + E2E 案例
- 📈 產品數據 子頁：數字卡 + 每來源一個 database（日期 key，upsert 累積）

內容 blocks 每次重寫；child_page / child_database 永不刪除。
"""
from __future__ import annotations

import re
import time
from datetime import date

import requests

_API = "https://api.notion.com/v1"
_VERSION = "2022-06-28"

SUBPAGES = {
    "backlog": ("📋 Backlog", "📋"),
    "tests": ("🧪 測試", "🧪"),
    "metrics": ("📈 產品數據", "📈"),
}
FEATURES_DB_TITLE = "Features"

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
    width = len(headers)

    def row(cells: list[str]) -> dict:
        # 補齊/截斷到表寬，否則 Notion 回 400
        padded = (list(cells) + [""] * width)[:width]
        return {
            "type": "table_row",
            "table_row": {"cells": [[_rt(str(c))] for c in padded]},
        }

    return {
        "type": "table",
        "table": {
            "table_width": width,
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


def _to_float(value: str) -> float | None:
    try:
        return float(str(value).replace(",", "").replace("%", ""))
    except ValueError:
        return None


def _error_callout(section: str, message: str) -> dict:
    return _callout(
        [_rt(f"{section} 收集失敗：", bold=True), _rt(message)],
        "❌",
        "red_background",
    )


def _updated_line(data: dict) -> dict:
    return _paragraph(_rt(f"最後更新：{data.get('generated_at', '?')}", color="gray"))


# ---------- 主頁 ----------


def _overview_cards(data: dict) -> list[dict]:
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

    if len(cards) >= 2:
        return [_columns(cards)]
    return cards[0] if cards else []


def build_main_blocks(data: dict) -> list[dict]:
    """主頁內容：健康燈號 + 部署狀態 + 每日故事（細節在子頁）。"""
    errors = data.get("errors", {})
    blocks = _overview_cards(data)
    blocks.append(_updated_line(data))
    blocks.append(_divider())

    deploys = data.get("deploys")
    blocks.append(_heading("🚀 部署狀態"))
    if deploys:
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
        blocks.append(_table(["服務", "最後部署", "commit", "vs master"], rows))
    else:
        blocks.append(_error_callout("deploys", errors.get("deploys", "沒有資料")))

    story = data.get("daily_story")
    blocks.append(_divider())
    if story:
        blocks.append(_heading(f"📅 每日故事（{story['date']}）"))
        blocks.extend(_daily_story_callouts(story))
    else:
        blocks.append(_heading("📅 每日故事"))
        blocks.append(_error_callout("daily_story", errors.get("daily_story", "沒有資料")))
    return blocks


def _daily_story_callouts(story: dict) -> list[dict]:
    if not story["posts"]:
        return [_callout([_rt("今天還沒有 daily story 記錄")], "❌", "red_background")]
    status_emoji = {
        "published": ("✅", "green_background"),
        "scheduled": ("🕘", "yellow_background"),
        "pending": ("⏳", "yellow_background"),
        "failed": ("❌", "red_background"),
        "rejected": ("🚫", "red_background"),
        "skipped": ("⏭", "gray_background"),
    }
    blocks = []
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


# ---------- Backlog 子頁 ----------


def build_backlog_blocks(data: dict) -> list[dict]:
    """Backlog 子頁內容：Epic 進度 + 待部署（features 在 database）。"""
    backlog = data.get("backlog")
    if not backlog:
        return [
            _error_callout("backlog", data.get("errors", {}).get("backlog", "沒有資料")),
        ]

    blocks = [_updated_line(data), _heading("🗺 Epic 進度")]
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

    pending = backlog.get("pending_deploy")
    if pending and any(not i["done"] for i in pending["items"]):
        blocks.append(_divider())
        blocks.append(
            _callout([_rt(_strip_md(pending["title"]), bold=True)], "⚠️", "yellow_background")
        )
        blocks.extend(
            _to_do(_strip_md(i["text"]), i["done"]) for i in pending["items"]
        )
    return blocks


FEATURES_DB_SCHEMA = {
    "Feature": {"title": {}},
    "編號": {"rich_text": {}},
    "編號數": {"number": {}},
    "Epic": {"select": {}},
    "狀態": {
        "select": {
            "options": [
                {"name": "已完成", "color": "green"},
                {"name": "進行中", "color": "blue"},
                {"name": "待辦", "color": "gray"},
            ]
        }
    },
    "Sprint": {"select": {}},
    "本期": {"checkbox": {}},
    "進度": {"rich_text": {}},
    "狀態備註": {"rich_text": {}},
}


def feature_properties(
    feature: dict, current_month: str, existing_sprint: str | None = None
) -> dict:
    """feature → database row 屬性。

    Sprint 規則：未完成 → 永遠當前月；已完成 → 既有值優先，否則從狀態
    文字解析完成月，再不然用當前月。

    「本期」checkbox = Sprint 是否為當前月。看板 view 以「本期 ✓」過濾
    （view 的過濾條件 API 改不了，用工具維護的 checkbox 才不會過期），
    過月後舊的 Done 自動掉出看板、不會無限堆積。
    """
    status_text = feature["status"] or ""
    if feature["done"]:
        status_select = "已完成"
        if existing_sprint:
            sprint = existing_sprint
        else:
            m = re.search(r"(\d{4}-\d{2})", status_text)
            sprint = m.group(1) if m else current_month
    else:
        status_select = "進行中" if "進行" in status_text else "待辦"
        sprint = current_month

    return {
        "Feature": {"title": [_rt(feature["title"])]},
        "編號": {"rich_text": [_rt(feature["id"])]},
        "編號數": {"number": int(feature["id"][1:])},
        "Epic": {"select": {"name": feature["epic"]} if feature["epic"] else None},
        "狀態": {"select": {"name": status_select}},
        "Sprint": {"select": {"name": sprint}},
        "本期": {"checkbox": sprint == current_month},
        "進度": {"rich_text": [_rt(f"{feature['tasks_done']}/{feature['tasks_total']}")]},
        "狀態備註": {"rich_text": [_rt(status_text)]},
    }


def feature_children(feature: dict) -> list[dict]:
    """feature row 頁面內文：tasks to-do 清單。"""
    if not feature["tasks"]:
        return [_paragraph(_rt("（無 tasks）", color="gray"))]
    return [_to_do(_strip_md(t["text"]), t["done"]) for t in feature["tasks"]]


# ---------- 測試 子頁 ----------


def build_tests_blocks(data: dict) -> list[dict]:
    errors = data.get("errors", {})
    blocks = [_updated_line(data), _heading("🧪 自動化測試")]

    tests = data.get("tests")
    if tests:
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
        blocks.append(_table(["套件", "通過", "狀態", "耗時", "其他"], rows))
        if failures:
            blocks.append(_paragraph(_rt("失敗案例：", bold=True)))
            for f in failures[:20]:
                error_head = (f.get("error") or "").splitlines()[0] if f.get("error") else ""
                blocks.append(_bullet(f"{f['name']} — {error_head}", color="red"))
    else:
        blocks.append(_error_callout("tests", errors.get("tests", "沒有資料")))

    blocks.append(_divider())
    e2e = data.get("e2e")
    if e2e:
        blocks.append(_heading(f"🎯 E2E 測試案例（{e2e['total']}）"))
        for group in e2e["groups"]:
            blocks.append(
                _paragraph(_rt(group["file"], bold=True), _rt(f"　{group['group']}", color="gray"))
            )
            blocks.extend(_bullet(c) for c in group["cases"])
    else:
        blocks.append(_heading("🎯 E2E 測試案例"))
        blocks.append(_error_callout("e2e", errors.get("e2e", "沒有資料")))
    return blocks


# ---------- 產品數據 子頁 ----------

_HEADLINES = {
    "gsc": ["clicks", "impressions"],
    "ga4": ["web_active_users", "ios_active_users", "android_active_users"],
    "ig": ["reach", "followers_count"],
    "revenuecat": ["mrr", "active_subscriptions", "active_trials"],
    "stores": ["ios_downloads_30d", "android_installs"],
    "narration": ["completion_rate"],
    "retention": ["cohort_size", "d1_rate", "d7_rate"],
}


def build_metrics_blocks(data: dict) -> list[dict]:
    """產品數據子頁內容：每來源數字卡（歷史資料在同頁的 databases）。"""
    metrics = data.get("metrics")
    if not metrics:
        return [
            _error_callout("metrics", data.get("errors", {}).get("metrics", "沒有資料")),
        ]

    blocks = [_updated_line(data)]
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
    return blocks


def metrics_db_properties(headers: list[str]) -> dict:
    """來源分頁 headers → database schema：date=title、note 類=文字、其餘 number。"""
    props: dict = {"日期": {"title": {}}}
    for column in headers[1:]:
        if column == "note":
            props[column] = {"rich_text": {}}
        else:
            props[column] = {"number": {}}
    return props


def metrics_row_properties(headers: list[str], row: list[str]) -> dict:
    """一列資料 → database row 屬性；缺欄與空值跳過。"""
    props: dict = {"日期": {"title": [_rt(row[0])]}}
    for i, column in enumerate(headers[1:], start=1):
        if i >= len(row) or str(row[i]).strip() == "":
            continue
        if column == "note":
            props[column] = {"rich_text": [_rt(str(row[i]))]}
        else:
            number = _to_float(row[i])
            if number is not None:
                props[column] = {"number": number}
    return props


# ---------- Notion API client ----------


class NotionClient:
    """薄封裝：children 讀寫、頁面/資料庫的 find-or-create、rows upsert。"""

    def __init__(self, token: str) -> None:
        self._headers = {
            "Authorization": f"Bearer {token}",
            "Notion-Version": _VERSION,
            "Content-Type": "application/json",
        }

    def _request(self, method: str, path: str, **kwargs) -> dict:
        for attempt in (1, 2):
            resp = requests.request(
                method, f"{_API}{path}", headers=self._headers, timeout=60, **kwargs
            )
            if resp.status_code == 429 and attempt == 1:
                time.sleep(float(resp.headers.get("Retry-After", 1)))
                continue
            if not resp.ok:
                raise RuntimeError(f"Notion {method} {path} 失敗：{resp.status_code} {resp.text[:400]}")
            return resp.json()
        raise AssertionError("unreachable")

    # --- blocks ---

    def children(self, block_id: str) -> list[dict]:
        results: list[dict] = []
        cursor: str | None = None
        while True:
            params = {"page_size": 100}
            if cursor:
                params["start_cursor"] = cursor
            payload = self._request("GET", f"/blocks/{block_id}/children", params=params)
            results.extend(payload.get("results", []))
            if not payload.get("has_more"):
                return results
            cursor = payload.get("next_cursor")

    def wipe_content(self, block_id: str) -> None:
        """刪除內容 blocks；child_page / child_database 永不刪除。"""
        for block in self.children(block_id):
            if block.get("type") in ("child_page", "child_database"):
                continue
            self._request("DELETE", f"/blocks/{block['id']}")

    def append(self, block_id: str, blocks: list[dict], chunk_size: int = 40) -> None:
        for start in range(0, len(blocks), chunk_size):
            self._request(
                "PATCH",
                f"/blocks/{block_id}/children",
                json={"children": blocks[start : start + chunk_size]},
            )

    # --- pages / databases ---

    def find_child_page(self, parent_id: str, title: str) -> str | None:
        for block in self.children(parent_id):
            if block.get("type") == "child_page" and block["child_page"]["title"] == title:
                return block["id"]
        return None

    def create_page(self, parent_page_id: str, title: str, emoji: str) -> str:
        payload = self._request(
            "POST",
            "/pages",
            json={
                "parent": {"page_id": parent_page_id},
                "icon": {"type": "emoji", "emoji": emoji},
                "properties": {"title": {"title": [_rt(title)]}},
            },
        )
        return payload["id"]

    def find_child_database(self, parent_id: str, title: str) -> str | None:
        for block in self.children(parent_id):
            if (
                block.get("type") == "child_database"
                and block["child_database"]["title"] == title
            ):
                return block["id"]
        return None

    def ensure_database_schema(self, database_id: str, properties: dict) -> None:
        """補上 schema 新增的屬性（PATCH 對既有屬性是 no-op）。"""
        self._request("PATCH", f"/databases/{database_id}", json={"properties": properties})

    def create_database(self, parent_page_id: str, title: str, properties: dict, emoji: str) -> str:
        payload = self._request(
            "POST",
            "/databases",
            json={
                "parent": {"type": "page_id", "page_id": parent_page_id},
                "icon": {"type": "emoji", "emoji": emoji},
                "title": [_rt(title)],
                "properties": properties,
            },
        )
        return payload["id"]

    def query_all(self, database_id: str) -> list[dict]:
        results: list[dict] = []
        cursor: str | None = None
        while True:
            body: dict = {"page_size": 100}
            if cursor:
                body["start_cursor"] = cursor
            payload = self._request("POST", f"/databases/{database_id}/query", json=body)
            results.extend(payload.get("results", []))
            if not payload.get("has_more"):
                return results
            cursor = payload.get("next_cursor")

    def create_db_page(self, database_id: str, properties: dict, children: list[dict] | None = None) -> str:
        body: dict = {"parent": {"database_id": database_id}, "properties": properties}
        if children:
            body["children"] = children
        return self._request("POST", "/pages", json=body)["id"]

    def update_page(self, page_id: str, properties: dict) -> None:
        self._request("PATCH", f"/pages/{page_id}", json={"properties": properties})

    def archive_page(self, page_id: str) -> None:
        self._request("PATCH", f"/pages/{page_id}", json={"archived": True})


# ---------- 屬性讀取小工具 ----------


def _plain(prop: dict | None, kind: str) -> str:
    if not prop:
        return ""
    return "".join(rt.get("plain_text", "") for rt in prop.get(kind, []))


def _select_name(prop: dict | None) -> str | None:
    if not prop or not prop.get("select"):
        return None
    return prop["select"].get("name")


# ---------- 同步 ----------


def _sync_features(client: NotionClient, db_id: str, backlog: dict) -> None:
    current_month = date.today().strftime("%Y-%m")
    existing = {
        _plain(page["properties"].get("編號"), "rich_text"): page
        for page in client.query_all(db_id)
    }

    seen = set()
    for feature in backlog["features"]:
        seen.add(feature["id"])
        page = existing.get(feature["id"])
        props = feature_properties(
            feature,
            current_month,
            existing_sprint=_select_name(page["properties"].get("Sprint")) if page else None,
        )
        if page is None:
            client.create_db_page(db_id, props, feature_children(feature))
            continue
        # 內容沒變就不重寫（省 API 呼叫）
        current_flag = (page["properties"].get("本期") or {}).get("checkbox")
        unchanged = (
            _plain(page["properties"].get("進度"), "rich_text")
            == f"{feature['tasks_done']}/{feature['tasks_total']}"
            and _plain(page["properties"].get("狀態備註"), "rich_text")
            == (feature["status"] or "")
            and _select_name(page["properties"].get("Sprint"))
            == props["Sprint"]["select"]["name"]
            and current_flag == props["本期"]["checkbox"]
        )
        if unchanged:
            continue
        client.update_page(page["id"], props)
        client.wipe_content(page["id"])
        client.append(page["id"], feature_children(feature))

    for feature_id, page in existing.items():
        if feature_id and feature_id not in seen:
            client.archive_page(page["id"])


def _sync_metrics_rows(client: NotionClient, db_id: str, tab: dict) -> None:
    """日期 key upsert：補缺的日期，並更新最近 3 天（來源可能回補）。"""
    existing = {
        _plain(page["properties"].get("日期"), "title"): page["id"]
        for page in client.query_all(db_id)
    }
    rows = tab.get("rows_30d") or list(reversed(tab["recent_rows"]))
    refresh_cutoff = max((r[0] for r in rows), default="")[:8] + "01"  # 保底值
    if rows:
        dates = sorted(r[0] for r in rows)
        refresh_cutoff = dates[-3] if len(dates) >= 3 else dates[0]

    for row in rows:
        row_date = row[0]
        props = metrics_row_properties(tab["headers"], row)
        if row_date not in existing:
            client.create_db_page(db_id, props)
        elif row_date >= refresh_cutoff:
            client.update_page(existing[row_date], props)


def sync(token: str, page_id: str, data: dict) -> dict:
    """整體同步；回傳各子頁/資料庫 id（供訊息輸出）。"""
    client = NotionClient(token)
    ids: dict = {"main": page_id}

    # 1. 子頁面 find-or-create
    for key, (title, emoji) in SUBPAGES.items():
        sub_id = client.find_child_page(page_id, title)
        if sub_id is None:
            sub_id = client.create_page(page_id, title, emoji)
        ids[key] = sub_id

    # 2. 主頁內容
    client.wipe_content(page_id)
    client.append(page_id, build_main_blocks(data))

    # 3. Backlog：database upsert + 頁面內容
    backlog = data.get("backlog")
    db_id = client.find_child_database(ids["backlog"], FEATURES_DB_TITLE)
    if db_id is None:
        db_id = client.create_database(ids["backlog"], FEATURES_DB_TITLE, FEATURES_DB_SCHEMA, "📋")
    else:
        client.ensure_database_schema(db_id, FEATURES_DB_SCHEMA)
    ids["features_db"] = db_id
    if backlog:
        _sync_features(client, db_id, backlog)
    client.wipe_content(ids["backlog"])
    client.append(ids["backlog"], build_backlog_blocks(data))

    # 4. 測試
    client.wipe_content(ids["tests"])
    client.append(ids["tests"], build_tests_blocks(data))

    # 5. 產品數據：每來源 database upsert + 數字卡
    metrics = data.get("metrics")
    if metrics:
        for tab in metrics["tabs"]:
            if "error" in tab:
                continue
            tab_db = client.find_child_database(ids["metrics"], tab["name"])
            if tab_db is None:
                tab_db = client.create_database(
                    ids["metrics"], tab["name"], metrics_db_properties(tab["headers"]), "📊"
                )
            _sync_metrics_rows(client, tab_db, tab)
    client.wipe_content(ids["metrics"])
    client.append(ids["metrics"], build_metrics_blocks(data))

    return ids
