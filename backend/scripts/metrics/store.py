"""Storage backends for the accumulating metrics datasets.

A store maps each :class:`DailySource` to one tab-shaped dataset (header row
plus data rows) and supports reading the existing keys and upserting fresh
rows. :class:`SheetStore` persists to a Google Sheet (the production source
of truth); :class:`MemoryStore` keeps data in-process for tests.
"""
from __future__ import annotations

from scripts.metrics._common import DailySource, merge_rows
from scripts.metrics.sheets import SheetClient


class MetricsStore:
    """Read/upsert datasets keyed by a source's key column.

    Subclasses implement :meth:`read` and :meth:`_write`; the merge and key
    extraction are shared so every backend de-duplicates identically.
    """

    def read(self, source: DailySource) -> tuple[list[str], list[list[str]]]:
        """Return (headers, rows) currently stored for `source`."""
        raise NotImplementedError

    def _write(
        self, source: DailySource, headers: list[str], rows: list[list[str]]
    ) -> None:
        """Overwrite `source`'s dataset with the given headers and rows."""
        raise NotImplementedError

    def keys(self, source: DailySource) -> set[str]:
        """Return the key-column values already stored for `source`."""
        _, rows = self.read(source)
        ki = source.key_index
        return {row[ki] for row in rows if len(row) > ki}

    def upsert(
        self, source: DailySource, headers: list[str], new_rows: list[list[str]]
    ) -> None:
        """Merge `new_rows` into `source`'s dataset and persist the result."""
        _, existing = self.read(source)
        self._write(source, headers, merge_rows(existing, new_rows, source.key_index))


class SheetStore(MetricsStore):
    """Persist datasets to a Google Sheet, one tab per source.

    Reads are cached for the lifetime of the store so a run that both plans
    the backfill window and upserts only fetches each tab once.
    """

    def __init__(self, client: SheetClient) -> None:
        self._client = client
        self._cache: dict[str, list[list[str]]] = {}

    @property
    def sheet_id(self) -> str:
        return self._client.sheet_id

    def _values(self, name: str) -> list[list[str]]:
        if name not in self._cache:
            self._cache[name] = self._client.read_tab(name)
        return self._cache[name]

    def read(self, source: DailySource) -> tuple[list[str], list[list[str]]]:
        values = self._values(source.name)
        if not values:
            return [], []
        return values[0], values[1:]

    def _write(
        self, source: DailySource, headers: list[str], rows: list[list[str]]
    ) -> None:
        self._client.write_tab(source.name, [headers, *rows])
        self._cache[source.name] = [headers, *rows]


class MemoryStore(MetricsStore):
    """In-process store backed by a dict, for tests and dry experiments."""

    def __init__(self) -> None:
        self._data: dict[str, tuple[list[str], list[list[str]]]] = {}

    def seed(
        self, name: str, headers: list[str], rows: list[list[str]]
    ) -> None:
        """Pre-populate a source's dataset (test helper)."""
        self._data[name] = (headers, rows)

    def read(self, source: DailySource) -> tuple[list[str], list[list[str]]]:
        return self._data.get(source.name, ([], []))

    def _write(
        self, source: DailySource, headers: list[str], rows: list[list[str]]
    ) -> None:
        self._data[source.name] = (headers, rows)
