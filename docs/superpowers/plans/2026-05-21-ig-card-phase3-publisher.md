# IG Card Phase 3 — Publisher + Supabase Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace IG's Wikipedia-photo + English-caption flow with rendered E0c card PNG + zh-TW caption, sourced from the zh-TW `daily_stories` row joined with its `daily_story_places` row, uploaded to a public Supabase Storage bucket.

**Architecture:** New `social/card/mapper.py` composes `CardContent` from joined rows (returns `None` if any required field is NULL). New `social/card_storage.py` uploads PNG bytes to the public `ig-cards` bucket and returns a public URL. `social/publisher.py` is rewired to load both rows, attempt to build `CardContent`, render via Phase 1's `render_card`, upload, and call `instagram.publish` with the card URL and a zh-TW caption. Threads continues to use the en row. If `CardContent` cannot be built, IG is skipped, Threads still runs, and a `publish_error` note is recorded.

**Tech Stack:** Python 3.12, pytest, supabase-py (storage3 client), Playwright (Phase 1 dep), Meta Graph API (Phase 0 token).

**Spec:** `docs/superpowers/specs/2026-05-21-ig-card-phase3-publisher-design.md`

---

## File Map

**Create:**
- `backend/src/lorescape_backend/social/card/mapper.py` — `build_card_content(daily_story_row, place_row) -> CardContent | None`
- `backend/src/lorescape_backend/social/card_storage.py` — `upload_card_png(supabase, png_bytes, *, path) -> str`
- `backend/tests/test_card_mapper.py`
- `backend/tests/test_card_storage.py`
- `docs/operations/2026-05-21-ig-cards-bucket-setup.md`

**Modify:**
- `backend/src/lorescape_backend/social/publisher.py` — rewire `_try_publish`, add `_load_zh_tw_row` / `_load_place_row` helpers, drop the `image_url`-based IG gating
- `backend/tests/test_publisher.py` — extend the supabase mock to handle multiple tables; rewrite tests covering card-content branches

---

## Commands

Run all backend commands from `/Users/paulwu/Documents/PLRepo/instant_explore/backend`:

```bash
uv run pytest path/to/test.py::test_name -v
uv run pytest tests/test_card_mapper.py -v
uv run pytest -q
```

---

## Task 1: `build_card_content` mapper

**Files:**
- Create: `backend/src/lorescape_backend/social/card/mapper.py`
- Create: `backend/tests/test_card_mapper.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/test_card_mapper.py`:

```python
"""Tests for build_card_content: zh-TW row + place row → CardContent | None."""
from __future__ import annotations

from lorescape_backend.social.card.content import CardContent
from lorescape_backend.social.card.mapper import build_card_content


def _zh_tw_row(**overrides) -> dict:
    base = {
        "id": "row-zh-1",
        "publish_date": "2026-05-21",
        "language": "zh-TW",
        "place_id": "place-1",
        "place_name": "艾菲爾鐵塔",
        "place_location": "巴黎",
        "era": "十九世紀末",
        "story": "第一段\n\n第二段\n\n第三段",
        "image_url": "https://upload.wikimedia.org/x.jpg",
        "wikipedia_url": "https://zh.wikipedia.org/wiki/...",
        "threads_summary": "短摘",
        "hashtags": ["paris", "eiffelTower"],
        "card_title_ch": "討厭鐵塔的文學大師",
        "card_title_sub_ch": "莫泊桑的「專屬午餐位」",
        "card_paragraphs_ch": ["第一段", "第二段", "第三段"],
        "card_pull_quote_ch": "「看不見鐵塔的地方。」",
        "card_pull_quote_attrib_ch": "—— 莫泊桑,一八八九",
        "card_anno_roman": "MDCCCLXXXIX",
    }
    base.update(overrides)
    return base


def _place_row(**overrides) -> dict:
    base = {
        "id": "place-1",
        "name": "Eiffel Tower",
        "wikipedia_title_en": "Eiffel Tower",
        "country": "France",
        "card_location_en": "TOUR EIFFEL · PARIS",
        "card_city_ch": "巴",
        "card_city_en": "PARIS",
        "latitude": 48.8584,
        "longitude": 2.2945,
    }
    base.update(overrides)
    return base


def test_build_card_content_happy_path():
    result = build_card_content(_zh_tw_row(), _place_row())
    assert result == CardContent(
        title_ch="討厭鐵塔的文學大師",
        title_ch_sub="莫泊桑的「專屬午餐位」",
        location_ch="艾菲爾鐵塔．巴黎",
        location_en="TOUR EIFFEL · PARIS",
        location_coord="48.8584°N · 2.2945°E",
        anno_roman="MDCCCLXXXIX",
        city_ch="巴",
        city_en="PARIS",
        paragraphs_ch=("第一段", "第二段", "第三段"),
        pull_quote_ch="「看不見鐵塔的地方。」",
        pull_quote_attrib_ch="—— 莫泊桑,一八八九",
        photo_url="https://upload.wikimedia.org/x.jpg",
    )


def test_build_card_content_paragraphs_list_becomes_tuple():
    result = build_card_content(_zh_tw_row(), _place_row())
    assert isinstance(result.paragraphs_ch, tuple)


def test_build_card_content_southern_western_hemisphere_coord():
    place = _place_row(latitude=-33.8688, longitude=-70.6483)  # Santiago
    result = build_card_content(_zh_tw_row(), place)
    assert result.location_coord == "33.8688°S · 70.6483°W"


def test_build_card_content_equator_and_prime_meridian_are_valid():
    place = _place_row(latitude=0.0, longitude=0.0)
    result = build_card_content(_zh_tw_row(), place)
    # 0 is treated as the northern / eastern side by convention.
    assert result.location_coord == "0.0000°N · 0.0000°E"


def test_build_card_content_returns_none_if_any_zh_tw_card_field_missing():
    for field in (
        "card_title_ch",
        "card_title_sub_ch",
        "card_paragraphs_ch",
        "card_pull_quote_ch",
        "card_pull_quote_attrib_ch",
        "card_anno_roman",
    ):
        row = _zh_tw_row(**{field: None})
        assert build_card_content(row, _place_row()) is None, (
            f"expected None when {field} is None"
        )


def test_build_card_content_returns_none_if_zh_tw_card_paragraphs_empty():
    row = _zh_tw_row(card_paragraphs_ch=[])
    assert build_card_content(row, _place_row()) is None


def test_build_card_content_returns_none_if_any_place_field_missing():
    for field in ("card_location_en", "card_city_ch", "card_city_en"):
        place = _place_row(**{field: None})
        assert build_card_content(_zh_tw_row(), place) is None, (
            f"expected None when place.{field} is None"
        )


def test_build_card_content_returns_none_if_latitude_or_longitude_missing():
    assert build_card_content(_zh_tw_row(), _place_row(latitude=None)) is None
    assert build_card_content(_zh_tw_row(), _place_row(longitude=None)) is None


def test_build_card_content_returns_none_if_image_url_missing():
    row = _zh_tw_row(image_url=None)
    assert build_card_content(row, _place_row()) is None


def test_build_card_content_returns_none_if_place_name_or_location_missing():
    assert build_card_content(_zh_tw_row(place_name=None), _place_row()) is None
    assert build_card_content(_zh_tw_row(place_location=None), _place_row()) is None
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_card_mapper.py -v
```

Expected: `ImportError: cannot import name 'build_card_content'`.

- [ ] **Step 3: Create the mapper module**

Write `backend/src/lorescape_backend/social/card/mapper.py`:

```python
"""Compose CardContent from a joined daily_stories + daily_story_places pair.

Returns None if any field required to render an E0c card is missing. This
lets the publisher gracefully skip IG while still publishing Threads.
"""
from __future__ import annotations

from typing import Any

from .content import CardContent


def build_card_content(
    daily_story_row: dict[str, Any], place_row: dict[str, Any]
) -> CardContent | None:
    """Return a CardContent if every required field is present, else None.

    `daily_story_row` is expected to be a zh-TW row (the only language that
    carries `card_*` fields). `place_row` is the matching
    `daily_story_places` row joined on `place_id`.
    """
    place_name = daily_story_row.get("place_name")
    place_location = daily_story_row.get("place_location")
    photo_url = daily_story_row.get("image_url")

    title_ch = daily_story_row.get("card_title_ch")
    title_ch_sub = daily_story_row.get("card_title_sub_ch")
    paragraphs = daily_story_row.get("card_paragraphs_ch")
    pull_quote_ch = daily_story_row.get("card_pull_quote_ch")
    pull_quote_attrib_ch = daily_story_row.get("card_pull_quote_attrib_ch")
    anno_roman = daily_story_row.get("card_anno_roman")

    location_en = place_row.get("card_location_en")
    city_ch = place_row.get("card_city_ch")
    city_en = place_row.get("card_city_en")
    latitude = place_row.get("latitude")
    longitude = place_row.get("longitude")

    # Truthy check rejects None and empty strings/lists. Latitude/longitude
    # are checked separately with `is None` so 0.0 (equator / prime meridian)
    # stays valid.
    string_required = (
        place_name, place_location, photo_url,
        title_ch, title_ch_sub, pull_quote_ch,
        pull_quote_attrib_ch, anno_roman,
        location_en, city_ch, city_en,
    )
    if not all(string_required):
        return None
    if not paragraphs:
        return None
    if latitude is None or longitude is None:
        return None

    return CardContent(
        title_ch=title_ch,
        title_ch_sub=title_ch_sub,
        location_ch=f"{place_name}．{place_location}",
        location_en=location_en,
        location_coord=_format_coord(float(latitude), float(longitude)),
        anno_roman=anno_roman,
        city_ch=city_ch,
        city_en=city_en,
        paragraphs_ch=tuple(paragraphs),
        pull_quote_ch=pull_quote_ch,
        pull_quote_attrib_ch=pull_quote_attrib_ch,
        photo_url=photo_url,
    )


def _format_coord(latitude: float, longitude: float) -> str:
    lat_dir = "N" if latitude >= 0 else "S"
    lng_dir = "E" if longitude >= 0 else "W"
    return f"{abs(latitude):.4f}°{lat_dir} · {abs(longitude):.4f}°{lng_dir}"
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd backend && uv run pytest tests/test_card_mapper.py -v
```

Expected: all 11 tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/social/card/mapper.py \
        backend/tests/test_card_mapper.py
git commit -m "feat(card): add build_card_content mapper from zh-TW + place rows"
```

---

## Task 2: `upload_card_png` storage uploader

**Files:**
- Create: `backend/src/lorescape_backend/social/card_storage.py`
- Create: `backend/tests/test_card_storage.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/test_card_storage.py`:

```python
"""Tests for upload_card_png: PNG bytes → public Supabase Storage URL."""
from __future__ import annotations

from unittest.mock import MagicMock

from lorescape_backend.social.card_storage import upload_card_png


def _supabase_with_storage(public_url: str = "https://example.supabase.co/storage/v1/object/public/ig-cards/2026-05-21/row-1.png"):
    bucket = MagicMock()
    bucket.upload.return_value = MagicMock()
    bucket.get_public_url.return_value = public_url

    storage = MagicMock()
    storage.from_.return_value = bucket

    client = MagicMock()
    client.storage = storage
    return client, storage, bucket


def test_upload_card_png_calls_storage_with_expected_args():
    client, storage, bucket = _supabase_with_storage()
    png_bytes = b"\x89PNG\r\n\x1a\nfake"
    path = "2026-05-21/row-1.png"

    url = upload_card_png(client, png_bytes, path=path)

    storage.from_.assert_called_once_with("ig-cards")
    bucket.upload.assert_called_once()
    upload_kwargs = bucket.upload.call_args.kwargs
    assert upload_kwargs["path"] == path
    assert upload_kwargs["file"] == png_bytes
    file_options = upload_kwargs["file_options"]
    assert file_options["content-type"] == "image/png"
    assert file_options["upsert"] == "true"
    bucket.get_public_url.assert_called_once_with(path)
    assert url == "https://example.supabase.co/storage/v1/object/public/ig-cards/2026-05-21/row-1.png"


def test_upload_card_png_returns_public_url_unchanged():
    client, _, _ = _supabase_with_storage(
        public_url="https://abc.supabase.co/storage/v1/object/public/ig-cards/x.png?token=ignored"
    )

    url = upload_card_png(client, b"x", path="x.png")

    assert url == "https://abc.supabase.co/storage/v1/object/public/ig-cards/x.png?token=ignored"
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_card_storage.py -v
```

Expected: `ImportError: cannot import name 'upload_card_png'`.

- [ ] **Step 3: Create the uploader**

Write `backend/src/lorescape_backend/social/card_storage.py`:

```python
"""Upload rendered IG card PNGs to the public `ig-cards` Supabase bucket.

Bucket must be created out-of-band (see
`docs/operations/2026-05-21-ig-cards-bucket-setup.md`). Uploads use upsert
so re-running the publisher for the same date overwrites the previous PNG
at the same path (and keeps the same public URL).
"""
from __future__ import annotations

BUCKET_NAME = "ig-cards"


def upload_card_png(supabase, png_bytes: bytes, *, path: str) -> str:
    """Upload PNG bytes to `ig-cards/<path>` and return the public URL.

    `path` should be of the form `<publish_date>/<row_id>.png`. The caller
    chooses the path so that the URL is deterministic for a given row.
    """
    bucket = supabase.storage.from_(BUCKET_NAME)
    bucket.upload(
        path=path,
        file=png_bytes,
        file_options={"content-type": "image/png", "upsert": "true"},
    )
    return bucket.get_public_url(path)
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd backend && uv run pytest tests/test_card_storage.py -v
```

Expected: both tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/social/card_storage.py \
        backend/tests/test_card_storage.py
git commit -m "feat(card): add upload_card_png to push PNG to public ig-cards bucket"
```

---

## Task 3: Rewire `publisher.py` to render + upload + IG-publish the card

This is the biggest task. The current `_try_publish` reads only the en row, uses `row["image_url"]` for IG, and builds the IG caption from the en row. After this task: the publisher loads the zh-TW row and the place row, tries to build `CardContent`, and on success renders + uploads + IG-publishes with the **zh-TW** row's text as the IG caption. Threads remains 100% en-driven.

**Files:**
- Modify: `backend/src/lorescape_backend/social/publisher.py`
- Modify: `backend/tests/test_publisher.py`

- [ ] **Step 1: Extend the supabase mock helper in tests/test_publisher.py**

The current helper `_supabase_with_rows` only handles `client.table("daily_stories").select().eq()...execute()`. The new publisher also calls `.table("daily_story_places").select().eq()...execute()`. Replace the helper at the top of `tests/test_publisher.py` (after the imports, before the first test) with:

```python
def _row(**overrides):
    base = dict(
        id="row-1",
        publish_date="2026-05-12",
        language="en",
        place_id="place-1",
        place_name="Colosseum",
        place_location="Rome",
        era="70-80 CE",
        story="story body",
        threads_summary="short",
        hashtags=["rome"],
        image_url="https://upload.wikimedia.org/x.jpg",
        wikipedia_url="https://en.wikipedia.org/wiki/Colosseum",
        review_state="pending",
        discord_message_id="msg-1",
    )
    base.update(overrides)
    return base


def _zh_row(**overrides):
    base = dict(
        id="row-zh-1",
        publish_date="2026-05-12",
        language="zh-TW",
        place_id="place-1",
        place_name="羅馬競技場",
        place_location="羅馬",
        era="公元 70-80 年",
        story="第一段\n\n第二段\n\n第三段",
        image_url="https://upload.wikimedia.org/x.jpg",
        wikipedia_url="https://zh.wikipedia.org/wiki/...",
        threads_summary="中文短摘",
        hashtags=["rome", "colosseum"],
        card_title_ch="石頭裡的吶喊",
        card_title_sub_ch="鬥獸場百年",
        card_paragraphs_ch=["第一段", "第二段", "第三段"],
        card_pull_quote_ch="「我們將娛樂血腥化為藝術。」",
        card_pull_quote_attrib_ch="—— 塔西陀",
        card_anno_roman="LXXX",
    )
    base.update(overrides)
    return base


def _place_row(**overrides):
    base = dict(
        id="place-1",
        name="Colosseum",
        wikipedia_title_en="Colosseum",
        country="Italy",
        card_location_en="COLOSSEUM · ROME",
        card_city_ch="羅",
        card_city_en="ROME",
        latitude=41.8902,
        longitude=12.4922,
    )
    base.update(overrides)
    return base


def _supabase_multi_table(
    *, en_rows, zh_row=None, place_row=None
):
    """Build a supabase mock that dispatches by table name.

    `client.table("daily_stories")` first responds to a select-pending-en query
    (returns en_rows). Subsequent select calls on daily_stories (the zh-TW
    lookup) return zh_row wrapped in a list if non-None.
    `client.table("daily_story_places")` returns place_row wrapped in a list.
    `client.table(...).update(...)` always returns a passing chain.
    """
    update_chain = MagicMock()
    update_chain.eq.return_value = update_chain
    update_chain.execute.return_value = MagicMock(data=None)

    def _make_select_chain(rows):
        chain = MagicMock()
        chain.eq.return_value = chain
        chain.limit.return_value = chain
        chain.execute.return_value = MagicMock(data=rows)
        return chain

    daily_stories_table = MagicMock()
    # The first .select() call serves the pending-en query; subsequent calls
    # serve the zh-TW lookup. Returning chains that resolve the same data
    # works because the publisher only calls .execute() at the end.
    daily_stories_calls = [
        _make_select_chain(en_rows),
        _make_select_chain([zh_row] if zh_row else []),
    ]
    daily_stories_table.select.side_effect = daily_stories_calls
    daily_stories_table.update.return_value = update_chain

    places_table = MagicMock()
    places_table.select.return_value = _make_select_chain(
        [place_row] if place_row else []
    )

    client = MagicMock()

    def _table(name):
        if name == "daily_stories":
            return daily_stories_table
        if name == "daily_story_places":
            return places_table
        raise AssertionError(f"unexpected table: {name}")

    client.table.side_effect = _table
    return client, daily_stories_table, places_table, update_chain
```

- [ ] **Step 2: Rewrite the existing test `test_approved_row_publishes_to_threads_and_ig`**

Replace its body so it uses the new mock helper and asserts on the new flow:

```python
@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_publishes_to_threads_and_ig(
    upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    zh = _zh_row()
    place = _place_row()
    client, ds_table, places_table, update_chain = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"
    render.return_value = b"\x89PNGfake"
    upload.return_value = "https://x.supabase.co/storage/v1/object/public/ig-cards/2026-05-12/row-zh-1.png"
    ig_pub.return_value = "ig-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    # Threads called with the en row's content
    th_pub.assert_called_once()
    # render_card called once with a CardContent derived from zh + place
    render.assert_called_once()
    # upload called with path = <date>/<zh_row_id>.png
    upload.assert_called_once()
    assert upload.call_args.kwargs["path"] == "2026-05-12/row-zh-1.png"
    # IG called with the storage URL (not the wikipedia image)
    ig_pub.assert_called_once()
    ig_kwargs = ig_pub.call_args.kwargs
    assert ig_kwargs["image_url"] == upload.return_value
    # Caption is the zh-TW caption — contains the zh-TW place_name
    assert "羅馬競技場" in ig_kwargs["caption"]

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["threads_post_id"] == "th-1"
    assert payload["ig_post_id"] == "ig-1"
    # Healthy publish: no publish_error set
    assert payload.get("publish_error") in (None, "")
```

- [ ] **Step 3: Rewrite `test_approved_row_without_image_skips_ig` for the new card-content gating**

The previous test gated IG on `image_url`. The new gating is "card content can be built". Replace its body with a missing-zh-row case:

```python
@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_skips_ig_when_zh_row_missing(
    upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=None, place_row=_place_row(),
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_called_once()
    render.assert_not_called()
    upload.assert_not_called()
    ig_pub.assert_not_called()

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["threads_post_id"] == "th-1"
    assert payload["ig_post_id"] is None
    assert payload["publish_error"] == "ig_skipped_missing_card_content"
```

- [ ] **Step 4: Add new tests covering more skip paths**

Append to `tests/test_publisher.py`:

```python
@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_skips_ig_when_place_row_missing(
    upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    zh = _zh_row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=None,
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_called_once()
    ig_pub.assert_not_called()
    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["publish_error"] == "ig_skipped_missing_card_content"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_skips_ig_when_card_fields_null(
    upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    zh = _zh_row(card_title_ch=None)  # one missing card field → mapper returns None
    place = _place_row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    ig_pub.assert_not_called()
    render.assert_not_called()
    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["publish_error"] == "ig_skipped_missing_card_content"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_ig_render_failure_marks_failed_and_notifies(
    notify, upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    zh = _zh_row()
    place = _place_row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"
    render.side_effect = RuntimeError("chromium crashed")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    assert "chromium crashed" in payload["publish_error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_ig_upload_failure_marks_failed_and_notifies(
    notify, upload, render, ig_pub, th_pub, check, create, fake_config
):
    en = _row()
    zh = _zh_row()
    place = _place_row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"
    render.return_value = b"\x89PNGfake"
    upload.side_effect = RuntimeError("supabase storage down")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    assert "supabase storage down" in payload["publish_error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
@patch("lorescape_backend.social.publisher.render_card")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_threads_disabled_still_publishes_ig(
    upload, render, ig_pub, th_pub, check, create
):
    """If Threads is disabled but IG + card content are good, only IG runs."""
    from lorescape_backend.config import Config

    config = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url="https://hook",
        discord_bot_token="b",
        discord_review_channel_id="111",
        discord_approver_ids=("222",),
        threads_user_id=None, threads_access_token=None,  # Threads disabled
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_threads="", brand_handle_ig="@brand", cta_text="cta",
    )
    en = _row()
    zh = _zh_row()
    place = _place_row()
    client, ds_table, _, _ = _supabase_multi_table(
        en_rows=[en], zh_row=zh, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    render.return_value = b"\x89PNGfake"
    upload.return_value = "https://x.supabase.co/storage/v1/object/public/ig-cards/2026-05-12/row-zh-1.png"
    ig_pub.return_value = "ig-1"

    run_publish_job(config, date(2026, 5, 12))

    th_pub.assert_not_called()
    ig_pub.assert_called_once()
    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["threads_post_id"] is None
    assert payload["ig_post_id"] == "ig-1"
```

- [ ] **Step 5: Update remaining existing publisher tests to use the new mock helper**

The tests `test_rejected_row_does_not_publish`, `test_no_reaction_skips_row`, `test_publish_exception_marks_failed_and_notifies`, `test_no_pending_rows_does_nothing`, `test_review_disabled_marks_pending_as_skipped` all use the old `_supabase_with_rows` helper. Update each to use `_supabase_multi_table` instead, passing only `en_rows=[...]` (zh_row + place_row can stay as default `None` since these tests don't reach the IG branch).

For each of those 5 tests, change:

```python
client, table, _ = _supabase_with_rows(rows)
```

to:

```python
client, table, _, _ = _supabase_multi_table(en_rows=rows)
```

(The 4-tuple unpack reflects the new helper's return shape — `client, daily_stories_table, places_table, update_chain`.)

Then delete the old `_supabase_with_rows` helper function. `_row` stays.

- [ ] **Step 6: Run publisher tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_publisher.py -v
```

Expected: tests fail with `ImportError: cannot import name 'render_card'` (from publisher) and/or `AttributeError: module ... has no attribute 'card_storage'` because publisher hasn't been rewired yet.

- [ ] **Step 7: Rewire `publisher.py`**

Open `backend/src/lorescape_backend/social/publisher.py`. Add imports at the top:

```python
from lorescape_backend.social import card_storage, caption, instagram, threads
from lorescape_backend.social.card import mapper
from lorescape_backend.social.card.renderer import render_card
```

(The existing `from lorescape_backend.social import caption, instagram, threads` line is replaced by the expanded one above.)

Replace the `_try_publish` function entirely with:

```python
def _try_publish(supabase, config: Config, row: dict[str, Any]) -> None:
    en_story_copy = caption.StoryCopy(
        place_name=row["place_name"],
        era=row["era"],
        story=row["story"],
        threads_summary=row["threads_summary"] or "",
        hashtags=tuple(row.get("hashtags") or ()),
    )
    threads_text = caption.build_threads_caption(
        story=en_story_copy,
        brand_handle=config.brand_handle_threads,
        cta_text=config.cta_text,
    )

    zh_row = _load_zh_tw_row(supabase, row["publish_date"])
    place_row = _load_place_row(supabase, row["place_id"])
    card_content = None
    if zh_row is not None and place_row is not None:
        card_content = mapper.build_card_content(zh_row, place_row)

    ig_caption = None
    if card_content is not None:
        zh_story_copy = caption.StoryCopy(
            place_name=zh_row["place_name"],
            era=zh_row["era"],
            story=zh_row["story"],
            threads_summary=zh_row["threads_summary"] or "",
            hashtags=tuple(zh_row.get("hashtags") or ()),
        )
        ig_caption = caption.build_full_caption(
            story=zh_story_copy,
            brand_handle=config.brand_handle_ig,
            cta_text=config.cta_text,
        )

    threads_post_id: str | None = None
    ig_post_id: str | None = None
    publish_error: str | None = None
    try:
        if config.threads_enabled:
            threads_post_id = threads.publish(
                user_id=config.threads_user_id,  # type: ignore[arg-type]
                access_token=config.threads_access_token,  # type: ignore[arg-type]
                text=threads_text,
                image_url=row.get("image_url"),
            )
        else:
            logger.info("Threads not configured; skipping Threads publish")

        if config.instagram_enabled and card_content is not None:
            png = render_card(card_content)
            path = f"{row['publish_date']}/{zh_row['id']}.png"
            card_url = card_storage.upload_card_png(supabase, png, path=path)
            ig_post_id = instagram.publish(
                ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
                access_token=config.meta_page_access_token,  # type: ignore[arg-type]
                image_url=card_url,
                caption=ig_caption,  # type: ignore[arg-type]
            )
        elif card_content is None:
            logger.info(
                "Row %s missing card content; skipping IG publish", row["id"]
            )
            publish_error = "ig_skipped_missing_card_content"
        else:
            logger.info("Instagram not configured; skipping IG publish")

    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Publish failed for row %s", row["id"])
        _update_state(
            supabase,
            row,
            "failed",
            extra={
                "publish_error": _truncate(str(exc), 1000),
                "threads_post_id": threads_post_id,
                "ig_post_id": ig_post_id,
            },
        )
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=row["publish_date"],
                error_message=f"Publish failed: {exc}",
                traceback_str="",
            )
        return

    _update_state(
        supabase,
        row,
        "published",
        extra={
            "threads_post_id": threads_post_id,
            "ig_post_id": ig_post_id,
            "publish_error": publish_error,
        },
    )
```

Add two new helper functions next to `_load_pending_rows`:

```python
def _load_zh_tw_row(supabase, publish_date: str) -> dict[str, Any] | None:
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", publish_date)
        .eq("language", "zh-TW")
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


def _load_place_row(supabase, place_id: str) -> dict[str, Any] | None:
    response = (
        supabase.table("daily_story_places")
        .select("*")
        .eq("id", place_id)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None
```

The `_load_pending_rows` function and the rest of the module stay as they are.

- [ ] **Step 8: Run publisher tests to confirm they pass**

```bash
cd backend && uv run pytest tests/test_publisher.py -v
```

Expected: all tests pass (the 7-ish existing tests rewired through the new helper plus the 4 new ones).

- [ ] **Step 9: Run full backend suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green. No regressions in Phase 1/2 tests.

- [ ] **Step 10: Commit**

```bash
git add backend/src/lorescape_backend/social/publisher.py \
        backend/tests/test_publisher.py
git commit -m "feat(publisher): render and upload IG card; publish with zh-TW caption"
```

---

## Task 4: Bucket setup operations doc

**Files:**
- Create: `docs/operations/2026-05-21-ig-cards-bucket-setup.md`

- [ ] **Step 1: Write the operations doc**

Create `docs/operations/2026-05-21-ig-cards-bucket-setup.md` with the following content (outer fence below is 4 backticks so inner SQL/code fences stay 3-backtick):

````markdown
# Create the `ig-cards` Supabase Storage bucket (Phase 3)

The Phase 3 publisher uploads each rendered IG card PNG to a public Supabase
Storage bucket named `ig-cards`. Meta's Graph API fetches that public URL
when publishing the IG post, so the bucket must be readable anonymously.

This step is **one-time per environment** (local dev + prod). Re-run only
if the bucket is deleted.

## 1. Create the bucket in Supabase Dashboard

1. Open https://supabase.com/dashboard and pick the project.
2. In the left nav choose **Storage**.
3. Click **New bucket**.
4. Fill in:
   - **Name**: `ig-cards`
   - **Public bucket**: ✅ **enabled** (Meta servers fetch anonymously)
   - **File size limit**: `5 MB`
   - **Allowed MIME types**: `image/png`
5. Click **Create bucket**.

## 2. Verify the bucket is public

1. Click into the new `ig-cards` bucket.
2. Open the **Configuration** tab and confirm `Public` is on.
3. Upload any small placeholder PNG via the dashboard, click it, choose
   **Get URL**, and open the URL in an incognito browser. It must load
   without authentication. Delete the placeholder afterwards.

## 3. (Optional) Restrict writes to the service role

By default, Supabase Storage buckets allow inserts by service_role only,
so no policy changes are strictly required. If you want to make this
explicit, add a policy under **Policies → ig-cards**:

```sql
create policy "service_role can manage ig-cards"
on storage.objects for all
to service_role
using (bucket_id = 'ig-cards')
with check (bucket_id = 'ig-cards');
```

## 4. Smoke-test from the backend

After Phase 3 deploys, the first 21:00 publisher run for a row whose
zh-TW + place fields are populated will create
`ig-cards/<publish_date>/<zh_row_id>.png`. Confirm via:

```bash
supabase db psql -c "select id, ig_post_id, publish_error \
  from public.daily_stories \
  where publish_date = '<YYYY-MM-DD>' and language = 'en' and review_state = 'published';"
```

A successful card publish has `ig_post_id` set and `publish_error` null.
A row where the publisher gracefully skipped IG (Phase 2 backfill
incomplete) has `ig_post_id` null and
`publish_error = 'ig_skipped_missing_card_content'`.
````

- [ ] **Step 2: Commit**

```bash
git add docs/operations/2026-05-21-ig-cards-bucket-setup.md
git commit -m "docs(ops): bucket setup guide for ig-cards public Supabase Storage"
```

---

## Final Verification

- [ ] **Step 1: Full backend test suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green. No skips, no warnings.

- [ ] **Step 2: Push branch and open PR**

```bash
git push -u origin feature/ig-card-phase3-publisher
gh pr create --title "feat(card): Phase 3 — render IG card and publish with zh-TW caption" \
  --body "$(cat <<'EOF'
## Summary
- New `social/card/mapper.py` composes `CardContent` from a zh-TW `daily_stories` row joined with its `daily_story_places` row. Returns `None` if any required field is NULL (so the publisher can gracefully skip IG).
- New `social/card_storage.py` uploads PNG bytes to the public `ig-cards` Supabase Storage bucket and returns the URL Meta servers fetch.
- `social/publisher.py` rewired: IG image is now the rendered card PNG, IG caption is built from the zh-TW row, Threads continues using the en row unchanged. Rows whose card content cannot be assembled get `publish_error = 'ig_skipped_missing_card_content'` and only Threads runs.
- One-time bucket creation guide at `docs/operations/2026-05-21-ig-cards-bucket-setup.md`.

Spec: `docs/superpowers/specs/2026-05-21-ig-card-phase3-publisher-design.md`

## Test plan
- [ ] `uv run pytest -q` passes
- [ ] After creating the `ig-cards` bucket per the ops doc, run `python -m lorescape_backend.social.publisher <date>` against a real row with backfilled card fields; confirm the PNG lands in the bucket and IG post URL appears in `daily_stories.ig_post_id`
- [ ] Force the missing-card path by clearing one `card_*` field, re-run publisher; confirm `ig_skipped_missing_card_content` is recorded and Threads still posts
EOF
)"
```

---

## Self-Review Notes

- **Spec coverage:**
  - Mapper § "Mapping 規則" + NULL-check + `_format_coord` → Task 1.
  - Storage uploader § + bucket setup doc → Tasks 2 & 4.
  - Publisher rewire § (load zh-TW + place row, build CardContent, render, upload, IG-publish with zh-TW caption, error state machine) → Task 3.
  - State matrix in spec → Tasks 3 tests cover each row (Threads-only, IG-only, both, missing card content, render fail, upload fail).
- **Type consistency:** `CardContent` field names match Phase 1's frozen dataclass exactly (`title_ch`, `title_ch_sub`, `location_ch`, `location_en`, `location_coord`, `anno_roman`, `city_ch`, `city_en`, `paragraphs_ch`, `pull_quote_ch`, `pull_quote_attrib_ch`, `photo_url`). The new functions: `build_card_content(daily_story_row, place_row) -> CardContent | None` and `upload_card_png(supabase, png_bytes, *, path) -> str` — both signatures referenced verbatim from Task 3's wiring.
- **No placeholders:** Every code step shows the full code. The bucket setup doc is the only place with optional guidance (policy step marked Optional).
