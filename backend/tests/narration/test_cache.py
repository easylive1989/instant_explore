"""Tests for narration/cache.py — HooksCacheRepository + place_key_for."""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import MagicMock

from lorescape_backend.narration.cache import (
    HooksCacheRepository,
    place_key_for,
)
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    HooksResponse,
)


def _client_returning(rows: list[dict]) -> MagicMock:
    """Supabase client whose select chain resolves to `rows`."""
    client = MagicMock()
    (
        client.table.return_value.select.return_value
        .eq.return_value.eq.return_value
        .limit.return_value.execute.return_value
    ) = SimpleNamespace(data=rows)
    return client


def test_place_key_prefers_wikidata_id():
    req = HooksRequest(
        wikidata_id="Q48292", place_name="Arles", language="en",
    )
    assert place_key_for(req) == "Q48292"


def test_place_key_falls_back_to_title():
    req = HooksRequest(
        wikipedia_title="Arles", place_name="Arles", language="en",
    )
    assert place_key_for(req) == "title:Arles"


def test_get_returns_parsed_response_on_hit():
    client = _client_returning(
        [{"hooks": [{"id": "h1", "title": "T", "teaser": "t"}]}]
    )
    repo = HooksCacheRepository(client)

    result = repo.get("Q48292", "en")

    assert result is not None
    assert result.hooks[0].id == "h1"
    assert result.insufficient_source is False


def test_get_returns_none_on_miss():
    repo = HooksCacheRepository(_client_returning([]))
    assert repo.get("Q1", "en") is None


def test_get_returns_none_when_client_raises():
    client = MagicMock()
    client.table.side_effect = RuntimeError("supabase down")
    repo = HooksCacheRepository(client)

    assert repo.get("Q1", "en") is None  # never raises


def test_put_upserts_dumped_hooks():
    client = MagicMock()
    repo = HooksCacheRepository(client)

    repo.put(
        "Q48292",
        "en",
        HooksResponse(
            hooks=[HookItem(id="h1", title="T", teaser="t")],
            insufficient_source=False,
        ),
    )

    payload = client.table.return_value.upsert.call_args.args[0]
    assert payload["place_key"] == "Q48292"
    assert payload["language"] == "en"
    assert payload["hooks"] == [{"id": "h1", "title": "T", "teaser": "t"}]


def test_put_skips_insufficient_and_empty_results():
    client = MagicMock()
    repo = HooksCacheRepository(client)

    repo.put("Q1", "en", HooksResponse(hooks=[], insufficient_source=True))
    repo.put("Q1", "en", HooksResponse(hooks=[], insufficient_source=False))

    client.table.assert_not_called()


def test_put_swallows_client_errors():
    client = MagicMock()
    client.table.side_effect = RuntimeError("supabase down")
    repo = HooksCacheRepository(client)

    repo.put(
        "Q1",
        "en",
        HooksResponse(
            hooks=[HookItem(id="h", title="T", teaser="t")],
            insufficient_source=False,
        ),
    )  # must not raise
