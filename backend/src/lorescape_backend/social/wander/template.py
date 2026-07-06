"""Pure Jinja2 HTML rendering for the wander-style slide (no browser)."""
from __future__ import annotations

import re
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape
from markupsafe import Markup, escape

from .content import WanderSlide

_TEMPLATE_DIR = Path(__file__).resolve().parent / "template"


def _mark_highlights(text: str, highlights: tuple[str, ...]) -> Markup:
    """Escape `text`, then wrap each highlight word in `<em class="hl">`.

    Escaping happens first so the replacement operates on the same form the
    page will show. A single regex pass (longest word first) keeps
    overlapping highlight words from nesting inside each other's markup.
    """
    escaped = str(escape(text))
    words = [str(escape(w)) for w in highlights if w]
    if not words:
        return Markup(escaped)
    pattern = re.compile(
        "|".join(
            re.escape(word)
            for word in sorted(words, key=len, reverse=True)
        )
    )
    marked = pattern.sub(
        lambda match: f'<em class="hl">{match.group(0)}</em>', escaped
    )
    return Markup(marked)


_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATE_DIR)),
    autoescape=select_autoescape(["html", "j2"]),
)
_env.filters["hl"] = _mark_highlights


def render_html(
    slide: WanderSlide, *, photo_uri: str, base_url: str = ""
) -> str:
    """Render one slide to an HTML string.

    `photo_uri` is the background photo as an absolute URI (`file://` when
    rendering locally). `base_url` is injected as `<base href>` so
    wander.css and the shared fonts resolve when loaded in a browser.
    """
    tmpl = _env.get_template("wander.html.j2")
    return tmpl.render(slide=slide, photo_uri=photo_uri, base_url=base_url)


def template_dir() -> Path:
    """Absolute path to the template directory (used by the renderer)."""
    return _TEMPLATE_DIR
