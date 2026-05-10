from datetime import date
from unittest.mock import MagicMock, call, patch

import pytest

from lorescape_backend.daily_story.job import LANGUAGES, run_once, run_with_retry
from lorescape_backend.daily_story.gemini_client import GeneratedStory
from lorescape_backend.daily_story.place_picker import PickedPlace
from lorescape_backend.daily_story.wikipedia import WikipediaSummary


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
        GeneratedStory("羅馬競技場", "義大利羅馬", "公元 70-80 年", "中文故事"),
        GeneratedStory("Colosseum", "Rome, Italy", "70-80 CE", "english story"),
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
    generate_story.return_value = GeneratedStory("X", "Y", "Z", "S")

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
    )
    run_once_mock.side_effect = RuntimeError("boom")
    with pytest.raises(RuntimeError):
        run_with_retry(config_no_webhook, date(2026, 5, 11))
    notify.assert_not_called()


def test_languages_list_matches_spec():
    assert LANGUAGES == ["zh-TW", "en"]
