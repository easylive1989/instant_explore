"""Build a daily-story reel with a zh-TW voiceover, beat-synced.

Reuses daily_video_post's TTS and reel-remotion's build_video.sh. Run from the
scripts/ uv project:

    cd scripts && uv run python -m reel_voiceover <YYYY-MM-DD> [flags]
"""
from __future__ import annotations

import argparse
import hashlib
import json
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


def render_reel(date: str, lufs: str = "-28") -> None:
    """Re-render the reel with voice-matched durations + a quiet BGM bed."""
    dvp._run(["bash", str(BUILD_VIDEO), date, "--lufs", lufs])


def mux(date: str, voice_path: Path, out_path: Path) -> None:
    """Lay voice over cinematic.mp4, ducking its BGM under the voice."""
    cinematic = out_dir(date) / "cinematic.mp4"
    graph = (
        "[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[vtmp];"
        "[vtmp]asplit=2[v1][v2];"
        "[0:a][v1]sidechaincompress=threshold=0.03:ratio=8:attack=5:release=300[bgd];"
        "[bgd][v2]amix=inputs=2:normalize=0:duration=first[a]"
    )
    dvp._run([
        "ffmpeg", "-y", "-i", str(cinematic), "-i", str(voice_path),
        "-filter_complex", graph, "-map", "0:v", "-map", "[a]",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
        str(out_path), "-loglevel", "error",
    ])


def main(argv: list[str]) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("date", help="YYYY-MM-DD")
    parser.add_argument("--engine", choices=("gemini", "say"), default="gemini")
    parser.add_argument("--voice", default=None)
    parser.add_argument("--style", default=dvp.DEFAULT_GEMINI_STYLE)
    parser.add_argument("--force-tts", action="store_true")
    args = parser.parse_args(argv)

    story = json.loads(STORY_JSON.read_text(encoding="utf-8"))
    beats = story["beats"]

    od = out_dir(args.date)
    work = od / "voice_work"
    work.mkdir(parents=True, exist_ok=True)
    cache_path = work / "voice_cache.json"
    cache = (
        json.loads(cache_path.read_text(encoding="utf-8"))
        if cache_path.exists() else {}
    )

    voice = args.voice or (
        dvp.DEFAULT_GEMINI_VOICE if args.engine == "gemini" else "Meijia"
    )
    synth = dvp._make_synth(args.engine, voice, None, args.style)
    logger.info("tts: engine=%s voice=%s", args.engine, voice)
    synth_result, new_cache = synth_beats(
        beats, work, cache, synth, force=args.force_tts,
    )
    cache_path.write_text(
        json.dumps(new_cache, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    durations = []
    for beat in beats:
        _, voice_sec = synth_result[beat["id"]]
        dframes = duration_frames(text_default_frames(beat), voice_sec)
        beat["durationFrames"] = dframes
        durations.append(dframes)
        logger.info("%-7s voice=%5.2fs -> durationFrames=%d",
                    beat["id"], voice_sec, dframes)
    STORY_JSON.write_text(
        json.dumps(story, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    voice_wav = od / "voice.wav"
    build_voice_wav(beats, synth_result, durations, voice_wav)
    render_reel(args.date)
    final = od / "final.mp4"
    mux(args.date, voice_wav, final)
    logger.info("DONE -> %s (%.2fs)", final, total_frames(durations) / FPS)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
