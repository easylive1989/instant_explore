"""wander/content.py — slides.json + caption.txt 載入與驗證."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from lorescape_backend.social.wander.content import (
    WanderContentError,
    load_carousel,
)

VALID = {
    "slides": [
        {
            "layout": "cover",
            "photo": "dress.jpg",
            "tag_zh": "奧地利旅行",
            "tag_en": "Austria",
            "title": "茜茜公主",
            "title_en": "Empress Sisi",
            "lines": ["原本安排訂婚的，", "其實是她的姊姊。", "", "沒想到，"],
        },
        {
            "layout": "beat",
            "photo": "room.jpg",
            "text_position": "left",
            "title": "16 歲時，",
            "lines": ["西西公主嫁入奧地利皇室。"],
            "highlights": ["奧地利皇室"],
            "overlay": "darker",
        },
        {
            "layout": "bright",
            "photo": "palace.jpg",
            "lines": ["比起留在皇宮，", "她更喜歡旅行。"],
        },
        {
            "layout": "ending",
            "photo": "salon.jpg",
            "lines": ["人生難免有許多身不由己。"],
        },
    ]
}


def _write_day_dir(tmp_path: Path, payload: dict, caption: str = "cap") -> Path:
    (tmp_path / "slides.json").write_text(
        json.dumps(payload, ensure_ascii=False), encoding="utf-8"
    )
    (tmp_path / "caption.txt").write_text(caption, encoding="utf-8")
    return tmp_path


def test_load_carousel_parses_slides_and_caption(tmp_path):
    day_dir = _write_day_dir(tmp_path, VALID, caption="今天的故事 #lorescape")
    carousel = load_carousel(day_dir)
    assert carousel.caption == "今天的故事 #lorescape"
    assert carousel.date == tmp_path.name
    assert len(carousel.slides) == 4
    cover = carousel.slides[0]
    assert cover.layout == "cover"
    assert cover.title == "茜茜公主"
    assert cover.lines[2] == ""          # 分隔符慣例
    beat = carousel.slides[1]
    assert beat.text_position == "left"
    assert beat.highlights == ("奧地利皇室",)
    assert beat.overlay == "darker"


def test_defaults_are_dark_overlay_and_left_text(tmp_path):
    day_dir = _write_day_dir(tmp_path, VALID)
    bright = load_carousel(day_dir).slides[2]
    assert bright.overlay == "dark"
    assert bright.text_position == "left"
    assert bright.highlights == ()


@pytest.mark.parametrize(
    "mutate, message_part",
    [
        (lambda p: p["slides"][0].pop("photo"), "photo"),
        (lambda p: p["slides"][0].update(layout="hero"), "layout"),
        (lambda p: p["slides"][1].update(text_position="middle"),
         "text_position"),
        (lambda p: p["slides"][1].update(overlay="red"), "overlay"),
        (lambda p: p["slides"][0].update(lines=[]), "lines"),
        (lambda p: p.update(slides=[]), "slides"),
        (lambda p: p.update(
            slides=[dict(p["slides"][1]) for _ in range(11)]), "10"),
    ],
)
def test_invalid_payload_raises(tmp_path, mutate, message_part):
    payload = json.loads(json.dumps(VALID))
    mutate(payload)
    day_dir = _write_day_dir(tmp_path, payload)
    with pytest.raises(WanderContentError, match=message_part):
        load_carousel(day_dir)


def test_missing_caption_file_raises(tmp_path):
    (tmp_path / "slides.json").write_text(
        json.dumps(VALID, ensure_ascii=False), encoding="utf-8"
    )
    with pytest.raises(WanderContentError, match="caption"):
        load_carousel(tmp_path)
