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
