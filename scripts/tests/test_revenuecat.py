# scripts/tests/test_revenuecat.py
from __future__ import annotations

from metrics import revenuecat
from metrics._common import MetricsConfig

OVERVIEW = {
    "object": "overview",
    "metrics": [
        {"id": "mrr", "value": 128.5},
        {"id": "active_subscriptions", "value": 42},
        {"id": "active_trials", "value": 5},
        {"id": "active_users", "value": 310},
        {"id": "new_customers", "value": 17},
        {"id": "revenue", "value": 256.0},
    ],
}


def test_parse_overview_maps_id_to_value():
    values = revenuecat.parse_overview(OVERVIEW)
    assert values["mrr"] == "128.5"
    assert values["active_subscriptions"] == "42"
    assert values["revenue"] == "256.0"


def test_parse_overview_handles_null_and_missing_id():
    resp = {"metrics": [{"id": "mrr", "value": None}, {"value": 1}]}
    values = revenuecat.parse_overview(resp)
    assert values == {"mrr": ""}


def test_fetch_snapshot_builds_single_row_keyed_by_end(monkeypatch):
    monkeypatch.setattr(revenuecat, "_overview", lambda cfg: OVERVIEW)
    cfg = MetricsConfig(revenuecat_api_key="k", revenuecat_project_id="p")
    rows = revenuecat.fetch_snapshot(cfg, "2026-06-01", "2026-06-29")
    assert rows == [
        ["2026-06-29", "128.5", "42", "5", "310", "17", "256.0"],
    ]


def test_fetch_snapshot_leaves_unknown_metrics_blank(monkeypatch):
    monkeypatch.setattr(
        revenuecat, "_overview", lambda cfg: {"metrics": [{"id": "mrr", "value": 9}]}
    )
    cfg = MetricsConfig(revenuecat_api_key="k", revenuecat_project_id="p")
    rows = revenuecat.fetch_snapshot(cfg, "2026-06-29", "2026-06-29")
    assert rows == [["2026-06-29", "9", "", "", "", "", ""]]


def test_source_descriptor_is_snapshot_and_requires_credentials():
    assert revenuecat.SOURCE.snapshot is True
    assert revenuecat.SOURCE.missing_config(
        MetricsConfig(revenuecat_api_key=None, revenuecat_project_id=None)
    ) == ["revenuecat_api_key", "revenuecat_project_id"]
