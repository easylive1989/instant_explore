"""Threads Graph API client tests."""
from __future__ import annotations

from unittest.mock import patch

from lorescape_backend.social.threads import publish


def test_publish_text_only_creates_then_publishes(requests_mock):
    requests_mock.post(
        "https://graph.threads.net/v1.0/u1/threads",
        json={"id": "container-123"},
    )
    requests_mock.post(
        "https://graph.threads.net/v1.0/u1/threads_publish",
        json={"id": "post-999"},
    )

    with patch("lorescape_backend.social.threads.time.sleep"):
        post_id = publish(
            user_id="u1", access_token="tok", text="hello threads", image_url=None
        )

    assert post_id == "post-999"
    create_req = requests_mock.request_history[0]
    assert create_req.qs["media_type"] == ["text"]
    assert create_req.qs["text"] == ["hello threads"]
    assert create_req.qs["access_token"] == ["tok"]
    assert "image_url" not in create_req.qs

    publish_req = requests_mock.request_history[1]
    assert publish_req.qs["creation_id"] == ["container-123"]


def test_publish_with_image_sends_image_type(requests_mock):
    requests_mock.post(
        "https://graph.threads.net/v1.0/u1/threads",
        json={"id": "cid"},
    )
    requests_mock.post(
        "https://graph.threads.net/v1.0/u1/threads_publish",
        json={"id": "post-1"},
    )

    with patch("lorescape_backend.social.threads.time.sleep"):
        publish(
            user_id="u1", access_token="tok",
            text="caption",
            image_url="https://example.com/x.jpg",
        )

    create_req = requests_mock.request_history[0]
    assert create_req.qs["media_type"] == ["image"]
    assert create_req.qs["image_url"] == ["https://example.com/x.jpg"]


def test_publish_raises_on_http_error(requests_mock):
    requests_mock.post(
        "https://graph.threads.net/v1.0/u1/threads",
        status_code=400,
        json={"error": {"message": "Invalid token"}},
    )
    with patch("lorescape_backend.social.threads.time.sleep"):
        import pytest

        with pytest.raises(Exception):
            publish(user_id="u1", access_token="bad", text="x")
