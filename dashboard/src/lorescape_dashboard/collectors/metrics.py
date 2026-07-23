"""產品數據：讀 lorescape-metrics 累積在 data/metrics/ 的 CSV，整形成面板統計。

2026-07-11 起 metrics 不再寫 Google Sheet，改由 scripts/metrics 的 FileStore
累積到 repo 內的 data/metrics/*.csv（gitignored）。
"""
from __future__ import annotations

import csv
import re
from datetime import date, timedelta

from ..config import REPO_ROOT

DATA_DIR = REPO_ROOT / "data" / "metrics"

# 走 shape_tab（日期時間序列）的來源；ig_posts 結構不同，另由 shape_ig_posts 處理
_TABS = [
    "gsc", "ga4", "ig", "revenuecat", "store_ios", "store_ios_pages",
    "store_android", "narration", "retention",
]

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _read_csv(name: str) -> list[list[str]]:
    path = DATA_DIR / f"{name}.csv"
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.reader(f))


def _to_float(value: str) -> float | None:
    try:
        return float(value.replace(",", "").replace("%", ""))
    except (ValueError, AttributeError):
        return None


def shape_tab(
    name: str, values: list[list[str]], today: date | None = None, days: int = 30
) -> dict | None:
    """把一個來源（header + rows）整形成統計：最新值、週變化、近七列。"""
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
        "rows_30d": recent,
    }


def shape_ig_posts(values: list[list[str]]) -> list[dict]:
    """ig_posts.csv（一貼文 × 一觀測日多列）→ 每貼文最新快照，發文日新到舊。"""
    if len(values) < 2:
        return []
    headers, rows = values[0], values[1:]
    latest: dict[str, dict] = {}
    for row in rows:
        post = dict(zip(headers, row))
        media_id = post.get("media_id", "")
        if not media_id:
            continue
        kept = latest.get(media_id)
        if kept is None or post.get("obs_date", "") > kept.get("obs_date", ""):
            latest[media_id] = post
    return sorted(
        latest.values(), key=lambda p: p.get("posted_date", ""), reverse=True
    )


_CHECKPOINT_ORDER = ["24h", "48h", "7d"]


def shape_ig_reels(values: list[list[str]]) -> list[dict]:
    """ig_reels_insights.csv（一 reel × 一 checkpoint 多列）→ 每 reel 一列，
    checkpoints 依 24h/48h/7d 收攏，發文日新到舊。"""
    if len(values) < 2:
        return []
    headers, rows = values[0], values[1:]
    reels: dict[str, dict] = {}
    for row in rows:
        snapshot = dict(zip(headers, row))
        media_id = snapshot.get("media_id", "")
        checkpoint = snapshot.get("checkpoint", "")
        if not media_id or checkpoint not in _CHECKPOINT_ORDER:
            continue
        reel = reels.setdefault(media_id, {
            "media_id": media_id,
            "posted_date": snapshot.get("posted_date", ""),
            "permalink": snapshot.get("permalink", ""),
            "caption": snapshot.get("caption", ""),
            "checkpoints": {},
        })
        reel["checkpoints"][checkpoint] = snapshot
    return sorted(
        reels.values(), key=lambda r: r["posted_date"], reverse=True
    )


def collect() -> dict:
    if not DATA_DIR.is_dir():
        raise SystemExit(
            f"{DATA_DIR} 不存在——先跑 lorescape-metrics 累積數據"
            "（scripts/metrics，寫入 data/metrics/*.csv）"
        )
    tabs = []
    for name in _TABS:
        try:
            shaped = shape_tab(name, _read_csv(name))
        except Exception as exc:  # 個別來源失敗不拖垮整個區塊
            shaped = {"name": name, "error": str(exc)}
        if shaped:
            tabs.append(shaped)
    result: dict = {"tabs": tabs}
    try:
        posts = shape_ig_posts(_read_csv("ig_posts"))
    except Exception:  # 逐貼文表格失敗不拖垮整個區塊
        posts = []
    if posts:
        result["ig_posts"] = posts
    try:
        reels = shape_ig_reels(_read_csv("ig_reels_insights"))
    except Exception:  # 快照表失敗不拖垮整個區塊
        reels = []
    if reels:
        result["ig_reels"] = reels
    return result
