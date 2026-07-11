"""Build a daily-story reel with a zh-TW voiceover, beat-synced.

Reuses daily_video_post's TTS and reel-remotion's build_video.sh. Run from the
scripts/ uv project:

    cd scripts && uv run python -m reel_voiceover <YYYY-MM-DD> [flags]
"""
from __future__ import annotations

import hashlib
import math
from pathlib import Path

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
