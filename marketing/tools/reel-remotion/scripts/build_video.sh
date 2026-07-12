#!/usr/bin/env bash
# Render a day's daily-story reel and mux a quiet BGM bed.
#
# Usage: scripts/build_video.sh <YYYY-MM-DD> [--style Cinematic] [--bgm FILE] [--lufs -20]
#
# Runs AFTER prepare_story.mjs and after Claude has condensed story.json's
# lines. Subsets fonts, renders the chosen style, then mixes background music
# (fade in/out, loudness-normalised) into the final mp4.
#
# BGM defaults to the newest file in marketing/sound/. --lufs sets the bed
# loudness: -20 = music-forward; use -28 when a voiceover will be added later.
set -euo pipefail

DATE="${1:-}"
if [[ ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: scripts/build_video.sh <YYYY-MM-DD> [--style Cinematic] [--bgm FILE] [--lufs -20]"
  exit 1
fi
shift

STYLE="Cinematic"
BGM=""
LUFS="-20"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --style) STYLE="$2"; shift 2 ;;
    --bgm) BGM="$2"; shift 2 ;;
    --lufs) LUFS="$2"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$PROJ/../../.." && pwd)"
OUTDIR="$REPO/marketing/outputs/daily_video/$DATE"
SOUNDDIR="$REPO/marketing/sound"
mkdir -p "$OUTDIR"
NAME="$(echo "$STYLE" | tr '[:upper:]' '[:lower:]')"
FINAL="$OUTDIR/$NAME.mp4"

echo "== 1/3 subset fonts =="
python3 "$PROJ/scripts/subset_fonts.py"

echo "== 2/3 render $STYLE =="
TMP="$OUTDIR/_noaudio.mp4"
( cd "$PROJ" && npx remotion render "$STYLE" "$TMP" --log=error )

# pick BGM
if [[ -z "$BGM" ]]; then
  BGM="$(ls -t "$SOUNDDIR"/*.mp3 "$SOUNDDIR"/*.wav "$SOUNDDIR"/*.m4a 2>/dev/null | head -1 || true)"
fi

# IG-safe video encode: Meta's server-side transcoder rejects the raw render
# profile (yuvj420p full-range, e.g. 2026-07-11's reel failed with "both HD
# and SD progressive failed to transcode"). Re-encode once here so every
# downstream mp4 (cinematic + voiced final) inherits a profile IG accepts.
IGSAFE_V=(-c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -crf 20 -preset medium \
  -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv \
  -movflags +faststart)

if [[ -z "$BGM" || ! -f "$BGM" ]]; then
  echo "== 3/3 no BGM found in $SOUNDDIR — keeping silent video =="
  ffmpeg -y -i "$TMP" "${IGSAFE_V[@]}" -an "$FINAL" -loglevel error
  rm -f "$TMP"
else
  echo "== 3/3 mux BGM: $(basename "$BGM") @ ${LUFS} LUFS =="
  DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP")"
  OF="$(python3 -c "print(f'{float('$DUR')-2:.3f}')")"
  ffmpeg -y -i "$TMP" -i "$BGM" \
    -filter_complex "[1:a]atrim=0:${DUR},loudnorm=I=${LUFS}:TP=-2:LRA=11,afade=t=in:st=0:d=1.5,afade=t=out:st=${OF}:d=2[a]" \
    -map 0:v -map "[a]" "${IGSAFE_V[@]}" -c:a aac -ar 44100 -b:a 192k -shortest "$FINAL" -loglevel error
  rm -f "$TMP"
fi

echo "DONE -> $FINAL"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$FINAL"
