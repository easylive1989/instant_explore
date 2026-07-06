"""publisher.run_publish_job state-machine tests."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

from lorescape_backend.social.publisher import run_publish_job


def _row(**overrides):
    """The primary pending row: zh-TW (carries review_state + discord_message_id)."""
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
        hashtags=["rome", "colosseum"],
        review_state="pending",
        discord_message_id="msg-1",
        card_title="石頭裡的吶喊",
        card_title_sub="鬥獸場百年",
        card_paragraphs=["第一段", "第二段", "第三段"],
        card_pull_quote="「我們將娛樂血腥化為藝術。」",
        card_pull_quote_attrib="—— 塔西陀",
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


def _supabase_multi_table(*, zh_rows, place_row=None):
    """Build a supabase mock that dispatches by table name.

    `client.table("daily_stories")` serves the select-pending-zh-TW query
    (returns zh_rows). `client.table("daily_story_places")` returns place_row
    wrapped in a list. `client.table("social_posts")` records publish
    outcomes via upsert. `client.table(...).update(...)` always returns a
    passing chain.
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
    daily_stories_table.select.return_value = _make_select_chain(zh_rows)
    daily_stories_table.update.return_value = update_chain

    places_table = MagicMock()
    places_table.select.return_value = _make_select_chain(
        [place_row] if place_row else []
    )

    social_posts_table = MagicMock()
    social_posts_table.upsert.return_value.execute.return_value = MagicMock(
        data=None
    )
    # No pre-rendered row for these tests: default flow only.
    social_posts_table.select.return_value = _make_select_chain([])

    client = MagicMock()

    def _table(name):
        if name == "daily_stories":
            return daily_stories_table
        if name == "daily_story_places":
            return places_table
        if name == "social_posts":
            return social_posts_table
        raise AssertionError(f"unexpected table: {name}")

    client.table.side_effect = _table
    return client, daily_stories_table, social_posts_table, update_chain


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_publishes_to_ig(
    upload, render, ig_pub, check, create, fake_config
):
    zh = _row()
    place = _place_row()
    client, ds_table, social_table, update_chain = _supabase_multi_table(
        zh_rows=[zh], place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    render.return_value = [b"\x89PNGcover", b"\x89PNGstory", b"\x89PNGcta"]
    upload.return_value = "https://x.supabase.co/storage/v1/object/public/ig-cards/2026-05-12/row-zh-1.png"
    ig_pub.return_value = "ig-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    # render_slides called once, producing one PNG per carousel slide
    render.assert_called_once()
    # upload called once per slide, paths suffixed -0/-1/-2
    assert upload.call_count == 3
    upload_paths = [c.kwargs["path"] for c in upload.call_args_list]
    assert upload_paths == [
        "2026-05-12/row-zh-1-0.png",
        "2026-05-12/row-zh-1-1.png",
        "2026-05-12/row-zh-1-2.png",
    ]
    # IG carousel called with the storage URLs (not the wikipedia image)
    ig_pub.assert_called_once()
    ig_kwargs = ig_pub.call_args.kwargs
    assert ig_kwargs["image_urls"] == [upload.return_value] * 3
    # Caption is the zh-TW caption — contains the zh-TW place_name
    assert "羅馬競技場" in ig_kwargs["caption"]

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    # IG outcome is recorded on social_posts, not daily_stories
    assert "ig_post_id" not in payload
    post = social_table.upsert.call_args[0][0]
    assert post["media_type"] == "carousel"
    assert post["status"] == "published"
    assert post["ig_post_id"] == "ig-1"
    assert post["error"] is None


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
def test_rejected_row_does_not_publish(ig_pub, check, create, fake_config):
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
    create.return_value = client
    check.return_value = "rejected"

    run_publish_job(fake_config, date(2026, 5, 12))

    ig_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "rejected"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
def test_no_reaction_skips_row(ig_pub, check, create, fake_config):
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
    create.return_value = client
    check.return_value = "none"

    run_publish_job(fake_config, date(2026, 5, 12))

    ig_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "skipped"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_publish_exception_marks_failed_and_notifies(
    notify, upload, render, ig_pub, check, create, fake_config
):
    rows = [_row()]
    place = _place_row()
    client, table, social_table, _ = _supabase_multi_table(
        zh_rows=rows, place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    render.return_value = [b"\x89PNGcover", b"\x89PNGstory", b"\x89PNGcta"]
    upload.return_value = "https://x.supabase.co/storage/v1/object/public/ig-cards/2026-05-12/row-zh-1.png"
    ig_pub.side_effect = RuntimeError("API blew up")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    post = social_table.upsert.call_args[0][0]
    assert post["media_type"] == "carousel"
    assert post["status"] == "failed"
    assert "API blew up" in post["error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
def test_no_pending_rows_does_nothing(create, fake_config):
    rows = []
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
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
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_ig="", cta_text="",
    )
    rows = [_row()]
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
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
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_ig="", cta_text="",
    )
    rows = [_row(), _row(id="row-2")]
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
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
    client, table, _, _ = _supabase_multi_table(zh_rows=rows)
    create.return_value = client

    run_publish_job(fake_config, date(2026, 5, 12))

    # Must not consult Discord, must not mutate the row.
    check.assert_not_called()
    table.update.assert_not_called()


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_skips_ig_when_place_row_missing(
    upload, render, ig_pub, check, create, fake_config
):
    zh = _row()
    client, ds_table, social_table, _ = _supabase_multi_table(
        zh_rows=[zh], place_row=None,
    )
    create.return_value = client
    check.return_value = "approved"

    run_publish_job(fake_config, date(2026, 5, 12))

    ig_pub.assert_not_called()
    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    post = social_table.upsert.call_args[0][0]
    assert post["status"] == "failed"
    assert post["error"] == "ig_skipped_missing_card_content"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
def test_approved_row_skips_ig_when_card_fields_null(
    upload, render, ig_pub, check, create, fake_config
):
    zh = _row(card_title=None)  # one missing card field → mapper returns None
    place = _place_row()
    client, ds_table, social_table, _ = _supabase_multi_table(
        zh_rows=[zh], place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"

    run_publish_job(fake_config, date(2026, 5, 12))

    ig_pub.assert_not_called()
    render.assert_not_called()
    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    post = social_table.upsert.call_args[0][0]
    assert post["status"] == "failed"
    assert post["error"] == "ig_skipped_missing_card_content"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_ig_render_failure_marks_failed_and_notifies(
    notify, upload, render, ig_pub, check, create, fake_config
):
    zh = _row()
    place = _place_row()
    client, ds_table, social_table, _ = _supabase_multi_table(
        zh_rows=[zh], place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    render.side_effect = RuntimeError("chromium crashed")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    post = social_table.upsert.call_args[0][0]
    assert post["status"] == "failed"
    assert "chromium crashed" in post["error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.instagram.publish_carousel")
@patch("lorescape_backend.social.publisher.render_slides")
@patch("lorescape_backend.social.publisher.card_storage.upload_card_png")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_ig_upload_failure_marks_failed_and_notifies(
    notify, upload, render, ig_pub, check, create, fake_config
):
    zh = _row()
    place = _place_row()
    client, ds_table, social_table, _ = _supabase_multi_table(
        zh_rows=[zh], place_row=place,
    )
    create.return_value = client
    check.return_value = "approved"
    render.return_value = [b"\x89PNGcover", b"\x89PNGstory", b"\x89PNGcta"]
    upload.side_effect = RuntimeError("supabase storage down")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = ds_table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    post = social_table.upsert.call_args[0][0]
    assert post["status"] == "failed"
    assert "supabase storage down" in post["error"]
    notify.assert_called_once()
