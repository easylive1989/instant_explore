"""Layout-fit integration tests for the IG card renderer.

Reproduces the bug where a long body text pushed the pull-quote + footer
past the bottom edge (the bare `1fr` text-plate track grew to its
min-content height, overflowing the fixed 1350px card). The renderer now
caps the track and auto-shrinks `--fit` until the footer clears the inner
frame.

Requires Chromium installed locally:
    uv run playwright install chromium
"""
from __future__ import annotations

import dataclasses

import pytest
from playwright.sync_api import sync_playwright

from lorescape_publisher.card._demo import EIFFEL_DEMO, LONG_DEMO, _BLANK_PNG
from lorescape_publisher.card.content import CardContent
from lorescape_publisher.card.renderer import (
    _CARD_HEIGHT,
    _CARD_WIDTH,
    _FRAME_INSET,
    _html_file,
    _prepare_page,
)

# Short demo with a local photo so the test never touches the network.
SHORT_DEMO = dataclasses.replace(EIFFEL_DEMO, photo_url=_BLANK_PNG)

_MEASURE = """
() => {
  const plate = document.querySelector('.ls-text');
  const foot = document.querySelector('.ls-foot');
  const card = document.querySelector('.ls-card');
  const fitRaw = plate.style.getPropertyValue('--fit');
  return {
    fit: fitRaw === '' ? 1 : parseFloat(fitRaw),
    footBottom: foot.getBoundingClientRect().bottom,
    cardBottom: card.getBoundingClientRect().bottom,
    plateScroll: plate.scrollHeight,
    plateClient: plate.clientHeight,
  };
}
"""


def _measure(content: CardContent) -> dict:
    """Render `content` through the real load+fit path and return DOM metrics."""
    with _html_file(content) as tmp_path:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            try:
                page = browser.new_page(
                    viewport={"width": _CARD_WIDTH, "height": _CARD_HEIGHT},
                    device_scale_factor=1.0,
                )
                _prepare_page(page, tmp_path)
                return page.evaluate(_MEASURE)
            finally:
                browser.close()


@pytest.fixture(scope="module")
def long_metrics() -> dict:
    return _measure(LONG_DEMO)


@pytest.fixture(scope="module")
def short_metrics() -> dict:
    return _measure(SHORT_DEMO)


def test_long_content_footer_clears_frame(long_metrics: dict):
    # The footer must sit fully on the card, above the inner frame line —
    # the original bug pushed it to y≈1413 (63px past the 1350 edge).
    limit = long_metrics["cardBottom"] - _FRAME_INSET
    assert long_metrics["footBottom"] <= limit


def test_long_content_does_not_overflow_or_clip(long_metrics: dict):
    # Nothing is clipped: the plate content fits its (now capped) slot.
    assert long_metrics["plateScroll"] <= long_metrics["plateClient"] + 1


def test_long_content_triggers_autofit(long_metrics: dict):
    # The fix actually engaged (shrunk below the natural size).
    assert long_metrics["fit"] < 1.0


def test_long_content_footer_still_near_bottom(long_metrics: dict):
    # Sanity: auto-fit didn't collapse the layout to a tiny block near the
    # top — the footer should still live in the lower portion of the card.
    assert long_metrics["footBottom"] >= 1150


def test_short_content_is_unchanged(short_metrics: dict):
    # Short content never overflows, so `--fit` stays 1 (byte-for-byte the
    # previous layout) and the footer sits comfortably above the frame.
    assert short_metrics["fit"] == 1.0
    limit = short_metrics["cardBottom"] - _FRAME_INSET
    assert short_metrics["footBottom"] <= limit
    assert short_metrics["footBottom"] >= 1250
