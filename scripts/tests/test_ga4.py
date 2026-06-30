# backend/tests/metrics/test_ga4.py
from __future__ import annotations

from metrics import ga4
from metrics._common import MetricsConfig


DAILY_PLATFORM = {
    "rows": [
        {"dimensionValues": [{"value": "20260622"}, {"value": "web"}],
         "metricValues": [{"value": "16"}, {"value": "16"}]},
        {"dimensionValues": [{"value": "20260622"}, {"value": "iOS"}],
         "metricValues": [{"value": "5"}, {"value": "4"}]},
        {"dimensionValues": [{"value": "20260622"}, {"value": "Android"}],
         "metricValues": [{"value": "123"}, {"value": "123"}]},
        {"dimensionValues": [{"value": "20260623"}, {"value": "Android"}],
         "metricValues": [{"value": "20"}, {"value": "2"}]},
    ]
}


def test_parse_daily_groups_by_date_and_platform():
    out = ga4.parse_daily(DAILY_PLATFORM)
    assert out["2026-06-22"]["web"] == ("16", "16")
    assert out["2026-06-22"]["ios"] == ("5", "4")
    assert out["2026-06-22"]["android"] == ("123", "123")


def test_to_rows_lays_out_web_ios_android_columns():
    rows = ga4.to_rows(ga4.parse_daily(DAILY_PLATFORM))
    # date, web a/n, ios a/n, android a/n
    assert rows[0] == ["2026-06-22", "16", "16", "5", "4", "123", "123"]
    # 06-23 only has Android → other platforms blank
    assert rows[1] == ["2026-06-23", "", "", "", "", "20", "2"]


def test_fetch_daily_uses_single_property_with_platform(monkeypatch):
    monkeypatch.setattr(ga4, "_run_report_daily",
                        lambda pid, s, e: DAILY_PLATFORM)
    cfg = MetricsConfig(ga4_property_id_web="123", ga4_property_id_app=None)
    rows = ga4.fetch_daily(cfg, "2026-06-22", "2026-06-23")
    assert rows[0] == ["2026-06-22", "16", "16", "5", "4", "123", "123"]


def test_source_descriptor_ready_with_any_property():
    assert ga4.SOURCE.is_ready(
        MetricsConfig(ga4_property_id_web="123", ga4_property_id_app=None)
    )
    assert not ga4.SOURCE.is_ready(
        MetricsConfig(ga4_property_id_web=None, ga4_property_id_app=None)
    )
    assert ga4.SOURCE.headers[1] == "web_active_users"
    assert "android_active_users" in ga4.SOURCE.headers
