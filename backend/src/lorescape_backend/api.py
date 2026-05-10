"""Minimal FastAPI app — placeholder for future endpoints.

For now, exposes only `/health` so the deployment can be monitored.
"""
from __future__ import annotations

from fastapi import FastAPI

app = FastAPI(title="Lorescape Backend", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
