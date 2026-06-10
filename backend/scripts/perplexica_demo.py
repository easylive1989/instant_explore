"""Compare narration WITH vs WITHOUT Perplexica web-research augmentation.

A spike to judge whether feeding Perplexica's web research into the
narration prompt produces richer stories — especially for places where
Wikipedia is thin and the quality gate currently returns
`insufficient_source` (i.e. no story at all).

For each sample place it:
  1. Builds the baseline SourceBundle (Wikipedia zh/en + Wikidata).
  2. Fetches Perplexica web research.
  3. Builds an augmented bundle = baseline + a `perplexica_web` extract.
  4. Runs the real narration Gemini call for both and prints them
     side by side.

Run it (needs GEMINI_API_KEY + a running Perplexica per backend/demo/perplexica):

    cd backend
    uv run python -m scripts.perplexica_demo --language zh-TW
    uv run python -m scripts.perplexica_demo --no-gemini --place "..." --wikidata-id Q...

Without --place it iterates the built-in sample set. `--no-gemini` skips
the Gemini calls and only shows what Perplexica returned (saves quota).
PERPLEXICA_URL overrides the Perplexica base URL (default localhost:3000).
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time
from dataclasses import dataclass

from dotenv import load_dotenv

from lorescape_backend.narration import gemini_client, prompts
from lorescape_backend.sources import perplexica
from lorescape_backend.sources.models import SourceBundle, SourceExtract
from lorescape_backend.sources.pipeline import build_source_bundle

logger = logging.getLogger(__name__)

_RULE = "=" * 78
_SUBRULE = "-" * 78


@dataclass(frozen=True)
class SamplePlace:
    """A place to run the comparison on."""

    place_name: str
    location: str
    wikidata_id: str
    note: str


# A mix of rich-Wikipedia and thin-Wikipedia places. The thin ones are
# where Perplexica should help most (baseline likely insufficient_source).
SAMPLE_PLACES: list[SamplePlace] = [
    SamplePlace(
        place_name="Arles",
        location="Provence, France",
        wikidata_id="Q48292",
        note="rich wiki — sanity check Perplexica doesn't degrade good cases",
    ),
    SamplePlace(
        place_name="馬卡龍公園",
        location="桃園市, 台灣",
        wikidata_id="Q108234567",
        note="thin wiki — likely insufficient_source baseline",
    ),
]


def _augment_bundle(bundle: SourceBundle, web_text: str) -> SourceBundle:
    """Return a copy of `bundle` with a perplexica_web extract appended."""
    extract = SourceExtract(
        provider="perplexica_web",
        title=None,
        text=web_text,
        char_count=len(web_text),
        has_named_entity=True,
    )
    extracts = [*bundle.extracts, extract]
    return SourceBundle(
        wikidata_id=bundle.wikidata_id,
        place_name=bundle.place_name,
        extracts=extracts,
        total_chars=sum(e.char_count for e in extracts),
        # Always considered sufficient once augmented — we want to see the
        # story Gemini produces from the combined material.
        is_sufficient=True,
    )


def _run_narration(
    *, api_key: str, place: SamplePlace, language: str, bundle: SourceBundle
) -> dict:
    """Call Gemini for one bundle, retrying transient 503 overloads."""
    last_exc: Exception | None = None
    for attempt in range(4):
        try:
            return gemini_client.generate_structured(
                api_key=api_key,
                system_instruction=prompts.narration_system_instruction(language),
                user_prompt=prompts.build_narration_user_prompt(
                    place_name=place.place_name,
                    location=place.location,
                    source_bundle=bundle,
                    language=language,
                    hook=None,
                ),
                response_schema=prompts.narration_response_schema(language),
            )
        except Exception as exc:  # noqa: BLE001 — surface as a row, not a crash
            msg = str(exc)
            last_exc = exc
            transient = any(
                s in msg
                for s in ("503", "UNAVAILABLE", "high demand", "429", "RESOURCE_EXHAUSTED")
            )
            if transient:
                wait = 20 * (attempt + 1)
                print(f"  (Gemini rate/overload, retry {attempt + 1}/3 in {wait}s...)")
                time.sleep(wait)
                continue
            raise
    raise last_exc  # type: ignore[misc]


def _print_story(title: str, payload: dict) -> None:
    print(f"\n{title}")
    print(_SUBRULE)
    if payload.get("_error"):
        print(f"(failed: {payload['_error']})")
        return
    if payload.get("insufficient_source"):
        print("insufficient_source=True (no story produced)")
        return
    print(f"era: {payload.get('era', '')}")
    for i, para in enumerate(payload.get("paragraphs", []), start=1):
        print(f"\n[{i}] {para}")
    pull = payload.get("pull_quote", "")
    if pull:
        print(f"\npull_quote: {pull}")


def _process_place(
    *, place: SamplePlace, language: str, api_key: str | None, run_gemini: bool
) -> None:
    print(f"\n{_RULE}")
    print(f"PLACE: {place.place_name} ({place.location})  [{place.wikidata_id}]")
    print(f"note: {place.note}")
    print(_RULE)

    baseline = build_source_bundle(
        wikidata_id=place.wikidata_id,
        language=language,
        place_name=place.place_name,
    )
    wiki_summary = ", ".join(
        f"{e.provider}:{e.char_count}c" for e in baseline.extracts
    ) or "(no wiki/wikidata extracts)"
    print(f"baseline providers: {wiki_summary}")
    print(f"baseline is_sufficient: {baseline.is_sufficient}")

    web_text = None
    for attempt in range(3):
        web_text = perplexica.fetch_web_research(
            place_name=place.place_name,
            location=place.location,
            language=language,
        )
        if web_text:
            break
        if attempt < 2:
            print(f"  (Perplexica empty/failed, retry {attempt + 1}/2 in 25s...)")
            time.sleep(25)
    if web_text is None:
        print("\nPerplexica: no result after retries (likely Gemini free-tier")
        print("rate limit on Perplexica's internal calls). Try again shortly.")
        return

    print(f"\nPerplexica web research ({len(web_text)} chars):")
    print(_SUBRULE)
    print(web_text)

    augmented = _augment_bundle(baseline, web_text)

    if not run_gemini:
        print("\n(--no-gemini set; skipping story generation)")
        return
    if not api_key:
        print("\nGEMINI_API_KEY missing; cannot run story comparison.")
        return

    # Let Gemini's per-minute quota recover after Perplexica's internal calls.
    print("\n(cooling down 20s before story generation to dodge rate limits...)")
    time.sleep(20)

    baseline_story = (
        _safe_story(api_key=api_key, place=place, language=language, bundle=baseline)
        if baseline.is_sufficient
        else {"insufficient_source": True}
    )
    augmented_story = _safe_story(
        api_key=api_key, place=place, language=language, bundle=augmented
    )

    _print_story("STORY — baseline (Wikipedia + Wikidata only)", baseline_story)
    _print_story("STORY — augmented (+ Perplexica web research)", augmented_story)


def _safe_story(
    *, api_key: str, place: SamplePlace, language: str, bundle: SourceBundle
) -> dict:
    """Run narration; return an error marker instead of crashing the run."""
    try:
        return _run_narration(
            api_key=api_key, place=place, language=language, bundle=bundle
        )
    except Exception as exc:  # noqa: BLE001 — keep the comparison alive
        return {"_error": str(exc)[:200]}


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--place", help="Place name (overrides sample set)")
    parser.add_argument(
        "--wikidata-id", help="Wikidata Q-id (required with --place)"
    )
    parser.add_argument("--location", default="", help="Location label for --place")
    parser.add_argument(
        "--language", default="zh-TW", choices=["zh-TW", "en"], help="Output language"
    )
    parser.add_argument(
        "--no-gemini",
        action="store_true",
        help="Only show Perplexica output; skip Gemini story generation",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    logging.basicConfig(level=logging.WARNING)
    load_dotenv()
    args = _parse_args(argv)
    api_key = os.environ.get("GEMINI_API_KEY")
    if not args.no_gemini and (not api_key or api_key == "your_gemini_api_key"):
        print(
            "GEMINI_API_KEY missing or placeholder. Put a real key in "
            "backend/.env (or `export GEMINI_API_KEY=...`) to run story "
            "generation, or pass --no-gemini to only see Perplexica output.",
            file=sys.stderr,
        )
        return 2

    if args.place:
        if not args.wikidata_id:
            print("--wikidata-id is required when using --place", file=sys.stderr)
            return 2
        places = [
            SamplePlace(
                place_name=args.place,
                location=args.location,
                wikidata_id=args.wikidata_id,
                note="(custom)",
            )
        ]
    else:
        places = SAMPLE_PLACES

    print(f"Perplexica base URL: {perplexica.default_base_url()}")
    for place in places:
        _process_place(
            place=place,
            language=args.language,
            api_key=api_key,
            run_gemini=not args.no_gemini,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
