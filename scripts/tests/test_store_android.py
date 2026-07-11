# scripts/tests/test_store_android.py
from __future__ import annotations

from metrics import store_android
from metrics._common import MetricsConfig

_INSTALLS_CSV = "\n".join([
    "Date,Package Name,Daily Device Installs,Daily Device Uninstalls,"
    "Daily Device Upgrades,Total User Installs,Daily User Installs,"
    "Daily User Uninstalls,Active Device Installs,Install events,"
    "Update events,Uninstall events",
    "2026-07-09,com.paulchwu.instantexplore,2,0,0,2,2,0,2,2,0,0",
    "2026-07-10,com.paulchwu.instantexplore,1,0,0,3,1,0,3,1,0,0",
])

_RATINGS_CSV = "\n".join([
    "Date,Package Name,Daily Average Rating,Total Average Rating",
    "2026-07-09,com.paulchwu.instantexplore,NA,NA",
    "2026-07-10,com.paulchwu.instantexplore,5.00,5.00",
])


def test_parse_installs_maps_days_to_user_installs_and_active_devices():
    days = store_android.parse_installs(_INSTALLS_CSV)
    assert days["2026-07-09"] == ("2", "2")
    assert days["2026-07-10"] == ("1", "3")


def test_parse_ratings_maps_days_and_blanks_na():
    days = store_android.parse_ratings(_RATINGS_CSV)
    assert days["2026-07-09"] == ("", "")
    assert days["2026-07-10"] == ("5.00", "5.00")


def test_months_between_spans_month_boundary():
    assert store_android.months_between("2026-06-28", "2026-07-02") == [
        "202606", "202607",
    ]


def _cfg():
    return MetricsConfig(play_reports_bucket="pubsite_prod_rev_038")


def test_fetch_daily_merges_installs_and_ratings(monkeypatch):
    monkeypatch.setattr(
        store_android, "_month_csv",
        lambda cfg, kind, month: _INSTALLS_CSV if kind == "installs"
        else _RATINGS_CSV,
    )
    rows = store_android.fetch_daily(_cfg(), "2026-07-09", "2026-07-10")
    assert rows == [
        ["2026-07-09", "2", "2", "", ""],
        ["2026-07-10", "1", "3", "5.00", "5.00"],
    ]


def test_fetch_daily_skips_days_not_yet_exported(monkeypatch):
    # Play exports lag ~2 days: 07-11 absent from the CSV stays a gap.
    monkeypatch.setattr(
        store_android, "_month_csv",
        lambda cfg, kind, month: _INSTALLS_CSV if kind == "installs"
        else _RATINGS_CSV,
    )
    rows = store_android.fetch_daily(_cfg(), "2026-07-10", "2026-07-11")
    assert rows == [["2026-07-10", "1", "3", "5.00", "5.00"]]


def test_fetch_daily_handles_missing_month_object(monkeypatch):
    monkeypatch.setattr(
        store_android, "_month_csv", lambda cfg, kind, month: None
    )
    assert store_android.fetch_daily(_cfg(), "2026-07-09", "2026-07-10") == []


def test_source_is_registered_in_report():
    from metrics import report

    assert report.SOURCES["store_android"] is store_android.SOURCE


def test_source_descriptor_requires_bucket():
    assert store_android.SOURCE.filename == "store_android.csv"
    assert store_android.SOURCE.missing_config(MetricsConfig()) == [
        "play_reports_bucket",
    ]
