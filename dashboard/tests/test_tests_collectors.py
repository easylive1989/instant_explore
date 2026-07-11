"""tests_flutter / tests_python 的解析函式測試。"""
import json

from lorescape_dashboard.collectors.tests_flutter import (
    parse_lcov,
    parse_machine_output,
)
from lorescape_dashboard.collectors.tests_python import parse_junit_xml


def _machine_lines(*events: dict) -> str:
    return "\n".join(json.dumps(e) for e in events)


class TestParseMachineOutput:
    def test_統計通過與失敗案例(self):
        lines = _machine_lines(
            {"type": "start", "time": 0},
            # loading 的 hidden test 不計入
            {"type": "testStart", "test": {"id": 1, "name": "loading /x_test.dart"}, "time": 1},
            {"type": "testDone", "testID": 1, "result": "success", "hidden": True, "skipped": False, "time": 2},
            {"type": "testStart", "test": {"id": 2, "name": "登入 成功導向首頁"}, "time": 3},
            {"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False, "time": 9},
            {"type": "testStart", "test": {"id": 3, "name": "登入 失敗顯示錯誤"}, "time": 10},
            {"type": "error", "testID": 3, "error": "Expected: X\n  Actual: Y", "stackTrace": "...", "time": 11},
            {"type": "testDone", "testID": 3, "result": "error", "hidden": False, "skipped": False, "time": 12},
            {"type": "testStart", "test": {"id": 4, "name": "略過的測試"}, "time": 13},
            {"type": "testDone", "testID": 4, "result": "success", "hidden": False, "skipped": True, "time": 14},
            {"type": "done", "success": False, "time": 4500},
        )
        result = parse_machine_output(lines)
        assert result["total"] == 3
        assert result["passed"] == 1
        assert result["failed"] == 1
        assert result["skipped"] == 1
        assert result["duration_seconds"] == 4.5
        assert result["failures"] == [
            {"name": "登入 失敗顯示錯誤", "error": "Expected: X\n  Actual: Y"}
        ]

    def test_容忍非_json_行(self):
        result = parse_machine_output("Waiting for another flutter command...\n" + _machine_lines(
            {"type": "done", "success": True, "time": 100},
        ))
        assert result["total"] == 0


class TestParseLcov:
    def test_加總所有檔案的行覆蓋率(self):
        lcov = (
            "SF:lib/a.dart\nLF:10\nLH:8\nend_of_record\n"
            "SF:lib/b.dart\nLF:10\nLH:2\nend_of_record\n"
        )
        assert parse_lcov(lcov) == 50.0

    def test_空內容回_none(self):
        assert parse_lcov("") is None


class TestParseJunitXml:
    XML = """<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="pytest" errors="0" failures="1" skipped="1" tests="4" time="2.345">
    <testcase classname="tests.test_a" name="test_ok" time="0.01"/>
    <testcase classname="tests.test_a" name="test_bad" time="0.02">
      <failure message="assert 1 == 2">traceback...</failure>
    </testcase>
    <testcase classname="tests.test_b" name="test_skip" time="0">
      <skipped message="not ready"/>
    </testcase>
    <testcase classname="tests.test_b" name="test_ok2" time="0.03"/>
  </testsuite>
</testsuites>"""

    def test_統計與失敗清單(self):
        result = parse_junit_xml(self.XML)
        assert result["total"] == 4
        assert result["passed"] == 2
        assert result["failed"] == 1
        assert result["skipped"] == 1
        assert result["duration_seconds"] == 2.345
        assert result["failures"] == [
            {"name": "tests.test_a::test_bad", "error": "assert 1 == 2"}
        ]
