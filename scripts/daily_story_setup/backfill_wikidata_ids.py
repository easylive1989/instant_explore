"""Backfill daily_story_places.wikidata_id from wikipedia_title_en.

One-shot maintenance script. Resolves each place still missing a
`wikidata_id` via the MediaWiki `pageprops.wikibase_item` API, then updates
the row. Rows that can't be resolved are logged and left untouched.

Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (service-role key required to
update rows under RLS).

Run: `python backfill_wikidata_ids.py`
"""

from __future__ import annotations

import os
import sys

import requests

WIKIPEDIA_API_URL = "https://en.wikipedia.org/w/api.php"
USER_AGENT = (
    "lorescape-daily-story-setup/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)


def resolve_qid_from_title(title: str) -> str | None:
    """Return the Wikidata Q-id for an enwiki page title, or None."""
    response = requests.get(
        WIKIPEDIA_API_URL,
        params={
            "action": "query",
            "prop": "pageprops",
            "ppprop": "wikibase_item",
            "redirects": "1",
            "titles": title,
            "format": "json",
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        qid = page.get("pageprops", {}).get("wikibase_item")
        if qid:
            return qid
    return None


def _create_client():
    from supabase import create_client

    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(url, key)


def main() -> int:
    client = _create_client()
    response = (
        client.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .is_("wikidata_id", "null")
        .execute()
    )
    rows = response.data or []
    print(f"{len(rows)} places missing wikidata_id")

    resolved = 0
    for row in rows:
        title = row["wikipedia_title_en"]
        qid = resolve_qid_from_title(title)
        if qid is None:
            print(f"  UNRESOLVED: {title!r}")
            continue
        client.table("daily_story_places").update({"wikidata_id": qid}).eq(
            "id", row["id"]
        ).execute()
        resolved += 1
        print(f"  {title!r} -> {qid}")

    print(f"Backfilled {resolved}/{len(rows)} places")
    return 0


if __name__ == "__main__":
    sys.exit(main())
