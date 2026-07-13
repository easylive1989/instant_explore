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

- **9:16, 30fps, 目標 20–30s, no voiceover baked in** (narration added later in post)
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

# 3a. 音樂版（無語音）：Render + mux BGM -> daily_video/<date>/cinematic.mp4
scripts/build_video.sh <YYYY-MM-DD>              # music-forward (-20 LUFS)

# 3b. 語音版（zh-TW 旁白，逐 beat 同步）-> daily_video/<date>/final.mp4
#     先在 story.json 每拍填 `narration`（口說版，見 Step 2），再：
cd ../../../scripts && uv run python -m reel_voiceover <YYYY-MM-DD>
#     離線 say（不吃 Gemini 配額）：… -m reel_voiceover <date> --engine say
#     改一句只重唸一句（逐拍快取）；--force-tts 全部重唸
```

`build_video.sh` subsets the fonts (required after any text change), renders,
then muxes the newest track in `marketing/sound/`. Preview the mp4, iterate,
then hand off to upload (lorescape-manual-daily-story Step 11).

### Step 2 — condensing narration（目標 20–30 秒，do NOT skip）

`prepare_story.mjs` 會把 carousel 全 9 拍的完整 lines 搬進來——那對 reel
太長（實測會到 60–100 秒，壓低完播與觸及）。目標是**成片 20–30 秒**。
編輯 `src/data/story.json`：

- **挑拍**：只留 **hook cover ＋ 3–4 個最強拍 ＋ ending**（合計 5–6 拍），
  其餘整拍刪掉。保留反轉/懸念/彩蛋，丟掉鋪陳與次要細節。（carousel 仍是
  9 拍，reel 用子集不影響圖組。）
- **零秒 hook（cover）**：cover 的 `lines[0]` 寫成一句話講完反轉/懸念的
  **拋問句或反轉句**（例：「全世界最著名的建築，其實是一座墳墓。」）。
  render 會讓 `lines[0]` 第一幀就以最大字級出現，地區/地名自動降為小字，
  所以 hook 句要能獨立抓住人、別依賴標題。cover `lines` 儘量只留 hook 句
  ＋最多一句補充。
- **每拍精煉**：非 cover 拍收成 **1–2 句短 clause**（口說唸完約 3–4 秒），
  不要複句。
- 每個 `highlights` 必須是某句 `lines` 的**精確子字串**，否則不會highlight。
- `narration`（口說旁白）每拍填一句，比畫面 `lines` 完整一點即可；
  `reel_voiceover` 會逐拍 TTS、用實測長度回寫 `durationFrames`。因此
  **寫短旁白＝片子自然短**，不需另設上限。
- 算下來若仍超過 ~35 秒（beats × 各拍旁白秒數相加），再砍一拍或縮句。
- ending 拍會自動保留 ≥7 秒讓片尾下載 CTA 讀得完（`ENDING_MIN_FRAMES`），
  ending 旁白寫 1–2 句收尾即可，不用硬撐長度。

## Quick Reference

| Task | Command |
|---|---|
| Scaffold a day | `node scripts/prepare_story.mjs <date>` |
| Live preview / tweak | `npx remotion studio` |
| One-frame check | `npx remotion still Cinematic out.png --frame=90 --scale=0.5` |
| Build final | `scripts/build_video.sh <date> [--style S] [--bgm F] [--lufs N]` |
| Build voiced (final.mp4) | `cd ../../../scripts && uv run python -m reel_voiceover <date> [--engine say] [--force-tts]` |
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
- **BGM too loud under the voiceover** → the voiced flow (`reel_voiceover`) already builds the bed at `--lufs -28` automatically; only reach for a manual `--lufs -28` on the music-only `build_video.sh` path.
- **ffmpeg has no `drawtext`/libass here** → all text is Remotion (or PIL
  overlays), never ffmpeg drawtext.

## BGM

Drop a royalty-free, commercial-OK track in `marketing/sound/` (Pixabay Music
= no attribution required). `build_video.sh` picks the newest one; override
with `--bgm <file>`. Courtesy-credit it in the IG caption.
