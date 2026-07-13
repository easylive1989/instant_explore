"""Tests for the temporary reel video hosting in the reel-videos bucket."""
from __future__ import annotations

from unittest.mock import MagicMock

from lorescape_publisher.reel_video_storage import (
    delete_reel_video,
    upload_reel_video,
)

PUBLIC_URL = (
    "https://example.supabase.co/storage/v1/object/public/"
    "reel-videos/2026-07-13/final.mp4"
)


def test_upload_reel_video_calls_storage_with_expected_args():
    supabase = MagicMock()
    bucket = supabase.storage.from_.return_value
    bucket.get_public_url.return_value = PUBLIC_URL
    path = "2026-07-13/final.mp4"

    url = upload_reel_video(supabase, b"video-bytes", path=path)

    supabase.storage.from_.assert_called_once_with("reel-videos")
    bucket.upload.assert_called_once_with(
        path=path,
        file=b"video-bytes",
        file_options={"content-type": "video/mp4", "upsert": "true"},
    )
    bucket.get_public_url.assert_called_once_with(path)
    assert url == PUBLIC_URL


def test_delete_reel_video_removes_the_path():
    supabase = MagicMock()
    bucket = supabase.storage.from_.return_value

    delete_reel_video(supabase, path="2026-07-13/final.mp4")

    supabase.storage.from_.assert_called_once_with("reel-videos")
    bucket.remove.assert_called_once_with(["2026-07-13/final.mp4"])
