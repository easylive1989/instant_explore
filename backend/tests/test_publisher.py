"""publisher.run_publish_job state-machine tests."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

from lorescape_backend.social.publisher import run_publish_job


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


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
def test_rejected_row_does_not_publish(
    ig_pub, th_pub, check, create, fake_config
):
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client
    check.return_value = "rejected"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_not_called()
    ig_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "rejected"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
def test_no_reaction_skips_row(th_pub, check, create, fake_config):
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client
    check.return_value = "none"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "skipped"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_publish_exception_marks_failed_and_notifies(
    notify, th_pub, check, create, fake_config
):
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client
    check.return_value = "approved"
    th_pub.side_effect = RuntimeError("API blew up")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    assert "API blew up" in payload["publish_error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
def test_no_pending_rows_does_nothing(create, fake_config):
    rows = []
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client

    run_publish_job(fake_config, date(2026, 5, 12))

    table.update.assert_not_called()


@patch("lorescape_backend.social.publisher.create_client")
def test_review_disabled_leaves_pending_rows_untouched(create):
    from lorescape_backend.config import Config

    config = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url=None,
        discord_bot_token=None,  # review disabled
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id="u", threads_access_token="t",
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client

    run_publish_job(config, date(2026, 5, 12))

    # Rows must stay pending so a later run (after config is fixed) can
    # still process them. The earlier behaviour of marking them `skipped`
    # was destructive and made the day permanently un-publishable.
    table.update.assert_not_called()


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_review_disabled_pings_webhook_when_configured(notify, create):
    """If the failure webhook is set, operator must be alerted that pending
    rows are silently accumulating because of missing review config."""
    from lorescape_backend.config import Config

    config = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g",
        discord_webhook_url="https://discord.com/api/webhooks/hook",
        discord_bot_token=None,  # review disabled
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id="u", threads_access_token="t",
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )
    rows = [_row(), _row(id="row-2")]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client

    run_publish_job(config, date(2026, 5, 12))

    table.update.assert_not_called()
    notify.assert_called_once()
    kwargs = notify.call_args.kwargs
    assert kwargs["webhook_url"] == config.discord_webhook_url
    assert kwargs["date_str"] == "2026-05-12"
    assert "2 row" in kwargs["error_message"]


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
def test_row_without_discord_message_id_stays_pending(check, create, fake_config):
    """If discord_message_id is NULL (e.g. 09:00 ran before Discord was wired),
    the row must stay in `pending` so back-fill can recover it later."""
    rows = [_row(discord_message_id=None)]
    client, table, _, _ = _supabase_multi_table(en_rows=rows)
    create.return_value = client

    run_publish_job(fake_config, date(2026, 5, 12))

    # Must not consult Discord, must not mutate the row.
    check.assert_not_called()
    table.update.assert_not_called()


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
