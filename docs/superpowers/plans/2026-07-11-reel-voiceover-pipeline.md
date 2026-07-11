# Reel 語音旁白 pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 產品化「TTS→回寫 durationFrames→組對齊 voice.wav→重渲染→混音」成一句指令 `uv run python -m reel_voiceover <date>`，產出帶 zh-TW 語音、逐 beat 同步的 `final.mp4`。

**Architecture:** 新增 `scripts/reel_voiceover.py` 編排器，重用 `scripts/daily_video_post.py` 的 TTS 引擎與 `build_video.sh` 的渲染。純函式（時長推導、起始幀、快取判定）走 TDD 單元測試；TTS/ffmpeg/subprocess 走 `--engine say` 端到端驗收。`Beat` 型別加 `narration?`，`prepare_story.mjs` scaffold 時種入草稿。

**Tech Stack:** Python 3（scripts/ uv 專案，pytest + pytest-mock）、Node（prepare_story.mjs）、TypeScript（Remotion types）、ffmpeg、Gemini TTS。

## Global Constraints

- 對齊常數：`FPS=30`、`TRANSITION=18`、`LEAD=20`、`TAIL=18`（frames）。`TRANSITION` 對應 `marketing/tools/reel-remotion/src/styles/Cinematic.tsx` 的 `TRANSITION`。
- 只支援 Cinematic style（每日預設）。
- 文字推導時長須與 `src/data/story.ts` 的 `beatFrames` 一致：cover=140、ending=150、其它 `max(116, min(170, 66 + 27×非空行數))`。
- TTS 重用 `daily_video_post` 的 `_make_synth` / `_GeminiSynth`（含 key1→`GEMINI_API_KEY_2` fallback、空回應重試）；Gemini 免費層 10 req/day/key，故逐拍快取。
- 混音 filter（verbatim）：`[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[vtmp];[vtmp]asplit=2[v1][v2];[0:a][v1]sidechaincompress=threshold=0.03:ratio=8:attack=5:release=300[bgd];[bgd][v2]amix=inputs=2:normalize=0:duration=first[a]`
- 輸出：`marketing/outputs/daily_video/<date>/{final.mp4, voice.wav}`；中間檔在 `<date>/voice_work/`。
- 所有 uv 指令從 `scripts/` 執行（`cd scripts && uv run ...`）。
- 提交訊息結尾：`Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`。

---

### Task 1: `narration` 欄位接線（types.ts + prepare_story.mjs）

**Files:**
- Modify: `marketing/tools/reel-remotion/src/types.ts`（`Beat` 介面加 `narration?`）
- Modify: `marketing/tools/reel-remotion/scripts/prepare_story.mjs:67`（beat 物件加 `narration` 種子）

**Interfaces:**
- Produces: story.json 每個 beat 多一個 `narration: string` 欄位（scaffold 時＝非空 `lines` 串接草稿）。

- [ ] **Step 1: types.ts 加 `narration?`**

在 `src/types.ts` 的 `Beat` 介面，`highlights: string[];` 之後、`durationFrames?` 之前插入：

```ts
  /** Spoken (for-the-ear) narration for this beat. Fuller than the on-screen
   * `lines`; the voiceover pipeline (reel_voiceover.py) reads it for TTS. */
  narration?: string;
```

- [ ] **Step 2: prepare_story.mjs 種入 narration 草稿**

在 `scripts/prepare_story.mjs` 的 beat 物件（`return { ... }`）中，把
`lines: s.lines || [],` 這行改為兩行：

```js
    lines: s.lines || [],
    narration: (s.lines || []).filter((l) => l !== "").join(""),
```

- [ ] **Step 3: 執行 scaffold 驗證欄位出現**

Run: `cd marketing/tools/reel-remotion && node scripts/prepare_story.mjs 2026-07-11 && grep -c '"narration"' src/data/story.json`
Expected: 輸出 `7`（每拍一個 narration）。
注意：這會用 carousel 重新生成 story.json（覆蓋今天手動 condense 的 lines 與 durationFrames）——屬預期，後續 reel_voiceover 會重寫 durationFrames；lines 需重新 condense 才能實際發布。

- [ ] **Step 4: TypeScript 型別檢查通過**

Run: `cd marketing/tools/reel-remotion && npx tsc --noEmit`
Expected: 無錯誤（`narration?` 為選填，story.json 帶此欄位仍相容）。

- [ ] **Step 5: Commit**

```bash
git add marketing/tools/reel-remotion/src/types.ts marketing/tools/reel-remotion/scripts/prepare_story.mjs
git commit -m "$(printf 'feat(reel-remotion): Beat 加 narration 欄位並於 scaffold 種入草稿\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 2: `reel_voiceover.py` 純函式（TDD）

**Files:**
- Create: `scripts/reel_voiceover.py`
- Test: `scripts/tests/test_reel_voiceover.py`

**Interfaces:**
- Produces:
  - `FPS=30`, `TRANSITION=18`, `LEAD=20`, `TAIL=18`（模組常數）
  - `text_default_frames(beat: dict) -> int`
  - `duration_frames(text_default: int, voice_sec: float) -> int`
  - `beat_start_frames(durations: list[int], transition: int = TRANSITION) -> list[int]`
  - `total_frames(durations: list[int], transition: int = TRANSITION) -> int`
  - `narration_hash(text: str) -> str`
  - `cache_hit(cache: dict, beat_id: str, text: str, wav_exists: bool) -> bool`

- [ ] **Step 1: 寫失敗測試**

Create `scripts/tests/test_reel_voiceover.py`:

```python
"""Tests for the reel voiceover pipeline's pure helpers."""
from __future__ import annotations

import reel_voiceover as rv


def test_text_default_frames_cover_and_ending():
    assert rv.text_default_frames({"layout": "cover", "lines": ["a", "b"]}) == 140
    assert rv.text_default_frames({"layout": "ending", "lines": ["a"]}) == 150


def test_text_default_frames_scales_with_nonempty_lines():
    # 2 non-empty lines: 66 + 27*2 = 120
    assert rv.text_default_frames(
        {"layout": "beat", "lines": ["a", "", "b"]}
    ) == 120
    # 4 non-empty lines: 66 + 27*4 = 174 -> capped at 170
    assert rv.text_default_frames(
        {"layout": "beat", "lines": ["a", "b", "c", "d"]}
    ) == 170
    # 0 non-empty lines: max(116, 66) = 116
    assert rv.text_default_frames({"layout": "beat", "lines": []}) == 116


def test_duration_frames_takes_max_of_text_and_voice():
    # voice 7.0s -> ceil(210) + 38 = 248 > text default 120
    assert rv.duration_frames(120, 7.0) == 248
    # empty narration (0s) -> text default wins
    assert rv.duration_frames(140, 0.0) == 140


def test_beat_start_frames_accounts_for_transition_overlap():
    assert rv.beat_start_frames([296, 249, 266], 18) == [0, 278, 509]


def test_total_frames_subtracts_overlaps():
    assert rv.total_frames([296, 249, 266], 18) == 775


def test_narration_hash_is_deterministic_and_distinct():
    assert rv.narration_hash("富士山") == rv.narration_hash("富士山")
    assert rv.narration_hash("富士山") != rv.narration_hash("富士 山")


def test_cache_hit_requires_matching_hash_and_existing_wav():
    cache = {"cover": rv.narration_hash("hello")}
    assert rv.cache_hit(cache, "cover", "hello", True) is True
    assert rv.cache_hit(cache, "cover", "changed", True) is False
    assert rv.cache_hit(cache, "cover", "hello", False) is False
    assert rv.cache_hit({}, "cover", "hello", True) is False
```

- [ ] **Step 2: 執行確認失敗**

Run: `cd scripts && uv run pytest tests/test_reel_voiceover.py -q`
Expected: FAIL（`ModuleNotFoundError: No module named 'reel_voiceover'`）

- [ ] **Step 3: 寫最小實作**

Create `scripts/reel_voiceover.py`:

```python
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
```

- [ ] **Step 4: 執行確認通過**

Run: `cd scripts && uv run pytest tests/test_reel_voiceover.py -q`
Expected: PASS（7 passed）

- [ ] **Step 5: Commit**

```bash
git add scripts/reel_voiceover.py scripts/tests/test_reel_voiceover.py
git commit -m "$(printf 'feat(reel): reel_voiceover 對齊與快取純函式\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 3: TTS＋快取＋voice.wav 組裝

**Files:**
- Modify: `scripts/reel_voiceover.py`（加 imports、`_run`/`logger`、`synth_beats`、`voice_filter_graph`、`build_voice_wav`）
- Test: `scripts/tests/test_reel_voiceover.py`（加 `synth_beats` 快取測試、`voice_filter_graph` 測試）

**Interfaces:**
- Consumes: `daily_video_post._ffprobe_duration`, `daily_video_post._run`
- Produces:
  - `synth_beats(beats, work_dir, cache, synth, force, measure) -> tuple[dict, dict]`
    回傳 `({beat_id: (wav_path|None, voice_sec)}, new_cache)`。
  - `voice_filter_graph(delays_ms: list[int], total_sec: float) -> str`
  - `build_voice_wav(beats, synth_result, durations, out_path) -> None`

- [ ] **Step 1: 寫失敗測試（加到 test_reel_voiceover.py 末尾）**

```python
def test_synth_beats_skips_cached_and_synths_changed(tmp_path):
    beats = [
        {"id": "cover", "narration": "hello"},
        {"id": "beat1", "narration": "world"},
        {"id": "beat2", "narration": ""},  # empty -> no voice
    ]
    # pre-seed cover's wav + matching cache -> should be skipped
    (tmp_path / "beat_cover.wav").write_bytes(b"x")
    cache = {"cover": rv.narration_hash("hello")}
    synthed = []

    def fake_synth(text, dest):
        synthed.append(text)
        Path(dest).write_bytes(b"y")

    result, new_cache = rv.synth_beats(
        beats, tmp_path, cache, fake_synth, force=False,
        measure=lambda p: 5.0,
    )

    assert synthed == ["world"]            # only the uncached, non-empty beat
    assert result["cover"][1] == 5.0       # measured even when cached
    assert result["beat2"] == (None, 0.0)  # empty narration -> no wav
    assert new_cache["beat1"] == rv.narration_hash("world")
    assert "beat2" not in new_cache


def test_synth_beats_force_resynths_cached(tmp_path):
    beats = [{"id": "cover", "narration": "hello"}]
    (tmp_path / "beat_cover.wav").write_bytes(b"x")
    cache = {"cover": rv.narration_hash("hello")}
    synthed = []

    def fake_synth(text, dest):
        synthed.append(text)
        Path(dest).write_bytes(b"y")

    rv.synth_beats(beats, tmp_path, cache, fake_synth, force=True,
                   measure=lambda p: 3.0)
    assert synthed == ["hello"]


def test_voice_filter_graph_delays_and_trims():
    graph = rv.voice_filter_graph([0, 9260], 60.767)
    assert "adelay=0|0[a0]" in graph
    assert "adelay=9260|9260[a1]" in graph
    assert "amix=inputs=2:normalize=0:duration=longest[m]" in graph
    assert "atrim=0:60.767[out]" in graph
```

- [ ] **Step 2: 執行確認失敗**

Run: `cd scripts && uv run pytest tests/test_reel_voiceover.py -q`
Expected: FAIL（`AttributeError: module 'reel_voiceover' has no attribute 'synth_beats'`）

- [ ] **Step 3: 寫實作（加到 reel_voiceover.py）**

在檔案 import 區塊補上（`from pathlib import Path` 之後）：

```python
import logging
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import daily_video_post as dvp  # noqa: E402

logger = logging.getLogger("reel_voiceover")
```

在檔尾加：

```python
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
```

- [ ] **Step 4: 執行確認通過**

Run: `cd scripts && uv run pytest tests/test_reel_voiceover.py -q`
Expected: PASS（10 passed）

- [ ] **Step 5: Commit**

```bash
git add scripts/reel_voiceover.py scripts/tests/test_reel_voiceover.py
git commit -m "$(printf 'feat(reel): reel_voiceover TTS 快取與 voice.wav 組裝\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 4: render＋mux＋CLI（端到端）

**Files:**
- Modify: `scripts/reel_voiceover.py`（加 `json`/`argparse` import、`render_reel`、`mux`、`main`、`__main__`）

**Interfaces:**
- Consumes: `synth_beats`, `build_voice_wav`, `text_default_frames`, `duration_frames`, `dvp._make_synth`, `dvp.DEFAULT_GEMINI_VOICE`, `dvp.DEFAULT_GEMINI_STYLE`
- Produces: `main(argv: list[str]) -> int`；CLI `python -m reel_voiceover <date> [--engine] [--voice] [--style] [--force-tts]`

- [ ] **Step 1: 寫實作**

在 import 區塊補（與其它 import 並列）：

```python
import argparse
import json
```

在檔尾加：

```python
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
```

- [ ] **Step 2: 純函式測試仍全綠（無回歸）**

Run: `cd scripts && uv run pytest tests/test_reel_voiceover.py -q`
Expected: PASS（10 passed）

- [ ] **Step 3: 端到端驗收（離線 say 引擎，不吃 Gemini 配額）**

先確保 story.json 每拍有 `narration`（Task 1 的 scaffold 已種；若被覆寫過，先跑 `node scripts/prepare_story.mjs 2026-07-11`）。
Run: `cd scripts && uv run python -m reel_voiceover 2026-07-11 --engine say`
Expected: log 印各拍 `durationFrames`、`DONE -> .../final.mp4`。
注意：這會用 `say` 版覆寫 2026-07-11 的 `final.mp4`（原 Gemini 版已上傳存於 VPS）；要恢復 Gemini 版可重跑 `--engine gemini`。

- [ ] **Step 4: 驗收 final.mp4（時長／音軌）**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore/marketing/outputs/daily_video/2026-07-11
ffprobe -v error -show_entries format=duration -of csv=p=0 final.mp4
ffmpeg -hide_banner -i final.mp4 -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume"
```
Expected: duration 與 log 印的秒數一致（±0.1s）；`max_volume` < 0 dB（無爆音）、`mean_volume` 非 `-inf`（非靜音）。

- [ ] **Step 5: 快取驗收（二次執行不發 TTS）**

Run: `cd scripts && uv run python -m reel_voiceover 2026-07-11 --engine say 2>&1 | grep -c "tts skip (cached)"`
Expected: `7`（narration 未變，全部命中快取）。

- [ ] **Step 6: Commit**

```bash
git add scripts/reel_voiceover.py
git commit -m "$(printf 'feat(reel): reel_voiceover render+mux+CLI 端到端\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 5: 更新 lorescape-daily-reel skill 文件

**Files:**
- Modify: `.claude/skills/lorescape-daily-reel/SKILL.md`

**Interfaces:**
- Produces: 文件把「加語音」從一次性手動步驟改成正式指令，並在文案規則加「每拍寫 narration 口說版」。

- [ ] **Step 1: 改 Pipeline 區塊**

在 `## Pipeline` 的 code block，把步驟 2/3 之間補上語音路徑說明。將：

```
# 3. Render + mux BGM -> marketing/outputs/daily_video/<date>/cinematic.mp4
scripts/build_video.sh <YYYY-MM-DD>              # music-forward (-20 LUFS)
scripts/build_video.sh <YYYY-MM-DD> --lufs -28   # quiet bed if adding voiceover
```

改為：

```
# 3a. 音樂版（無語音）：Render + mux BGM -> daily_video/<date>/cinematic.mp4
scripts/build_video.sh <YYYY-MM-DD>              # music-forward (-20 LUFS)

# 3b. 語音版（zh-TW 旁白，逐 beat 同步）-> daily_video/<date>/final.mp4
#     先在 story.json 每拍填 `narration`（口說版，見 Step 2），再：
cd ../../../scripts && uv run python -m reel_voiceover <YYYY-MM-DD>
#     离線 say（不吃 Gemini 配額）：… -m reel_voiceover <date> --engine say
#     改一句只重唸一句（逐拍快取）；--force-tts 全部重唸
```

- [ ] **Step 2: 在「Step 2 — condensing narration」補 narration 規則**

在該小節末尾加一段：

```
- 若要加語音旁白，另外替每拍填 `narration`（口說、為耳朵而寫，比畫面
  `lines` 完整一點，一拍一句連貫）。`prepare_story.mjs` 會用非空 lines
  串接種一個草稿，潤成順口的口說版即可。reel_voiceover 會逐拍 TTS、
  用實測長度回寫 `durationFrames`，讓畫面撐到旁白唸得完。
```

- [ ] **Step 3: 更新 Quick Reference 表**

在 `| Build final |` 那列下方加一列：

```
| Build voiced (final.mp4) | `cd scripts && uv run python -m reel_voiceover <date> [--engine say] [--force-tts]` |
```

- [ ] **Step 4: 目視檢查**

Run: `sed -n '/## Pipeline/,/## Quick Reference/p' .claude/skills/lorescape-daily-reel/SKILL.md`
Expected: 3a/3b 區塊與 narration 規則正確呈現、無殘留舊字。

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/lorescape-daily-reel/SKILL.md
git commit -m "$(printf 'docs(reel): lorescape-daily-reel 記錄 reel_voiceover 正式語音流程\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

## Self-Review

**Spec coverage：**
- 介面 `python -m reel_voiceover <date> [flags]` → Task 4 ✓
- story.json `narration` 欄位 → Task 1 ✓
- 資料流 5 步（TTS→durationFrames→voice.wav→render→mux）→ Task 3+4 ✓
- 對齊細節（FPS/TRANSITION/LEAD/TAIL、start_i、文字推導 max）→ Task 2 純函式 ✓
- 混音 filter（sidechain）→ Task 4 `mux` verbatim ✓
- TTS 配額快取 + fallback + --force-tts + --engine say → Task 3 `synth_beats` + Task 4 CLI ✓
- 邊界：空 narration 不報錯 → Task 3 `synth_beats`（None,0.0）+ Task 4 duration 退回 text_default ✓
- 全數配額用罄報錯 → 重用 `_GeminiSynth` 的 `PostProductionError`（Task 4 透過 `_make_synth`）✓
- 檔案變更清單 4 檔 + build_video/story.ts 不改 → Task 1/2/3/4/5 ✓
- 驗收（say 端到端、時長一致、非靜音、快取全 skip）→ Task 4 Step 3–5 ✓

**Placeholder scan：** 無 TBD/TODO；每個 code step 都有完整程式碼。

**Type consistency：** `synth_beats` 回傳 `{id:(wav|None, sec)}` 在 Task 3 定義、Task 4 `main` 依此解包；`voice_filter_graph`/`build_voice_wav`/`text_default_frames`/`duration_frames`/`beat_start_frames`/`total_frames` 命名跨 Task 2→3→4 一致；常數 `FPS/TRANSITION/LEAD/TAIL` 單一來源（Task 2）。
