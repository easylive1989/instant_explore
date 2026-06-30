from __future__ import annotations

from metrics import gsc
from metrics._common import MetricsConfig


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
