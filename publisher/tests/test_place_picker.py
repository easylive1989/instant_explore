from unittest.mock import MagicMock, ANY

import pytest

from lorescape_publisher.daily_story.place_picker import (
    PickedPlace,
    pick_next_place,
    mark_place_used,
)


def _mock_supabase_with_query_result(rows: list[dict]) -> MagicMock:
    """Build a chained-mock Supabase client whose .table().select()....execute()
    chain returns a response with `data = rows`."""
    response = MagicMock()
    response.data = rows
    chain = MagicMock()
    chain.select.return_value = chain
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.order.return_value = chain
    chain.limit.return_value = chain
    chain.update.return_value = chain
    chain.execute.return_value = response
    client = MagicMock()
    client.table.return_value = chain
    return client


def test_pick_next_place_picks_unused_active_when_present():
    client = _mock_supabase_with_query_result(
        [{"id": "p1", "wikipedia_title_en": "Colosseum"}]
    )

    place = pick_next_place(client)

    assert place == PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    # Verify the right table was queried first
    client.table.assert_any_call("daily_story_places")


def test_pick_next_place_returns_none_when_no_places():
    """If neither unused nor recyclable rows exist, return None.

    To simulate this, we configure the chain so .execute() always returns empty.
    """
    client = _mock_supabase_with_query_result([])

    assert pick_next_place(client) is None


def test_pick_next_place_recycles_oldest_when_all_used(mocker):
    """When the unused query returns empty, the picker should fall back to the
    oldest used active place (re-cycle)."""
    response_empty = MagicMock()
    response_empty.data = []
    response_recycle = MagicMock()
    response_recycle.data = [{"id": "p_old", "wikipedia_title_en": "Old Place"}]

    chain = MagicMock()
    chain.select.return_value = chain
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.order.return_value = chain
    chain.limit.return_value = chain
    # First call → empty (unused query); second call → recycle result
    chain.execute.side_effect = [response_empty, response_recycle]

    client = MagicMock()
    client.table.return_value = chain

    place = pick_next_place(client)
    assert place == PickedPlace(id="p_old", wikipedia_title_en="Old Place")


def test_mark_place_used_calls_update_with_now_timestamp():
    client = _mock_supabase_with_query_result([])
    mark_place_used(client, "p1")

    client.table.assert_called_with("daily_story_places")
    chain = client.table.return_value
    chain.update.assert_called_once()
    payload = chain.update.call_args[0][0]
    assert "used_at" in payload
    # Should be ISO-8601 UTC timestamp
    assert "T" in payload["used_at"]
    chain.eq.assert_called_with("id", "p1")
    chain.execute.assert_called()
