from __future__ import annotations

import argparse
import csv
from datetime import date, timedelta

from metrics import stores


def _args(**overrides):
    base = dict(
        date="2026-06-29",
        ios_downloads="1",
        ios_rating="5.0",
        ios_ratings="1",
        ios_reviews="0",
        android_installs="",
        android_rating="",
        android_ratings="",
        note="hi",
    )
    base.update(overrides)
    return argparse.Namespace(**base)


def _read(path):
    with path.open(newline="") as f:
        return list(csv.reader(f))


def test_build_row_orders_fields_and_keeps_blanks():
    row = stores.build_row(_args())
    assert row == ["2026-06-29", "1", "5.0", "1", "0", "", "", "", "hi"]


def test_upsert_writes_header_then_row(tmp_path):
    path = tmp_path / "stores.csv"
    count = stores.upsert(path, stores.build_row(_args()))
    values = _read(path)
    assert values[0] == stores.HEADERS
    assert values[1][0] == "2026-06-29"
    assert count == 1


def test_upsert_overwrites_same_date_without_duplicating(tmp_path):
    path = tmp_path / "stores.csv"
    with path.open("w", newline="") as f:
        csv.writer(f).writerows(
            [stores.HEADERS, ["2026-06-29", "1", "5.0", "1", "0", "", "", "", ""]]
        )
    count = stores.upsert(path, stores.build_row(_args(ios_downloads="3")))
    values = _read(path)
    assert count == 1
    assert values[1][1] == "3"


def test_default_date_is_yesterday():
    expected = (date.today() - timedelta(days=1)).isoformat()
    assert stores._default_date() == expected
