"""Shared FastAPI dependencies."""
from __future__ import annotations

from lorescape_backend.config import Config


def get_config() -> Config:
    """FastAPI dependency providing app config — overridden in tests."""
    return Config.from_env()
