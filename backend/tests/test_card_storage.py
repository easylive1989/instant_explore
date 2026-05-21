"""Tests for upload_card_png: PNG bytes → public Supabase Storage URL."""
from __future__ import annotations

from unittest.mock import MagicMock

from lorescape_backend.social.card_storage import upload_card_png


def _supabase_with_storage(public_url: str = "https://example.supabase.co/storage/v1/object/public/ig-cards/2026-05-21/row-1.png"):
    bucket = MagicMock()
    bucket.upload.return_value = MagicMock()
    bucket.get_public_url.return_value = public_url

    storage = MagicMock()
    storage.from_.return_value = bucket

    client = MagicMock()
    client.storage = storage
    return client, storage, bucket


def test_upload_card_png_calls_storage_with_expected_args():
    client, storage, bucket = _supabase_with_storage()
    png_bytes = b"\x89PNG\r\n\x1a\nfake"
    path = "2026-05-21/row-1.png"

    url = upload_card_png(client, png_bytes, path=path)

    storage.from_.assert_called_once_with("ig-cards")
    bucket.upload.assert_called_once()
    upload_kwargs = bucket.upload.call_args.kwargs
    assert upload_kwargs["path"] == path
    assert upload_kwargs["file"] == png_bytes
    file_options = upload_kwargs["file_options"]
    assert file_options["content-type"] == "image/png"
    assert file_options["upsert"] == "true"
    bucket.get_public_url.assert_called_once_with(path)
    assert url == "https://example.supabase.co/storage/v1/object/public/ig-cards/2026-05-21/row-1.png"


def test_upload_card_png_returns_public_url_unchanged():
    client, _, _ = _supabase_with_storage(
        public_url="https://abc.supabase.co/storage/v1/object/public/ig-cards/x.png?token=ignored"
    )

    url = upload_card_png(client, b"x", path="x.png")

    assert url == "https://abc.supabase.co/storage/v1/object/public/ig-cards/x.png?token=ignored"
