"""Shared FastAPI dependencies."""
from __future__ import annotations

from fastapi import Depends
from supabase import Client, create_client

from lorescape_backend.config import Config


def get_config() -> Config:
    """FastAPI dependency providing app config — overridden in tests."""
    return Config.from_env()


def get_supabase_client(config: Config = Depends(get_config)) -> Client:
    """Service-role Supabase client, shared across one request's dependencies.

    FastAPI caches dependency results per request, so repositories that depend
    on this all receive the same client instance.
    """
    return create_client(
        config.supabase_url, config.supabase_service_role_key
    )
