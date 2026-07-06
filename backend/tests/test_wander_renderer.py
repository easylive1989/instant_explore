# backend/tests/test_wander_renderer.py
"""wander/renderer.py — Playwright JPEG 渲染（真的開 chromium，同 card 慣例）."""
from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path

import pytest
from PIL import Image
from playwright.sync_api import sync_playwright

from lorescape_backend.social.wander import renderer as renderer_module
from lorescape_backend.social.wander.content import (
    WanderCarousel,
    WanderContentError,
    WanderSlide,
)
from lorescape_backend.social.wander.renderer import (
    _FIT_OPTS,
    _FIT_SCRIPT,
    _html_file,
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


def test_fit_script_shrinks_long_copy_until_it_fits(photos_dir):
    """Auto-fit 必須真的縮字：--fit < 1 且縮完不再 overflow.

    `test_long_copy_shrinks_via_fit_instead_of_overflowing` only checks the
    output image dimensions, which stay 1080x1350 even if `--fit` never
    engages (`.ws-card` hides overflow, so clipping is invisible to a size
    check). This test drives the real fit pass and reads the DOM metrics
    directly, so a no-op fit script would fail it.
    """
    long_slide = WanderSlide(
        layout="beat", photo="a.jpg", title="長文測試，",
        lines=tuple(f"這是一句用來把版面塞爆的長句子第 {i} 行。"
                    for i in range(14)),
    )
    with _html_file(long_slide, photos_dir=photos_dir) as tmp_path:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            try:
                page = browser.new_page(
                    viewport={"width": 1080, "height": 1350},
                    device_scale_factor=1.0,
                )
                page.goto(tmp_path.as_uri(), wait_until="networkidle")
                fit = page.evaluate(_FIT_SCRIPT, _FIT_OPTS)
                metrics = page.evaluate(
                    "() => { const p = document.querySelector('.ws-fit');"
                    " return {scroll: p.scrollHeight, client: p.clientHeight}; }"
                )
            finally:
                browser.close()

    assert fit < 1.0
    assert metrics["scroll"] <= metrics["client"]


def test_cli_removes_stale_slides_before_writing(tmp_path, monkeypatch):
    """重渲染必須清掉舊的 slide_*.jpg，避免殘留頁被送審發布."""
    day_dir = tmp_path / "2026-07-06"
    day_dir.mkdir()
    (day_dir / "slides.json").write_text(json.dumps({
        "slides": [
            {"layout": "beat", "photo": "a.jpg", "lines": ["一句。"]},
            {"layout": "ending", "photo": "a.jpg", "lines": ["結尾。"]},
        ],
    }, ensure_ascii=False), encoding="utf-8")
    (day_dir / "caption.txt").write_text("cap", encoding="utf-8")
    (day_dir / "slide_03.jpg").write_bytes(b"stale")
    (day_dir / "slide_09.jpg").write_bytes(b"stale")
    monkeypatch.setattr(
        renderer_module, "render_carousel",
        lambda carousel, *, photos_dir: [b"new-1", b"new-2"],
    )

    exit_code = renderer_module.main([str(day_dir), str(tmp_path)])

    assert exit_code == 0
    slides = sorted(p.name for p in day_dir.glob("slide_*.jpg"))
    assert slides == ["slide_01.jpg", "slide_02.jpg"]
