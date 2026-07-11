"""產品數據：讀 lorescape-metrics 累積的 Google Sheet，各分頁整形成面板統計。

SheetClient 的 read-only 部分複製自 scripts/metrics/sheets.py（dashboard 是
獨立 uv 專案，無法 import scripts/；比照 ADR 0004 的兩份複製慣例，改動需
人工同步）。
"""
from __future__ import annotations

import os
import re
from datetime import date, timedelta

from google.oauth2 import service_account
from googleapiclient.discovery import build

from ..config import SETUP_DOC

_SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]

# 面板顯示的分頁（略過 ig_posts——逐貼文時間序列對面板太細）
_TABS = ["gsc", "ga4", "ig", "revenuecat", "stores", "narration", "retention"]

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _build_service():
    creds_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not creds_path or not os.path.exists(creds_path):
        raise SystemExit(
            "GOOGLE_APPLICATION_CREDENTIALS 未設定或檔案不存在；"
            f"見 docs/init/metrics-setup.md 與 {SETUP_DOC}"
        )
    creds = service_account.Credentials.from_service_account_file(
        creds_path, scopes=_SCOPES
    )
    return build("sheets", "v4", credentials=creds, cache_discovery=False)


def _read_tab(service, sheet_id: str, title: str) -> list[list[str]]:
    resp = (
        service.spreadsheets()
        .values()
        .get(spreadsheetId=sheet_id, range=f"'{title}'")
        .execute()
    )
    return resp.get("values", [])


def _to_float(value: str) -> float | None:
    try:
        return float(value.replace(",", "").replace("%", ""))
    except (ValueError, AttributeError):
        return None


def shape_tab(
    name: str, values: list[list[str]], today: date | None = None, days: int = 30
) -> dict | None:
    """把一個分頁（header + rows）整形成統計：最新值、週變化、近七列。"""
    if len(values) < 2:
        return None
    today = today or date.today()
    headers, rows = values[0], values[1:]

    dated = sorted(
        (r for r in rows if r and _DATE_RE.match(r[0])), key=lambda r: r[0]
    )
    if not dated:
        return None
    cutoff = (today - timedelta(days=days)).isoformat()
    recent = [r for r in dated if r[0] >= cutoff] or dated[-1:]

    latest = recent[-1]
    week_ago_cutoff = (
        date.fromisoformat(latest[0]) - timedelta(days=7)
    ).isoformat()
    baseline = next(
        (r for r in reversed(dated) if r[0] <= week_ago_cutoff), None
    )

    def cell(row: list[str] | None, index: int) -> float | None:
        if row is None or index >= len(row):
            return None
        return _to_float(row[index])

    stats = {}
    for i, column in enumerate(headers[1:], start=1):
        latest_v = cell(latest, i)
        baseline_v = cell(baseline, i)
        if latest_v is None and not any(cell(r, i) is not None for r in recent):
            continue  # 整欄非數值（如 note）
        stats[column] = {
            "latest": latest_v,
            "week_ago": baseline_v,
            "delta": (
                round(latest_v - baseline_v, 2)
                if latest_v is not None and baseline_v is not None
                else None
            ),
        }

    return {
        "name": name,
        "headers": headers,
        "latest_date": latest[0],
        "stats": stats,
        "recent_rows": list(reversed(recent))[:7],
    }


def collect() -> dict:
    sheet_id = os.environ.get("METRICS_SHEET_ID", "").strip()
    if not sheet_id:
        raise SystemExit(
            f"METRICS_SHEET_ID 未設定（scripts/.env）；見 {SETUP_DOC}"
        )
    service = _build_service()
    tabs = []
    for name in _TABS:
        try:
            shaped = shape_tab(name, _read_tab(service, sheet_id, name))
        except Exception as exc:  # 個別分頁失敗不拖垮整個區塊
            shaped = {"name": name, "error": str(exc)}
        if shaped:
            tabs.append(shaped)
    return {"tabs": tabs}
