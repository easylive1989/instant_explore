"""測試用最小記憶體 Supabase 假件（只支援 social_posts 用到的操作）。"""
from __future__ import annotations

from typing import Any


class _Result:
    def __init__(self, data):
        self.data = data


class _Query:
    def __init__(self, rows: list[dict], op: str, payload: Any = None):
        self._rows = rows
        self._op = op
        self._payload = payload
        self._filters: list[tuple[str, str, Any]] = []

    def eq(self, col, val):
        self._filters.append(("eq", col, val))
        return self

    def is_(self, col, val):
        self._filters.append(("is", col, val))
        return self

    def lte(self, col, val):
        self._filters.append(("lte", col, val))
        return self

    def limit(self, _n):
        return self

    def _match(self, row) -> bool:
        for kind, col, val in self._filters:
            if kind == "eq" and row.get(col) != val:
                return False
            if kind == "is" and not (val == "null" and row.get(col) is None):
                return False
            if kind == "lte" and not (
                row.get(col) is not None and row[col] <= val
            ):
                return False
        return True

    def execute(self):
        matched = [r for r in self._rows if self._match(r)]
        if self._op == "select":
            return _Result([dict(r) for r in matched])
        if self._op == "update":
            for r in matched:
                r.update(self._payload)
            return _Result([dict(r) for r in matched])
        raise AssertionError(f"unsupported op {self._op}")


class _Table:
    def __init__(self, rows: list[dict]):
        self._rows = rows

    def select(self, *_a, **_k):
        return _Query(self._rows, "select")

    def update(self, payload):
        return _Query(self._rows, "update", payload)

    def upsert(self, payload, *, on_conflict=None):
        key_cols = (on_conflict or "").split(",")
        existing = None
        for r in self._rows:
            if all(r.get(c) == payload.get(c) for c in key_cols if c):
                existing = r
                break
        if existing is not None:
            existing.update(payload)
        else:
            self._rows.append(dict(payload))
        return _NoopExecute()


class _NoopExecute:
    def execute(self):
        return _Result(None)


class FakeSupabase:
    """支援 social_posts CRUD 的假 client。`.rows` 為底層資料。"""

    def __init__(self, rows: list[dict] | None = None):
        self.rows = rows or []

    def table(self, name):
        assert name == "social_posts", f"unexpected table {name}"
        return _Table(self.rows)
