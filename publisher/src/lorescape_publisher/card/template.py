"""Pure Jinja2 HTML rendering for the IG card (no browser)."""
from __future__ import annotations

from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape

from .content import CardContent

_TEMPLATE_DIR = Path(__file__).resolve().parent / "template"

_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATE_DIR)),
    autoescape=select_autoescape(["html", "j2"]),
)


def render_html(
    content: CardContent, *, base_url: str = "", slide: str | None = None
) -> str:
    """Render the card to an HTML string. No browser involved.

    `base_url` is injected as `<base href=...>` so relative paths (card.css,
    ./fonts/...) resolve correctly when loaded in a browser. Unit tests can
    leave it empty.

    `slide` selects a single carousel plate: 'cover', 'story' or 'cta'. The
    default (None) renders the legacy combined photo+text card unchanged.
    """
    tmpl = _env.get_template("card.html.j2")
    return tmpl.render(content=content, base_url=base_url, slide=slide)


def template_dir() -> Path:
    """Absolute path to the template directory (used by the Playwright renderer)."""
    return _TEMPLATE_DIR
