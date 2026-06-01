"""Fetch World Heritage Sites from Wikidata SPARQL and write CSV.

One-shot setup script. Run with `python fetch_world_heritage_sites.py`.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote

import requests

WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"

SPARQL_QUERY = """
SELECT ?item ?itemLabel ?countryLabel ?enwiki WHERE {
  ?item wdt:P1435 wd:Q9259.
  OPTIONAL { ?item wdt:P17 ?country. }
  OPTIONAL {
    ?enwiki schema:about ?item ;
            schema:isPartOf <https://en.wikipedia.org/> .
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
ORDER BY ?itemLabel
"""

# Wikidata properties used:
#   P1435 = heritage designation (use this to filter "is a UNESCO WHS")
#   P17   = country
#   Q9259 = World Heritage Site (the designation itself)

USER_AGENT = (
    "lorescape-daily-story-setup/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)

OUTPUT_PATH = Path(__file__).parent / "output" / "raw.csv"


def parse_sparql_response(data: dict) -> list[tuple[str, str, str, str]]:
    """Extract (wikidata_id, name, wikipedia_title_en, country) from SPARQL JSON.

    Skips rows without enwiki sitelink or country (incomplete entries).
    Returns title with spaces (URL-decoded, underscores normalised to spaces)
    — Wikipedia REST API accepts both forms; spaces is canonical.
    """
    rows = []
    for binding in data.get("results", {}).get("bindings", []):
        if (
            "enwiki" not in binding
            or "countryLabel" not in binding
            or "item" not in binding
        ):
            continue
        if "itemLabel" not in binding:
            continue
        qid = binding["item"]["value"].rsplit("/", 1)[-1]
        name = binding["itemLabel"]["value"]
        country = binding["countryLabel"]["value"]
        wiki_url = binding["enwiki"]["value"]
        # https://en.wikipedia.org/wiki/<title> → <title>, URL-decoded with spaces
        title = unquote(wiki_url.rsplit("/", 1)[-1]).replace("_", " ")
        rows.append((qid, name, title, country))
    return rows


def fetch_sparql() -> dict:
    response = requests.get(
        WIKIDATA_SPARQL_URL,
        params={"query": SPARQL_QUERY, "format": "json"},
        headers={"User-Agent": USER_AGENT, "Accept": "application/sparql-results+json"},
        timeout=120,
    )
    response.raise_for_status()
    return response.json()


def write_csv(rows: Iterable[tuple[str, str, str, str]], path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["wikidata_id", "name", "wikipedia_title_en", "country"])
        for row in rows:
            writer.writerow(row)
            count += 1
    return count


def main() -> int:
    print(f"Fetching SPARQL from {WIKIDATA_SPARQL_URL}...")
    data = fetch_sparql()
    rows = parse_sparql_response(data)
    written = write_csv(rows, OUTPUT_PATH)
    print(f"Wrote {written} rows to {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
