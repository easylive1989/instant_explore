"""Instagram Graph API client tests."""
from __future__ import annotations

from unittest.mock import patch

import pytest

from lorescape_publisher.instagram import (
    publish,
    publish_carousel,
    publish_reel,
)


def test_publish_creates_container_then_publishes(requests_mock):
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "container-1"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "ig-post-1"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
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


def test_publish_carousel_creates_children_then_parent_then_publishes(
    requests_mock,
):
    # All /media POSTs hit the same URL; queue distinct ids in call order:
    # three children, then the parent CAROUSEL container.
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        [
            {"json": {"id": "child-1"}},
            {"json": {"id": "child-2"}},
            {"json": {"id": "child-3"}},
            {"json": {"id": "parent-1"}},
        ],
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "ig-carousel-1"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        post_id = publish_carousel(
            ig_user_id="ig1",
            access_token="tok",
            image_urls=[
                "https://example.com/1.png",
                "https://example.com/2.png",
                "https://example.com/3.png",
            ],
            caption="carousel caption",
        )

    assert post_id == "ig-carousel-1"

    history = requests_mock.request_history
    # 3 children + 1 parent + 1 publish = 5 calls
    assert len(history) == 5

    # Each child container is flagged as a carousel item, carries its image,
    # and does NOT carry the caption.
    for i, url in enumerate(
        ["https://example.com/1.png", "https://example.com/2.png",
         "https://example.com/3.png"]
    ):
        child_req = history[i]
        assert child_req.qs["is_carousel_item"] == ["true"]
        assert child_req.qs["image_url"] == [url]
        assert "caption" not in child_req.qs

    parent_req = history[3]
    assert parent_req.qs["media_type"] == ["carousel"]
    assert parent_req.qs["children"] == ["child-1,child-2,child-3"]
    assert parent_req.qs["caption"] == ["carousel caption"]

    publish_req = history[4]
    assert publish_req.qs["creation_id"] == ["parent-1"]


def test_publish_carousel_rejects_empty_image_list():
    with pytest.raises(ValueError):
        publish_carousel(
            ig_user_id="ig1", access_token="tok",
            image_urls=[], caption="c",
        )


def test_publish_raises_on_http_error(requests_mock):
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        status_code=400,
        json={"error": {"message": "Image not reachable"}},
    )
    with patch("lorescape_publisher.instagram.time.sleep"):
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

    with patch("lorescape_publisher.instagram.time.sleep"):
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


def test_publish_reel_passes_cover_url_when_provided(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"v")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-c"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-c",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-c",
        json={"status_code": "FINISHED"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "reel-post"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        publish_reel(
            ig_user_id="ig1",
            access_token="tok",
            video_path=str(video),
            caption="c",
            cover_url="https://example.com/cover.png",
        )

    create_req = requests_mock.request_history[0]
    assert create_req.qs["cover_url"] == ["https://example.com/cover.png"]


def test_publish_reel_omits_cover_url_when_none(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"v")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media", json={"id": "reel-c"}
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-c",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-c",
        json={"status_code": "FINISHED"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "reel-post"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        publish_reel(
            ig_user_id="ig1", access_token="tok",
            video_path=str(video), caption="c",
        )

    assert "cover_url" not in requests_mock.request_history[0].qs


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
        json={"status_code": "ERROR", "status": "Video aspect ratio invalid"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        with pytest.raises(RuntimeError) as exc_info:
            publish_reel(
                ig_user_id="ig1",
                access_token="tok",
                video_path=str(video),
                caption="c",
            )
    assert "Video aspect ratio invalid" in str(exc_info.value)


def test_publish_reel_raises_when_upload_rejected(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"x")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-3"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-3",
        json={"success": False, "error": "rejected"},
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        with pytest.raises(RuntimeError, match="not accepted"):
            publish_reel(
                ig_user_id="ig1",
                access_token="tok",
                video_path=str(video),
                caption="c",
            )


def test_publish_reel_upload_http_error_includes_response_body(
    requests_mock, tmp_path
):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"x")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-4"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-4",
        status_code=400,
        json={
            "debug_info": {
                "type": "ProcessingFailedError",
                "message": "Video Transcoding Error",
            }
        },
    )

    with patch("lorescape_publisher.instagram.time.sleep"):
        with pytest.raises(Exception, match="Video Transcoding Error"):
            publish_reel(
                ig_user_id="ig1",
                access_token="tok",
                video_path=str(video),
                caption="c",
            )
