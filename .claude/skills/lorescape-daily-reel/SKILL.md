---
name: lorescape-daily-reel
description: Use when producing the daily-story reel/video for a Lorescape place — the place-photo, aspect-switching, narration-text style rendered locally (NOT Google Flow). Triggers on 「產每日故事影片」「做 reel / 短影片」「不要用 flow 做影片」「把今天的故事做成影片」, and lorescape-manual-daily-story's post-publish video step. Covers preparing the story, condensing narration, rendering, and muxing BGM.
---

# Lorescape Daily-Story Reel (Remotion)

## Overview

Produce the daily-story reel **locally with Remotion** — no Google Flow.
The video focuses on the real place photos, switches between the story's
aspects (beats), and overlays the guide narration as animated text. This is
the default video method for daily stories (replaces the Flow reel, which
felt stiff and generic).

Engine: `marketing/tools/reel-remotion/` (a parametrised Remotion project).
Content comes from the day's carousel `slides.json` + Unsplash photos, so the
reel tells the same story the carousel does.

## When to Use

- The daily-story post-publish video step (lorescape-manual-daily-story Step 9)
- Any "make a reel / short video from today's story", explicitly not Flow
- Re-rendering a day's reel after tweaking text, fonts, or BGM

## The Cinematic style (the locked look)

Keep these when editing — this IS the approved style:

- **9:16, 30fps, ~30s, no voiceover baked in** (narration added later in post)
- Full-bleed photo with a slow continuous **Ken Burns** push (never static)
- **Cross-dissolve** between beats; each beat = one aspect of the place
- Narration reveals **line-by-line** with a spring (weight, not a linear ramp)
- Type: **Songti TC bold serif** for title + lines, **Heiti TC** kicker;
  gold `#f4c869` highlights on key phrases
- Small **white Lorescape lockup** bottom-right (line-art, trail visible)
- **Condensed** narration so a later voiceover keeps pace
- A quiet **BGM bed** muxed in (fade in/out, loudness-normalised)

Three alternate styles exist for one-offs (`--style Editorial|Collage|Focus`);
Cinematic is the daily default.

## Pipeline

```bash
cd marketing/tools/reel-remotion

# 1. Scaffold story.json from the day's carousel + copy its photos
node scripts/prepare_story.mjs <YYYY-MM-DD>

# 2. Claude condenses story.json's narration (the judgment step — see below)

# 3. Render + mux BGM -> marketing/outputs/daily_video/<date>/cinematic.mp4
scripts/build_video.sh <YYYY-MM-DD>              # music-forward (-20 LUFS)
scripts/build_video.sh <YYYY-MM-DD> --lufs -28   # quiet bed if adding voiceover
```

`build_video.sh` subsets the fonts (required after any text change), renders,
then muxes the newest track in `marketing/sound/`. Preview the mp4, iterate,
then hand off to upload (lorescape-manual-daily-story Step 11).

### Step 2 — condensing narration (do NOT skip)

`prepare_story.mjs` copies the carousel's full lines; on screen that's too much
to read in 30s and too long for a voiceover to keep pace. Edit each beat's
`lines` in `src/data/story.json`:

- Cut to **~half** — aim for **1–3 short lines per beat** (a couplet).
- Keep the **cover hook** intact (the curiosity gap / reversal).
- Each `highlights` entry MUST be an **exact substring** of a line, or it
  won't render highlighted.
- Preserve the story arc across the 8 beats; tighten wording, don't drop beats.
- `prepare_story.mjs` auto-numbers kickers 其之一…；enrich with a one-word
  theme if it helps (e.g. `其之二 · 戰火`).

## Quick Reference

| Task | Command |
|---|---|
| Scaffold a day | `node scripts/prepare_story.mjs <date>` |
| Live preview / tweak | `npx remotion studio` |
| One-frame check | `npx remotion still Cinematic out.png --frame=90 --scale=0.5` |
| Build final | `scripts/build_video.sh <date> [--style S] [--bgm F] [--lufs N]` |
| Output | `marketing/outputs/daily_video/<date>/cinematic.mp4` |

## Common Mistakes

- **Text changed but fonts not re-subset** → missing glyphs. `build_video.sh`
  re-subsets automatically; if rendering by hand, run `scripts/subset_fonts.py`
  first. Fonts are macOS Songti/Heiti subset locally (not the Google CJK font,
  which pulls hundreds of chunks and hangs the render).
- **Highlight not showing** → the phrase isn't an exact substring of a line.
- **Logo detail (the trail) lost** → use `public/logo-lockup-white.png`
  (blue strokes → white, light fill → transparent). Don't flatten the whole
  logo to solid white; that swallows the trail.
- **BGM too loud under a planned voiceover** → build with `--lufs -28`.
- **ffmpeg has no `drawtext`/libass here** → all text is Remotion (or PIL
  overlays), never ffmpeg drawtext.

## BGM

Drop a royalty-free, commercial-OK track in `marketing/sound/` (Pixabay Music
= no attribution required). `build_video.sh` picks the newest one; override
with `--bgm <file>`. Courtesy-credit it in the IG caption.
