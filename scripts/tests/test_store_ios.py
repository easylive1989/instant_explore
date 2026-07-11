# scripts/tests/test_store_ios.py
from __future__ import annotations

from metrics import store_ios

_HEADER = (
    "Provider\tProvider Country\tSKU\tDeveloper\tTitle\tVersion\t"
    "Product Type Identifier\tUnits\tDeveloper Proceeds\tBegin Date\t"
    "End Date\tCustomer Currency\tCountry Code\tCurrency of Proceeds\t"
    "Apple Identifier\tCustomer Price\tPromo Code\tParent Identifier\t"
    "Subscription\tPeriod\tCategory\tCID\tCMB\tDevice\tSupported Platforms"
)


def _row(product_type: str, units: str, apple_id: str = "6751904060") -> str:
    cols = [""] * 25
    cols[6] = product_type
    cols[7] = units
    cols[14] = apple_id
    return "\t".join(cols)


def test_parse_sales_units_sums_first_download_types():
    tsv = "\n".join([_HEADER, _row("1F", "3"), _row("1T", "2")])
    assert store_ios.parse_sales_units(tsv, "6751904060") == 5


def test_parse_sales_units_ignores_updates_and_other_apps():
    tsv = "\n".join([
        _HEADER,
        _row("1F", "3"),
        _row("7F", "9"),               # update, not a download
        _row("1F", "4", "999"),        # some other app under the vendor
    ])
    assert store_ios.parse_sales_units(tsv, "6751904060") == 3


def test_parse_sales_units_empty_report_is_zero():
    assert store_ios.parse_sales_units("", "6751904060") == 0
    assert store_ios.parse_sales_units(_HEADER, "6751904060") == 0


LOOKUP = {
    "resultCount": 1,
    "results": [{"averageUserRating": 4.83333, "userRatingCount": 12}],
}


def test_parse_lookup_returns_rating_and_count():
    assert store_ios.parse_lookup(LOOKUP) == ("4.83", "12")


def test_parse_lookup_handles_missing_results():
    assert store_ios.parse_lookup({"resultCount": 0, "results": []}) == ("", "")


def _patch_network(monkeypatch, sales=None, not_ready=()):
    """Stub the three HTTP helpers; `sales` maps day → units TSV."""
    sales = sales or {}

    def fake_sales_day(cfg, day):
        if day in not_ready:
            return None
        return sales.get(day, "")

    monkeypatch.setattr(store_ios, "_sales_day", fake_sales_day)
    monkeypatch.setattr(store_ios, "_lookup", lambda cfg: LOOKUP)
    monkeypatch.setattr(store_ios, "_reviews_total", lambda cfg: "4")


def _cfg():
    from metrics._common import MetricsConfig

    return MetricsConfig(
        asc_key_id="k", asc_issuer_id="i",
        asc_key_path="/tmp/x.p8", asc_vendor_number="93430162",
    )


def test_fetch_daily_builds_one_row_per_day_with_end_snapshot(monkeypatch):
    tsv = "\n".join([_HEADER, _row("1F", "3")])
    _patch_network(monkeypatch, sales={"2026-07-09": tsv})
    rows = store_ios.fetch_daily(_cfg(), "2026-07-09", "2026-07-10")
    assert rows == [
        ["2026-07-09", "3", "", "", ""],
        # Rating / review snapshots only on the latest day.
        ["2026-07-10", "0", "4.83", "12", "4"],
    ]


def test_fetch_daily_stops_when_report_not_ready(monkeypatch):
    _patch_network(monkeypatch, not_ready={"2026-07-10"})
    rows = store_ios.fetch_daily(_cfg(), "2026-07-09", "2026-07-10")
    # The unready tail is left for the next run's gap-fill; no snapshot row.
    assert rows == [["2026-07-09", "0", "", "", ""]]


def test_source_is_registered_in_report():
    from metrics import report

    assert report.SOURCES["store_ios"] is store_ios.SOURCE


def test_source_descriptor_requires_asc_credentials():
    from metrics._common import MetricsConfig

    assert store_ios.SOURCE.filename == "store_ios.csv"
    assert store_ios.SOURCE.missing_config(MetricsConfig()) == [
        "asc_key_id", "asc_issuer_id", "asc_key_path", "asc_vendor_number",
    ]
