"""Tests for the bearer-token auth dependency."""
from __future__ import annotations

from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from lorescape_backend.auth import (
    AuthedUser,
    InvalidTokenError,
    get_token_verifier,
    require_user,
)


class _FakeVerifier:
    """Records the token it was handed and returns a fixed user or error."""

    def __init__(self, user: AuthedUser | None = None,
                 error: Exception | None = None) -> None:
        self._user = user
        self._error = error
        self.seen_token: str | None = None

    def verify(self, token: str) -> AuthedUser:
        self.seen_token = token
        if self._error is not None:
            raise self._error
        assert self._user is not None
        return self._user


def _app(verifier: _FakeVerifier) -> FastAPI:
    app = FastAPI()

    @app.get("/whoami")
    def whoami(user: AuthedUser = Depends(require_user)) -> dict:
        return {"user_id": user.user_id, "is_anonymous": user.is_anonymous}

    app.dependency_overrides[get_token_verifier] = lambda: verifier
    return app


def test_missing_authorization_header_returns_401():
    client = TestClient(_app(_FakeVerifier()))
    assert client.get("/whoami").status_code == 401


def test_non_bearer_scheme_returns_401():
    client = TestClient(_app(_FakeVerifier()))
    res = client.get("/whoami", headers={"Authorization": "Basic abc"})
    assert res.status_code == 401


def test_invalid_token_returns_401():
    verifier = _FakeVerifier(error=InvalidTokenError("bad token"))
    client = TestClient(_app(verifier))

    res = client.get("/whoami", headers={"Authorization": "Bearer xxx"})

    assert res.status_code == 401
    assert verifier.seen_token == "xxx"


def test_valid_token_resolves_anonymous_user():
    verifier = _FakeVerifier(
        user=AuthedUser(user_id="u-123", is_anonymous=True)
    )
    client = TestClient(_app(verifier))

    res = client.get("/whoami", headers={"Authorization": "Bearer tok-1"})

    assert res.status_code == 200
    assert res.json() == {"user_id": "u-123", "is_anonymous": True}
    assert verifier.seen_token == "tok-1"


def test_valid_token_resolves_registered_user():
    verifier = _FakeVerifier(
        user=AuthedUser(user_id="u-456", is_anonymous=False)
    )
    client = TestClient(_app(verifier))

    res = client.get("/whoami", headers={"Authorization": "Bearer tok-2"})

    assert res.status_code == 200
    assert res.json() == {"user_id": "u-456", "is_anonymous": False}
