"""Instagram Business publishing via the Meta Graph API.

Two-step pattern: create a media container, then publish.
The IG Business account must be linked to a Facebook Page, and the access
token must be a long-lived Page access token with `instagram_content_publish`.

Reference: https://developers.facebook.com/docs/instagram-api/guides/content-publishing
"""
from __future__ import annotations

import logging
import time

import requests

logger = logging.getLogger(__name__)

META_GRAPH_API = "https://graph.facebook.com/v21.0"
_REQUEST_TIMEOUT = 30
_CONTAINER_READY_DELAY_SECONDS = 5


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
