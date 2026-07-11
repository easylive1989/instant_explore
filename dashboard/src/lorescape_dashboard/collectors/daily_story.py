"""每日故事發布狀態：Supabase REST 查 social_posts 今日 rows（read-only）。"""
from __future__ import annotations

import os
from datetime import date

import requests

from ..config import SETUP_DOC

_SELECT = (
    "media_type,status,review_decision,scheduled_at,published_at,"
    "ig_post_id,error"
)


def fetch_today(supabase_url: str, service_key: str, today: date) -> list[dict]:
    resp = requests.get(
        f"{supabase_url.rstrip('/')}/rest/v1/social_posts",
        params={
            "publish_date": f"eq.{today.isoformat()}",
            "select": _SELECT,
            "order": "media_type",
        },
        headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
        },
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()


def shape_posts(rows: list[dict], today: date) -> dict:
    return {
        "date": today.isoformat(),
        "posts": rows,
        "all_published": bool(rows)
        and all(r.get("status") == "published" for r in rows),
    }


def collect() -> dict:
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not url or not key:
        raise SystemExit(
            "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 未設定"
            f"（publisher/.env）；見 {SETUP_DOC}"
        )
    today = date.today()
    return shape_posts(fetch_today(url, key, today), today)
