from __future__ import annotations

from metrics import retention
from metrics._common import MetricsConfig


def _row(cohort: str, nth: str, active: str) -> dict:
    return {
        "dimensionValues": [{"value": cohort}, {"value": nth}],
        "metricValues": [{"value": active}],
    }


COHORTS = {
    "rows": [
        _row("2026-06-22", "0000", "10"),
        _row("2026-06-22", "0001", "6"),
        _row("2026-06-22", "0007", "3"),
        # A younger cohort whose D7 hasn't matured yet (no day-7 row).
        _row("2026-06-23", "0000", "8"),
        _row("2026-06-23", "0001", "2"),
    ]
}


def test_parse_cohorts_groups_by_date_and_offset():
    out = retention.parse_cohorts(COHORTS)
    assert out["2026-06-22"] == {0: 10, 1: 6, 7: 3}
    assert out["2026-06-23"] == {0: 8, 1: 2}


def test_to_rows_computes_d1_and_d7_rates():
    rows = retention.to_rows(retention.parse_cohorts(COHORTS))
    # date, cohort_size, d1_retained, d1_rate, d7_retained, d7_rate
    assert rows[0] == ["2026-06-22", "10", "6", "0.600", "3", "0.300"]
    # 06-23 has no day-7 yet → d7 shown as 0 with rate 0.000
    assert rows[1] == ["2026-06-23", "8", "2", "0.250", "0", "0.000"]


def test_rate_blank_when_cohort_empty():
    rows = retention.to_rows({"2026-06-24": {1: 5}})
    # day0 is missing (0) → rates blank, retained counts still shown
    assert rows[0] == ["2026-06-24", "0", "5", "", "0", ""]


def test_fetch_daily_uses_app_property_and_window(monkeypatch):
    captured: dict[str, str] = {}

    def fake_run(pid, start, end):
        captured["pid"] = pid
        captured["start"] = start
        captured["end"] = end
        return COHORTS

    monkeypatch.setattr(retention, "_run_cohort_report", fake_run)
    cfg = MetricsConfig(ga4_property_id_web="web-1", ga4_property_id_app="app-9")
    rows = retention.fetch_daily(cfg, "2026-06-22", "2026-06-30")
    assert captured["pid"] == "app-9"
    # Window ignores the requested start and looks back _WINDOW_DAYS from end.
    assert captured["end"] == "2026-06-30"
    assert captured["start"] == "2026-06-17"
    assert rows[0][0] == "2026-06-22"


def test_source_ready_requires_a_property():
    assert retention.SOURCE.ready(
        MetricsConfig(ga4_property_id_web=None, ga4_property_id_app="app-9")
    )
    assert not retention.SOURCE.ready(
        MetricsConfig(ga4_property_id_web=None, ga4_property_id_app=None)
    )
