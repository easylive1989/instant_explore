from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from lorescape_backend.auth import AuthedUser, get_token_verifier, require_user
from lorescape_backend.config import Config
from lorescape_backend.narration.models import (
    HookItem,
    HooksResponse,
    NarrationResponse,
)
from lorescape_backend.narration.routes import get_config, router
from lorescape_backend.subscriptions.dependencies import (
    get_subscription_repository,
)


def _fake_config() -> Config:
    return Config(
        supabase_url="x",
        supabase_service_role_key="x",
        gemini_api_key="test-key",
        discord_webhook_url=None,
        discord_bot_token=None,
        discord_review_channel_id=None,
        discord_approver_ids=(),
        ig_user_id=None,
        meta_page_access_token=None,
        brand_handle_ig="",
        cta_text="",
        revenuecat_webhook_auth_token=None,
        revenuecat_api_key=None,
    )


class _FakeSubscriptions:
    def __init__(self, subscribed: bool = False) -> None:
        self._subscribed = subscribed

    def is_subscribed(self, _user_id: str) -> bool:
        return self._subscribed


def _make_app(
    subscriptions: _FakeSubscriptions | None = None,
) -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    app.dependency_overrides[get_config] = _fake_config
    app.dependency_overrides[require_user] = lambda: AuthedUser(
        user_id="user-1", is_anonymous=False
    )
    app.dependency_overrides[get_subscription_repository] = (
        lambda: subscriptions or _FakeSubscriptions()
    )
    return app


def _subscriber_app() -> FastAPI:
    """App where the authed user has an active subscription."""
    return _make_app(subscriptions=_FakeSubscriptions(subscribed=True))


@patch("lorescape_backend.narration.routes.service.generate_hooks")
def test_post_hooks_returns_payload(gen_hooks):
    gen_hooks.return_value = HooksResponse(
        hooks=[HookItem(id="h1", title="T1", teaser="Te1")],
        insufficient_source=False,
    )
    client = TestClient(_make_app())

    response = client.post(
        "/narration/hooks",
        json={
            "place_name": "Arles",
            "location": "Provence",
            "wikipedia_title": "Arles",
            "language": "zh-TW",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["hooks"][0]["id"] == "h1"
    assert body["insufficient_source"] is False
    # The route MUST pass the gemini key from config to the service.
    assert gen_hooks.call_args.kwargs["api_key"] == "test-key"


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_post_narration_returns_payload(gen_narration):
    gen_narration.return_value = NarrationResponse(
        place_name="亞爾",
        location="法國普羅旺斯",
        era="十九世紀末",
        paragraphs=["一", "二", "三"],
        pull_quote="",
        insufficient_source=False,
    )
    client = TestClient(_subscriber_app())

    response = client.post(
        "/narration",
        json={
            "place_name": "Arles",
            "location": "Provence",
            "wikipedia_title": "Arles",
            "language": "zh-TW",
            "hook": {"id": "h", "title": "梵谷", "teaser": "444 天"},
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["place_name"] == "亞爾"
    assert body["paragraphs"] == ["一", "二", "三"]
    assert body["insufficient_source"] is False


def test_post_hooks_rejects_unsupported_language():
    client = TestClient(_make_app())
    response = client.post(
        "/narration/hooks",
        json={
            "place_name": "x",
            "wikipedia_title": "x",
            "language": "ja",
        },
    )
    assert response.status_code == 400


def test_post_narration_rejects_unsupported_language():
    client = TestClient(_subscriber_app())
    response = client.post(
        "/narration",
        json={
            "place_name": "x",
            "wikipedia_title": "x",
            "language": "ja",
        },
    )
    assert response.status_code == 400


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_narration_route_accepts_wikidata_id(gen_narration):
    gen_narration.return_value = NarrationResponse(
        place_name="Test",
        location="Somewhere",
        era="modern",
        paragraphs=["a", "a", "a"],
        pull_quote="x",
        insufficient_source=False,
    )
    client = TestClient(_subscriber_app())

    res = client.post(
        "/narration",
        json={
            "wikidata_id": "Q1",
            "place_name": "Test",
            "location": "Somewhere",
            "language": "en",
        },
    )
    assert res.status_code == 200


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_narration_route_accepts_legacy_wikipedia_title(gen_narration):
    gen_narration.return_value = NarrationResponse(
        place_name="Macaron Park",
        location="Taoyuan",
        era="modern",
        paragraphs=["a", "a", "a"],
        pull_quote="x",
        insufficient_source=False,
    )
    client = TestClient(_subscriber_app())

    res = client.post(
        "/narration",
        json={
            "wikipedia_title": "Macaron Park",
            "place_name": "Macaron Park",
            "location": "Taoyuan",
            "language": "en",
        },
    )
    assert res.status_code == 200


def test_narration_route_400_when_no_identity_provided():
    client = TestClient(_make_app())
    res = client.post(
        "/narration",
        json={
            "place_name": "x",
            "location": "y",
            "language": "en",
        },
    )
    assert res.status_code in (400, 422)


class _NeverVerifier:
    """Token verifier that fails the test if ever consulted."""

    def verify(self, token: str):  # pragma: no cover - must not run
        raise AssertionError("verifier should not run without a token")


def test_narration_route_401_without_bearer_token():
    # An app WITHOUT a require_user override behaves like production: a
    # request carrying no Authorization header is rejected up front, before
    # the token verifier (which would hit Supabase) is ever consulted.
    app = FastAPI()
    app.include_router(router)
    app.dependency_overrides[get_config] = _fake_config
    app.dependency_overrides[get_token_verifier] = lambda: _NeverVerifier()
    app.dependency_overrides[get_subscription_repository] = _FakeSubscriptions
    client = TestClient(app)

    res = client.post(
        "/narration",
        json={
            "place_name": "x",
            "location": "y",
            "wikidata_id": "Q1",
            "language": "en",
        },
    )
    assert res.status_code == 401


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_narration_returns_402_for_free_user(gen_narration):
    """/narration is subscribers-only: free users get 402 (paywall signal)
    and Gemini must NOT be called."""
    client = TestClient(_make_app())  # default: not subscribed

    res = client.post(
        "/narration",
        json={"wikidata_id": "Q1", "place_name": "P", "language": "en"},
    )

    assert res.status_code == 402
    gen_narration.assert_not_called()


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_premium_user_can_generate(gen_narration):
    gen_narration.return_value = NarrationResponse(
        place_name="P",
        location="L",
        era="modern",
        paragraphs=["a", "b", "c"],
        pull_quote="q",
        insufficient_source=False,
    )
    client = TestClient(_subscriber_app())

    res = client.post(
        "/narration",
        json={"wikidata_id": "Q1", "place_name": "P", "language": "en"},
    )

    assert res.status_code == 200


@patch("lorescape_backend.narration.routes.service.generate_hooks")
def test_hooks_stay_free_for_unsubscribed_users(gen_hooks):
    """/narration/hooks has no subscription gate — the upsell funnel."""
    gen_hooks.return_value = HooksResponse(
        hooks=[HookItem(id="h1", title="T", teaser="t")],
        insufficient_source=False,
    )
    client = TestClient(_make_app())  # not subscribed

    res = client.post(
        "/narration/hooks",
        json={"wikidata_id": "Q1", "place_name": "P", "language": "en"},
    )

    assert res.status_code == 200
