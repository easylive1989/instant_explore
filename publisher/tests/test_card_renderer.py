"""Integration test for the IG card Playwright renderer.

Requires Chromium installed locally:
    uv run playwright install chromium
"""
from __future__ import annotations

from io import BytesIO

import pytest
from PIL import Image

from lorescape_publisher.card import (
    CAROUSEL_SLIDES,
    render_card,
    render_cover,
    render_slides,
)
from lorescape_publisher.card._demo import EIFFEL_DEMO


@pytest.fixture(scope="module")
def png_bytes() -> bytes:
    return render_card(EIFFEL_DEMO)


@pytest.fixture(scope="module")
def slide_pngs() -> list[bytes]:
    return render_slides(EIFFEL_DEMO)


def test_render_card_returns_bytes(png_bytes: bytes):
    assert isinstance(png_bytes, bytes)
    assert len(png_bytes) > 1000  # sanity floor — even a blank 1080×1350 is bigger


def test_render_card_output_decodes_as_png(png_bytes: bytes):
    image = Image.open(BytesIO(png_bytes))
    image.verify()
    assert image.format == "PNG"


def test_render_card_dimensions_are_1080_by_1350(png_bytes: bytes):
    image = Image.open(BytesIO(png_bytes))
    assert image.size == (1080, 1350)


def test_render_slides_returns_one_png_per_carousel_slide(
    slide_pngs: list[bytes],
):
    assert len(slide_pngs) == len(CAROUSEL_SLIDES)


def test_render_slides_each_decodes_as_1080_by_1350_png(
    slide_pngs: list[bytes],
):
    for png in slide_pngs:
        image = Image.open(BytesIO(png))
        image.verify()
        assert image.format == "PNG"
        assert Image.open(BytesIO(png)).size == (1080, 1350)


def test_render_cover_returns_a_1080_by_1350_png():
    png = render_cover(EIFFEL_DEMO)
    image = Image.open(BytesIO(png))
    image.verify()
    assert image.format == "PNG"
    assert Image.open(BytesIO(png)).size == (1080, 1350)
