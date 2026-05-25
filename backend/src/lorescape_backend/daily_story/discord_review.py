"""Discord review-flow client (REST only — no Gateway).

The bot posts a daily-story preview to a private review channel and adds the
two approval reactions. Later, the publish job reads the reactions to decide
what to do.

Bot permissions required in the review channel:
- Send Messages
- Embed Links
- Add Reactions
- Read Message History
"""
from __future__ import annotations

import logging
import time
import urllib.parse
from dataclasses import dataclass
from typing import Literal

import requests

logger = logging.getLogger(__name__)

DISCORD_API = "https://discord.com/api/v10"
APPROVE_EMOJI = "✅"
REJECT_EMOJI = "❌"

ReviewDecision = Literal["approved", "rejected", "none"]

# Discord embed limits (per their docs).
_EMBED_DESCRIPTION_LIMIT = 4096
_REQUEST_TIMEOUT = 10
# Cap Retry-After we honor so a misbehaving header can't stall the job.
_MAX_RETRY_AFTER_SECONDS = 5.0


@dataclass(frozen=True)
class ReviewPayload:
    """The subset of a daily story we surface in the review embed."""

    place_name: str
    era: str
    place_location: str
    story: str
    threads_summary: str
    image_url: str | None
    wikipedia_url: str


def send_for_review(
    *, bot_token: str, channel_id: str, payload: ReviewPayload
) -> str:
    """Post the review message and seed it with ✅/❌. Returns message id."""
    embed = _build_embed(payload)
    message_id = _post_message(
        bot_token=bot_token, channel_id=channel_id, embed=embed
    )
    for emoji in (APPROVE_EMOJI, REJECT_EMOJI):
        _add_self_reaction(
            bot_token=bot_token,
            channel_id=channel_id,
            message_id=message_id,
            emoji=emoji,
        )
    return message_id


def check_reaction(
    *,
    bot_token: str,
    channel_id: str,
    message_id: str,
    approver_ids: tuple[str, ...] | list[str],
) -> ReviewDecision:
    """Read reactions and decide. Approval wins ties (production-friendly)."""
    approver_set = {str(uid) for uid in approver_ids}

    def _reactors(emoji: str) -> set[str]:
        return {u["id"] for u in _list_reaction_users(
            bot_token=bot_token,
            channel_id=channel_id,
            message_id=message_id,
            emoji=emoji,
        )}

    approved_by = _reactors(APPROVE_EMOJI) & approver_set
    rejected_by = _reactors(REJECT_EMOJI) & approver_set

    if approved_by:
        return "approved"
    if rejected_by:
        return "rejected"
    return "none"


def _build_embed(payload: ReviewPayload) -> dict:
    description_lines = [
        payload.story,
        "",
        "📱 *Threads version:*",
        payload.threads_summary,
    ]
    description = "\n".join(description_lines)
    if len(description) > _EMBED_DESCRIPTION_LIMIT:
        description = description[: _EMBED_DESCRIPTION_LIMIT - 1] + "…"

    embed: dict = {
        "title": f"📜 {payload.place_name} · {payload.era}",
        "description": description,
        "url": payload.wikipedia_url,
        "footer": {
            "text": "React ✅ to publish at 21:00 Asia/Taipei · ❌ to skip",
        },
        "fields": [
            {"name": "Location", "value": payload.place_location, "inline": True},
        ],
    }
    if payload.image_url:
        embed["image"] = {"url": payload.image_url}
    return embed


def _post_message(*, bot_token: str, channel_id: str, embed: dict) -> str:
    response = requests.post(
        f"{DISCORD_API}/channels/{channel_id}/messages",
        headers=_bot_headers(bot_token),
        json={"embeds": [embed]},
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def _add_self_reaction(
    *, bot_token: str, channel_id: str, message_id: str, emoji: str
) -> None:
    encoded = urllib.parse.quote(emoji, safe="")
    url = (
        f"{DISCORD_API}/channels/{channel_id}/messages/{message_id}"
        f"/reactions/{encoded}/@me"
    )
    headers = _bot_headers(bot_token)
    response = requests.put(url, headers=headers, timeout=_REQUEST_TIMEOUT)
    # Reactions share a tight per-route bucket (~1 req / 250 ms per channel);
    # seeding ✅ and ❌ back-to-back can 429. Honor Retry-After once.
    if response.status_code == 429:
        delay = _parse_retry_after(response)
        logger.warning(
            "discord reaction rate-limited; sleeping %.2fs then retrying once",
            delay,
        )
        time.sleep(delay)
        response = requests.put(url, headers=headers, timeout=_REQUEST_TIMEOUT)
    response.raise_for_status()


def _parse_retry_after(response: requests.Response) -> float:
    """Discord returns Retry-After in seconds (sometimes fractional)."""
    raw = response.headers.get("Retry-After", "1")
    try:
        delay = float(raw)
    except ValueError:
        delay = 1.0
    return max(0.0, min(delay, _MAX_RETRY_AFTER_SECONDS))


def _list_reaction_users(
    *, bot_token: str, channel_id: str, message_id: str, emoji: str
) -> list[dict]:
    encoded = urllib.parse.quote(emoji, safe="")
    url = (
        f"{DISCORD_API}/channels/{channel_id}/messages/{message_id}"
        f"/reactions/{encoded}"
    )
    response = requests.get(
        url,
        headers=_bot_headers(bot_token),
        params={"limit": 100},
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()


def _bot_headers(bot_token: str) -> dict:
    return {
        "Authorization": f"Bot {bot_token}",
        "Content-Type": "application/json",
        "User-Agent": "lorescape-daily-story (https://github.com, 0.1.0)",
    }
