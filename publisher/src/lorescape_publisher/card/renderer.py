"""Playwright-based IG card renderer.

Opens a headless Chromium with a 1080×1350 viewport, loads the Jinja2-
rendered HTML (CSS + local fonts referenced via file://), and screenshots
the page.

Synchronous API for ergonomics: callers should not have to worry about
async event loops just to render a single image.
"""
from __future__ import annotations

import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

from .content import CardContent
from .template import render_html, template_dir

_CARD_WIDTH = 1080
_CARD_HEIGHT = 1350

# Inner decorative frame inset (keep in sync with `.ls-card::after` in
# card.css). Used by the layout tests to assert the footer clears the frame.
_FRAME_INSET = 22

# Auto-fit: when the body text is long the text plate would otherwise push
# the quote + footer past the bottom edge (a bare `1fr` grid track grows to
# its content's min-content height; card.css now caps it with `minmax(0,1fr)`
# so the overflow is real and measurable). This script dials the plate's
# `--fit` variable down in small steps — scaling the type and vertical rhythm
# uniformly — until the whole block (including its bottom breathing room)
# fits the capped slot, i.e. the plate no longer overflows. Short content
# never overflows, so `--fit` stays 1 and the layout is byte-for-byte
# unchanged.
_FIT_SCRIPT = """
(opts) => {
  const plate = document.querySelector('.ls-text');
  if (!plate) return 1;
  const initial = parseFloat(
    getComputedStyle(plate).getPropertyValue('--fit'),
  );
  let fit = Number.isFinite(initial) ? initial : 1;
  let guard = 0;
  while (
    plate.scrollHeight > plate.clientHeight &&
    fit > opts.floor &&
    guard < 80
  ) {
    fit = Math.round((fit - opts.step) * 1000) / 1000;
    plate.style.setProperty('--fit', String(fit));
    guard += 1;
  }
  return fit;
}
"""

_FIT_OPTS = {
    "floor": 0.6,
    "step": 0.02,
}


@contextmanager
def _html_file(content: CardContent, *, slide: str | None = None) -> Iterator[Path]:
    """Render the card HTML to a temp file inside the template dir.

    The file lives in the template dir so that:
      1. relative paths (card.css, ./fonts/...) resolve via file://
      2. Chromium treats the document as file://-origin, which allows
         loading sibling file:// resources (about:blank from set_content
         would block them as a cross-origin security measure).
    """
    base_url = template_dir().as_uri() + "/"
    html = render_html(content, base_url=base_url, slide=slide)
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".html",
        dir=str(template_dir()),
        encoding="utf-8",
        delete=False,
    ) as tmp:
        tmp.write(html)
        tmp_path = Path(tmp.name)
    try:
        yield tmp_path
    finally:
        tmp_path.unlink(missing_ok=True)


def _prepare_page(page: Page, tmp_path: Path) -> None:
    """Load the card into `page` and apply the auto-fit pass.

    Shared by `render_card` and the layout tests so both exercise the exact
    same load + fit behaviour.
    """
    page.goto(tmp_path.as_uri(), wait_until="networkidle")
    page.evaluate(_FIT_SCRIPT, _FIT_OPTS)


# Carousel slides, in feed order: clean cover → readable story → CTA.
CAROUSEL_SLIDES: tuple[str, ...] = ("cover", "story", "cta")


def _screenshot_slide(browser, tmp_path: Path) -> bytes:
    page = browser.new_page(
        viewport={"width": _CARD_WIDTH, "height": _CARD_HEIGHT},
        device_scale_factor=1.0,
    )
    try:
        _prepare_page(page, tmp_path)
        return page.screenshot(
            type="png", full_page=False, omit_background=False
        )
    finally:
        page.close()


def render_card(content: CardContent) -> bytes:
    """Render the legacy combined IG card to PNG bytes (1080×1350)."""
    with _html_file(content) as tmp_path:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            try:
                return _screenshot_slide(browser, tmp_path)
            finally:
                browser.close()


def render_cover(content: CardContent) -> bytes:
    """Render just the carousel cover slide to PNG bytes (1080×1350).

    Used as a Reel cover so a video post shares the same clean title face as
    the carousel cards in the grid.
    """
    with _html_file(content, slide="cover") as tmp_path:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            try:
                return _screenshot_slide(browser, tmp_path)
            finally:
                browser.close()


def render_slides(content: CardContent) -> list[bytes]:
    """Render the carousel slides to a list of PNG bytes (each 1080×1350).

    Order matches `CAROUSEL_SLIDES`: cover, story, CTA. One browser is
    launched and reused across slides.
    """
    slides: list[bytes] = []
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        try:
            for slide in CAROUSEL_SLIDES:
                with _html_file(content, slide=slide) as tmp_path:
                    slides.append(_screenshot_slide(browser, tmp_path))
        finally:
            browser.close()
    return slides


def _cli() -> None:
    """Write the Eiffel demo card to /tmp/eiffel.png for visual inspection.

    Usage:
        uv run python -m lorescape_publisher.card.renderer
    """
    from ._demo import EIFFEL_DEMO

    out = Path("/tmp/eiffel.png")
    out.write_bytes(render_card(EIFFEL_DEMO))
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    _cli()
