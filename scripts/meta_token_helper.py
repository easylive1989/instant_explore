#!/usr/bin/env python3
"""Meta token helper for the Lorescape social publisher.

Run this script once to exchange a short-lived token for the long-lived
tokens needed by the automated Instagram posting system, then paste the
values into backend/.env.

Usage
-----
  # Instagram (Facebook Page + IG Business)
  python scripts/meta_token_helper.py --platform instagram

The script walks you through each step interactively and prints the exact
env-var lines to copy into backend/.env at the end.

Prerequisites
-------------
  pip install requests
  (already a dependency of lorescape-backend)

Reference
---------
  scripts/social_publisher_setup/README.md
"""
from __future__ import annotations

import argparse
import sys
import textwrap
import webbrowser

GRAPH_API = "https://graph.facebook.com/v21.0"


# ── shared helpers ────────────────────────────────────────────────────────────

def _prompt(label: str, secret: bool = False) -> str:
    """Read a non-empty string from stdin."""
    import getpass
    while True:
        value = (getpass.getpass if secret else input)(f"  {label}: ").strip()
        if value:
            return value
        print("  [!] Value cannot be empty — try again.")


def _step(n: int, title: str) -> None:
    print(f"\n{'─'*60}")
    print(f"  Step {n}: {title}")
    print(f"{'─'*60}")


def _success(label: str, value: str) -> None:
    print(f"\n  ✅  {label}")
    print(f"      {value}")


def _env_block(pairs: list[tuple[str, str]]) -> None:
    print("\n" + "═" * 60)
    print("  Copy these lines into  backend/.env")
    print("═" * 60)
    for key, val in pairs:
        print(f"  {key}={val}")
    print("═" * 60 + "\n")


# ── Instagram flow ─────────────────────────────────────────────────────────────

def instagram_flow() -> None:
    """Exchange a short-lived token → long-lived user token → Page token,
    then resolve the IG Business Account ID."""
    import requests  # noqa: PLC0415

    print(textwrap.dedent("""
    ┌─────────────────────────────────────────────────────┐
    │  Instagram Business + Facebook Page — token setup   │
    └─────────────────────────────────────────────────────┘

    Before you start, make sure:
      • You have a Facebook Page (https://www.facebook.com/pages/create)
      • Your Instagram account is set to Business or Creator
      • The IG account is linked to the FB Page
        (FB Page → Professional dashboard → Linked accounts → Instagram)
      • You have a Meta Developer App with these permissions granted:
          pages_show_list  pages_read_engagement  pages_manage_posts
          instagram_basic  instagram_content_publish
      (See scripts/social_publisher_setup/README.md §2–3)
    """))

    _step(1, "App credentials")
    print("  Find these in https://developers.facebook.com/apps → your app → Settings → Basic")
    app_id = _prompt("App ID")
    app_secret = _prompt("App Secret", secret=True)

    _step(2, "Short-lived user token")
    explorer_url = (
        f"https://developers.facebook.com/tools/explorer/"
        f"?method=GET&path=me&version=v21.0"
    )
    print(f"""
  Open Graph API Explorer and generate a User Token with these permissions:
    pages_show_list  pages_read_engagement  pages_manage_posts
    instagram_basic  instagram_content_publish

  URL: {explorer_url}
    """)
    _open_browser(explorer_url)
    short_token = _prompt("Paste short-lived user token here", secret=True)

    _step(3, "Exchange → long-lived user token (valid ~60 days)")
    resp = requests.get(
        f"{GRAPH_API}/oauth/access_token",
        params={
            "grant_type": "fb_exchange_token",
            "client_id": app_id,
            "client_secret": app_secret,
            "fb_exchange_token": short_token,
        },
        timeout=30,
    )
    _raise_for_status(resp, "exchange short→long-lived user token")
    long_user_token = resp.json()["access_token"]
    _success("Long-lived user token obtained", long_user_token[:20] + "…")

    _step(4, "Fetch Facebook Pages and their permanent Page access tokens")
    resp = requests.get(
        f"{GRAPH_API}/me/accounts",
        params={"access_token": long_user_token},
        timeout=30,
    )
    _raise_for_status(resp, "fetch /me/accounts")
    pages = resp.json().get("data", [])
    if pages:
        print("\n  Your Facebook Pages:")
        for i, page in enumerate(pages):
            print(f"    [{i}] {page['name']}  (id: {page['id']})")

        page_index = 0
        if len(pages) > 1:
            while True:
                raw = input("  Select page number [0]: ").strip() or "0"
                if raw.isdigit() and int(raw) < len(pages):
                    page_index = int(raw)
                    break
                print("  [!] Invalid selection.")
        chosen_page = pages[page_index]
    else:
        # New Pages Experience / Business-Portfolio pages do not appear in
        # /me/accounts even with pages_show_list granted. Fetch the Page
        # access token directly by its ID instead — still derived from the
        # long-lived user token, so the Page token does not expire.
        print(
            "\n  /me/accounts returned no Pages (normal for New Pages Experience\n"
            "  or Business-Portfolio pages). Fetching the Page token by ID instead.\n"
            "  Find the Page ID via Graph API Explorer: GET <page-id>?fields=name"
        )
        page_id_input = _prompt("Facebook Page ID")
        resp = requests.get(
            f"{GRAPH_API}/{page_id_input}",
            params={"fields": "name,access_token", "access_token": long_user_token},
            timeout=30,
        )
        _raise_for_status(resp, "fetch Page token by ID")
        chosen_page = resp.json()
        if "access_token" not in chosen_page:
            _die(
                "That Page returned no access_token. Make sure you are an admin of\n"
                "  the Page and pages_show_list / pages_read_engagement are granted."
            )

    page_id = chosen_page["id"]
    page_access_token = chosen_page["access_token"]
    _success(f"Selected page: {chosen_page['name']}", f"Page ID: {page_id}")

    _step(5, "Resolve IG Business Account ID")
    resp = requests.get(
        f"{GRAPH_API}/{page_id}",
        params={
            "fields": "instagram_business_account",
            "access_token": page_access_token,
        },
        timeout=30,
    )
    _raise_for_status(resp, "fetch instagram_business_account")
    ig_biz = resp.json().get("instagram_business_account")
    if not ig_biz:
        _die(
            "No Instagram Business account linked to this Page.\n"
            "  → Go to FB Page → Professional dashboard → Linked accounts → Instagram"
        )
    ig_user_id = ig_biz["id"]
    _success("IG Business Account ID", ig_user_id)

    _env_block([
        ("IG_USER_ID", ig_user_id),
        ("META_PAGE_ACCESS_TOKEN", page_access_token),
    ])

    print(textwrap.dedent("""
  Note: The Page access token above does NOT expire as long as it was
  generated from a long-lived user token. Store it securely in backend/.env
  and do not commit it to version control.
    """))


# ── utilities ─────────────────────────────────────────────────────────────────

def _open_browser(url: str) -> None:
    try:
        webbrowser.open(url)
    except Exception:
        pass


def _raise_for_status(resp, context: str) -> None:
    if not resp.ok:
        print(f"\n  ❌  API error during: {context}")
        print(f"      Status: {resp.status_code}")
        try:
            print(f"      Body:   {resp.json()}")
        except Exception:
            print(f"      Body:   {resp.text}")
        sys.exit(1)


def _die(message: str) -> None:
    print(f"\n  ❌  {message}\n")
    sys.exit(1)


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Meta token helper for Lorescape social publisher",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""
        Examples:
          python scripts/meta_token_helper.py --platform instagram
        """),
    )
    parser.add_argument(
        "--platform",
        choices=["instagram"],
        required=True,
        help="Which platform to set up",
    )
    args = parser.parse_args()

    if args.platform == "instagram":
        instagram_flow()


if __name__ == "__main__":
    main()
