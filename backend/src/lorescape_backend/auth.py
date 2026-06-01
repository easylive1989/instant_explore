"""Authentication for protected on-demand API endpoints.

Every protected route depends on :func:`require_user`, which reads the
``Authorization: Bearer <token>`` header, asks Supabase Auth who the token
belongs to, and exposes the result as an :class:`AuthedUser`.

Anonymous Supabase users (created via anonymous sign-in and not yet linked
to a real identity) are accepted just like registered users — the only
requirement is a valid, unexpired access token. Routes that need to gate a
feature on a *real* account can inspect ``AuthedUser.is_anonymous``.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Protocol

from fastapi import Depends, Header, HTTPException, status
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.dependencies import get_config

_BEARER_PREFIX = "Bearer "


@dataclass(frozen=True)
class AuthedUser:
    """The caller behind a request, resolved from their access token.

    ``is_anonymous`` is ``True`` for users created via Supabase anonymous
    sign-in who have not yet linked a real identity.
    """

    user_id: str
    is_anonymous: bool


class InvalidTokenError(Exception):
    """Raised when an access token is missing, expired, or invalid."""


class TokenVerifier(Protocol):
    """Verifies an access token and returns the authenticated user."""

    def verify(self, token: str) -> AuthedUser:
        ...


class SupabaseTokenVerifier:
    """Verifies tokens by asking Supabase Auth who the token belongs to."""

    def __init__(self, url: str, service_role_key: str) -> None:
        self._client = create_client(url, service_role_key)

    def verify(self, token: str) -> AuthedUser:
        try:
            response = self._client.auth.get_user(token)
        except Exception as exc:  # network error / rejected token
            raise InvalidTokenError(str(exc)) from exc
        user = getattr(response, "user", None)
        if user is None:
            raise InvalidTokenError("token did not resolve to a user")
        return AuthedUser(
            user_id=user.id,
            is_anonymous=bool(getattr(user, "is_anonymous", False)),
        )


@lru_cache(maxsize=None)
def _cached_verifier(url: str, service_role_key: str) -> SupabaseTokenVerifier:
    return SupabaseTokenVerifier(url, service_role_key)


def get_token_verifier(
    config: Config = Depends(get_config),
) -> TokenVerifier:
    """FastAPI dependency providing the token verifier — overridden in tests."""
    return _cached_verifier(
        config.supabase_url, config.supabase_service_role_key
    )


def require_user(
    authorization: str | None = Header(default=None),
    verifier: TokenVerifier = Depends(get_token_verifier),
) -> AuthedUser:
    """Authenticate the caller, accepting both anonymous and real users.

    Raises ``401`` when the bearer token is absent, malformed, expired, or
    otherwise rejected by Supabase.
    """
    if not authorization or not authorization.startswith(_BEARER_PREFIX):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )
    token = authorization[len(_BEARER_PREFIX):].strip()
    try:
        return verifier.verify(token)
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc
