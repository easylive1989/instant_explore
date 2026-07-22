"""Shared App Store Connect API helpers (base URL + JWT auth)."""
from __future__ import annotations

import time

from metrics._common import MetricsConfig

API = "https://api.appstoreconnect.apple.com/v1"


def token(cfg: MetricsConfig) -> str:
    """Mint a short-lived ES256 JWT for the App Store Connect API."""
    import jwt  # lazy: needs the `cryptography` extra

    now = int(time.time())
    with open(cfg.asc_key_path, encoding="utf-8") as f:
        key = f.read()
    return jwt.encode(
        {"iss": cfg.asc_issuer_id, "iat": now, "exp": now + 600,
         "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": cfg.asc_key_id},
    )
