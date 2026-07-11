"""wander/template.py — 純 HTML 渲染（不開瀏覽器）."""
from __future__ import annotations

from lorescape_publisher.wander.content import WanderSlide
from lorescape_publisher.wander.template import render_html

COVER = WanderSlide(
    layout="cover",
    photo="dress.jpg",
    tag_zh="奧地利旅行",
    tag_en="Austria",
    title="茜茜公主",
    title_en="Empress Sisi",
    lines=("原本安排訂婚的，", "其實是她的姊姊。", "", "沒想到，"),
)

BEAT = WanderSlide(
    layout="beat",
    photo="room.jpg",
    title="16 歲時，",
    lines=("西西公主嫁入奧地利皇室。",),
    highlights=("奧地利皇室",),
    text_position="right",
    overlay="darker",
)


def test_cover_contains_title_tag_and_script_subtitle():
    html = render_html(COVER, photo_uri="file:///photos/dress.jpg")
    assert "ws-card--cover" in html
    assert "茜茜公主" in html
    assert "Empress Sisi" in html
    assert "奧地利旅行" in html
    assert "file:///photos/dress.jpg" in html


def test_separator_line_renders_as_ws_sep_not_paragraph():
    html = render_html(COVER, photo_uri="x")
    assert html.count('class="ws-sep"') == 1


def test_highlight_words_are_wrapped_in_em_hl():
    html = render_html(BEAT, photo_uri="x")
    assert '<em class="hl">奧地利皇室</em>' in html


def test_beat_carries_layout_overlay_and_position_classes():
    html = render_html(BEAT, photo_uri="x")
    assert "ws-card--beat" in html
    assert "ws-overlay--darker" in html
    assert "ws-body--right" in html
    assert "ws-fit" in html


def test_every_slide_has_lorescape_brandmark():
    for slide in (COVER, BEAT):
        assert "ws-brandmark" in render_html(slide, photo_uri="x")
        assert "Lorescape" in render_html(slide, photo_uri="x")


def test_ending_has_brand_block():
    ending = WanderSlide(
        layout="ending", photo="salon.jpg",
        lines=("人生難免有許多身不由己。",),
    )
    html = render_html(ending, photo_uri="x")
    assert "ws-endbrand" in html
    assert "AI 旅行說書人" in html
    assert "下載連結在個人簡介" in html


def test_html_is_escaped_but_highlights_stay_markup():
    slide = WanderSlide(
        layout="beat", photo="x.jpg",
        lines=('<script>alert(1)</script>',),
    )
    html = render_html(slide, photo_uri="x")
    assert "<script>alert" not in html
    assert "&lt;script&gt;" in html


def test_overlapping_highlights_do_not_nest():
    slide = WanderSlide(
        layout="beat", photo="x.jpg",
        lines=("西西公主嫁入奧地利皇室。",),
        highlights=("奧地利", "奧地利皇室"),
    )
    html = render_html(slide, photo_uri="x")
    assert '<em class="hl">奧地利皇室</em>' in html
    assert '<em class="hl"><em' not in html
