from __future__ import annotations

import argparse
from datetime import date, timedelta

from scripts.metrics import stores


class FakeClient:
    """Minimal SheetClient stand-in recording reads and writes."""

    def __init__(self, tabs=None):
        self.sheet_id = "fake"
        self.tabs: dict[str, list[list[str]]] = tabs or {}
        self.writes: list[tuple[str, list[list[str]]]] = []

    def read_tab(self, title):
        return self.tabs.get(title, [])

    def write_tab(self, title, values):
        self.writes.append((title, values))
        self.tabs[title] = values


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


def test_build_row_orders_fields_and_keeps_blanks():
    row = stores.build_row(_args())
    assert row == ["2026-06-29", "1", "5.0", "1", "0", "", "", "", "hi"]


def test_upsert_writes_header_then_row_into_stores_tab():
    client = FakeClient()
    count = stores.upsert(client, stores.build_row(_args()))
    title, values = client.writes[-1]
    assert title == "stores"
    assert values[0] == stores.HEADERS
    assert values[1][0] == "2026-06-29"
    assert count == 1


def test_upsert_overwrites_same_date_without_duplicating():
    seed = [stores.HEADERS, ["2026-06-29", "1", "5.0", "1", "0", "", "", "", ""]]
    client = FakeClient({"stores": seed})
    count = stores.upsert(
        client, stores.build_row(_args(ios_downloads="3"))
    )
    _, values = client.writes[-1]
    assert count == 1
    assert values[1][1] == "3"


def test_default_date_is_yesterday():
    expected = (date.today() - timedelta(days=1)).isoformat()
    assert stores._default_date() == expected
