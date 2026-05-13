"""Instagram Graph API client tests."""
from __future__ import annotations

from unittest.mock import patch

import pytest

from lorescape_backend.social.instagram import publish


def test_publish_creates_container_then_publishes(requests_mock):
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "container-1"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "ig-post-1"},
    )

    with patch("lorescape_backend.social.instagram.time.sleep"):
        post_id = publish(
            ig_user_id="ig1",
            access_token="tok",
            image_url="https://example.com/x.jpg",
            caption="my caption",
        )

    assert post_id == "ig-post-1"
    create_req = requests_mock.request_history[0]
    assert create_req.qs["image_url"] == ["https://example.com/x.jpg"]
    assert create_req.qs["caption"] == ["my caption"]
    assert create_req.qs["access_token"] == ["tok"]

    publish_req = requests_mock.request_history[1]
    assert publish_req.qs["creation_id"] == ["container-1"]


def test_publish_raises_on_http_error(requests_mock):
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        status_code=400,
        json={"error": {"message": "Image not reachable"}},
    )
    with patch("lorescape_backend.social.instagram.time.sleep"):
        with pytest.raises(Exception):
            publish(
                ig_user_id="ig1", access_token="tok",
                image_url="bad", caption="c",
            )
