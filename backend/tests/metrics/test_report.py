from __future__ import annotations

from scripts.metrics import report
from scripts.metrics._common import MetricsConfig, SourceResult


def _ok_source(name):
    return lambda cfg, s, e: SourceResult(
        name=name, ok=True, summary_lines=[f"{name}: 10 clicks"],
        csv_headers=["k", "v"], csv_rows=[["a", "1"]],
    )


def test_build_summary_lists_ok_and_skipped():
    results = [
        SourceResult(name="gsc", ok=True, summary_lines=["clicks: 42"]),
        SourceResult.skipped("ig", "missing token"),
    ]
    md = report.build_summary(results, "2026-06-17", "2026-06-23")
    assert "2026-06-17" in md and "2026-06-23" in md
    assert "clicks: 42" in md
    assert "skipped" in md.lower() and "missing token" in md


def test_check_lines_reports_missing_config():
    cfg = MetricsConfig(gsc_site_url=None, ig_user_id="x",
                        meta_page_access_token="y")
    lines = report.check_lines(cfg, ["gsc", "ig"])
    joined = "\n".join(lines)
    assert "gsc" in joined and "ig" in joined
    assert "missing" in joined.lower()  # gsc has no site url


def test_run_writes_summary_and_csv(tmp_path, monkeypatch):
    monkeypatch.setitem(report.SOURCES, "demo", _ok_source("demo"))
    out = report.run(MetricsConfig(), ["demo"], "2026-06-17",
                     "2026-06-23", root=tmp_path)
    assert (out / "summary.md").exists()
    assert (out / "demo.csv").read_text(encoding="utf-8").count("a,1") == 1
    report.SOURCES.pop("demo", None)


def test_main_check_does_not_write(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(report, "_repo_root", lambda: tmp_path)
    rc = report.main(["--check", "--only", "gsc"])
    assert rc == 0
    assert not (tmp_path / "docs" / "metrics").exists()
    assert "gsc" in capsys.readouterr().out
