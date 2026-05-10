import requests_mock

from lorescape_backend.daily_story.discord_notify import notify_failure


WEBHOOK = "https://discord.com/api/webhooks/123/abc"


def test_notify_failure_posts_content_with_date_error_traceback():
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=204)
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str="Traceback (most recent call last):\n  ...",
        )
    assert m.called
    body = m.last_request.json()
    content = body["content"]
    assert "2026-05-11" in content
    assert "boom" in content
    assert "Traceback" in content


def test_notify_failure_truncates_long_traceback_to_safe_size():
    huge_tb = "x" * 5000
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=204)
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str=huge_tb,
        )
    body = m.last_request.json()
    # Discord content max is 2000 chars; payload must be under it.
    assert len(body["content"]) <= 2000


def test_notify_failure_does_not_raise_on_http_error():
    """Network error must not crash the calling process — it's already failing."""
    with requests_mock.Mocker() as m:
        m.post(WEBHOOK, status_code=500)
        # Should not raise
        notify_failure(
            webhook_url=WEBHOOK,
            date_str="2026-05-11",
            error_message="boom",
            traceback_str="...",
        )
