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


def test_metrics_config_from_env_normalizes_empty_string(monkeypatch):
    monkeypatch.setenv("GA4_PROPERTY_ID_WEB", "")
    monkeypatch.setenv("GA4_PROPERTY_ID_APP", "123")
    cfg = c.MetricsConfig.from_env()
    assert cfg.ga4_property_id_web is None   # empty string → None
    assert cfg.ga4_property_id_app == "123"  # non-empty preserved


def test_daily_dir_builds_fixed_path_without_creating():
    out = c.daily_dir(root=Path("/repo"))
    assert out == Path("/repo/docs/metrics/daily")
    assert not out.exists()


def test_read_daily_csv_missing_file_returns_empty(tmp_path):
    headers, rows = c.read_daily_csv(tmp_path / "nope.csv")
    assert headers == []
    assert rows == []


def test_existing_keys_collects_first_column(tmp_path):
    p = tmp_path / "ig.csv"
    c.write_csv(p, ["date", "reach"], [["2026-06-20", "5"], ["2026-06-21", "8"]])
    assert c.existing_keys(p) == {"2026-06-20", "2026-06-21"}


def test_upsert_daily_rows_appends_and_sorts(tmp_path):
    p = tmp_path / "ig.csv"
    c.write_csv(p, ["date", "reach"], [["2026-06-21", "8"]])
    c.upsert_daily_rows(p, ["date", "reach"], [["2026-06-20", "5"]])
    _, rows = c.read_daily_csv(p)
    assert rows == [["2026-06-20", "5"], ["2026-06-21", "8"]]


def test_upsert_daily_rows_overwrites_same_key(tmp_path):
    p = tmp_path / "ig.csv"
    c.write_csv(p, ["date", "reach"], [["2026-06-21", "8"]])
    c.upsert_daily_rows(p, ["date", "reach"], [["2026-06-21", "99"]])
    _, rows = c.read_daily_csv(p)
    assert rows == [["2026-06-21", "99"]]


def test_missing_days_seeds_first_backfill_when_empty():
    days = c.missing_days(set(), "2026-06-23", first_backfill=3)
    assert days == ["2026-06-21", "2026-06-22", "2026-06-23"]


def test_missing_days_resumes_after_latest_record():
    existing = {"2026-06-20", "2026-06-21"}
    assert c.missing_days(existing, "2026-06-23") == ["2026-06-22", "2026-06-23"]


def test_missing_days_empty_when_up_to_date():
    assert c.missing_days({"2026-06-23"}, "2026-06-23") == []
