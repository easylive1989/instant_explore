from __future__ import annotations

import csv

from metrics._common import DailySource
from metrics.store import FileStore


def _source(name="demo", key_index=0):
    return DailySource(
        name=name,
        filename=f"{name}.csv",
        headers=["date", "v"],
        required=(),
        fetch=lambda cfg, s, e: [],
        key_index=key_index,
    )


def _seed(directory, name, values):
    directory.mkdir(parents=True, exist_ok=True)
    with (directory / f"{name}.csv").open("w", newline="") as f:
        csv.writer(f).writerows(values)


def _read(directory, name):
    with (directory / f"{name}.csv").open(newline="") as f:
        return list(csv.reader(f))


def test_keys_reads_first_column(tmp_path):
    _seed(tmp_path, "demo", [["date", "v"], ["2026-06-20", "5"]])
    assert FileStore(tmp_path).keys(_source()) == {"2026-06-20"}


def test_keys_composite_index_returns_tuples(tmp_path):
    _seed(tmp_path, "demo", [
        ["media_id", "obs_date", "v"],
        ["m1", "2026-06-22", "1"],
        ["m1", "2026-06-23", "2"],
    ])
    assert FileStore(tmp_path).keys(_source(key_index=(0, 1))) == {
        ("m1", "2026-06-22"), ("m1", "2026-06-23"),
    }


def test_keys_missing_file_returns_empty_set(tmp_path):
    assert FileStore(tmp_path).keys(_source()) == set()


def test_upsert_merges_existing_and_writes_with_header(tmp_path):
    _seed(tmp_path, "demo", [["date", "v"], ["2026-06-21", "8"]])
    store = FileStore(tmp_path)
    store.upsert(_source(), ["date", "v"], [["2026-06-22", "5"]])
    assert _read(tmp_path, "demo") == [
        ["date", "v"], ["2026-06-21", "8"], ["2026-06-22", "5"],
    ]


def test_upsert_overwrites_same_key(tmp_path):
    _seed(tmp_path, "demo", [["date", "v"], ["2026-06-21", "8"]])
    store = FileStore(tmp_path)
    store.upsert(_source(), ["date", "v"], [["2026-06-21", "99"]])
    assert _read(tmp_path, "demo") == [["date", "v"], ["2026-06-21", "99"]]


def test_upsert_creates_directory_and_file(tmp_path):
    store = FileStore(tmp_path / "nested")
    src = _source()
    store.upsert(src, ["date", "v"], [["2026-06-21", "1"]])
    assert store.keys(src) == {"2026-06-21"}


def test_cell_with_comma_survives_roundtrip(tmp_path):
    store = FileStore(tmp_path)
    store.upsert(_source(), ["date", "v"], [["2026-06-21", "a, b"]])
    _, rows = store.read(_source())
    assert rows == [["2026-06-21", "a, b"]]
