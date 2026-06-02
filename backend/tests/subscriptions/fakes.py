"""Shared in-memory fakes for subscription tests."""
from __future__ import annotations

from lorescape_backend.subscriptions.models import SubscriptionEvent


class FakeResponse:
    def __init__(self, data) -> None:
        self.data = data


class FakeQuery:
    def __init__(self, response: FakeResponse) -> None:
        self._response = response

    def select(self, *_args, **_kwargs) -> "FakeQuery":
        return self

    def execute(self) -> FakeResponse:
        return self._response


class FakeSupabaseClient:
    """Records RPC calls and serves canned responses."""

    def __init__(self, *, subscribed: bool = False,
                 user_ids: list[str] | None = None) -> None:
        self.rpc_calls: list[tuple[str, dict]] = []
        self._subscribed = subscribed
        self._user_ids = user_ids or []

    def rpc(self, name: str, params: dict) -> FakeQuery:
        self.rpc_calls.append((name, params))
        if name == "is_user_subscribed":
            return FakeQuery(FakeResponse(self._subscribed))
        return FakeQuery(FakeResponse(None))

    def table(self, _name: str) -> FakeQuery:
        rows = [{"user_id": uid} for uid in self._user_ids]
        return FakeQuery(FakeResponse(rows))


class FakeSubscriptionRepository:
    """Captures applied events and serves canned subscriber lists."""

    def __init__(self, user_ids: list[str] | None = None) -> None:
        self.applied: list[SubscriptionEvent] = []
        self._user_ids = user_ids or []

    def apply_event(self, event: SubscriptionEvent) -> None:
        self.applied.append(event)

    def list_user_ids(self) -> list[str]:
        return list(self._user_ids)
