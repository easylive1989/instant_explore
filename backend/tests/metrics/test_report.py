from __future__ import annotations

from pathlib import Path

from scripts.metrics import report
from scripts.metrics._common import (
    DailySource,
    MetricsConfig,
    daily_dir,
    read_daily_csv,
    write_csv,
)


def _demo_source(rows, required=("gsc_site_url",), keyed_by_date=True):
    return DailySource(
        name="demo",
        filename="demo.csv",
        headers=["date", "v"],
        required=required,
        fetch=lambda cfg, s, e: rows,
        keyed_by_date=keyed_by_date,
    )


READY = MetricsConfig(gsc_site_url="https://x")


def test_plan_window_returns_none_when_up_to_date(tmp_path):
    src = _demo_source([])
    path = tmp_path / "demo.csv"
    write_csv(path, ["date", "v"], [["2026-06-23", "1"]])
    assert report.plan_window(src, path, "2026-06-23", 30, None) is None


def test_plan_window_backfills_gap(tmp_path):
    src = _demo_source([])
    path = tmp_path / "demo.csv"
    write_csv(path, ["date", "v"], [["2026-06-21", "1"]])
    assert report.plan_window(src, path, "2026-06-23", 30, None) == (
        "2026-06-22", "2026-06-23"
    )


def test_plan_window_explicit_overrides(tmp_path):
    src = _demo_source([])
    path = tmp_path / "demo.csv"
    assert report.plan_window(
        src, path, "2026-06-23", 30, ("2026-01-01", "2026-01-05")
    ) == ("2026-01-01", "2026-01-05")


def test_plan_window_media_keyed_uses_recent_window(tmp_path):
    src = _demo_source([], keyed_by_date=False)
    path = tmp_path / "demo.csv"
    assert report.plan_window(src, path, "2026-06-23", 3, None) == (
        "2026-06-21", "2026-06-23"
    )


def test_accumulate_skips_when_not_ready(tmp_path):
    src = _demo_source([["2026-06-23", "1"]])
    r = report.accumulate(src, MetricsConfig(gsc_site_url=None),
                          "2026-06-23", tmp_path)
    assert r.ok is False
    assert "missing config" in (r.skipped_reason or "")


def test_accumulate_upserts_into_daily_file(tmp_path):
    src = _demo_source([["2026-06-23", "9"]])
    r = report.accumulate(src, READY, "2026-06-23", tmp_path)
    assert r.ok is True and r.written == 1
    _, rows = read_daily_csv(daily_dir(tmp_path) / "demo.csv")
    assert rows == [["2026-06-23", "9"]]


def test_run_isolates_source_errors(tmp_path, monkeypatch):
    def boom(cfg, s, e):
        raise RuntimeError("api down")

    src = DailySource(name="demo", filename="demo.csv", headers=["date", "v"],
                      required=("gsc_site_url",), fetch=boom)
    monkeypatch.setitem(report.SOURCES, "demo", src)
    results = report.run(READY, ["demo"], "2026-06-23", tmp_path)
    report.SOURCES.pop("demo", None)
    assert results[0].ok is False
    assert "api down" in (results[0].skipped_reason or "")


def test_check_lines_reports_missing_config(tmp_path):
    cfg = MetricsConfig(gsc_site_url=None, ig_user_id="x",
                        meta_page_access_token="y")
    lines = report.check_lines(cfg, ["gsc", "ig"], "2026-06-23", tmp_path)
    joined = "\n".join(lines)
    assert "gsc" in joined and "missing" in joined.lower()


def test_check_lines_reports_backfill_count(tmp_path):
    write_csv(daily_dir(tmp_path) / "gsc.csv",
              ["date", "clicks"], [["2026-06-21", "1"]])
    lines = report.check_lines(MetricsConfig(gsc_site_url="https://x"),
                               ["gsc"], "2026-06-23", tmp_path)
    assert "backfill 2 day(s)" in "\n".join(lines)


def test_check_lines_ga4_ready_with_only_app(tmp_path):
    cfg = MetricsConfig(ga4_property_id_web=None, ga4_property_id_app="123")
    lines = report.check_lines(cfg, ["ga4"], "2026-06-23", tmp_path)
    assert "ga4: ready" in "\n".join(lines)


def test_check_lines_ga4_missing_when_neither(tmp_path):
    cfg = MetricsConfig(ga4_property_id_web=None, ga4_property_id_app=None)
    lines = report.check_lines(cfg, ["ga4"], "2026-06-23", tmp_path)
    joined = "\n".join(lines)
    assert "GA4_PROPERTY_ID_WEB or GA4_PROPERTY_ID_APP" in joined


def test_main_check_does_not_write(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(report, "_repo_root", lambda: tmp_path)
    rc = report.main(["--check", "--only", "gsc"])
    assert rc == 0
    assert not (tmp_path / "docs" / "metrics").exists()
    assert "gsc" in capsys.readouterr().out


def test_format_results_renders_each_outcome():
    results = [
        report.AccumResult("gsc", ok=True, written=2,
                           window=("2026-06-22", "2026-06-23")),
        report.AccumResult("ga4", ok=True, note="up to date"),
        report.AccumResult("ig", ok=False, skipped_reason="missing config"),
    ]
    text = report.format_results(results)
    assert "gsc: +2 row(s)" in text
    assert "ga4: up to date" in text
    assert "ig: skipped — missing config" in text
