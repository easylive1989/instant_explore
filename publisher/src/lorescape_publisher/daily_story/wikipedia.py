"""Wikipedia REST/MediaWiki API client.

Two endpoints used:
- REST `/page/summary/{title}` for extract + thumbnail (English ground truth)
- MediaWiki `?action=query&prop=langlinks` for target-language article URLs
"""
from __future__ import annotations

import re
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


@dataclass(frozen=True)
class LeadImage:
    """A page's lead image with its Wikimedia licence metadata.

    `is_commercial_ok` is True only for licences that allow commercial reuse
    (public domain, CC0, CC BY, CC BY-SA). `attribution` is the credit string
    to display alongside the image (None when the image is not commercially
    usable, since we won't post it).
    """

    url: str
    license_short: str | None
    license_code: str | None
    artist: str | None
    attribution: str | None
    is_commercial_ok: bool


def fetch_lead_image(title: str) -> LeadImage | None:
    """Fetch the page's lead image together with its licence metadata.

    Unlike the REST summary thumbnail (which carries no licence info), this
    resolves the lead image file and queries Wikimedia `imageinfo`
    `extmetadata` so the caller can filter to commercially reusable images
    and record the required attribution.

    Returns None when the page has no lead image or the file has no usable
    image info.
    """
    file_name = _fetch_lead_image_filename(title)
    if not file_name:
        return None
    info = _fetch_file_imageinfo(file_name)
    if not info:
        return None
    url = info.get("url")
    if not url:
        return None
    meta = info.get("extmetadata", {}) or {}
    license_short = _meta_value(meta, "LicenseShortName")
    license_code = _meta_value(meta, "License")
    non_free = _meta_value(meta, "NonFree")
    artist = _clean_html(_meta_value(meta, "Artist"))
    ok = _is_commercial_ok(license_code, license_short, non_free)
    attribution = _build_attribution(artist, license_short) if ok else None
    return LeadImage(
        url=url,
        license_short=license_short,
        license_code=license_code,
        artist=artist,
        attribution=attribution,
        is_commercial_ok=ok,
    )


def _fetch_lead_image_filename(title: str) -> str | None:
    response = requests.get(
        _API_URL,
        params={
            "action": "query",
            "format": "json",
            "titles": title,
            "prop": "pageimages",
            "piprop": "name",
            "redirects": 1,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        name = page.get("pageimage")
        if name:
            return name
    return None


def _fetch_file_imageinfo(file_name: str) -> dict | None:
    response = requests.get(
        _API_URL,
        params={
            "action": "query",
            "format": "json",
            "titles": f"File:{file_name}",
            "prop": "imageinfo",
            "iiprop": "url|extmetadata",
            "redirects": 1,
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        infos = page.get("imageinfo")
        if infos:
            return infos[0]
    return None


def _meta_value(meta: dict, key: str) -> str | None:
    entry = meta.get(key)
    if not entry:
        return None
    value = entry.get("value")
    return value if value else None


def _is_commercial_ok(
    license_code: str | None,
    license_short: str | None,
    non_free: str | None,
) -> bool:
    """Allow only licences that permit commercial reuse.

    Whitelist: public domain, CC0, CC BY, CC BY-SA. Anything carrying a
    NonCommercial (NC) or NoDerivatives (ND) term, marked non-free
    (fair use), or with an unknown licence is rejected.
    """
    if non_free and str(non_free).strip().lower() not in ("0", "false", ""):
        return False

    code = (license_code or "").strip().lower()
    short = (license_short or "").strip().lower()
    if not code and not short:
        return False

    # Reject non-commercial / no-derivatives variants outright.
    if "nc" in re.split(r"[-\s]", code) or "nc" in re.split(r"[-\s]", short):
        return False
    if "nd" in re.split(r"[-\s]", code) or "nd" in re.split(r"[-\s]", short):
        return False
    if "noncommercial" in short or "non-commercial" in short:
        return False

    if code.startswith(("cc0", "pd", "cc-by")):
        return True
    if "public domain" in short or short.startswith(("cc0", "cc by")):
        return True
    return False


def _build_attribution(artist: str | None, license_short: str | None) -> str | None:
    parts = [p for p in (artist, license_short) if p]
    if not parts:
        return None
    return " / ".join(parts) + " (via Wikimedia Commons)"


def _clean_html(value: str | None) -> str | None:
    if not value:
        return None
    text = re.sub(r"<[^>]+>", "", value)
    text = re.sub(r"\s+", " ", text).strip()
    return text or None


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
