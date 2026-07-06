# backend/tests/test_wander_renderer.py
"""wander/renderer.py — Playwright JPEG 渲染（真的開 chromium，同 card 慣例）."""
from __future__ import annotations

from io import BytesIO
from pathlib import Path

import pytest
from PIL import Image

from lorescape_backend.social.wander.content import (
    WanderCarousel,
    WanderContentError,
    WanderSlide,
)
from lorescape_backend.social.wander.renderer import (
    render_carousel,
    render_slide,
)


@pytest.fixture(scope="module")
def photos_dir(tmp_path_factory) -> Path:
    """兩張小 JPEG 當背景照."""
    photos = tmp_path_factory.mktemp("photos")
    for name, color in (("a.jpg", (120, 40, 40)), ("b.jpg", (40, 40, 120))):
        Image.new("RGB", (320, 400), color).save(photos / name, "JPEG")
    return photos


BEAT = WanderSlide(
    layout="beat", photo="a.jpg", title="16 歲時，",
    lines=("西西公主嫁入奧地利皇室。", "卻沒有帶來她想像中的幸福。"),
)


@pytest.fixture(scope="module")
def beat_jpeg(photos_dir) -> bytes:
    return render_slide(BEAT, photos_dir=photos_dir)


def test_render_slide_returns_1080_by_1350_jpeg(beat_jpeg):
    image = Image.open(BytesIO(beat_jpeg))
    image.verify()
    assert image.format == "JPEG"
    assert Image.open(BytesIO(beat_jpeg)).size == (1080, 1350)


def test_render_slide_missing_photo_raises(photos_dir):
    slide = WanderSlide(layout="beat", photo="nope.jpg", lines=("x",))
    with pytest.raises(WanderContentError, match="nope.jpg"):
        render_slide(slide, photos_dir=photos_dir)


def test_render_carousel_returns_one_jpeg_per_slide(photos_dir):
    carousel = WanderCarousel(
        date="2026-07-06", caption="cap",
        slides=(
            BEAT,
            WanderSlide(layout="bright", photo="b.jpg",
                        lines=("比起留在皇宮，", "她更喜歡旅行。")),
        ),
    )
    jpegs = render_carousel(carousel, photos_dir=photos_dir)
    assert len(jpegs) == 2
    for jpeg in jpegs:
        assert Image.open(BytesIO(jpeg)).size == (1080, 1350)


def test_long_copy_shrinks_via_fit_instead_of_overflowing(photos_dir):
    """長文觸發 auto-fit：仍要輸出完整尺寸的圖（不炸版）."""
    long_slide = WanderSlide(
        layout="beat", photo="a.jpg", title="長文測試，",
        lines=tuple(f"這是一句用來把版面塞爆的長句子第 {i} 行。"
                    for i in range(14)),
    )
    jpeg = render_slide(long_slide, photos_dir=photos_dir)
    assert Image.open(BytesIO(jpeg)).size == (1080, 1350)
