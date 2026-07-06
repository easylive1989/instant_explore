"""Pure Jinja2 HTML rendering for the wander-style slide (no browser)."""
from __future__ import annotations

from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape
from markupsafe import Markup, escape

from .content import WanderSlide

_TEMPLATE_DIR = Path(__file__).resolve().parent / "template"


def _mark_highlights(text: str, highlights: tuple[str, ...]) -> Markup:
    """Escape `text`, then wrap each highlight word in `<em class="hl">`.

    Escaping happens first so the replacement operates on the same form the
    page will show; highlight words themselves are escaped the same way.
    """
    escaped = str(escape(text))
    for word in highlights or ():
        escaped_word = str(escape(word))
        escaped = escaped.replace(
            escaped_word, f'<em class="hl">{escaped_word}</em>'
        )
    return Markup(escaped)


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
