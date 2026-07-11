"""backend / publisher 測試：uv run pytest --junitxml 後解析 JUnit XML。"""
from __future__ import annotations

import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

from ..config import BACKEND_DIR, PUBLISHER_DIR


def parse_junit_xml(xml_text: str) -> dict:
    """解析 pytest 的 JUnit XML，回傳統計與失敗清單。"""
    root = ET.fromstring(xml_text)
    suites = root.iter("testsuite")
    total = failed = errored = skipped = 0
    duration = 0.0
    failures: list[dict] = []

    for suite in suites:
        total += int(suite.get("tests", 0))
        failed += int(suite.get("failures", 0))
        errored += int(suite.get("errors", 0))
        skipped += int(suite.get("skipped", 0))
        duration += float(suite.get("time", 0))
        for case in suite.iter("testcase"):
            problem = case.find("failure")
            if problem is None:
                problem = case.find("error")
            if problem is not None:
                failures.append(
                    {
                        "name": f"{case.get('classname')}::{case.get('name')}",
                        "error": problem.get("message", ""),
                    }
                )

    return {
        "total": total,
        "passed": total - failed - errored - skipped,
        "failed": failed + errored,
        "skipped": skipped,
        "duration_seconds": duration,
        "failures": failures,
    }


def _run_suite(name: str, directory: Path) -> dict:
    with tempfile.NamedTemporaryFile(suffix=".xml") as tmp:
        subprocess.run(
            ["uv", "run", "pytest", "-q", f"--junitxml={tmp.name}"],
            cwd=directory,
            capture_output=True,
            text=True,
        )
        xml_text = Path(tmp.name).read_text()
    if not xml_text.strip():
        raise RuntimeError(f"{name} pytest 沒有產出 JUnit XML（測試可能沒跑起來）")
    result = parse_junit_xml(xml_text)
    result["suite"] = name
    return result


def collect() -> dict:
    """實際執行 backend 與 publisher 的 pytest。"""
    return {
        "suites": [
            _run_suite("backend", BACKEND_DIR),
            _run_suite("publisher", PUBLISHER_DIR),
        ]
    }
