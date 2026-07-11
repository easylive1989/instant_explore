"""Build a daily-story reel with a zh-TW voiceover, beat-synced.

Reuses daily_video_post's TTS and reel-remotion's build_video.sh. Run from the
scripts/ uv project:

    cd scripts && uv run python -m reel_voiceover <YYYY-MM-DD> [flags]
"""
from __future__ import annotations

import hashlib
import logging
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import daily_video_post as dvp  # noqa: E402

logger = logging.getLogger("reel_voiceover")

FPS = 30
TRANSITION = 18  # matches src/styles/Cinematic.tsx TRANSITION
LEAD = 20
TAIL = 18

REPO_ROOT = Path(__file__).resolve().parents[1]
REEL_DIR = REPO_ROOT / "marketing" / "tools" / "reel-remotion"
STORY_JSON = REEL_DIR / "src" / "data" / "story.json"
BUILD_VIDEO = REEL_DIR / "scripts" / "build_video.sh"


def out_dir(date: str) -> Path:
    return REPO_ROOT / "marketing" / "outputs" / "daily_video" / date


def text_default_frames(beat: dict) -> int:
    """Port of story.ts beatFrames() — text-derived on-screen duration."""
    layout = beat.get("layout")
    if layout == "cover":
        return 140
    if layout == "ending":
        return 150
    nonempty = len([l for l in beat.get("lines", []) if l != ""])
    return max(116, min(170, 66 + 27 * nonempty))


def duration_frames(text_default: int, voice_sec: float) -> int:
    """Beat holds long enough for BOTH legible text and full narration."""
    voice = math.ceil(voice_sec * FPS) + LEAD + TAIL
    return max(text_default, voice)


def beat_start_frames(durations: list[int], transition: int = TRANSITION) -> list[int]:
    """Visual start frame of each beat under TransitionSeries overlap."""
    starts, cum = [], 0
    for i, dframes in enumerate(durations):
        starts.append(cum - i * transition)
        cum += dframes
    return starts


def total_frames(durations: list[int], transition: int = TRANSITION) -> int:
    return sum(durations) - (len(durations) - 1) * transition


def narration_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def cache_hit(cache: dict, beat_id: str, text: str, wav_exists: bool) -> bool:
    return wav_exists and cache.get(beat_id) == narration_hash(text)


class ReelVoiceoverError(Exception):
    """Raised when the voiced reel cannot be built."""


def synth_beats(beats, work_dir, cache, synth, force, measure=None):
    """TTS each beat.narration into work_dir/beat_<id>.wav (cache-aware).

    Returns ({beat_id: (wav_path|None, voice_sec)}, new_cache). A beat with an
    empty narration yields (None, 0.0) and is dropped from the cache.
    """
    measure = measure or dvp._ffprobe_duration
    result, new_cache = {}, dict(cache)
    for beat in beats:
        bid = beat["id"]
        text = (beat.get("narration") or "").strip()
        wav = Path(work_dir) / f"beat_{bid}.wav"
        if not text:
            result[bid] = (None, 0.0)
            new_cache.pop(bid, None)
            continue
        if not force and cache_hit(cache, bid, text, wav.exists()):
            logger.info("tts skip (cached): %s", bid)
        else:
            synth(text, wav)
            new_cache[bid] = narration_hash(text)
        result[bid] = (wav, measure(wav))
    return result, new_cache


def voice_filter_graph(delays_ms: list[int], total_sec: float) -> str:
    """ffmpeg -filter_complex: delay each voice input, mix, pad+trim to length."""
    filters, labels = [], []
    for i, delay in enumerate(delays_ms):
        filters.append(f"[{i}]adelay={delay}|{delay}[a{i}]")
        labels.append(f"[a{i}]")
    mix = (
        "".join(labels)
        + f"amix=inputs={len(delays_ms)}:normalize=0:duration=longest[m];"
        + f"[m]apad,atrim=0:{total_sec:.3f}[out]"
    )
    return ";".join(filters) + ";" + mix


def build_voice_wav(beats, synth_result, durations, out_path) -> None:
    """Assemble a full-length voice.wav with each beat's audio at its start."""
    starts = beat_start_frames(durations)
    total_sec = total_frames(durations) / FPS
    inputs, delays = [], []
    for beat, start in zip(beats, starts):
        wav, _ = synth_result[beat["id"]]
        if wav is None:
            continue
        inputs += ["-i", str(wav)]
        delays.append(round((start + LEAD) / FPS * 1000))
    if not delays:
        raise ReelVoiceoverError("no narration in any beat")
    graph = voice_filter_graph(delays, total_sec)
    dvp._run([
        "ffmpeg", "-y", *inputs, "-filter_complex", graph,
        "-map", "[out]", "-c:a", "pcm_s16le", str(out_path), "-loglevel", "error",
    ])
