# backend/tests/metrics/test_ga4.py
from __future__ import annotations

from scripts.metrics import ga4
from scripts.metrics._common import MetricsConfig


SAMPLE = {
    "rows": [
        {"dimensionValues": [{"value": "google / organic"}],
         "metricValues": [{"value": "120"}, {"value": "45"}]},
        {"dimensionValues": [{"value": "(direct) / (none)"}],
         "metricValues": [{"value": "80"}, {"value": "30"}]},
    ]
}


def test_parse_run_report_prefixes_label():
    rows = ga4.parse_run_report(SAMPLE, "web")
    assert rows[0] == ["web", "google / organic", "120", "45"]
    assert rows[1][1] == "(direct) / (none)"


def test_parse_run_report_empty():
    assert ga4.parse_run_report({}, "web") == []


def test_fetch_ga4_skips_without_any_property():
    r = ga4.fetch_ga4(MetricsConfig(ga4_property_id_web=None,
                                    ga4_property_id_app=None),
                      "2026-06-17", "2026-06-23")
    assert r.ok is False
    assert "GA4_PROPERTY_ID" in (r.skipped_reason or "")


def test_fetch_ga4_skips_when_all_properties_error(monkeypatch):
    def boom(pid, start, end):
        raise RuntimeError("boom")
    monkeypatch.setattr(ga4, "_run_report", boom)
    cfg = MetricsConfig(ga4_property_id_web="123", ga4_property_id_app=None)
    r = ga4.fetch_ga4(cfg, "2026-06-17", "2026-06-23")
    assert r.ok is False
    assert "boom" in (r.skipped_reason or "")


def test_fetch_ga4_ok_with_zero_rows(monkeypatch):
    monkeypatch.setattr(ga4, "_run_report", lambda pid, s, e: {})
    cfg = MetricsConfig(ga4_property_id_web="123", ga4_property_id_app=None)
    r = ga4.fetch_ga4(cfg, "2026-06-17", "2026-06-23")
    assert r.ok is True
    assert r.csv_rows == []
