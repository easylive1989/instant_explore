#!/usr/bin/env python3
"""Subset the macOS CJK system fonts to only the glyphs this story uses.

Run after src/data/story.json changes. Produces small .ttf files under
public/fonts/ (loaded by src/fonts.ts). Keeps render fast & deterministic —
the full Noto CJK Google Font would otherwise pull hundreds of chunk files.
"""
import json
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
STORY = os.path.join(PROJ, "src/data/story.json")
FONTS = os.path.join(PROJ, "public/fonts")

# (source .ttc, font-number, output name) — Songti TC serif + Heiti TC sans.
JOBS = [
    ("/System/Library/Fonts/Supplemental/Songti.ttc", 7, "songti-regular.ttf"),
    ("/System/Library/Fonts/Supplemental/Songti.ttc", 2, "songti-bold.ttf"),
    ("/System/Library/Fonts/STHeiti Light.ttc", 0, "heiti-light.ttf"),
    ("/System/Library/Fonts/STHeiti Medium.ttc", 0, "heiti-medium.ttf"),
]

# Latin + punctuation always included so English/numerals/kickers render.
ASCII_EXTRA = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
    ".,·—–、，。！？「」『』（）():;/&"
)

# Text burned into the template rather than coming from story.json (the ending
# CTA). Without these the glyphs fall back to a system font mid-line and the
# weight visibly changes. Keep in sync with src/styles/Cinematic.tsx.
CHROME_TEXT = "更多景點故事，下載免費"


def collect_chars() -> set:
    story = json.load(open(STORY))
    chars = set(ASCII_EXTRA)
    for b in story["beats"]:
        for key in ("kicker", "title", "subtitle"):
            chars.update(b.get(key, "") or "")
        for ln in b.get("lines", []):
            chars.update(ln)
        for h in b.get("highlights", []):
            chars.update(h)
    for k in ("titleZh", "titleEn", "region", "placeZh", "credits"):
        chars.update(story.get(k, "") or "")
    return chars


def main() -> None:
    os.makedirs(FONTS, exist_ok=True)
    chars = collect_chars()
    unicodes = ",".join(f"U+{ord(c):04X}" for c in sorted(chars))
    print(f"subsetting {len(chars)} glyphs")
    for src, num, out in JOBS:
        subprocess.run(
            ["pyftsubset", src, f"--font-number={num}",
             f"--unicodes={unicodes}", f"--output-file={os.path.join(FONTS, out)}",
             "--no-hinting", "--desubroutinize",
             "--drop-tables+=feat,morx,meta"],
            check=True, stderr=subprocess.DEVNULL,
        )
        print("  wrote", out)


if __name__ == "__main__":
    main()
