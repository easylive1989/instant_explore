"""Search Unsplash for direct photos of the current daily story place.

Reads /tmp/lorescape_daily_story_draft.json, runs 5 place-anchored queries
against the Unsplash API (every query contains the place name, so results
depict the place itself — not loosely related themes), and writes them to:
  outputs/daily_image/{date}/unsplash_results.json  (repo root)

The caller still visually filters the downloads to keep only genuine
place shots; these feed the cover image and the Google Flow video prompt.

Usage (from backend/):
    uv run python -m scripts.unsplash_images [--date YYYY-MM-DD]

Requires UNSPLASH_ACCESS_KEY in backend/.env or the environment.
Get a free demo key (50 req/hr) at https://unsplash.com/developers
"""

import argparse
import json
import os
import ssl
import sys
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

# macOS often lacks system CA certs for Python; use certifi when available.
try:
    import certifi
    _SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    _SSL_CTX = ssl._create_unverified_context()  # noqa: SLF001

DRAFT_PATH = "/tmp/lorescape_daily_story_draft.json"
RESULTS_PER_QUERY = 5

# Five place-anchored templates — every query contains the place name so
# results depict the place ITSELF, not loosely related themes. {place},
# {location}, {era} are substituted from the draft JSON.
ANGLE_TEMPLATES: list[tuple[str, str, str]] = [
    (
        "direct",
        "直接景點",
        "{place}",
    ),
    (
        "disambiguated",
        "景點＋地點",
        "{place} {location}",
    ),
    (
        "view",
        "景點全景",
        "{place} view",
    ),
    (
        "landscape",
        "景點景觀",
        "{place} landscape",
    ),
    (
        "panorama",
        "景點全貌",
        "{place} panorama",
    ),
]


def _load_access_key() -> str:
    key = os.environ.get("UNSPLASH_ACCESS_KEY", "")
    if key:
        return key
    env_path = Path(__file__).parent.parent / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            if line.startswith("UNSPLASH_ACCESS_KEY="):
                key = line.split("=", 1)[1].strip().strip("\"'")
                if key:
                    return key
    return ""


def _search(query: str, key: str) -> list[dict]:
    url = (
        "https://api.unsplash.com/search/photos"
        f"?query={urllib.parse.quote(query)}"
        f"&per_page={RESULTS_PER_QUERY}"
        "&orientation=landscape"
    )
    req = urllib.request.Request(url, headers={"Authorization": f"Client-ID {key}"})
    with urllib.request.urlopen(req, timeout=15, context=_SSL_CTX) as resp:
        return json.loads(resp.read()).get("results", [])


def _format_photo(p: dict) -> dict:
    return {
        "url": p["urls"]["regular"],
        "thumb": p["urls"]["thumb"],
        "description": p.get("description") or p.get("alt_description") or "",
        "photographer": p["user"]["name"],
        "photographer_profile": p["user"]["links"]["html"],
        "unsplash_page": p["links"]["html"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--date",
        default=date.today().isoformat(),
        help="Target date (YYYY-MM-DD). Defaults to today.",
    )
    args = parser.parse_args()

    key = _load_access_key()
    if not key:
        print(
            "ERROR: UNSPLASH_ACCESS_KEY not found.\n"
            "Add it to backend/.env — free demo key at https://unsplash.com/developers",
            file=sys.stderr,
        )
        sys.exit(1)

    draft_path = Path(DRAFT_PATH)
    if not draft_path.exists():
        print(
            f"ERROR: {DRAFT_PATH} not found.\n"
            "Run `uv run python -m scripts.manual_daily_story generate` first.",
            file=sys.stderr,
        )
        sys.exit(1)

    draft = json.loads(draft_path.read_text())
    place = draft["wikipedia_title_en"]
    en_story = draft["stories"]["en"]
    location = en_story.get("place_location", "")
    era = en_story.get("era", "")

    print(f"Place: {place} | {location} | {era}", file=sys.stderr)

    output: dict = {
        "date": args.date,
        "place": place,
        "location": location,
        "angles": {},
    }

    for angle_key, angle_label, template in ANGLE_TEMPLATES:
        query = template.format(place=place, location=location, era=era).strip()
        print(f"  [{angle_label}] {query}", file=sys.stderr)
        try:
            photos = _search(query, key)
            output["angles"][angle_key] = {
                "label": angle_label,
                "query": query,
                "photos": [_format_photo(p) for p in photos],
            }
        except Exception as exc:
            print(f"    Error: {exc}", file=sys.stderr)
            output["angles"][angle_key] = {
                "label": angle_label,
                "query": query,
                "photos": [],
                "error": str(exc),
            }

    out_dir = Path(__file__).parent.parent.parent / "outputs" / "daily_image" / args.date
    out_dir.mkdir(parents=True, exist_ok=True)

    # Download images — {angle_key}_{index+1}.jpg
    for angle_key, angle_data in output["angles"].items():
        for i, photo in enumerate(angle_data.get("photos", []), start=1):
            filename = f"{angle_key}_{i}.jpg"
            dest = out_dir / filename
            if dest.exists():
                print(f"  skip {filename} (already exists)", file=sys.stderr)
                photo["local_file"] = filename
                continue
            print(f"  ↓ {filename}  {photo['description'][:50]}", file=sys.stderr)
            try:
                req = urllib.request.Request(
                    photo["url"], headers={"User-Agent": "lorescape-dev/1.0"}
                )
                with urllib.request.urlopen(req, timeout=30, context=_SSL_CTX) as resp:
                    dest.write_bytes(resp.read())
                photo["local_file"] = filename
            except Exception as exc:
                print(f"    download error: {exc}", file=sys.stderr)

    out_file = out_dir / "unsplash_results.json"
    out_file.write_text(json.dumps(output, indent=2, ensure_ascii=False))
    print(f"Saved → {out_file}", file=sys.stderr)


if __name__ == "__main__":
    main()
