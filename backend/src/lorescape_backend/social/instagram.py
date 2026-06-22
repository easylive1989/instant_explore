"""Instagram Business publishing via the Meta Graph API.

Two-step pattern: create a media container, then publish.
The IG Business account must be linked to a Facebook Page, and the access
token must be a long-lived Page access token with `instagram_content_publish`.

Reference: https://developers.facebook.com/docs/instagram-api/guides/content-publishing
"""
from __future__ import annotations

import logging
import os
import time

import requests

logger = logging.getLogger(__name__)

META_GRAPH_API = "https://graph.facebook.com/v21.0"
_REQUEST_TIMEOUT = 30
_CONTAINER_READY_DELAY_SECONDS = 5
RUPLOAD_API = "https://rupload.facebook.com/ig-api-upload/v21.0"
_UPLOAD_TIMEOUT = 300
_REEL_POLL_INTERVAL_SECONDS = 5
_REEL_POLL_MAX_ATTEMPTS = 60


def publish(
    *,
    ig_user_id: str,
    access_token: str,
    image_url: str,
    caption: str,
) -> str:
    """Create + publish an IG single-image post. Returns the IG post id.

    Caller is responsible for ensuring `image_url` is publicly reachable —
    Meta servers fetch the image directly, they do not accept uploads.
    """
    container_id = _create_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        image_url=image_url,
        caption=caption,
    )
    time.sleep(_CONTAINER_READY_DELAY_SECONDS)
    return _publish_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        container_id=container_id,
    )


def _create_container(
    *,
    ig_user_id: str,
    access_token: str,
    image_url: str,
    caption: str,
) -> str:
    response = requests.post(
        f"{META_GRAPH_API}/{ig_user_id}/media",
        params={
            "image_url": image_url,
            "caption": caption,
            "access_token": access_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def _publish_container(
    *, ig_user_id: str, access_token: str, container_id: str
) -> str:
    response = requests.post(
        f"{META_GRAPH_API}/{ig_user_id}/media_publish",
        params={
            "creation_id": container_id,
            "access_token": access_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def publish_reel(
    *,
    ig_user_id: str,
    access_token: str,
    video_path: str,
    caption: str,
) -> str:
    """Create + resumable-upload + publish an IG Reel. Returns the IG post id.

    Uploads the local video bytes directly to Meta's resumable upload
    endpoint — no public URL or intermediate storage is needed.
    """
    container_id = _create_reel_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        caption=caption,
    )
    _upload_reel_bytes(
        container_id=container_id,
        access_token=access_token,
        video_path=video_path,
    )
    _wait_until_finished(container_id=container_id, access_token=access_token)
    return _publish_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        container_id=container_id,
    )


def _create_reel_container(
    *, ig_user_id: str, access_token: str, caption: str
) -> str:
    response = requests.post(
        f"{META_GRAPH_API}/{ig_user_id}/media",
        params={
            "media_type": "REELS",
            "upload_type": "resumable",
            "caption": caption,
            "access_token": access_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def _upload_reel_bytes(
    *, container_id: str, access_token: str, video_path: str
) -> None:
    file_size = os.path.getsize(video_path)
    with open(video_path, "rb") as video_file:
        video_bytes = video_file.read()
    response = requests.post(
        f"{RUPLOAD_API}/{container_id}",
        headers={
            "Authorization": f"OAuth {access_token}",
            "Content-Type": "application/octet-stream",
            "offset": "0",
            "file_size": str(file_size),
        },
        data=video_bytes,
        timeout=_UPLOAD_TIMEOUT,
    )
    response.raise_for_status()
    body = response.json()
    if not body.get("success", True):
        raise RuntimeError(f"Reel upload was not accepted: {body}")


def _wait_until_finished(*, container_id: str, access_token: str) -> None:
    for _ in range(_REEL_POLL_MAX_ATTEMPTS):
        response = requests.get(
            f"{META_GRAPH_API}/{container_id}",
            params={
                "fields": "status_code,status",
                "access_token": access_token,
            },
            timeout=_REQUEST_TIMEOUT,
        )
        response.raise_for_status()
        payload = response.json()
        status = payload.get("status_code")
        if status == "FINISHED":
            return
        if status in ("ERROR", "EXPIRED"):
            detail = payload.get("status", "")
            raise RuntimeError(
                f"Reel container {container_id} failed: "
                f"{status} {detail}".strip()
            )
        time.sleep(_REEL_POLL_INTERVAL_SECONDS)
    raise TimeoutError(
        f"Reel container {container_id} not ready after polling"
    )
