"""Discord webhook notifier for failure alerts."""
from __future__ import annotations

import logging

import requests

logger = logging.getLogger(__name__)

# Discord content limit is 2000 chars; reserve some headroom for the prefix.
_MAX_CONTENT = 1900
_PREFIX_BUDGET = 200  # rough budget for the date/error prefix


def notify_failure(
    *, webhook_url: str, date_str: str, error_message: str, traceback_str: str
) -> None:
    """POST a failure summary to Discord.

    Truncates the traceback to keep the total payload under Discord's 2000-char
    limit. Swallows HTTP errors — the caller is already handling a failure and
    we don't want to crash on top of that.
    """
    prefix = f"🚨 daily_story_job failed for date {date_str}\n"
    body = f"{error_message}\n\n{traceback_str}"
    available = _MAX_CONTENT - len(prefix) - len("```\n\n```")
    truncated = body[:available]
    content = f"{prefix}```\n{truncated}\n```"

    try:
        requests.post(webhook_url, json={"content": content}, timeout=10)
    except Exception:  # noqa: BLE001 — last-resort notifier
        logger.exception("Failed to POST Discord notification")
