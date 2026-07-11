"""Tests for the reel voiceover pipeline's pure helpers."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

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


def test_synth_beats_persists_cache_after_each_synth(tmp_path):
    beats = [
        {"id": "cover", "narration": "hello"},
        {"id": "beat1", "narration": "boom"},
    ]
    cache_path = tmp_path / "voice_cache.json"
    calls = []

    def flaky_synth(text, dest):
        calls.append(text)
        if text == "boom":
            raise RuntimeError("simulated mid-run TTS failure")
        Path(dest).write_bytes(b"y")

    with pytest.raises(RuntimeError):
        rv.synth_beats(
            beats, tmp_path, {}, flaky_synth, force=False,
            measure=lambda p: 4.0, cache_path=cache_path,
        )

    # cover was synthesized before the failure; its hash must already be on disk
    persisted = json.loads(cache_path.read_text(encoding="utf-8"))
    assert persisted == {"cover": rv.narration_hash("hello")}


def test_voice_filter_graph_delays_and_trims():
    graph = rv.voice_filter_graph([0, 9260], 60.767)
    assert "adelay=0|0[a0]" in graph
    assert "adelay=9260|9260[a1]" in graph
    assert "amix=inputs=2:normalize=0:duration=longest[m]" in graph
    assert "atrim=0:60.767[out]" in graph
