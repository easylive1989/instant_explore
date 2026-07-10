from __future__ import annotations

from metrics._common import DailySource
from metrics.store import SheetStore


def _source(name="demo", key_index=0):
    return DailySource(
        name=name,
        filename=f"{name}.csv",
        headers=["date", "v"],
        required=(),
        fetch=lambda cfg, s, e: [],
        key_index=key_index,
    )


class FakeClient:
    """Minimal SheetClient stand-in recording reads and writes."""

    def __init__(self, tabs=None):
        self.sheet_id = "fake"
        self.tabs: dict[str, list[list[str]]] = tabs or {}
        self.reads = 0
        self.writes: list[tuple[str, list[list[str]]]] = []

    def read_tab(self, title):
        self.reads += 1
        return self.tabs.get(title, [])

    def write_tab(self, title, values):
        self.writes.append((title, values))
        self.tabs[title] = values


def test_keys_reads_first_column():
    client = FakeClient({"demo": [["date", "v"], ["2026-06-20", "5"]]})
    store = SheetStore(client)
    assert store.keys(_source()) == {"2026-06-20"}


def test_keys_composite_index_returns_tuples():
    client = FakeClient({"demo": [
        ["media_id", "obs_date", "v"],
        ["m1", "2026-06-22", "1"],
        ["m1", "2026-06-23", "2"],
    ]})
    store = SheetStore(client)
    assert store.keys(_source(key_index=(0, 1))) == {
        ("m1", "2026-06-22"), ("m1", "2026-06-23"),
    }


def test_keys_empty_tab_returns_empty_set():
    store = SheetStore(FakeClient())
    assert store.keys(_source()) == set()


def test_upsert_merges_existing_and_writes_with_header():
    client = FakeClient({"demo": [["date", "v"], ["2026-06-21", "8"]]})
    store = SheetStore(client)
    store.upsert(_source(), ["date", "v"], [["2026-06-22", "5"]])
    title, values = client.writes[-1]
    assert title == "demo"
    assert values == [["date", "v"], ["2026-06-21", "8"], ["2026-06-22", "5"]]


def test_upsert_overwrites_same_key():
    client = FakeClient({"demo": [["date", "v"], ["2026-06-21", "8"]]})
    store = SheetStore(client)
    store.upsert(_source(), ["date", "v"], [["2026-06-21", "99"]])
    _, values = client.writes[-1]
    assert values == [["date", "v"], ["2026-06-21", "99"]]


def test_read_is_cached_within_run():
    client = FakeClient({"demo": [["date", "v"], ["2026-06-21", "8"]]})
    store = SheetStore(client)
    store.keys(_source())
    store.read(_source())
    assert client.reads == 1


def test_upsert_refreshes_cache_so_next_keys_see_new_rows():
    client = FakeClient()
    store = SheetStore(client)
    src = _source()
    store.upsert(src, ["date", "v"], [["2026-06-21", "1"]])
    assert store.keys(src) == {"2026-06-21"}
    assert client.reads <= 1
