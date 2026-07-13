"""Temporary reel video hosting in the public `reel-videos` Supabase bucket.

Only used by the video_url fallback path when Meta's rupload endpoint
rejects the byte upload generically (BACKLOG F11). The bucket must be
created out-of-band (see `docs/init/2026-07-13-reel-videos-bucket-setup.md`).
Videos are deleted right after the publish attempt; a Meta container created
from the URL keeps its own copy once FINISHED, and unpublished containers
expire on their own within ~24h.
"""
from __future__ import annotations

BUCKET_NAME = "reel-videos"


def upload_reel_video(supabase, video_bytes: bytes, *, path: str) -> str:
    """Upload video bytes to `reel-videos/<path>` and return the public URL.

    Upsert keeps retries idempotent: the same path overwrites the previous
    object and keeps the same public URL.
    """
    bucket = supabase.storage.from_(BUCKET_NAME)
    bucket.upload(
        path=path,
        file=video_bytes,
        file_options={"content-type": "video/mp4", "upsert": "true"},
    )
    return bucket.get_public_url(path)


def delete_reel_video(supabase, *, path: str) -> None:
    """Delete the temporary video at `reel-videos/<path>`."""
    supabase.storage.from_(BUCKET_NAME).remove([path])
