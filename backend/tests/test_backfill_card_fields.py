"""Tests for the one-off backfill script."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import pytest

from scripts import backfill_card_fields


@dataclass
class _FakeStoryRow:
    id: str
    language: str
    place_id: str
    card_paragraphs: list[str] | None


@dataclass
class _FakePlaceRow:
    id: str
    wikipedia_title_en: str


class _FakeSupabase:
    def __init__(self, story_rows: list[dict], place_rows: list[dict]):
        self.story_rows = story_rows
        self.place_rows = place_rows
        self.updates: list[tuple[str, dict]] = []

    def table(self, name: str):
        return _FakeTable(self, name)


class _FakeTable:
    def __init__(self, db: _FakeSupabase, name: str):
        self.db = db
        self.name = name
        self._filters: dict[str, Any] = {}
        self._select_called = False
        self._update_payload: dict | None = None

    def select(self, *_args, **_kwargs):
        self._select_called = True
        return self

    def is_(self, col: str, val):
        self._filters[col] = ("is", val)
        return self

    def eq(self, col: str, val):
        self._filters[col] = ("eq", val)
        return self

    def update(self, payload: dict):
        self._update_payload = payload
        return self

    def execute(self):
        if self._update_payload is not None:
            row_id = self._filters["id"][1]
            self.db.updates.append((row_id, self._update_payload))
            return _Result(data=[{"id": row_id}])
        if self.name == "daily_stories":
            rows = [r for r in self.db.story_rows if r["card_paragraphs"] is None]
            return _Result(data=rows)
        if self.name == "daily_story_places":
            target_id = self._filters["id"][1]
            rows = [r for r in self.db.place_rows if r["id"] == target_id]
            return _Result(data=rows)
        return _Result(data=[])


@dataclass
class _Result:
    data: list[dict]


def _fake_generate_story(**_kwargs):
    from lorescape_backend.daily_story.gemini_client import GeneratedStory
    return GeneratedStory(
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        hashtags=("history",),
        paragraphs=("長段一", "長段二", "長段三"),
        card_title="血腥的盛宴",
        card_title_sub="從石灰岩堆砌的命運舞台",
        card_paragraphs=("段一", "段二", "段三"),
        card_pull_quote="「他們將死之人向您致敬」",
        card_pull_quote_attrib="── 蘇埃托尼烏斯，西元 121 年",
        card_anno_roman="LXXX",
    )


def _fake_fetch_summary(_title: str):
    from lorescape_backend.daily_story.wikipedia import WikipediaSummary
    return WikipediaSummary(
        title="Colosseum",
        extract="Built in 70-80 CE by Vespasian.",
        image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )


@pytest.fixture
def fake_db():
    return _FakeSupabase(
        story_rows=[
            {"id": "r1", "language": "zh-TW", "place_id": "p1", "card_paragraphs": None},
            {"id": "r2", "language": "en",    "place_id": "p1", "card_paragraphs": None},
            {"id": "r3", "language": "zh-TW", "place_id": "p1", "card_paragraphs": ["a", "b", "c"]},
        ],
        place_rows=[{"id": "p1", "wikipedia_title_en": "Colosseum"}],
    )


def test_run_backfills_only_null_rows(monkeypatch, fake_db):
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _fake_generate_story)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=False)

    assert result.processed == 2
    assert result.failed == 0
    updated_ids = {row_id for row_id, _ in fake_db.updates}
    assert updated_ids == {"r1", "r2"}


def test_run_writes_joined_story_and_all_card_fields(monkeypatch, fake_db):
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _fake_generate_story)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    backfill_card_fields.run(fake_db, dry_run=False)

    _, payload = fake_db.updates[0]
    assert payload["card_paragraphs"] == ["段一", "段二", "段三"]
    assert payload["story"] == "段一\n\n段二\n\n段三"
    assert payload["card_title"] == "血腥的盛宴"
    assert payload["card_anno_roman"] == "LXXX"
    assert payload["place_name"] == "羅馬競技場"


def test_dry_run_does_not_call_gemini_or_write(monkeypatch, fake_db):
    called = []
    def _spy(**kwargs):
        called.append(kwargs)
        return _fake_generate_story(**kwargs)
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _spy)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=True)

    assert result.processed == 2  # would-process count
    assert called == []
    assert fake_db.updates == []


def test_single_row_failure_does_not_stop_run(monkeypatch, fake_db):
    call_count = {"n": 0}
    def _flaky(**kwargs):
        call_count["n"] += 1
        if call_count["n"] == 1:
            raise RuntimeError("simulated Gemini failure")
        return _fake_generate_story(**kwargs)
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _flaky)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=False)

    assert result.processed == 1
    assert result.failed == 1
    assert len(fake_db.updates) == 1
