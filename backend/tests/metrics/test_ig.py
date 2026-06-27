# backend/tests/metrics/test_ig.py
from __future__ import annotations

from scripts.metrics import ig
from scripts.metrics._common import MetricsConfig


INSIGHTS = {
    "data": [
        {"name": "reach", "values": [{"value": 1500}]},
        {"name": "profile_views", "values": [{"value": 90}]},
    ]
}
PROFILE = {"followers_count": 320, "media_count": 48}


TOTAL_VALUE_INSIGHTS = {
    "data": [
        {"name": "reach", "total_value": {"value": 1500}},
        {"name": "profile_views", "total_value": {"value": 90}},
    ]
}


def test_parse_account_insights_rows():
    rows = ig.parse_account_insights(INSIGHTS)
    assert ["reach", "1500"] in rows
    assert ["profile_views", "90"] in rows


def test_parse_account_insights_total_value_shape():
    rows = ig.parse_account_insights(TOTAL_VALUE_INSIGHTS)
    assert ["reach", "1500"] in rows
    assert ["profile_views", "90"] in rows


def test_parse_profile_lines():
    lines = ig.parse_profile(PROFILE)
    assert any("320" in ln for ln in lines)
    assert any("48" in ln for ln in lines)


def test_fetch_ig_skips_without_credentials():
    r = ig.fetch_ig(MetricsConfig(ig_user_id=None,
                                  meta_page_access_token=None),
                    "2026-06-17", "2026-06-23")
    assert r.ok is False
    assert "IG" in (r.skipped_reason or "").upper()


def test_fetch_daily_builds_one_row_per_day(monkeypatch):
    monkeypatch.setattr(ig, "_profile", lambda cfg: PROFILE)
    monkeypatch.setattr(ig, "_account_insights_day",
                        lambda cfg, day: TOTAL_VALUE_INSIGHTS)
    cfg = MetricsConfig(ig_user_id="1", meta_page_access_token="t")
    rows = ig.fetch_daily(cfg, "2026-06-22", "2026-06-23")
    assert len(rows) == 2
    assert rows[0] == ["2026-06-22", "1500", "90", "", ""]
    # Snapshot followers/media only on the latest day.
    assert rows[1] == ["2026-06-23", "1500", "90", "320", "48"]


def test_source_descriptor_requires_credentials():
    assert ig.SOURCE.filename == "ig.csv"
    assert ig.SOURCE.missing_config(
        MetricsConfig(ig_user_id=None, meta_page_access_token=None)
    ) == ["ig_user_id", "meta_page_access_token"]
