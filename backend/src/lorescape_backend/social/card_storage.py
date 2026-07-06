"""Upload rendered IG card PNGs to the public `ig-cards` Supabase bucket.

Bucket must be created out-of-band (see
`docs/operations/2026-05-21-ig-cards-bucket-setup.md`). Uploads use upsert
so re-running the publisher for the same date overwrites the previous PNG
at the same path (and keeps the same public URL).
"""
from __future__ import annotations

BUCKET_NAME = "ig-cards"


def upload_card_image(
    supabase, image_bytes: bytes, *, path: str, content_type: str
) -> str:
    """Upload image bytes to `ig-cards/<path>` and return the public URL.

    Upsert keeps re-runs idempotent: the same path overwrites the previous
    object and keeps the same public URL.
    """
    bucket = supabase.storage.from_(BUCKET_NAME)
    bucket.upload(
        path=path,
        file=image_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )
    return bucket.get_public_url(path)


def upload_card_png(supabase, png_bytes: bytes, *, path: str) -> str:
    """Upload PNG bytes to `ig-cards/<path>` and return the public URL.

    `path` should be of the form `<publish_date>/<row_id>.png`. The caller
    chooses the path so that the URL is deterministic for a given row.
    """
    return upload_card_image(
        supabase, png_bytes, path=path, content_type="image/png"
    )
