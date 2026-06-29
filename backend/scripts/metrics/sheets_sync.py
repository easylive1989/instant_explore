"""Mirror the accumulated daily metrics CSVs into a Google Sheet.

Reads the four datasets under ``docs/metrics/daily/`` and writes each one
to a same-named tab (``gsc``, ``ga4``, ``ig``, ``ig_posts``) in a target
spreadsheet, overwriting that tab's contents. Other tabs (e.g. the user's
own analysis sheets) are left untouched.

Authentication reuses the metrics service account configured in
``backend/.env`` via ``GOOGLE_APPLICATION_CREDENTIALS``; the spreadsheet
must be shared with that service account's email as an editor.

Usage::

    cd backend && uv run python -m scripts.metrics.sheets_sync \
        --sheet-url 'https://docs.google.com/spreadsheets/d/<id>/edit'

The spreadsheet may instead be given as ``--sheet-id <id>`` or via the
``METRICS_SHEET_ID`` environment variable.
"""
from __future__ import annotations

import argparse
import os
import re

from dotenv import load_dotenv
from google.oauth2 import service_account
from googleapiclient.discovery import build

from scripts.metrics._common import daily_dir, read_daily_csv

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
SOURCES = ["gsc", "ga4", "ig", "ig_posts"]


def parse_sheet_id(value: str) -> str:
    """Extract a spreadsheet id from a full URL or return it unchanged."""
    match = re.search(r"/spreadsheets/d/([a-zA-Z0-9-_]+)", value)
    return match.group(1) if match else value


def resolve_sheet_id(args: argparse.Namespace) -> str:
    """Resolve the target spreadsheet id from args or environment."""
    raw = args.sheet_id or args.sheet_url or os.environ.get("METRICS_SHEET_ID")
    if not raw:
        raise SystemExit(
            "No spreadsheet given. Pass --sheet-url/--sheet-id or set "
            "METRICS_SHEET_ID in backend/.env."
        )
    return parse_sheet_id(raw)


def build_service():
    """Build the Sheets API client from the metrics service account."""
    creds_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not creds_path or not os.path.exists(creds_path):
        raise SystemExit(
            "GOOGLE_APPLICATION_CREDENTIALS is not set or the file is "
            "missing; see docs/init/metrics-setup.md."
        )
    creds = service_account.Credentials.from_service_account_file(
        creds_path, scopes=SCOPES
    )
    return build("sheets", "v4", credentials=creds, cache_discovery=False)


def existing_tabs(service, sheet_id: str) -> set[str]:
    """Return the set of tab titles already present in the spreadsheet."""
    meta = service.spreadsheets().get(spreadsheetId=sheet_id).execute()
    return {s["properties"]["title"] for s in meta.get("sheets", [])}


def ensure_tab(service, sheet_id: str, title: str, present: set[str]) -> None:
    """Create a tab if it is not already present."""
    if title in present:
        return
    service.spreadsheets().batchUpdate(
        spreadsheetId=sheet_id,
        body={"requests": [{"addSheet": {"properties": {"title": title}}}]},
    ).execute()
    present.add(title)


def write_tab(service, sheet_id: str, title: str, values: list[list[str]]) -> None:
    """Overwrite a tab with the given rows (headers first)."""
    service.spreadsheets().values().clear(
        spreadsheetId=sheet_id, range=f"'{title}'"
    ).execute()
    service.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range=f"'{title}'!A1",
        valueInputOption="RAW",
        body={"values": values},
    ).execute()


def sync(service, sheet_id: str, sources: list[str]) -> None:
    """Mirror each source CSV into its same-named tab."""
    present = existing_tabs(service, sheet_id)
    for source in sources:
        headers, rows = read_daily_csv(daily_dir() / f"{source}.csv")
        if not headers:
            print(f"{source}: skipped (no data file)")
            continue
        ensure_tab(service, sheet_id, source, present)
        write_tab(service, sheet_id, source, [headers, *rows])
        print(f"{source}: wrote {len(rows)} row(s) to tab '{source}'")


def main() -> None:
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sheet-url", help="Full Google Sheet URL.")
    parser.add_argument("--sheet-id", help="Spreadsheet id (overrides URL).")
    parser.add_argument(
        "--only",
        help="Comma-separated subset of sources to sync (default: all).",
    )
    args = parser.parse_args()

    sheet_id = resolve_sheet_id(args)
    sources = args.only.split(",") if args.only else SOURCES
    unknown = [s for s in sources if s not in SOURCES]
    if unknown:
        raise SystemExit(f"Unknown source(s): {', '.join(unknown)}")

    service = build_service()
    sync(service, sheet_id, sources)


if __name__ == "__main__":
    main()
