from __future__ import annotations

from metrics import narration
from metrics._common import MetricsConfig


DAILY_EVENTS = {
    "rows": [
        {"dimensionValues": [{"value": "20260622"}, {"value": "narration_started"}],
         "metricValues": [{"value": "8"}]},
        {"dimensionValues": [{"value": "20260622"}, {"value": "narration_completed"}],
         "metricValues": [{"value": "6"}]},
        {"dimensionValues": [{"value": "20260622"}, {"value": "narration_abandoned"}],
         "metricValues": [{"value": "2"}]},
        # An unrelated app event on the same day is ignored.
        {"dimensionValues": [{"value": "20260622"}, {"value": "screen_view"}],
         "metricValues": [{"value": "99"}]},
        # A day with starts but no completions → rate 0.000.
        {"dimensionValues": [{"value": "20260623"}, {"value": "narration_started"}],
         "metricValues": [{"value": "4"}]},
    ]
}


def test_parse_daily_keeps_only_narration_events():
    out = narration.parse_daily(DAILY_EVENTS)
    assert out["2026-06-22"]["narration_started"] == 8
    assert out["2026-06-22"]["narration_completed"] == 6
    assert out["2026-06-22"]["narration_abandoned"] == 2
    assert "screen_view" not in out["2026-06-22"]


def test_to_rows_derives_completion_rate():
    rows = narration.to_rows(narration.parse_daily(DAILY_EVENTS))
    # date, started, completed, abandoned, completion_rate
    assert rows[0] == ["2026-06-22", "8", "6", "2", "0.750"]
    # 06-23: 4 started, 0 completed → 0.000, missing events blank as 0
    assert rows[1] == ["2026-06-23", "4", "0", "0", "0.000"]


def test_completion_rate_blank_when_nothing_started():
    resp = {
        "rows": [
            {"dimensionValues": [{"value": "20260624"}, {"value": "narration_completed"}],
             "metricValues": [{"value": "3"}]},
        ]
    }
    rows = narration.to_rows(narration.parse_daily(resp))
    # No started events → completion_rate is blank, started shown as 0.
    assert rows[0] == ["2026-06-24", "0", "3", "0", ""]


def test_fetch_daily_uses_app_property(monkeypatch):
    captured: dict[str, str] = {}

    def fake_run(pid, start, end):
        captured["pid"] = pid
        return DAILY_EVENTS

    monkeypatch.setattr(narration, "_run_report_daily", fake_run)
    cfg = MetricsConfig(ga4_property_id_web="web-1", ga4_property_id_app="app-9")
    rows = narration.fetch_daily(cfg, "2026-06-22", "2026-06-23")
    assert captured["pid"] == "app-9"
    assert rows[0][0] == "2026-06-22"


def test_source_ready_requires_a_property():
    assert narration.SOURCE.ready(
        MetricsConfig(ga4_property_id_web=None, ga4_property_id_app="app-9")
    )
    assert not narration.SOURCE.ready(
        MetricsConfig(ga4_property_id_web=None, ga4_property_id_app=None)
    )
