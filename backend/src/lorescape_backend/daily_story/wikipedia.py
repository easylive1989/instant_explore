"""Wikipedia REST/MediaWiki API client.

Two endpoints used:
- REST `/page/summary/{title}` for extract + thumbnail (English ground truth)
- MediaWiki `?action=query&prop=langlinks` for target-language article URLs
"""
from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import quote

import requests

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_REST_BASE = "https://en.wikipedia.org/api/rest_v1"
_API_URL = "https://en.wikipedia.org/w/api.php"


@dataclass(frozen=True)
class WikipediaSummary:
    title: str
    extract: str
    image_url: str | None
    en_url: str


def fetch_summary(title: str) -> WikipediaSummary:
    """Fetch the English Wikipedia summary for `title`.

    `title` may contain spaces; the path segment is URL-encoded.
    """
    encoded = quote(title, safe="")
    response = requests.get(
        f"{_REST_BASE}/page/summary/{encoded}",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    return WikipediaSummary(
        title=data["title"],
        extract=data.get("extract", ""),
        image_url=(data.get("thumbnail") or {}).get("source"),
        en_url=data["content_urls"]["desktop"]["page"],
    )


def fetch_intro_extract(title: str) -> str:
    """Fetch the plaintext intro section of `title` via MediaWiki extracts API.

    The REST `/page/summary` endpoint only returns the lead paragraph
    (~200 chars for many places), which is too thin to ground a real
    story. The MediaWiki `prop=extracts` query with `exintro=1` returns
    the full intro section (typically 1-5k chars) — enough to mention
    the people and events a story needs.

    Returns the extracted plaintext (may be empty if the page has no
    intro or does not exist).
    """
    response = requests.get(
        _API_URL,
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


def fetch_langlink_url(title: str, target_lang: str) -> str | None:
    """Find the URL of `title`'s article in `target_lang` (e.g. 'zh').

    Returns None if no langlink to that language exists.
    Constructs the URL deterministically from the langlink title — does NOT
    rely on the API returning a `url` field.
    """
    response = requests.get(
        _API_URL,
        params={
            "action": "query",
            "format": "json",
            "titles": title,
            "prop": "langlinks",
            "lllang": target_lang,
            "redirects": 1,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        for link in page.get("langlinks", []):
            target_title = link.get("*") or link.get("title")
            if not target_title:
                continue
            return _wiki_url(target_lang, target_title)
    return None


def _wiki_url(lang: str, title: str) -> str:
    return f"https://{lang}.wikipedia.org/wiki/{quote(title.replace(' ', '_'))}"
