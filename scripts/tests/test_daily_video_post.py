"""Tests for the daily-video post-production helpers."""
from __future__ import annotations

from PIL import Image

import daily_video_post


def test_target_dimensions_upscales_720p_to_1080p():
    assert daily_video_post._target_dimensions(720, 1280, 1920) == (1080, 1920)


def test_target_dimensions_keeps_matching_height_unchanged():
    assert daily_video_post._target_dimensions(1080, 1920, 1920) == (1080, 1920)


def test_target_dimensions_zero_disables_scaling():
    assert daily_video_post._target_dimensions(720, 1280, 0) == (720, 1280)


def test_target_dimensions_rounds_width_to_even():
    # An odd computed width (e.g. 4:3 upscaled) is bumped up to stay even so
    # libx264/yuv420p never chokes on an odd dimension.
    width, height = daily_video_post._target_dimensions(1001, 1920, 960)
    assert height == 960
    assert width % 2 == 0


def test_hook_caption_is_higher_and_larger_than_body(tmp_path):
    # First line = attention-grabbing hook (bigger, upper-centre); the rest
    # are body captions anchored above IG's bottom UI band.
    timings = [(0.0, 2.0, "鉤子問句？"), (2.0, 4.0, "本文內容。")]
    pngs = daily_video_post._render_caption_pngs(
        timings, 1080, 1920, daily_video_post.DEFAULT_FONT, tmp_path
    )

    assert len(pngs) == 2
    hook_bbox = Image.open(pngs[0][0]).getbbox()
    body_bbox = Image.open(pngs[1][0]).getbbox()
    # Hook sits above the body (smaller top y).
    assert hook_bbox[1] < body_bbox[1]
    # Body stays clear of the bottom ~20% UI band.
    assert body_bbox[3] <= 1920 * (1 - daily_video_post
                                   .CAPTION_BOTTOM_MARGIN_FRACTION) + 1
    # Hook glyphs are taller (larger font).
    assert (hook_bbox[3] - hook_bbox[1]) > (body_bbox[3] - body_bbox[1])
