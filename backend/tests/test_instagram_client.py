"""Instagram Graph API client tests."""
from __future__ import annotations

from unittest.mock import patch

import pytest

from lorescape_backend.social.instagram import publish, publish_reel


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


def test_publish_reel_runs_create_upload_poll_publish(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"fake-bytes")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-1"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-1",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-container-1",
        json={"status_code": "FINISHED"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "reel-post-1"},
    )

    with patch("lorescape_backend.social.instagram.time.sleep"):
        post_id = publish_reel(
            ig_user_id="ig1",
            access_token="tok",
            video_path=str(video),
            caption="my reel caption",
        )

    assert post_id == "reel-post-1"

    create_req = requests_mock.request_history[0]
    assert create_req.qs["media_type"] == ["reels"]
    assert create_req.qs["upload_type"] == ["resumable"]
    assert create_req.qs["caption"] == ["my reel caption"]

    upload_req = requests_mock.request_history[1]
    assert upload_req.headers["Authorization"] == "OAuth tok"
    assert upload_req.headers["offset"] == "0"
    assert upload_req.headers["file_size"] == "10"
    assert upload_req.body == b"fake-bytes"

    publish_req = requests_mock.request_history[-1]
    assert publish_req.qs["creation_id"] == ["reel-container-1"]


def test_publish_reel_raises_when_container_errors(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"x")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-2"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-2",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-container-2",
        json={"status_code": "ERROR"},
    )

    with patch("lorescape_backend.social.instagram.time.sleep"):
        with pytest.raises(RuntimeError):
            publish_reel(
                ig_user_id="ig1",
                access_token="tok",
                video_path=str(video),
                caption="c",
            )
