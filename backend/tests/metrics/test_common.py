from __future__ import annotations

from datetime import date
from pathlib import Path

from scripts.metrics import _common as c


def test_date_range_defaults_to_last_7_days_ending_yesterday():
    start, end = c.date_range(days=7, clock=date(2026, 6, 24))
    assert end == "2026-06-23"
    assert start == "2026-06-17"


def test_date_range_explicit_start_end_overrides_days():
    start, end = c.date_range(days=7, start="2026-01-01", end="2026-01-31")
    assert (start, end) == ("2026-01-01", "2026-01-31")


def test_report_dir_builds_dated_path_without_creating():
    root = Path("/repo")
    out = c.report_dir("2026-06-23", root=root)
    assert out == Path("/repo/docs/metrics/2026-06-23")
    assert not out.exists()


def test_rows_to_md_table_renders_pipes():
    md = c.rows_to_md_table(["q", "clicks"], [["taipei", "12"]])
    assert "| q | clicks |" in md
    assert "| taipei | 12 |" in md


def test_rows_to_md_table_empty_rows():
    assert c.rows_to_md_table(["q"], []) == "_(no rows)_"


def test_write_csv_roundtrip(tmp_path):
    p = tmp_path / "sub" / "out.csv"
    c.write_csv(p, ["a", "b"], [["1", "2"], ["3", "4"]])
    text = p.read_text(encoding="utf-8")
    assert "a,b" in text
    assert "3,4" in text


def test_source_result_skipped_factory():
    r = c.SourceResult.skipped("gsc", "no creds")
    assert r.ok is False
    assert r.skipped_reason == "no creds"
    assert r.csv_rows == []
