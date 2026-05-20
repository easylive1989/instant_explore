"""Tests for Jinja2 HTML rendering (no Playwright)."""
from __future__ import annotations

from lorescape_backend.social.card import render_html
from lorescape_backend.social.card._demo import EIFFEL_DEMO


def test_render_html_contains_title():
    html = render_html(EIFFEL_DEMO)
    assert "討厭鐵塔的文學大師" in html
    assert "莫泊桑的「專屬午餐位」" in html


def test_render_html_contains_first_paragraph_with_dropcap_split():
    html = render_html(EIFFEL_DEMO)
    # First Chinese character of first paragraph becomes drop-cap
    assert "西" in html  # the dropcap char
    assert "元一八八九年艾菲爾鐵塔甫落成" in html  # the remainder


def test_render_html_contains_all_paragraphs():
    html = render_html(EIFFEL_DEMO)
    for paragraph in EIFFEL_DEMO.paragraphs_ch:
        # Each paragraph appears at least as substring of HTML (drop-cap
        # might split the first, so accept either the full or the tail).
        if paragraph is EIFFEL_DEMO.paragraphs_ch[0]:
            assert paragraph[1:] in html  # tail after drop-cap
        else:
            assert paragraph in html


def test_render_html_contains_pull_quote():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.pull_quote_ch in html
    assert EIFFEL_DEMO.pull_quote_attrib_ch in html


def test_render_html_contains_location_block():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.location_en in html       # spine label
    assert EIFFEL_DEMO.location_coord in html
    assert EIFFEL_DEMO.anno_roman in html


def test_render_html_contains_photo_url():
    html = render_html(EIFFEL_DEMO)
    assert EIFFEL_DEMO.photo_url in html


def test_render_html_links_local_css_and_fonts():
    html = render_html(EIFFEL_DEMO)
    # Stylesheet linked relative or via file:// — ok either way
    assert "card.css" in html
