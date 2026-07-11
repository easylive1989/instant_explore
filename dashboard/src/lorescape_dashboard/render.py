"""把 collector 資料渲染成單一自包含 HTML 面板（無外部資源、無 JS 依賴）。

視覺規範依 dataviz skill 參考色盤：light/dark 雙模式、固定 status 色、
sparkline 2px 線 + 端點 dot、表格 tabular-nums。
"""
from __future__ import annotations

import html
import re

_E = html.escape

_CSS = """
:root{
  --page:#f9f9f7;--surface:#fcfcfb;--ink:#0b0b0b;--ink-2:#52514e;--muted:#898781;
  --grid:#e1e0d9;--border:rgba(11,11,11,.10);--series:#2a78d6;
  --good:#0ca30c;--good-text:#006300;--warning:#fab219;--critical:#d03b3b;
  --wash:rgba(42,120,214,.10);
}
@media (prefers-color-scheme:dark){:root{
  --page:#0d0d0d;--surface:#1a1a19;--ink:#fff;--ink-2:#c3c2b7;--muted:#898781;
  --grid:#2c2c2a;--border:rgba(255,255,255,.10);--series:#3987e5;
  --good:#0ca30c;--good-text:#0ca30c;--warning:#fab219;--critical:#d03b3b;
  --wash:rgba(57,135,229,.12);
}}
*{box-sizing:border-box;margin:0}
body{background:var(--page);color:var(--ink);
  font:15px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif;padding:0 20px 80px}
main{max-width:1080px;margin:0 auto}
a{color:var(--series);text-decoration:none}
header{display:flex;flex-wrap:wrap;align-items:baseline;gap:12px;
  padding:28px 0 8px;border-bottom:1px solid var(--grid)}
header h1{font-size:20px;letter-spacing:.04em}
header .stamp{color:var(--muted);font-size:13px;margin-left:auto}
nav{display:flex;flex-wrap:wrap;gap:4px 16px;padding:10px 0;font-size:13px;
  position:sticky;top:0;background:var(--page);z-index:2;border-bottom:1px solid var(--grid)}
nav a{color:var(--ink-2)}
nav a:hover{color:var(--series)}
h2{font-size:16px;margin:36px 0 14px;display:flex;align-items:center;gap:8px}
h2 .hash{color:var(--muted);font-weight:400}
section{scroll-margin-top:48px}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-top:20px}
.tile{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px 16px}
.tile .label{font-size:12px;color:var(--ink-2)}
.tile .value{font-size:22px;font-weight:600;margin-top:2px;display:flex;align-items:center;gap:8px}
.dot{width:10px;height:10px;border-radius:50%;flex:none}
.dot.good{background:var(--good)}.dot.warning{background:var(--warning)}
.dot.critical{background:var(--critical)}.dot.muted{background:var(--muted)}
table{border-collapse:collapse;width:100%;background:var(--surface);
  border:1px solid var(--border);border-radius:10px;overflow:hidden;font-size:14px}
th,td{text-align:left;padding:8px 12px;border-top:1px solid var(--grid);
  font-variant-numeric:tabular-nums}
thead th{border-top:none;color:var(--ink-2);font-weight:500;font-size:12px;background:var(--surface)}
.num{text-align:right}
.status-good{color:var(--good-text)}.status-warning{color:#8a6100}
@media (prefers-color-scheme:dark){.status-warning{color:var(--warning)}}
.status-critical{color:var(--critical)}
.callout{background:var(--surface);border:1px solid var(--border);border-left:3px solid var(--series);
  border-radius:8px;padding:10px 14px;margin:10px 0;font-size:14px}
.callout.warn{border-left-color:var(--warning)}
.callout.error{border-left-color:var(--critical)}
.progress{height:8px;background:var(--grid);border-radius:4px;overflow:hidden;margin:6px 0 4px}
.progress i{display:block;height:100%;background:var(--series);border-radius:4px}
.kanban{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px;align-items:start}
.kanban .col{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:10px}
.kanban .col>h3{font-size:12px;color:var(--ink-2);font-weight:500;padding:2px 4px 8px}
.card{border:1px solid var(--grid);border-radius:8px;margin-bottom:8px;background:var(--page)}
.card summary{padding:8px 10px;cursor:pointer;font-size:14px;list-style:none}
.card summary::-webkit-details-marker{display:none}
.card .meta{color:var(--muted);font-size:12px}
.card ul{padding:2px 12px 10px 26px;font-size:13px;color:var(--ink-2)}
.card li.done{text-decoration:line-through;color:var(--muted)}
ul.plain{list-style:none;padding:0}
ul.plain li{padding:3px 0;font-size:14px}
.fail{color:var(--critical);font-size:13px;padding:2px 0}
.metric-card{background:var(--surface);border:1px solid var(--border);border-radius:10px;
  padding:14px 16px;margin-bottom:14px}
.metric-head{display:flex;align-items:baseline;gap:10px;margin-bottom:8px}
.metric-head b{font-size:14px}
.metric-head span{color:var(--muted);font-size:12px}
.stats-row{display:flex;flex-wrap:wrap;gap:8px 28px;margin-bottom:6px}
.stat .label{font-size:12px;color:var(--ink-2)}
.stat .value{font-size:19px;font-weight:600}
.delta{font-size:12px;font-weight:500;margin-left:4px}
.delta.up{color:var(--good-text)}.delta.down{color:var(--critical)}.delta.flat{color:var(--muted)}
details.table-fold{margin-top:8px;font-size:13px}
details.table-fold summary{color:var(--muted);cursor:pointer;font-size:12px}
.spark{display:block;margin-top:4px}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{background:var(--surface);border:1px solid var(--border);border-radius:8px;
  padding:8px 12px;font-size:14px;display:flex;gap:8px;align-items:center}
footer{margin-top:48px;color:var(--muted);font-size:12px}
"""


# ---------- 小工具 ----------


def _num(value: float | None) -> str:
    if value is None:
        return "–"
    return str(int(value)) if value == int(value) else str(value)


def _delta_html(value: float | None) -> str:
    if value is None:
        return ""
    if value > 0:
        return f'<span class="delta up">▲ +{_num(value)}</span>'
    if value < 0:
        return f'<span class="delta down">▼ {_num(value)}</span>'
    return '<span class="delta flat">±0</span>'


def _strip_md(text: str) -> str:
    return re.sub(r"\*\*(.+?)\*\*", r"\1", text).replace("`", "")


def _error_card(section: str, message: str) -> str:
    return f'<div class="callout error"><b>{_E(section)} 收集失敗：</b>{_E(message)}</div>'


def sparkline_svg(points: list[tuple[str, float]], width: int = 260, height: int = 48) -> str:
    """30 天趨勢 sparkline：2px 線、10% 面積 wash、端點 dot（含 2px 表面 ring）。"""
    if len(points) < 2:
        return ""
    values = [v for _, v in points]
    lo, hi = min(values), max(values)
    span = (hi - lo) or 1.0
    pad = 5
    step = (width - pad * 2) / (len(points) - 1)

    def xy(i: int, v: float) -> tuple[float, float]:
        return (
            round(pad + i * step, 1),
            round(pad + (height - pad * 2) * (1 - (v - lo) / span), 1),
        )

    coords = [xy(i, v) for i, (_, v) in enumerate(points)]
    poly = " ".join(f"{x},{y}" for x, y in coords)
    area = f"{pad},{height - pad} {poly} {coords[-1][0]},{height - pad}"
    end_x, end_y = coords[-1]
    titles = "".join(
        f'<circle cx="{x}" cy="{y}" r="7" fill="transparent">'
        f"<title>{_E(d)}：{_num(v)}</title></circle>"
        for (x, y), (d, v) in zip(coords, points)
    )
    return (
        f'<svg class="spark" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-label="近 30 天趨勢">'
        f'<polygon points="{area}" fill="var(--wash)"/>'
        f'<polyline points="{poly}" fill="none" stroke="var(--series)" '
        f'stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>'
        f'<circle cx="{end_x}" cy="{end_y}" r="4" fill="var(--series)" '
        f'stroke="var(--surface)" stroke-width="2"/>'
        f"{titles}</svg>"
    )


# ---------- 健康燈號 ----------


def health_signals(data: dict) -> list[dict]:
    signals = []

    tests = data.get("tests")
    if tests:
        failed = sum(s.get("failed", 0) for s in tests["suites"])
        total = sum(s.get("total", 0) for s in tests["suites"])
        signals.append(
            {
                "label": "測試",
                "value": f"{total - failed}/{total}",
                "level": "good" if failed == 0 else "critical",
            }
        )
    else:
        signals.append({"label": "測試", "value": "無資料", "level": "muted"})

    deploys = data.get("deploys")
    if deploys:
        behind = [s["behind_master"] for s in deploys["services"] if s.get("behind_master")]
        if behind:
            signals.append({"label": "部署", "value": f"最多落後 {max(behind)}", "level": "warning"})
        else:
            signals.append({"label": "部署", "value": "與 master 同步", "level": "good"})
    else:
        signals.append({"label": "部署", "value": "無資料", "level": "muted"})

    story = data.get("daily_story")
    if story:
        if story["all_published"]:
            signals.append({"label": "今日故事", "value": "已發布", "level": "good"})
        elif story["posts"]:
            signals.append({"label": "今日故事", "value": "進行中", "level": "warning"})
        else:
            signals.append({"label": "今日故事", "value": "尚無記錄", "level": "critical"})
    else:
        signals.append({"label": "今日故事", "value": "無資料", "level": "muted"})

    backlog = data.get("backlog")
    checkpoints = [
        c
        for e in (backlog or {}).get("epics", [])
        for c in e["checkpoints"]
        if not c["done"]
    ]
    if checkpoints:
        days = min(c["days_left"] for c in checkpoints)
        signals.append(
            {
                "label": "Epic 檢核",
                "value": f"倒數 {days} 天",
                "level": "critical" if days <= 7 else "warning" if days <= 14 else "good",
            }
        )
    return signals


def _tiles(data: dict) -> str:
    tiles = "".join(
        f'<div class="tile"><div class="label">{_E(s["label"])}</div>'
        f'<div class="value"><i class="dot {s["level"]}"></i>{_E(s["value"])}</div></div>'
        for s in health_signals(data)
    )
    return f'<div class="tiles">{tiles}</div>'


# ---------- Backlog（Epic + 看板） ----------


def _epic_html(backlog: dict) -> str:
    parts = []
    for epic in backlog["epics"]:
        done, total = epic["features_done"], epic["features_total"]
        percent = round(done / total * 100) if total else 0
        parts.append(
            f'<div class="metric-card"><div class="metric-head">'
            f'<b>{_E(epic["id"])} {_E(epic["title"])}</b>'
            f'<span>{_E(epic["status"] or "?")}</span></div>'
            f'<div class="progress"><i style="width:{percent}%"></i></div>'
            f'<div class="card .meta" style="font-size:13px;color:var(--ink-2)">'
            f'{done}/{total} features'
            + (f'　·　目標：{_E(epic["goal"])}' if epic["goal"] else "")
            + "</div>"
        )
        for cp in epic["checkpoints"]:
            if cp["done"]:
                continue
            css = "error" if cp["days_left"] <= 7 else "warn"
            parts.append(
                f'<div class="callout {css}">⏳ 檢核點 {_E(cp["date"])}（倒數 {cp["days_left"]} 天）：'
                f'{_E(cp["text"])}</div>'
            )
        parts.append("</div>")
    return "".join(parts)


def _pending_html(backlog: dict) -> str:
    pending = backlog.get("pending_deploy")
    if not pending or not any(not i["done"] for i in pending["items"]):
        return ""
    items = "".join(
        f'<li class="{"done" if i["done"] else ""}">{"✅" if i["done"] else "⬜"} '
        f'{_E(_strip_md(i["text"]))}</li>'
        for i in pending["items"]
    )
    return (
        f'<div class="callout warn"><b>{_E(_strip_md(pending["title"]))}</b>'
        f'<ul class="plain">{items}</ul></div>'
    )


def _feature_card(feature: dict) -> str:
    tasks = "".join(
        f'<li class="{"done" if t["done"] else ""}">{_E(_strip_md(t["text"]))}</li>'
        for t in feature["tasks"]
    ) or '<li>（無 tasks）</li>'
    epic_tag = f'（{feature["epic"]}）' if feature["epic"] else ""
    return (
        f'<details class="card"><summary><b>{_E(feature["id"])}</b> {_E(feature["title"])}'
        f'<div class="meta">{_E(feature["status"] or "?")}{_E(epic_tag)}　'
        f'{feature["tasks_done"]}/{feature["tasks_total"]}</div></summary>'
        f"<ul>{tasks}</ul></details>"
    )


def _done_month(feature: dict) -> str | None:
    m = re.search(r"(\d{4}-\d{2})", feature["status"] or "")
    return m.group(1) if m else None


def _kanban_html(backlog: dict, current_month: str) -> str:
    todo, doing, done_now, done_old = [], [], [], []
    for f in backlog["features"]:
        if f["done"]:
            month = _done_month(f)
            (done_now if month in (None, current_month) else done_old).append(f)
        elif "進行" in (f["status"] or ""):
            doing.append(f)
        else:
            todo.append(f)

    def col(title: str, features: list[dict], extra: str = "") -> str:
        cards = "".join(_feature_card(f) for f in features) or (
            '<div class="card"><summary style="padding:8px 10px;color:var(--muted)">（無）</summary></div>'
            if not extra else ""
        )
        return f'<div class="col"><h3>{_E(title)}（{len(features)}）</h3>{cards}{extra}</div>'

    old_fold = ""
    if done_old:
        old_cards = "".join(_feature_card(f) for f in done_old)
        old_fold = (
            f'<details class="table-fold"><summary>更早完成（{len(done_old)}）</summary>'
            f"{old_cards}</details>"
        )
    return (
        '<div class="kanban">'
        + col("待辦", todo)
        + col("進行中", doing)
        + col(f"已完成・{current_month}", done_now, old_fold)
        + "</div>"
    )


# ---------- 部署 / 測試 / E2E ----------


def _deploys_html(deploys: dict) -> str:
    rows = []
    for s in deploys["services"]:
        if s["deployed_at"] is None:
            rows.append(
                f"<tr><td>{_E(s['service'])}</td><td>（無成功部署記錄）</td><td>–</td><td>–</td></tr>"
            )
            continue
        behind = s["behind_master"]
        status = (
            '<span class="status-good">✓ 同步</span>'
            if behind == 0
            else f'<span class="status-warning">⚠ 落後 {behind}</span>'
        )
        when = s["deployed_at"].replace("T", " ").replace("Z", " UTC")
        commit = (
            f'<a href="{_E(s["run_url"])}">{_E(s["commit"])}</a>'
            if s.get("run_url")
            else _E(s["commit"])
        )
        rows.append(
            f"<tr><td>{_E(s['service'])}</td><td>{_E(when)}</td><td>{commit}</td><td>{status}</td></tr>"
        )
    return (
        "<table><thead><tr><th>服務</th><th>最後部署</th><th>commit</th><th>vs master</th></tr></thead>"
        f"<tbody>{''.join(rows)}</tbody></table>"
    )


def _tests_html(tests: dict) -> str:
    rows = []
    failures: list[dict] = []
    for s in tests["suites"]:
        extras = []
        if s.get("coverage_percent") is not None:
            extras.append(f"cov {s['coverage_percent']}%")
        analyze = s.get("analyze")
        if analyze:
            extras.append("analyze ✓" if analyze["ok"] else "analyze ✗")
        status = (
            '<span class="status-good">✓ 全數通過</span>'
            if s["failed"] == 0
            else f'<span class="status-critical">✗ {s["failed"]} 失敗</span>'
        )
        rows.append(
            f"<tr><td>{_E(s['suite'])}</td>"
            f'<td class="num">{s["passed"]}/{s["total"]}</td>'
            f"<td>{status}</td>"
            f'<td class="num">{round(s["duration_seconds"])}s</td>'
            f"<td>{_E('、'.join(extras) or '–')}</td></tr>"
        )
        failures.extend(s.get("failures", []))

    out = (
        "<table><thead><tr><th>套件</th><th>通過</th><th>狀態</th><th>耗時</th><th>其他</th></tr></thead>"
        f"<tbody>{''.join(rows)}</tbody></table>"
    )
    if failures:
        items = "".join(
            f'<div class="fail">✗ {_E(f["name"])} — '
            f'{_E((f.get("error") or "").splitlines()[0] if f.get("error") else "")}</div>'
            for f in failures[:30]
        )
        out += f'<div class="callout error"><b>失敗案例</b>{items}</div>'
    return out


def _e2e_html(e2e: dict) -> str:
    parts = []
    for group in e2e["groups"]:
        cases = "".join(f"<li>{_E(c)}</li>" for c in group["cases"])
        parts.append(
            f'<details class="card" open><summary><b>{_E(group["file"])}</b>'
            f'<div class="meta">{_E(group["group"])}　{len(group["cases"])} cases</div></summary>'
            f"<ul>{cases}</ul></details>"
        )
    return "".join(parts)


# ---------- 產品數據 ----------

_HEADLINES = {
    "gsc": ["clicks", "impressions"],
    "ga4": ["web_active_users", "ios_active_users", "android_active_users"],
    "ig": ["reach", "followers_count"],
    "revenuecat": ["mrr", "active_subscriptions", "active_trials"],
    "stores": ["ios_downloads_30d", "android_installs"],
    "narration": ["completion_rate"],
    "retention": ["cohort_size", "d1_rate", "d7_rate"],
}


def _to_float(value) -> float | None:
    try:
        return float(str(value).replace(",", "").replace("%", ""))
    except ValueError:
        return None


def _metric_card(tab: dict) -> str:
    if "error" in tab:
        return _error_card(tab["name"], tab["error"])

    headline_cols = [
        c for c in _HEADLINES.get(tab["name"], list(tab["stats"])[:3]) if c in tab["stats"]
    ]
    stats = "".join(
        f'<div class="stat"><div class="label">{_E(col)}</div>'
        f'<div class="value">{_num(tab["stats"][col]["latest"])}'
        f'{_delta_html(tab["stats"][col]["delta"])}</div></div>'
        for col in headline_cols
    )

    spark = ""
    if headline_cols:
        col_index = tab["headers"].index(headline_cols[0])
        points = [
            (row[0], v)
            for row in tab.get("rows_30d", [])
            if col_index < len(row) and (v := _to_float(row[col_index])) is not None
        ]
        spark = sparkline_svg(points)
        if spark:
            spark = (
                f'<div class="stat"><div class="label">{_E(headline_cols[0])}・近 30 天</div>'
                f"{spark}</div>"
            )

    header_cells = "".join(f"<th>{_E(h)}</th>" for h in tab["headers"])
    width = len(tab["headers"])
    body_rows = "".join(
        "<tr>" + "".join(
            f"<td>{_E(str(c))}</td>" for c in (list(r) + [""] * width)[:width]
        ) + "</tr>"
        for r in tab["recent_rows"]
    )
    table = (
        f'<details class="table-fold"><summary>近 7 天明細</summary>'
        f"<table><thead><tr>{header_cells}</tr></thead><tbody>{body_rows}</tbody></table></details>"
    )
    return (
        f'<div class="metric-card"><div class="metric-head"><b>{_E(tab["name"])}</b>'
        f'<span>至 {_E(tab["latest_date"])}</span></div>'
        f'<div class="stats-row">{stats}{spark}</div>{table}</div>'
    )


# ---------- 每日故事 ----------

_STORY_STATUS = {
    "published": ("good", "已發布"),
    "scheduled": ("warning", "已排程"),
    "pending": ("warning", "待審核"),
    "failed": ("critical", "失敗"),
    "rejected": ("critical", "已拒絕"),
    "skipped": ("muted", "略過"),
}


def _daily_story_html(story: dict) -> str:
    if not story["posts"]:
        return '<div class="callout error">今天還沒有 daily story 記錄</div>'
    chips = []
    for post in story["posts"]:
        level, label = _STORY_STATUS.get(post["status"], ("muted", post["status"]))
        detail = ""
        if post.get("published_at"):
            detail = f'　發布於 {post["published_at"][:16].replace("T", " ")} UTC'
        elif post.get("scheduled_at"):
            detail = f'　排程 {post["scheduled_at"][:16].replace("T", " ")} UTC'
        error = f'　<span class="status-critical">{_E(post["error"])}</span>' if post.get("error") else ""
        chips.append(
            f'<div class="chip"><i class="dot {level}"></i>'
            f'<b>{_E(post["media_type"])}</b>{_E(label)}{_E(detail)}{error}</div>'
        )
    return f'<div class="chips">{"".join(chips)}</div>'


# ---------- 組頁 ----------

_SECTIONS = [
    ("backlog", "📋 Backlog"),
    ("deploys", "🚀 部署狀態"),
    ("tests", "🧪 自動化測試"),
    ("e2e", "🎯 E2E 測試案例"),
    ("metrics", "📈 產品數據"),
    ("daily_story", "📅 每日故事"),
]


def build_html(data: dict) -> str:
    errors = data.get("errors", {})
    current_month = str(data.get("generated_at", ""))[:7]

    def section(key: str, title: str, body: str | None) -> str:
        content = body if body is not None else _error_card(
            key, errors.get(key, "沒有資料（該 collector 未執行）")
        )
        return (
            f'<section id="{key}"><h2><span class="hash">#</span>{_E(title)}</h2>{content}</section>'
        )

    backlog = data.get("backlog")
    tests = data.get("tests")
    e2e = data.get("e2e")
    deploys = data.get("deploys")
    metrics = data.get("metrics")
    story = data.get("daily_story")

    bodies = {
        "backlog": (
            _epic_html(backlog) + _pending_html(backlog) + _kanban_html(backlog, current_month)
            if backlog else None
        ),
        "deploys": _deploys_html(deploys) if deploys else None,
        "tests": _tests_html(tests) if tests else None,
        "e2e": _e2e_html(e2e) if e2e else None,
        "metrics": "".join(_metric_card(t) for t in metrics["tabs"]) if metrics else None,
        "daily_story": _daily_story_html(story) if story else None,
    }

    nav = "".join(f'<a href="#{key}">{_E(title)}</a>' for key, title in _SECTIONS)
    sections = "".join(section(key, title, bodies[key]) for key, title in _SECTIONS)

    return f"""<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lorescape 產品面板</title>
<style>{_CSS}</style>
</head>
<body>
<main>
<header><h1>LORESCAPE 產品面板</h1>
<span class="stamp">最後更新：{_E(str(data.get("generated_at", "?")))}</span></header>
<nav>{nav}</nav>
{_tiles(data)}
{sections}
<footer>由 dashboard/ 工具產生・<code>uv run lorescape-dashboard</code></footer>
</main>
</body>
</html>"""
