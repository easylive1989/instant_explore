"""Wikipedia extract fetcher anchored on Wikidata Q-id.

Two-step lookup:
  1. Wikidata wbgetentities → sitelinks → resolve Q-id to a wiki title
     in the requested language.
  2. MediaWiki `prop=extracts&exintro=1&explaintext=1` for that title.

Wraps both lookups in a 7-day TTL cache so the same Q-id+lang served
from memory on repeat requests within the same process.

Returns None (never raises) on:
  - missing sitelink for requested language
  - missing extract on the wiki page
  - any HTTP error
This is graceful-degrade by design: the source pipeline must tolerate
each individual provider failing.
"""
from __future__ import annotations

import logging

import requests
from cachetools import TTLCache, cached
from cachetools.keys import hashkey

logger = logging.getLogger(__name__)

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_WIKIDATA_API = "https://www.wikidata.org/w/api.php"
_EN_WIKI_API_URL = "https://en.wikipedia.org/w/api.php"
_TIMEOUT = 30

# 7-day TTL × 5000 entries × ~2KB ≈ 10MB max. Restart clears cache;
# Wikipedia/Wikidata APIs remain the source of truth.
_extract_cache: TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)


@cached(_extract_cache, key=lambda qid, lang: hashkey(qid, lang))
def fetch_extract_by_qid(qid: str, lang: str) -> str | None:
    """Resolve Q-id to a Wikipedia title in `lang`, then return its intro extract.

    `lang` is the wiki language code (e.g. `"zh"`, `"en"`) — NOT the
    request locale (e.g. `"zh-TW"`). Callers should strip region tags
    before invoking.
    """
    title = _resolve_sitelink_title(qid, lang)
    if title is None:
        return None
    return _fetch_intro_extract(title, lang)


def _resolve_sitelink_title(qid: str, lang: str) -> str | None:
    try:
        response = requests.get(
            _WIKIDATA_API,
            params={
                "action": "wbgetentities",
                "ids": qid,
                "props": "sitelinks",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.wikipedia.sitelinks_failed",
            extra={"qid": qid, "err": str(exc)},
        )
        return None

    data = response.json()
    entity = (data.get("entities") or {}).get(qid)
    if not isinstance(entity, dict):
        return None
    sitelinks = entity.get("sitelinks") or {}
    link = sitelinks.get(f"{lang}wiki")
    if not isinstance(link, dict):
        return None
    title = link.get("title")
    return title if isinstance(title, str) else None


def _fetch_intro_extract(title: str, lang: str) -> str | None:
    try:
        response = requests.get(
            f"https://{lang}.wikipedia.org/w/api.php",
            params={
                "action": "query",
                "format": "json",
                "titles": title,
                "prop": "extracts",
                "explaintext": 1,
                "exintro": 1,
                "redirects": 1,
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.wikipedia.extract_failed",
            extra={"lang": lang, "title": title, "err": str(exc)},
        )
        return None

    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        extract = page.get("extract")
        if isinstance(extract, str) and extract:
            return extract
    return None


def fetch_intro_extract(title: str) -> str:
    """Fetch the plaintext intro section of `title` via MediaWiki extracts API.

    The REST `/page/summary` endpoint only returns the lead paragraph
    (~200 chars for many places), which is too thin to ground a real
    story. The MediaWiki `prop=extracts` query with `exintro=1` returns
    the full intro section (typically 1-5k chars) — enough to mention
    the people and events a story needs.

    Returns the extracted plaintext (may be empty if the page has no
    intro or does not exist).

    Copied from daily_story/wikipedia.py — legacy wikipedia_title App path
    (see sources/pipeline.py).
    """
    response = requests.get(
        _EN_WIKI_API_URL,
        params={
            "action": "query",
            "format": "json",
            "titles": title,
            "prop": "extracts",
            "explaintext": 1,
            "exintro": 1,
            "redirects": 1,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        extract = page.get("extract")
        if extract:
            return extract
    return ""
