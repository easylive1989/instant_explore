from __future__ import annotations

from scripts.metrics import gsc
from scripts.metrics._common import MetricsConfig


SAMPLE = {
    "rows": [
        {"keys": ["taipei 101"], "clicks": 12, "impressions": 300,
         "ctr": 0.04, "position": 5.2},
        {"keys": ["lorescape"], "clicks": 8, "impressions": 50,
         "ctr": 0.16, "position": 1.1},
    ]
}


def test_parse_search_analytics_maps_rows():
    rows = gsc.parse_search_analytics(SAMPLE)
    assert rows[0] == ["taipei 101", "12", "300", "4.00%", "5.2"]
    assert rows[1][0] == "lorescape"


def test_parse_search_analytics_empty():
    assert gsc.parse_search_analytics({}) == []


def test_summarize_totals_clicks_and_impressions():
    rows = gsc.parse_search_analytics(SAMPLE)
    lines = gsc.summarize(rows)
    assert any("20" in ln for ln in lines)  # 12 + 8 clicks


def test_fetch_gsc_skips_without_site_url():
    r = gsc.fetch_gsc(MetricsConfig(gsc_site_url=None), "2026-06-17",
                      "2026-06-23")
    assert r.ok is False
    assert "GSC_SITE_URL" in (r.skipped_reason or "")


DAILY_SAMPLE = {
    "rows": [
        {"keys": ["2026-06-22"], "clicks": 4, "impressions": 120,
         "ctr": 0.033, "position": 7.4},
        {"keys": ["2026-06-23"], "clicks": 6, "impressions": 90,
         "ctr": 0.066, "position": 5.1},
    ]
}


def test_parse_daily_maps_rows_keyed_by_date():
    rows = gsc.parse_daily(DAILY_SAMPLE)
    assert rows[0] == ["2026-06-22", "4", "120", "3.30%", "7.4"]
    assert rows[1][0] == "2026-06-23"


def test_parse_daily_empty():
    assert gsc.parse_daily({}) == []


def test_source_descriptor_requires_site_url():
    assert gsc.SOURCE.name == "gsc"
    assert gsc.SOURCE.filename == "gsc.csv"
    assert gsc.SOURCE.missing_config(MetricsConfig(gsc_site_url=None)) == [
        "gsc_site_url"
    ]
    assert gsc.SOURCE.missing_config(
        MetricsConfig(gsc_site_url="https://x")
    ) == []
