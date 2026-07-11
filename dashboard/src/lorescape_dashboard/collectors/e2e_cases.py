"""靜態解析 E2E 測試案例名稱（不執行）：patrol integration_test 與 test/integration。"""
from __future__ import annotations

import re

from ..config import FRONTEND_DIR

# 第一個引數可能是多個相鄰字串常值（Dart 以相鄰常值串接長案例名）
_CASE_RE = re.compile(
    r"""(?:patrolTest|testWidgets)\s*\(\s*((?:['"][^'"]*['"]\s*)+)"""
)
_LITERAL_RE = re.compile(r"""['"]([^'"]*)['"]""")
_COMMENT_RE = re.compile(r"^\s*//.*$", re.MULTILINE)


def extract_case_names(dart_source: str) -> list[str]:
    """取出 patrolTest / testWidgets 的案例名稱，忽略 // 註解行。"""
    source = _COMMENT_RE.sub("", dart_source)
    return [
        "".join(_LITERAL_RE.findall(blob)) for blob in _CASE_RE.findall(source)
    ]


def collect() -> dict:
    """掃描 E2E 測試目錄，回傳依檔案分組的案例清單。"""
    groups = []
    for label, directory in (
        ("patrol (integration_test/)", FRONTEND_DIR / "integration_test"),
        ("widget integration (test/integration/)", FRONTEND_DIR / "test" / "integration"),
    ):
        if not directory.is_dir():
            continue
        for path in sorted(directory.rglob("*_test.dart")):
            cases = extract_case_names(path.read_text(encoding="utf-8"))
            if cases:
                groups.append(
                    {
                        "group": label,
                        "file": str(path.relative_to(FRONTEND_DIR)),
                        "cases": cases,
                    }
                )
    return {"groups": groups, "total": sum(len(g["cases"]) for g in groups)}
