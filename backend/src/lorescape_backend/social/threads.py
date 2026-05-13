"""Threads Graph API client.

Two-step publish: create a media container, then publish it. Same shape as
the Instagram Graph API.

Reference: https://developers.facebook.com/docs/threads/posts/
"""
from __future__ import annotations

import logging
import time
from typing import Literal

import requests

logger = logging.getLogger(__name__)

THREADS_API = "https://graph.threads.net/v1.0"
_REQUEST_TIMEOUT = 30
# Threads recommends polling status before publishing media containers,
# but for TEXT and single IMAGE posts the container is usually ready
# immediately. A small fixed delay is enough in practice.
_CONTAINER_READY_DELAY_SECONDS = 2


MediaType = Literal["TEXT", "IMAGE"]


def publish(
    *,
    user_id: str,
    access_token: str,
    text: str,
    image_url: str | None = None,
) -> str:
    """Create + publish a Threads post. Returns the Threads post id."""
    media_type: MediaType = "IMAGE" if image_url else "TEXT"
    container_id = _create_container(
        user_id=user_id,
        access_token=access_token,
        text=text,
        media_type=media_type,
        image_url=image_url,
    )

    # Threads requires a brief moment for the container to become publishable.
    time.sleep(_CONTAINER_READY_DELAY_SECONDS)

    return _publish_container(
        user_id=user_id,
        access_token=access_token,
        container_id=container_id,
    )


def _create_container(
    *,
    user_id: str,
    access_token: str,
    text: str,
    media_type: MediaType,
    image_url: str | None,
) -> str:
    params: dict = {
        "media_type": media_type,
        "text": text,
        "access_token": access_token,
    }
    if image_url:
        params["image_url"] = image_url

    response = requests.post(
        f"{THREADS_API}/{user_id}/threads",
        params=params,
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def _publish_container(
    *, user_id: str, access_token: str, container_id: str
) -> str:
    response = requests.post(
        f"{THREADS_API}/{user_id}/threads_publish",
        params={
            "creation_id": container_id,
            "access_token": access_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]
