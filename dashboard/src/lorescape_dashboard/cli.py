"""進入點與 orchestrator：收集各區塊（含快取與錯誤隔離）後產生 HTML 面板。"""
from __future__ import annotations

import argparse
import json
import webbrowser
from collections.abc import Callable
from datetime import datetime
from pathlib import Path

from . import render
from .config import DASHBOARD_DIR, OUT_DATA_DIR, load_env


def _registry() -> dict[str, Callable[[], dict]]:
    """區塊名 → collector。lazy import 讓單一 collector 壞掉不影響其他。"""
    from .collectors import backlog, daily_story, deploys, e2e_cases, metrics
    from .collectors import tests_flutter, tests_python

    def tests() -> dict:
        flutter = tests_flutter.collect()
        return {"suites": [flutter, *tests_python.collect()["suites"]]}

    return {
        "backlog": backlog.collect,
        "tests": tests,
        "e2e": e2e_cases.collect,
        "deploys": deploys.collect,
        "metrics": metrics.collect,
        "daily_story": daily_story.collect,
    }


def _read_cache(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def gather(
    registry: dict[str, Callable[[], dict]],
    refresh: set[str],
    data_dir: Path,
) -> dict:
    """收集（或讀快取）每個區塊，錯誤隔離：單區塊失敗退回快取並記錯誤。"""
    data_dir.mkdir(parents=True, exist_ok=True)
    data: dict = {"errors": {}}

    for name, collect in registry.items():
        cache_path = data_dir / f"{name}.json"
        cached = _read_cache(cache_path)

        if name not in refresh:
            data[name] = cached["data"] if cached else None
            if cached is None:
                data["errors"][name] = "跳過收集且沒有快取"
            continue

        try:
            fresh = collect()
        except Exception as exc:
            if cached:
                data[name] = cached["data"]
                data["errors"][name] = (
                    f"{exc}（改用 {cached['collected_at']} 的快取）"
                )
            else:
                data[name] = None
                data["errors"][name] = str(exc)
            continue

        data[name] = fresh
        cache_path.write_text(
            json.dumps(
                {
                    "collected_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
                    "data": fresh,
                },
                ensure_ascii=False,
                indent=1,
            ),
            encoding="utf-8",
        )

    return data


def main() -> None:
    parser = argparse.ArgumentParser(description="產生 Lorescape 產品面板（本地 HTML）")
    parser.add_argument("--skip-tests", action="store_true", help="跳過跑測試，改用上次快取")
    parser.add_argument("--only", help="只刷新這些區塊（逗號分隔），其餘用快取")
    parser.add_argument("--no-open", action="store_true", help="產生後不自動開瀏覽器")
    args = parser.parse_args()

    load_env()
    registry = _registry()

    refresh = set(registry)
    if args.only:
        unknown = set(args.only.split(",")) - set(registry)
        if unknown:
            raise SystemExit(f"未知區塊：{'、'.join(sorted(unknown))}；可用：{'、'.join(registry)}")
        refresh = set(args.only.split(","))
    if args.skip_tests:
        refresh.discard("tests")

    print(f"收集區塊：{'、'.join(sorted(refresh))}（其餘用快取）")
    data = gather(registry, refresh=refresh, data_dir=OUT_DATA_DIR)
    data["generated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M")

    for name in registry:
        status = "❌ " + data["errors"][name] if name in data["errors"] else "✅"
        print(f"  {name}: {status}")

    out_path = DASHBOARD_DIR / "out" / "index.html"
    out_path.write_text(render.build_html(data), encoding="utf-8")
    print(f"面板已產生：{out_path}")
    if not args.no_open:
        webbrowser.open(out_path.as_uri())
