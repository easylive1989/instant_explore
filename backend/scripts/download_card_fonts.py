"""Download Google Fonts .woff2 files used by the IG card renderer.

Run once to populate backend/src/lorescape_backend/social/card/template/fonts/.
The downloaded files are committed to the repo so card rendering is fully
offline at runtime.

Usage:
    cd backend && uv run python scripts/download_card_fonts.py
"""
from __future__ import annotations

import re
from pathlib import Path

import requests

# Google Fonts CSS2 endpoint returns @font-face blocks pointing at .woff2 URLs.
# Using a modern UA so it serves .woff2 (not legacy formats).
CSS_URL = (
    "https://fonts.googleapis.com/css2"
    "?family=Cormorant+Garamond:ital,wght@1,500"
    "&family=EB+Garamond:ital,wght@0,400;1,400"
    "&family=Noto+Serif+TC:wght@400;500;900"
    "&display=swap"
)
# Chrome UA so Google serves woff2 for every subset (Safari UA returns
# legacy .woff for Latin scripts while still serving .woff2 for CJK).
UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

FONT_OUT_DIR = (
    Path(__file__).resolve().parent.parent
    / "src" / "lorescape_backend" / "social" / "card" / "template" / "fonts"
)

# Maps the (family, style, weight) inferred from the CSS to a stable filename.
FILENAME_MAP = {
    ("Cormorant Garamond", "italic", "500"): "CormorantGaramond-Italic.woff2",
    ("EB Garamond", "normal", "400"):        "EBGaramond-Regular.woff2",
    ("EB Garamond", "italic", "400"):        "EBGaramond-Italic.woff2",
    ("Noto Serif TC", "normal", "400"):      "NotoSerifTC-Regular.woff2",
    ("Noto Serif TC", "normal", "500"):      "NotoSerifTC-Medium.woff2",
    ("Noto Serif TC", "normal", "900"):      "NotoSerifTC-Black.woff2",
}


def main() -> None:
    FONT_OUT_DIR.mkdir(parents=True, exist_ok=True)

    resp = requests.get(CSS_URL, headers={"User-Agent": UA}, timeout=30)
    resp.raise_for_status()
    css = resp.text

    # Parse @font-face blocks. Each block has font-family, font-style,
    # font-weight, and an src url(...) format('woff2').
    blocks = re.findall(r"@font-face\s*\{([^}]+)\}", css)
    for block in blocks:
        fam = re.search(r"font-family:\s*'([^']+)'", block)
        style = re.search(r"font-style:\s*(\w+)", block)
        weight = re.search(r"font-weight:\s*(\d+)", block)
        url = re.search(r"url\((https://[^)]+)\)\s*format\('woff2'\)", block)
        if not (fam and style and weight and url):
            continue
        key = (fam.group(1), style.group(1), weight.group(1))
        target_name = FILENAME_MAP.get(key)
        if not target_name:
            continue
        font_url = url.group(1)
        target = FONT_OUT_DIR / target_name
        if target.exists():
            print(f"skip   {target_name} (already present)")
            continue
        print(f"fetch  {target_name}  ← {font_url}")
        font_resp = requests.get(font_url, headers={"User-Agent": UA}, timeout=60)
        font_resp.raise_for_status()
        target.write_bytes(font_resp.content)

    print(f"\nFonts saved to: {FONT_OUT_DIR}")


if __name__ == "__main__":
    main()
