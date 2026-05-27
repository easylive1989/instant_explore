"""Discord review-flow REST client tests."""
from __future__ import annotations

import json

import pytest

from lorescape_backend.daily_story.discord_review import (
    APPROVE_EMOJI,
    REJECT_EMOJI,
    ReviewPayload,
    check_reaction,
    send_for_review,
)

CHANNEL = "777"
MESSAGE = "9999"
APPROVER_A = "111"
APPROVER_B = "222"
FAKE_PNG = b"\x89PNG\r\n\x1a\nfake-card-bytes"


def _payload(**overrides) -> ReviewPayload:
    base = dict(card_png=FAKE_PNG, publish_date="2026-05-12")
    base.update(overrides)
    return ReviewPayload(**base)


def test_send_for_review_uploads_png_then_adds_two_reactions(requests_mock):
    requests_mock.post(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages",
        json={"id": MESSAGE},
    )
    requests_mock.put(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9C%85/@me",
        json={},
    )
    requests_mock.put(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9D%8C/@me",
        json={},
    )

    msg_id = send_for_review(
        bot_token="tok", channel_id=CHANNEL, payload=_payload()
    )

    assert msg_id == MESSAGE
    history = requests_mock.request_history
    post = history[0]
    assert post.method == "POST"

    # Multipart body must carry the PNG and a JSON payload, not a text embed.
    content_type = post.headers["Content-Type"]
    assert content_type.startswith("multipart/form-data")
    body = post.body
    if isinstance(body, str):
        body = body.encode("latin-1")
    assert FAKE_PNG in body
    assert b"image/png" in body
    assert b'name="files[0]"' in body
    assert b'name="payload_json"' in body
    # The instruction lives in the message content, not as a story preview.
    assert b"React" in body and b"21:00" in body
    # No leftover story / threads fields from the old text-based flow.
    assert b"embeds" not in body

    # Reaction calls authenticated as the bot.
    assert any("Bot tok" in r.headers.get("Authorization", "") for r in history)


def test_send_for_review_filename_includes_publish_date(requests_mock):
    requests_mock.post(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages",
        json={"id": MESSAGE},
    )
    requests_mock.put(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9C%85/@me",
        json={},
    )
    requests_mock.put(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9D%8C/@me",
        json={},
    )

    send_for_review(
        bot_token="tok",
        channel_id=CHANNEL,
        payload=_payload(publish_date="2026-05-12"),
    )

    body = requests_mock.request_history[0].body
    if isinstance(body, str):
        body = body.encode("latin-1")
    assert b"ig-card-2026-05-12.png" in body


def test_send_for_review_retries_reaction_once_on_429(requests_mock, mocker):
    """Per-route bucket 429 on the second seed reaction must retry, not crash."""
    sleep = mocker.patch(
        "lorescape_backend.daily_story.discord_review.time.sleep"
    )
    requests_mock.post(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages",
        json={"id": MESSAGE},
    )
    requests_mock.put(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9C%85/@me",
        json={},
    )
    reject_url = (
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9D%8C/@me"
    )
    requests_mock.put(
        reject_url,
        [
            {"status_code": 429, "headers": {"Retry-After": "0.25"}, "json": {}},
            {"status_code": 204, "json": {}},
        ],
    )

    msg_id = send_for_review(
        bot_token="tok", channel_id=CHANNEL, payload=_payload()
    )

    assert msg_id == MESSAGE
    reject_calls = [
        r for r in requests_mock.request_history
        if r.method == "PUT" and r.url == reject_url
    ]
    assert len(reject_calls) == 2
    sleep.assert_called_once_with(0.25)


def _mock_reactions(requests_mock, approve_users, reject_users):
    requests_mock.get(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9C%85",
        json=[{"id": uid} for uid in approve_users],
    )
    requests_mock.get(
        f"https://discord.com/api/v10/channels/{CHANNEL}/messages/{MESSAGE}"
        f"/reactions/%E2%9D%8C",
        json=[{"id": uid} for uid in reject_users],
    )


def test_check_reaction_returns_approved_when_approver_reacts_check(requests_mock):
    _mock_reactions(requests_mock, [APPROVER_A], [])
    decision = check_reaction(
        bot_token="tok", channel_id=CHANNEL, message_id=MESSAGE,
        approver_ids=(APPROVER_A,),
    )
    assert decision == "approved"


def test_check_reaction_returns_rejected_when_approver_reacts_x(requests_mock):
    _mock_reactions(requests_mock, [], [APPROVER_A])
    decision = check_reaction(
        bot_token="tok", channel_id=CHANNEL, message_id=MESSAGE,
        approver_ids=(APPROVER_A,),
    )
    assert decision == "rejected"


def test_check_reaction_returns_none_when_no_approver_reacted(requests_mock):
    _mock_reactions(requests_mock, ["999"], ["888"])  # non-approver IDs
    decision = check_reaction(
        bot_token="tok", channel_id=CHANNEL, message_id=MESSAGE,
        approver_ids=(APPROVER_A,),
    )
    assert decision == "none"


def test_check_reaction_approval_beats_rejection(requests_mock):
    """If the same approver reacted with both (mistake), approve wins."""
    _mock_reactions(requests_mock, [APPROVER_A], [APPROVER_A])
    decision = check_reaction(
        bot_token="tok", channel_id=CHANNEL, message_id=MESSAGE,
        approver_ids=(APPROVER_A,),
    )
    assert decision == "approved"


def test_check_reaction_ignores_non_approver_reactions(requests_mock):
    """A stray reaction from a non-approver must not flip the decision."""
    _mock_reactions(requests_mock, ["999"], [APPROVER_A])
    decision = check_reaction(
        bot_token="tok", channel_id=CHANNEL, message_id=MESSAGE,
        approver_ids=(APPROVER_A,),
    )
    assert decision == "rejected"


def test_emoji_constants():
    """Keep the wire-level emoji bytes stable — Discord URLs depend on these."""
    assert APPROVE_EMOJI == "✅"
    assert REJECT_EMOJI == "❌"
