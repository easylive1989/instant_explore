"""frontend 測試：fvm flutter test --machine --coverage ＋ analyze ＋ lcov。"""
from __future__ import annotations

import json
import subprocess

from ..config import FRONTEND_DIR


def parse_machine_output(output: str) -> dict:
    """解析 `flutter test --machine` 的 JSON-lines 事件流。"""
    names: dict[int, str] = {}
    errors: dict[int, str] = {}
    total = passed = failed = skipped = 0
    duration_ms = 0
    failures: list[dict] = []

    for line in output.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        etype = event.get("type")
        if etype == "testStart":
            test = event["test"]
            names[test["id"]] = test.get("name", "")
        elif etype == "error":
            errors[event["testID"]] = event.get("error", "")
        elif etype == "testDone":
            if event.get("hidden"):
                continue
            total += 1
            if event.get("skipped"):
                skipped += 1
            elif event.get("result") == "success":
                passed += 1
            else:
                failed += 1
                test_id = event["testID"]
                failures.append(
                    {"name": names.get(test_id, f"#{test_id}"), "error": errors.get(test_id, "")}
                )
        elif etype == "done":
            duration_ms = event.get("time", 0)

    return {
        "total": total,
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "duration_seconds": duration_ms / 1000,
        "failures": failures,
    }


def parse_lcov(text: str) -> float | None:
    """lcov.info 全案行覆蓋率 %（LH 加總 / LF 加總）。"""
    found = hit = 0
    for line in text.splitlines():
        if line.startswith("LF:"):
            found += int(line[3:])
        elif line.startswith("LH:"):
            hit += int(line[3:])
    if not found:
        return None
    return round(hit / found * 100, 1)


def _run_analyze() -> dict:
    proc = subprocess.run(
        ["fvm", "flutter", "analyze", "--fatal-infos"],
        cwd=FRONTEND_DIR,
        capture_output=True,
        text=True,
    )
    summary = next(
        (l.strip() for l in reversed(proc.stdout.splitlines()) if l.strip()),
        "",
    )
    return {"ok": proc.returncode == 0, "summary": summary}


def collect() -> dict:
    """實際執行 frontend 測試（含 coverage）與 analyze。"""
    proc = subprocess.run(
        ["fvm", "flutter", "test", "--machine", "--coverage"],
        cwd=FRONTEND_DIR,
        capture_output=True,
        text=True,
    )
    result = parse_machine_output(proc.stdout)
    result["suite"] = "frontend"

    lcov_path = FRONTEND_DIR / "coverage" / "lcov.info"
    result["coverage_percent"] = (
        parse_lcov(lcov_path.read_text()) if lcov_path.exists() else None
    )
    result["analyze"] = _run_analyze()
    return result
