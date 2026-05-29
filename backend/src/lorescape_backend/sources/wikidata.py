"""Wikidata claims fetcher + narrative formatter.

Fetches a small whitelist of properties for a Q-id and serialises them
into a `"Key: value"` plaintext block consumable by the story prompt.

Supported properties (whitelist; in display order):
  P31  → "Type: <label>"
  P571 → "Founded: <year>"
  P138 → "Named after: <label>"
  P131 → "Located in: <label>"
  P17  → "Country: <label>"
  P361 → "Part of: <label>"

Returns None (never raises) on:
  - missing entity
  - no whitelisted claims
  - any HTTP error
"""
from __future__ import annotations

import logging
import re
from typing import Iterable

import requests
from cachetools import TTLCache, cached
from cachetools.keys import hashkey

logger = logging.getLogger(__name__)

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_API = "https://www.wikidata.org/w/api.php"
_TIMEOUT = 30

# (property id, display label, value extractor)
_PROP_ORDER: list[tuple[str, str, str]] = [
    ("P31", "Type", "entity"),
    ("P571", "Founded", "year"),
    ("P138", "Named after", "entity"),
    ("P131", "Located in", "entity"),
    ("P17", "Country", "entity"),
    ("P361", "Part of", "entity"),
]

_entity_cache: TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)


@cached(_entity_cache, key=lambda qid: hashkey(qid))
def fetch_entity_claims(qid: str) -> str | None:
    """Return a `"Key: value"` block of whitelisted claims, or None."""
    entity = _fetch_entity(qid)
    if entity is None:
        return None

    claims = entity.get("claims") or {}
    extracted: list[tuple[str, str]] = []
    referenced_ids: list[str] = []

    for prop_id, label, kind in _PROP_ORDER:
        statements = claims.get(prop_id)
        if not isinstance(statements, list) or not statements:
            continue
        first = statements[0]
        mainsnak = first.get("mainsnak") or {}
        if mainsnak.get("snaktype") != "value":
            continue
        value_payload = (mainsnak.get("datavalue") or {}).get("value")
        if value_payload is None:
            continue

        if kind == "year":
            year = _extract_year(value_payload)
            if year:
                extracted.append((label, year))
        elif kind == "entity":
            entity_id = (
                value_payload.get("id")
                if isinstance(value_payload, dict)
                else None
            )
            if isinstance(entity_id, str):
                extracted.append((label, entity_id))
                referenced_ids.append(entity_id)

    if not extracted:
        return None

    labels = _fetch_labels(referenced_ids) if referenced_ids else {}

    lines: list[str] = []
    for prop_label, value in extracted:
        if prop_label == "Founded":
            lines.append(f"Founded: {value}")
        else:
            human = labels.get(value, value)
            lines.append(f"{prop_label}: {human}")
    return "\n".join(lines)


def _fetch_entity(qid: str) -> dict | None:
    try:
        response = requests.get(
            _API,
            params={
                "action": "wbgetentities",
                "ids": qid,
                "props": "claims",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.wikidata.entity_failed",
            extra={"qid": qid, "err": str(exc)},
        )
        return None
    entity = (response.json().get("entities") or {}).get(qid)
    if not isinstance(entity, dict) or "missing" in entity:
        return None
    return entity


def _fetch_labels(ids: Iterable[str]) -> dict[str, str]:
    unique_ids = list(dict.fromkeys(ids))  # preserve order, dedupe
    if not unique_ids:
        return {}
    try:
        response = requests.get(
            _API,
            params={
                "action": "wbgetentities",
                "ids": "|".join(unique_ids),
                "props": "labels",
                "languages": "en",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.wikidata.labels_failed",
            extra={"ids": unique_ids, "err": str(exc)},
        )
        return {}

    out: dict[str, str] = {}
    entities = response.json().get("entities") or {}
    for entity_id, payload in entities.items():
        label = (
            ((payload.get("labels") or {}).get("en") or {}).get("value")
        )
        if isinstance(label, str):
            out[entity_id] = label
    return out


_YEAR_RE = re.compile(r"^[+-]?(\d{1,4})")


def _extract_year(value_payload: object) -> str | None:
    if not isinstance(value_payload, dict):
        return None
    time_str = value_payload.get("time")
    if not isinstance(time_str, str):
        return None
    match = _YEAR_RE.match(time_str)
    return match.group(1) if match else None
