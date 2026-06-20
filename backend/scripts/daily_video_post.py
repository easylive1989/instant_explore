"""IG Reels post-production for the daily-story Flow reel.

The lorescape-manual-daily-story skill produces a clean 9:16 / 10s reel in
Google Flow with NO narration and NO on-screen text (Step 9). That clip is
the master. This script is Step 10: it takes the downloaded master and
overlays a short zh-TW voiceover plus full burned-in captions, producing an
IG-ready cut in ``outputs/daily_video/{date}/final.mp4``.

The voiceover uses macOS ``say`` (offline, free). Captions are kept in sync
by speaking each line separately, measuring its duration with ``ffprobe``,
and showing each line only during its measured interval. The original
ambient audio is kept but ducked under the voiceover.

Captions are rendered to transparent PNGs with Pillow and composited via
ffmpeg's ``overlay`` filter. This deliberately avoids ffmpeg's libass /
drawtext text filters, which are not compiled into the Homebrew ffmpeg on
this machine.

Run from backend/:

    uv run python -m scripts.daily_video_post --date 2026-06-20
    uv run python -m scripts.daily_video_post \\
        --date 2026-06-20 \\
        --input outputs/daily_video/2026-06-20/source.mp4 \\
        --text  outputs/daily_video/2026-06-20/narration.txt \\
        --voice Meijia --bg-volume 0.28

``--text`` points at a UTF-8 file with one caption line per row (Claude
writes it in Step 10). Alternatively pass ``--line "句子"`` one or more
times. With neither, the script reads ``narration.txt`` from the date dir.
"""
from __future__ import annotations

import argparse
import logging
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

logger = logging.getLogger("daily_video_post")

REPO_ROOT = Path(__file__).resolve().parents[2]

DEFAULT_VOICE = "Meijia"  # Taiwanese Mandarin voice shipped with macOS.
DEFAULT_FONT = "/System/Library/Fonts/STHeiti Medium.ttc"  # CJK font file.
DEFAULT_BG_VOLUME = 0.28  # Ambient kept audible but well under the voiceover.
LEAD_IN_SECONDS = 0.3  # Small silence before the first line starts.
PAUSE_SECONDS = 0.25  # Gap inserted between spoken lines.
AUDIO_RATE = 44100


class PostProductionError(RuntimeError):
    """Raised when an external tool is missing or a step fails."""


def _run(cmd: list[str], *, cwd: Path | None = None) -> None:
    """Run a subprocess, raising PostProductionError on failure."""
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise PostProductionError(
            f"command failed ({result.returncode}): {' '.join(cmd)}\n"
            f"{result.stderr.strip()}"
        )


def _require_tools() -> None:
    for tool in ("say", "ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            raise PostProductionError(
                f"required tool {tool!r} not found on PATH"
            )


def _ffprobe_duration(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
        capture_output=True, text=True, check=True,
    )
    return float(out.stdout.strip())


def _ffprobe_dimensions(path: Path) -> tuple[int, int]:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height",
         "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
        capture_output=True, text=True, check=True,
    )
    width, height = out.stdout.split()
    return int(width), int(height)


def _has_audio_stream(path: Path) -> bool:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "a",
         "-show_entries", "stream=index", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    )
    return bool(out.stdout.strip())


def _read_lines(args: argparse.Namespace, out_dir: Path) -> list[str]:
    """Resolve caption/narration lines from --line, --text, or narration.txt."""
    if args.line:
        raw = args.line
    else:
        text_path = Path(args.text) if args.text else out_dir / "narration.txt"
        if not text_path.is_absolute():
            text_path = REPO_ROOT / text_path
        if not text_path.exists():
            raise PostProductionError(
                f"no narration found — provide --text/--line or create "
                f"{text_path}"
            )
        raw = text_path.read_text(encoding="utf-8").splitlines()
    lines = [line.strip() for line in raw if line.strip()]
    if not lines:
        raise PostProductionError("narration is empty after stripping blanks")
    return lines


def _make_silence(path: Path, seconds: float) -> None:
    _run([
        "ffmpeg", "-y", "-f", "lavfi",
        "-i", f"anullsrc=r={AUDIO_RATE}:cl=mono",
        "-t", f"{seconds:.3f}", "-c:a", "pcm_s16le", str(path),
    ])


def _speak_line(text: str, voice: str, rate: int | None, dest: Path) -> None:
    aiff = dest.with_suffix(".aiff")
    cmd = ["say", "-v", voice]
    if rate:
        cmd += ["-r", str(rate)]
    cmd += ["-o", str(aiff), text]
    _run(cmd)
    _run([
        "ffmpeg", "-y", "-i", str(aiff),
        "-ar", str(AUDIO_RATE), "-ac", "1", "-c:a", "pcm_s16le", str(dest),
    ])
    aiff.unlink(missing_ok=True)


def _build_voice_track(
    lines: list[str], voice: str, rate: int | None,
    work_dir: Path, voice_path: Path,
) -> list[tuple[float, float, str]]:
    """Speak each line, concat with pauses; return (start, end, text) rows."""
    pause_path = work_dir / "pause.wav"
    lead_path = work_dir / "lead.wav"
    _make_silence(pause_path, PAUSE_SECONDS)
    _make_silence(lead_path, LEAD_IN_SECONDS)

    concat_parts: list[Path] = [lead_path]
    timings: list[tuple[float, float, str]] = []
    cursor = LEAD_IN_SECONDS
    for index, text in enumerate(lines, start=1):
        chunk = work_dir / f"chunk_{index}.wav"
        _speak_line(text, voice, rate, chunk)
        duration = _ffprobe_duration(chunk)
        timings.append((cursor, cursor + duration, text))
        cursor += duration + PAUSE_SECONDS
        concat_parts.append(chunk)
        if index < len(lines):
            concat_parts.append(pause_path)

    list_file = work_dir / "concat.txt"
    list_file.write_text(
        "".join(f"file '{p.resolve()}'\n" for p in concat_parts),
        encoding="utf-8",
    )
    _run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(list_file),
        "-c:a", "pcm_s16le", str(voice_path),
    ])
    return timings


def _wrap(
    text: str, font: ImageFont.FreeTypeFont, max_width: float
) -> list[str]:
    """Greedily wrap text to max_width; breaks between characters (CJK-safe)."""
    lines: list[str] = []
    current = ""
    for char in text:
        if font.getlength(current + char) <= max_width:
            current += char
        else:
            if current:
                lines.append(current)
            current = char
    if current:
        lines.append(current)
    return lines or [""]


def _render_caption_pngs(
    timings: list[tuple[float, float, str]],
    width: int, height: int, font_file: str, work_dir: Path,
) -> list[tuple[Path, float, float]]:
    """Render each caption line to a full-frame transparent PNG with Pillow."""
    font_size = max(20, round(height * 0.045))
    margin_v = round(height * 0.10)
    max_text_width = width * 0.84
    stroke = max(2, round(height * 0.004))
    font = ImageFont.truetype(font_file, font_size)
    ascent, descent = font.getmetrics()
    line_height = ascent + descent + round(font_size * 0.25)

    captions: list[tuple[Path, float, float]] = []
    for index, (start, end, text) in enumerate(timings, start=1):
        rows = _wrap(text, font, max_text_width)
        image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        block_height = line_height * len(rows)
        y = height - margin_v - block_height
        for row in rows:
            x = (width - font.getlength(row)) / 2
            draw.text(
                (x, y), row, font=font, fill=(255, 255, 255, 255),
                stroke_width=stroke, stroke_fill=(0, 0, 0, 235),
            )
            y += line_height
        png = work_dir / f"caption_{index}.png"
        image.save(png)
        captions.append((png, start, end))
    return captions


def _render(
    source: Path, voice_path: Path,
    captions: list[tuple[Path, float, float]], out_dir: Path,
    final_path: Path, bg_volume: float, voice_dur: float, video_dur: float,
    has_audio: bool,
) -> bool:
    """Composite captions + audio into final.mp4; return whether padded."""
    inputs = ["-i", str(source), "-i", str(voice_path)]
    for png, _start, _end in captions:
        inputs += ["-i", str(png)]

    parts: list[str] = []
    padded = voice_dur > video_dur + 0.05
    if padded:
        parts.append(
            f"[0:v]tpad=stop_mode=clone:"
            f"stop_duration={voice_dur - video_dur:.3f}[vbase]"
        )
        current = "[vbase]"
    else:
        current = "[0:v]"
    for index, (_png, start, end) in enumerate(captions):
        overlay_in = f"[{2 + index}:v]"
        label = "[v]" if index == len(captions) - 1 else f"[vo{index}]"
        parts.append(
            f"{current}{overlay_in}overlay=eof_action=repeat:"
            f"enable='between(t,{start:.3f},{end:.3f})'{label}"
        )
        current = label

    if has_audio:
        parts.append(
            f"[0:a]volume={bg_volume}[bg];[1:a]volume=1.0[vo];"
            "[bg][vo]amix=inputs=2:duration=longest:dropout_transition=0:"
            "normalize=0[a]"
        )
    else:
        parts.append(f"[1:a]volume=1.0,aresample={AUDIO_RATE}[a]")

    _run([
        "ffmpeg", "-y", *inputs,
        "-filter_complex", ";".join(parts),
        "-map", "[v]", "-map", "[a]",
        "-c:v", "libx264", "-preset", "medium", "-crf", "20",
        "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
        "-movflags", "+faststart", str(final_path),
    ], cwd=out_dir)
    return padded


def cmd_build(args: argparse.Namespace) -> int:
    _require_tools()

    out_dir = REPO_ROOT / "outputs" / "daily_video" / args.date
    out_dir.mkdir(parents=True, exist_ok=True)

    source = Path(args.input) if args.input else out_dir / "source.mp4"
    if not source.is_absolute():
        source = REPO_ROOT / source
    if not source.exists():
        raise PostProductionError(
            f"input video not found: {source}\n"
            "Download the Flow reel and place it at "
            f"outputs/daily_video/{args.date}/source.mp4 (or pass --input)."
        )

    lines = _read_lines(args, out_dir)
    logger.info("narration: %d line(s)", len(lines))

    width, height = _ffprobe_dimensions(source)
    video_dur = _ffprobe_duration(source)
    has_audio = _has_audio_stream(source)
    logger.info(
        "source %dx%d, %.2fs, audio=%s", width, height, video_dur, has_audio
    )

    work_dir = out_dir / ".work"
    if work_dir.exists():
        shutil.rmtree(work_dir)
    work_dir.mkdir()

    voice_path = out_dir / "voice.wav"
    timings = _build_voice_track(
        lines, args.voice, args.rate, work_dir, voice_path
    )
    voice_dur = _ffprobe_duration(voice_path)
    logger.info("voiceover: %.2fs", voice_dur)

    captions = _render_caption_pngs(
        timings, width, height, args.font, work_dir
    )

    final_path = out_dir / "final.mp4"
    padded = _render(
        source, voice_path, captions, out_dir, final_path,
        args.bg_volume, voice_dur, video_dur, has_audio,
    )

    shutil.rmtree(work_dir, ignore_errors=True)

    if voice_dur > video_dur + 2.0:
        logger.warning(
            "voiceover (%.1fs) is much longer than the clip (%.1fs); consider "
            "a shorter intro so the reel stays tight.", voice_dur, video_dur
        )
    logger.info(
        "done: %s (%.2fs%s)", final_path, max(voice_dur, video_dur),
        ", last frame held to fit narration" if padded else "",
    )
    logger.info("kept for review: %s", voice_path.name)
    return 0


def main(argv: list[str]) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--date", required=True, help="Reel date YYYY-MM-DD (output folder)"
    )
    parser.add_argument(
        "--input", help="Source video (default: "
        "outputs/daily_video/{date}/source.mp4)"
    )
    parser.add_argument(
        "--text", help="UTF-8 file, one caption line per row (default: "
        "outputs/daily_video/{date}/narration.txt)"
    )
    parser.add_argument(
        "--line", action="append", help="Caption line (repeatable; overrides "
        "--text)"
    )
    parser.add_argument(
        "--voice", default=DEFAULT_VOICE,
        help=f"macOS say voice (default: {DEFAULT_VOICE})"
    )
    parser.add_argument(
        "--rate", type=int, help="say speaking rate (default: system default)"
    )
    parser.add_argument(
        "--font", default=DEFAULT_FONT,
        help=f"Caption font file path (default: {DEFAULT_FONT})"
    )
    parser.add_argument(
        "--bg-volume", type=float, default=DEFAULT_BG_VOLUME,
        help=f"Ambient volume under narration (default: {DEFAULT_BG_VOLUME})"
    )

    args = parser.parse_args(argv)
    try:
        return cmd_build(args)
    except PostProductionError as exc:
        logger.error("error: %s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
