"""Playwright-based IG card renderer.

Opens a headless Chromium with a 1080×1350 viewport, loads the Jinja2-
rendered HTML (CSS + local fonts referenced via file://), and screenshots
the page.

Synchronous API for ergonomics: callers should not have to worry about
async event loops just to render a single image.
"""
from __future__ import annotations

from pathlib import Path

from playwright.sync_api import sync_playwright

from .content import CardContent
from .template import render_html, template_dir

_CARD_WIDTH = 1080
_CARD_HEIGHT = 1350


def render_card(content: CardContent) -> bytes:
    """Render the E0c IG card to PNG bytes (1080×1350)."""
    base_url = template_dir().as_uri() + "/"  # file:///.../template/
    html = render_html(content, base_url=base_url)

    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        try:
            page = browser.new_page(
                viewport={"width": _CARD_WIDTH, "height": _CARD_HEIGHT},
                device_scale_factor=1.0,
            )
            # `<base href="...">` in the template makes card.css and the
            # bundled font files resolve under file:// — no temp file needed.
            page.set_content(html, wait_until="networkidle")
            return page.screenshot(
                type="png", full_page=False, omit_background=False
            )
        finally:
            browser.close()


def _cli() -> None:
    """Write the Eiffel demo card to /tmp/eiffel.png for visual inspection.

    Usage:
        uv run python -m lorescape_backend.social.card.renderer
    """
    from ._demo import EIFFEL_DEMO

    out = Path("/tmp/eiffel.png")
    out.write_bytes(render_card(EIFFEL_DEMO))
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    _cli()
