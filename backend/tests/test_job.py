from datetime import date
from unittest.mock import MagicMock, call, patch

import pytest

from lorescape_backend.daily_story.job import LANGUAGES, run_once, run_with_retry
from lorescape_backend.daily_story.gemini_client import GeneratedStory
from lorescape_backend.daily_story.place_picker import PickedPlace
from lorescape_backend.daily_story.wikipedia import WikipediaSummary


def _make_story(
    *,
    place_name: str = "X",
    place_location: str = "Y",
    era: str = "Z",
    threads_summary: str = "t",
    hashtags: tuple[str, ...] = (),
    paragraphs: tuple[str, ...] = ("long1", "long2", "long3"),
    card_title: str = "title",
    card_title_sub: str = "subtitle",
    card_paragraphs: tuple[str, ...] = ("p1", "p2", "p3"),
    card_pull_quote: str = "quote",
    card_pull_quote_attrib: str = "attrib",
    card_anno_roman: str = "MMXXVI",
) -> GeneratedStory:
    """Build a GeneratedStory with sensible defaults for tests."""
    return GeneratedStory(
        place_name=place_name,
        place_location=place_location,
        era=era,
        threads_summary=threads_summary,
        hashtags=hashtags,
        paragraphs=paragraphs,
        card_title=card_title,
        card_title_sub=card_title_sub,
        card_paragraphs=card_paragraphs,
        card_pull_quote=card_pull_quote,
        card_pull_quote_attrib=card_pull_quote_attrib,
        card_anno_roman=card_anno_roman,
    )


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_happy_path_calls_each_step(
    mark_used,
    insert_story,
    generate_story,
    fetch_langlink,
    fetch_summary,
    pick_next,
    create_client,
    fake_config,
):
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum",
        extract="Built 70-80 CE.",
        image_url="https://upload.wikimedia.org/x.jpg",
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    fetch_langlink.side_effect = lambda title, lang: (
        f"https://{lang}.wikipedia.org/wiki/{title}"
    )
    generate_story.side_effect = [
        _make_story(
            place_name="羅馬競技場",
            place_location="義大利羅馬",
            era="公元 70-80 年",
            threads_summary="中短",
            hashtags=("colosseum",),
        ),
        _make_story(
            place_name="Colosseum",
            place_location="Rome, Italy",
            era="70-80 CE",
            threads_summary="en short",
            hashtags=("rome", "colosseum"),
        ),
    ]

    run_once(fake_config, date(2026, 5, 11))

    pick_next.assert_called_once()
    fetch_summary.assert_called_once_with("Colosseum")
    # Two languages: should fetch langlinks and Gemini twice each
    assert fetch_langlink.call_count == 2
    assert generate_story.call_count == 2
    assert insert_story.call_count == 2
    # Place gets marked used exactly once
    mark_used.assert_called_once()
    args, _ = mark_used.call_args
    assert args[1] == "p1"


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
def test_run_once_raises_when_no_place(pick_next, create_client, fake_config):
    pick_next.return_value = None
    with pytest.raises(RuntimeError, match="No active places"):
        run_once(fake_config, date(2026, 5, 11))


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_falls_back_to_en_url_when_no_langlink(
    mark_used,
    insert_story,
    generate_story,
    fetch_langlink,
    fetch_summary,
    pick_next,
    create_client,
    fake_config,
):
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum",
        extract="Built 70-80 CE.",
        image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    # Simulate: zh has no langlink, en is just the same article
    fetch_langlink.return_value = None
    generate_story.return_value = _make_story()

    run_once(fake_config, date(2026, 5, 11))

    # Each insert_story call should have wikipedia_url == en_url (fallback)
    for c in insert_story.call_args_list:
        row = c.args[1]
        assert row.wikipedia_url == "https://en.wikipedia.org/wiki/Colosseum"


@patch("lorescape_backend.daily_story.job.time.sleep")  # speed up retry
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_succeeds_first_attempt(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.return_value = None
    run_with_retry(fake_config, date(2026, 5, 11))
    assert run_once_mock.call_count == 1
    notify.assert_not_called()


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_retries_on_failure_then_succeeds(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.side_effect = [RuntimeError("fail1"), None]
    run_with_retry(fake_config, date(2026, 5, 11))
    assert run_once_mock.call_count == 2
    notify.assert_not_called()


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_notifies_discord_after_all_retries_fail(
    notify, run_once_mock, sleep, fake_config
):
    run_once_mock.side_effect = RuntimeError("boom")
    with pytest.raises(RuntimeError, match="boom"):
        run_with_retry(fake_config, date(2026, 5, 11))

    # Default: 4 attempts (1 + 3 retries)
    assert run_once_mock.call_count == 4
    notify.assert_called_once()
    kwargs = notify.call_args.kwargs
    assert kwargs["webhook_url"] == fake_config.discord_webhook_url
    assert kwargs["date_str"] == "2026-05-11"
    assert "boom" in kwargs["error_message"]


@patch("lorescape_backend.daily_story.job.time.sleep")
@patch("lorescape_backend.daily_story.job.run_once")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_run_with_retry_skips_discord_when_no_webhook_configured(
    notify, run_once_mock, sleep
):
    from lorescape_backend.config import Config

    config_no_webhook = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url=None,
        discord_bot_token=None,
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id=None, threads_access_token=None,
        ig_user_id=None, meta_page_access_token=None,
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )
    run_once_mock.side_effect = RuntimeError("boom")
    with pytest.raises(RuntimeError):
        run_with_retry(config_no_webhook, date(2026, 5, 11))
    notify.assert_not_called()


def test_languages_list_matches_spec():
    assert LANGUAGES == ["zh-TW", "en"]


# ---------------------------------------------------------------------------
# send_today_for_review / run_generate_and_review
# ---------------------------------------------------------------------------


def _zh_row():
    return {
        "id": "row-zh",
        "place_id": "place-1",
        "place_name": "羅馬競技場",
        "place_location": "義大利羅馬",
        "era": "公元 70-80 年",
        "story": "第一段\n\n第二段\n\n第三段",
        "threads_summary": "中文短摘。",
        "hashtags": ["rome", "colosseum"],
        "image_url": "https://upload.wikimedia.org/x.jpg",
        "wikipedia_url": "https://zh.wikipedia.org/wiki/羅馬競技場",
        "discord_message_id": None,
        "card_title": "石頭裡的吶喊",
        "card_title_sub": "鬥獸場百年",
        "card_paragraphs": ["第一段", "第二段", "第三段"],
        "card_pull_quote": "「我們將娛樂血腥化為藝術。」",
        "card_pull_quote_attrib": "—— 塔西陀",
        "card_anno_roman": "LXXX",
    }


def _place_row():
    return {
        "id": "place-1",
        "name": "Colosseum",
        "wikipedia_title_en": "Colosseum",
        "country": "Italy",
        "card_location_en": "COLOSSEUM · ROME",
        "card_city_ch": "羅",
        "card_city_en": "ROME",
        "latitude": 41.8902,
        "longitude": 12.4922,
    }


def _supabase_with_select_and_update(row, place_row=None):
    """Mock supabase client supporting daily_stories + daily_story_places.

    `row` is the zh-TW review row (None to simulate missing). `place_row`
    is the joined daily_story_places row (None to simulate missing). The
    `daily_stories` table responds with `row` for the first .select() call
    (review-row lookup); the `daily_story_places` table responds with
    `place_row` for its lookup. .update() on daily_stories always passes.
    """
    def _select_chain(data):
        chain = MagicMock()
        chain.eq.return_value = chain
        chain.limit.return_value = chain
        chain.execute.return_value = MagicMock(data=data)
        return chain

    update_chain = MagicMock()
    update_chain.eq.return_value = update_chain
    update_chain.execute.return_value = MagicMock(data=None)

    daily_stories_table = MagicMock()
    daily_stories_table.select.return_value = _select_chain([row] if row else [])
    daily_stories_table.update.return_value = update_chain

    places_table = MagicMock()
    places_table.select.return_value = _select_chain(
        [place_row] if place_row else []
    )

    def _table(name):
        if name == "daily_stories":
            return daily_stories_table
        if name == "daily_story_places":
            return places_table
        raise AssertionError(f"unexpected table: {name}")

    client = MagicMock()
    client.table.side_effect = _table
    return client, daily_stories_table, update_chain


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.render_card")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
def test_send_today_for_review_renders_card_and_posts_image(
    send, render, create, fake_config
):
    from datetime import date as _date
    from lorescape_backend.daily_story.job import send_today_for_review

    row = _zh_row()
    place = _place_row()
    client, table, _ = _supabase_with_select_and_update(row, place_row=place)
    create.return_value = client
    render.return_value = b"\x89PNGfake-card"
    send.return_value = "msg-abc"

    send_today_for_review(fake_config, _date(2026, 5, 12))

    # Card rendered from the joined zh-TW + place rows, not stubbed in test.
    render.assert_called_once()
    rendered_card = render.call_args[0][0]
    assert rendered_card.title_ch == "石頭裡的吶喊"

    # Discord receives the PNG bytes — no story / threads text fields.
    send.assert_called_once()
    payload = send.call_args.kwargs["payload"]
    assert payload.card_png == b"\x89PNGfake-card"
    assert payload.publish_date == "2026-05-12"

    # message id written back to the row
    update_payload = table.update.call_args[0][0]
    assert update_payload == {"discord_message_id": "msg-abc"}


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.render_card")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_send_today_for_review_notifies_when_card_content_missing(
    notify, send, render, create, fake_config
):
    """If card fields are missing, don't render or post — alert via webhook."""
    from datetime import date as _date
    from lorescape_backend.daily_story.job import send_today_for_review

    row = _zh_row()
    row["card_title"] = None  # mapper rejects when any required field is empty
    client, _, _ = _supabase_with_select_and_update(row, place_row=_place_row())
    create.return_value = client

    send_today_for_review(fake_config, _date(2026, 5, 12))

    render.assert_not_called()
    send.assert_not_called()
    notify.assert_called_once()
    assert "card content" in notify.call_args.kwargs["error_message"]


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
def test_send_today_for_review_skipped_if_already_posted(
    send, create, fake_config
):
    from datetime import date as _date
    from lorescape_backend.daily_story.job import send_today_for_review

    row = _zh_row()
    row["discord_message_id"] = "already-there"
    client, _, _ = _supabase_with_select_and_update(row)
    create.return_value = client

    send_today_for_review(fake_config, _date(2026, 5, 12))

    send.assert_not_called()


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_send_today_for_review_notifies_webhook_when_zh_row_missing(
    notify, send, create, fake_config
):
    """If no zh-TW row exists, alert via webhook and don't post to Discord."""
    from datetime import date as _date
    from lorescape_backend.daily_story.job import send_today_for_review

    client, _, _ = _supabase_with_select_and_update(None)
    create.return_value = client

    send_today_for_review(fake_config, _date(2026, 5, 12))

    send.assert_not_called()
    notify.assert_called_once()
    kwargs = notify.call_args.kwargs
    assert kwargs["webhook_url"] == fake_config.discord_webhook_url
    assert kwargs["date_str"] == "2026-05-12"
    assert "zh-TW" in kwargs["error_message"]


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
def test_send_today_for_review_silently_skips_when_zh_row_missing_and_no_webhook(
    notify, send, create
):
    """If the webhook is not configured, the missing row is logged but no alert is sent."""
    from datetime import date as _date
    from lorescape_backend.config import Config
    from lorescape_backend.daily_story.job import send_today_for_review

    config = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g",
        discord_webhook_url=None,  # no webhook
        discord_bot_token="b",
        discord_review_channel_id="111",
        discord_approver_ids=("222",),
        threads_user_id=None, threads_access_token=None,
        ig_user_id=None, meta_page_access_token=None,
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )
    client, _, _ = _supabase_with_select_and_update(None)
    create.return_value = client

    send_today_for_review(config, _date(2026, 5, 12))

    send.assert_not_called()
    notify.assert_not_called()


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.discord_review.send_for_review")
def test_send_today_for_review_no_op_when_review_disabled(
    send, create
):
    from datetime import date as _date
    from lorescape_backend.config import Config
    from lorescape_backend.daily_story.job import send_today_for_review

    disabled = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url=None,
        discord_bot_token=None,
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id=None, threads_access_token=None,
        ig_user_id=None, meta_page_access_token=None,
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )

    send_today_for_review(disabled, _date(2026, 5, 12))

    create.assert_not_called()
    send.assert_not_called()


@patch("lorescape_backend.daily_story.job.run_with_retry")
@patch("lorescape_backend.daily_story.job.send_today_for_review")
def test_run_generate_and_review_calls_both_in_order(
    review, gen, fake_config
):
    from datetime import date as _date
    from lorescape_backend.daily_story.job import run_generate_and_review

    run_generate_and_review(fake_config, _date(2026, 5, 12))

    gen.assert_called_once_with(fake_config, _date(2026, 5, 12))
    review.assert_called_once_with(fake_config, _date(2026, 5, 12))


@patch("lorescape_backend.daily_story.job.discord_notify.notify_failure")
@patch("lorescape_backend.daily_story.job.run_with_retry")
@patch("lorescape_backend.daily_story.job.send_today_for_review")
def test_run_generate_and_review_swallows_review_failure(
    review, gen, notify, fake_config
):
    """Review send failure must not raise — story is already in DB."""
    from datetime import date as _date
    from lorescape_backend.daily_story.job import run_generate_and_review

    review.side_effect = RuntimeError("Discord down")

    # Should not raise.
    run_generate_and_review(fake_config, _date(2026, 5, 12))

    notify.assert_called_once()


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_both_languages_join_paragraphs_and_pass_card_fields(
    mark_used, insert_story, generate_story, fetch_langlink,
    fetch_summary, pick_next, create_client, fake_config,
):
    """Both zh-TW and en now produce card fields; story column is derived
    from joining card_paragraphs with '\n\n'."""
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Eiffel Tower")
    fetch_summary.return_value = WikipediaSummary(
        title="Eiffel Tower",
        extract="Built 1889 by Gustave Eiffel.",
        image_url="https://upload.wikimedia.org/x.jpg",
        en_url="https://en.wikipedia.org/wiki/Eiffel_Tower",
    )
    fetch_langlink.side_effect = lambda title, lang: (
        f"https://{lang}.wikipedia.org/wiki/{title}"
    )
    generate_story.side_effect = [
        # zh-TW: paragraphs + card fields
        _make_story(
            place_name="艾菲爾鐵塔",
            place_location="巴黎",
            era="十九世紀末",
            threads_summary="短摘",
            hashtags=("paris", "eiffelTower"),
            card_title="討厭鐵塔的文學大師",
            card_title_sub="莫泊桑的「專屬午餐位」",
            card_paragraphs=("第一段", "第二段", "第三段"),
            card_pull_quote="「看不見鐵塔的地方。」",
            card_pull_quote_attrib="—— 莫泊桑，一八八九",
            card_anno_roman="MDCCCLXXXIX",
        ),
        # en: also has card fields after unification
        _make_story(
            place_name="Eiffel Tower",
            place_location="Paris",
            era="Late 19th century",
            threads_summary="en short",
            hashtags=("paris",),
            card_title="The Writer Who Hated the Tower",
            card_title_sub="Maupassant's lunchtime ritual",
            card_paragraphs=("p1", "p2", "p3"),
            card_pull_quote="\"The only place I can't see it.\"",
            card_pull_quote_attrib="— Maupassant, 1889",
            card_anno_roman="MDCCCLXXXIX",
        ),
    ]

    run_once(fake_config, date(2026, 5, 21))

    zh_call, en_call = insert_story.call_args_list

    # zh-TW row: story joined from paragraphs, all card fields passed through.
    zh_row = zh_call.args[1]
    assert zh_row.language == "zh-TW"
    assert zh_row.story == "第一段\n\n第二段\n\n第三段"
    assert zh_row.card_title == "討厭鐵塔的文學大師"
    assert zh_row.card_paragraphs == ("第一段", "第二段", "第三段")
    assert zh_row.card_anno_roman == "MDCCCLXXXIX"

    # en row: now also has card fields and story is the joined paragraphs.
    en_row = en_call.args[1]
    assert en_row.language == "en"
    assert en_row.story == "p1\n\np2\n\np3"
    assert en_row.card_title == "The Writer Who Hated the Tower"
    assert en_row.card_paragraphs == ("p1", "p2", "p3")
    assert en_row.card_anno_roman == "MDCCCLXXXIX"


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_passes_per_language_response_schema(
    mark_used, insert_story, generate_story, fetch_langlink,
    fetch_summary, pick_next, create_client, fake_config,
):
    from lorescape_backend.daily_story import prompts

    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum", extract="...", image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    fetch_langlink.return_value = None
    generate_story.return_value = _make_story(card_paragraphs=("a", "b", "c"))

    run_once(fake_config, date(2026, 5, 21))

    # Both languages now share the unified card schema.
    zh_schema = generate_story.call_args_list[0].kwargs["response_schema"]
    en_schema = generate_story.call_args_list[1].kwargs["response_schema"]
    assert zh_schema == prompts.build_response_schema("zh-TW")
    assert en_schema == prompts.build_response_schema("en")
