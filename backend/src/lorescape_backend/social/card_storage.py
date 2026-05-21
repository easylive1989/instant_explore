"""Upload rendered IG card PNGs to the public `ig-cards` Supabase bucket.

Bucket must be created out-of-band (see
`docs/operations/2026-05-21-ig-cards-bucket-setup.md`). Uploads use upsert
so re-running the publisher for the same date overwrites the previous PNG
at the same path (and keeps the same public URL).
"""
from __future__ import annotations

BUCKET_NAME = "ig-cards"


def upload_card_png(supabase, png_bytes: bytes, *, path: str) -> str:
    """Upload PNG bytes to `ig-cards/<path>` and return the public URL.

    `path` should be of the form `<publish_date>/<row_id>.png`. The caller
    chooses the path so that the URL is deterministic for a given row.
    """
    bucket = supabase.storage.from_(BUCKET_NAME)
    bucket.upload(
        path=path,
        file=png_bytes,
        file_options={"content-type": "image/png", "upsert": "true"},
    )
    return bucket.get_public_url(path)
