"""Compare richness of two web-research approaches for multi-story output.

Goal: for a place, how many DISTINCT, factually-grounded story angles can
each approach surface? (Richness is what matters when the frontend shows
several stories per place.)

  A. Gemini + native Google Search grounding — Gemini searches the web
     itself and proposes angles in one grounded call.
  B. Perplexica web research → Gemini — our pipeline: Perplexica does the
     web search + synthesis, then Gemini extracts angles from it.
  C. SearXNG → Gemini — raw SearXNG result snippets (no middle LLM
     summarisation layer) fed straight to Gemini for angle extraction.

Both are asked for up to N angles, each anchored on a specific named
person OR recorded event (with concrete names/dates). We then print both
lists and a few quantitative richness metrics.

    cd backend
    uv run python -m scripts.source_quality_compare \
        --place "Arles" --wikidata-id Q48292 --location "Provence, France" --n 8

Needs a working GEMINI_API_KEY in backend/.env and a running Perplexica.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time

from dotenv import load_dotenv
from google import genai
from google.genai import types

from lorescape_backend.sources import perplexica

_MODEL = "gemini-2.5-flash"
_RULE = "=" * 78
_SUB = "-" * 78


def _angle_instruction(place: str, location: str, n: int, language: str) -> str:
    lang = "Traditional Chinese" if language.startswith("zh") else "English"
    return (
        f"Propose up to {n} DISTINCT short-story angles about {place} "
        f"({location}) for a culture/travel app that shows several stories "
        "per place. Each angle MUST centre on a specific named real person "
        "OR a specific recorded event, with concrete names, dates, or "
        "places — no generic 'rich history' filler. Angles must be "
        f"substantially different from each other. Write in {lang}."
    )


# ── Approach A: Gemini + Google Search grounding ───────────────────────────

_A_FORMAT = (
    "\n\nOutput ONLY a numbered list, one angle per line, EXACTLY in this "
    "format (use ' || ' as separator):\n"
    "N || TITLE || one-sentence teaser || entity1; entity2; entity3\n"
    "where the last field lists the concrete named people/events/years the "
    "angle is grounded in."
)


def approach_a(client, *, place, location, n, language):
    cfg = types.GenerateContentConfig(
        tools=[types.Tool(google_search=types.GoogleSearch())],
        temperature=0.4,
    )
    prompt = _angle_instruction(place, location, n, language) + _A_FORMAT
    resp = client.models.generate_content(model=_MODEL, contents=[prompt], config=cfg)
    angles = _parse_pipe_lines(resp.text or "")
    sources = 0
    try:
        gm = resp.candidates[0].grounding_metadata
        sources = len(getattr(gm, "grounding_chunks", None) or [])
    except (AttributeError, IndexError):
        pass
    return {"angles": angles, "sources": sources, "raw_chars": len(resp.text or "")}


def _parse_pipe_lines(text: str) -> list[dict]:
    angles: list[dict] = []
    for line in text.splitlines():
        if "||" not in line:
            continue
        parts = [p.strip() for p in line.split("||")]
        # drop the leading "N" number field if present
        if parts and re.fullmatch(r"\d+\.?", parts[0]):
            parts = parts[1:]
        if len(parts) < 2:
            continue
        title, teaser = parts[0], parts[1]
        ents = parts[2] if len(parts) > 2 else ""
        entities = [e.strip() for e in re.split(r"[;,]", ents) if e.strip()]
        angles.append({"title": title, "teaser": teaser, "entities": entities})
    return angles


# ── Approach B: Perplexica research → Gemini structured ────────────────────

_B_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "angles": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "title": {"type": "STRING"},
                    "teaser": {"type": "STRING"},
                    "entities": {"type": "ARRAY", "items": {"type": "STRING"}},
                },
                "required": ["title", "teaser", "entities"],
            },
        }
    },
    "required": ["angles"],
}


def approach_b(client, *, place, location, n, language, research: str):
    prompt = (
        _angle_instruction(place, location, n, language)
        + "\n\nGround every angle STRICTLY in the web research below. For "
        "each, fill 'entities' with the concrete named people/events/years "
        "it relies on.\n\nWEB RESEARCH:\n<<<\n" + research + "\n>>>"
    )
    cfg = types.GenerateContentConfig(
        temperature=0.4,
        response_mime_type="application/json",
        response_schema=_B_SCHEMA,
    )
    resp = client.models.generate_content(model=_MODEL, contents=[prompt], config=cfg)
    data = json.loads(resp.text)
    return {"angles": data.get("angles", [])}


# ── Approach C: raw SearXNG snippets → Gemini structured ───────────────────

import requests as _requests

_SEARXNG_DEFAULT = "http://localhost:8081"


def _searxng_snippets(
    *, place: str, location: str, language: str, base_url: str, max_results: int = 12
) -> tuple[str, int]:
    """Run 2 SearXNG queries and return (snippet block, result count)."""
    if language.startswith("zh"):
        queries = [f"{place} {location} 歷史", f"{place} 人物 事件 由來"]
    else:
        queries = [
            f"{place} {location} history",
            f"{place} notable people events",
        ]
    seen: set[str] = set()
    rows: list[str] = []
    for q in queries:
        try:
            resp = _requests.get(
                f"{base_url}/search",
                params={"q": q, "format": "json"},
                timeout=30,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])
        except (_requests.RequestException, ValueError):
            continue
        for r in results:
            url = r.get("url", "")
            if not url or url in seen:
                continue
            seen.add(url)
            title = r.get("title", "")
            content = (r.get("content") or "").strip()
            rows.append(f"- {title} ({url})\n  {content}")
            if len(rows) >= max_results:
                break
        if len(rows) >= max_results:
            break
    return "\n".join(rows), len(rows)


def approach_c(client, *, place, location, n, language, searxng_url):
    snippets, count = _searxng_snippets(
        place=place, location=location, language=language, base_url=searxng_url,
    )
    if not snippets:
        return {"angles": [], "sources": 0}
    prompt = (
        _angle_instruction(place, location, n, language)
        + "\n\nGround every angle STRICTLY in the raw search-result snippets "
        "below. For each, fill 'entities' with the concrete named "
        "people/events/years it relies on.\n\nSEARCH RESULTS:\n<<<\n"
        + snippets + "\n>>>"
    )
    cfg = types.GenerateContentConfig(
        temperature=0.4,
        response_mime_type="application/json",
        response_schema=_B_SCHEMA,
    )
    resp = client.models.generate_content(model=_MODEL, contents=[prompt], config=cfg)
    data = json.loads(resp.text)
    return {"angles": data.get("angles", []), "sources": count}


# ── Metrics + reporting ────────────────────────────────────────────────────


def _unique_entities(angles: list[dict]) -> set[str]:
    out: set[str] = set()
    for a in angles:
        for e in a.get("entities", []):
            out.add(e.strip().lower())
    return out


def _print_angles(label: str, angles: list[dict]) -> None:
    print(f"\n{label}  ({len(angles)} angles)")
    print(_SUB)
    for i, a in enumerate(angles, 1):
        ents = ", ".join(a.get("entities", []))
        print(f"{i}. {a.get('title', '')}")
        print(f"   {a.get('teaser', '')}")
        if ents:
            print(f"   ↳ entities: {ents}")


def _metrics(name: str, angles: list[dict], sources: int) -> dict:
    ents = _unique_entities(angles)
    teasers = [a.get("teaser", "") for a in angles]
    avg_teaser = round(sum(len(t) for t in teasers) / len(teasers)) if teasers else 0
    return {
        "approach": name,
        "angles": len(angles),
        "unique_entities": len(ents),
        "avg_teaser_chars": avg_teaser,
        "web_sources": sources,
    }


def main(argv: list[str]) -> int:
    load_dotenv()
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--place", required=True)
    p.add_argument("--wikidata-id", default="")
    p.add_argument("--location", default="")
    p.add_argument("--language", default="en", choices=["en", "zh-TW"])
    p.add_argument("--n", type=int, default=8)
    p.add_argument("--searxng-url", default=_SEARXNG_DEFAULT)
    p.add_argument(
        "--skip", default="", help="comma list of approaches to skip, e.g. a,b"
    )
    args = p.parse_args(argv)
    skip = {s.strip().lower() for s in args.skip.split(",") if s.strip()}

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key":
        print("GEMINI_API_KEY missing/placeholder in backend/.env", file=sys.stderr)
        return 2
    client = genai.Client(api_key=api_key)

    print(f"{_RULE}\nPLACE: {args.place} ({args.location})  n={args.n}\n{_RULE}")

    # Approach A
    a = {"angles": [], "sources": 0}
    if "a" not in skip:
        print("\n[A] Gemini + Google Search grounding ...")
        a = approach_a(
            client, place=args.place, location=args.location, n=args.n,
            language=args.language,
        )
        _print_angles("APPROACH A — Gemini + Google Search", a["angles"])
        time.sleep(5)  # breathe between approaches

    # Approach B
    b_angles, b_sources = [], 0
    if "b" not in skip:
        print("\n[B] Perplexica web research ...")
        research = perplexica.fetch_web_research(
            place_name=args.place, location=args.location, language=args.language,
        )
        if not research:
            print("Perplexica returned no research; cannot run approach B.")
        else:
            b_sources = research.count("\n- ")  # rough citation count
            b = approach_b(
                client, place=args.place, location=args.location, n=args.n,
                language=args.language, research=research,
            )
            b_angles = b["angles"]
            print(f"\n(Perplexica raw research: {len(research)} chars, "
                  f"~{b_sources} cited sources)")
            _print_angles("APPROACH B — Perplexica → Gemini", b_angles)
        time.sleep(5)

    # Approach C
    c = {"angles": [], "sources": 0}
    if "c" not in skip:
        print("\n[C] raw SearXNG snippets → Gemini ...")
        c = approach_c(
            client, place=args.place, location=args.location, n=args.n,
            language=args.language, searxng_url=args.searxng_url,
        )
        print(f"(SearXNG snippets: {c['sources']} results)")
        _print_angles("APPROACH C — SearXNG → Gemini", c["angles"])

    # Summary
    print(f"\n{_RULE}\nRICHNESS SUMMARY\n{_RULE}")
    rows = [
        _metrics("A: Gemini+Search", a["angles"], a["sources"]),
        _metrics("B: Perplexica", b_angles, b_sources),
        _metrics("C: SearXNG direct", c["angles"], c["sources"]),
    ]
    hdr = f"{'approach':22} {'angles':>7} {'uniq_entities':>14} {'avg_teaser':>11} {'sources':>8}"
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        print(f"{r['approach']:22} {r['angles']:>7} {r['unique_entities']:>14} "
              f"{r['avg_teaser_chars']:>11} {r['web_sources']:>8}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
