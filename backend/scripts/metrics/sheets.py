"""Google Sheets API client for the metrics datasets.

Wraps a single spreadsheet and exposes per-tab read/overwrite, reusing the
metrics service account configured via ``GOOGLE_APPLICATION_CREDENTIALS``.
The spreadsheet must be shared with that service account as an editor.
"""
from __future__ import annotations

import os

from google.oauth2 import service_account
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]


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


class SheetClient:
    """Per-tab access to one spreadsheet, with a cached tab-title list."""

    def __init__(self, sheet_id: str, service=None) -> None:
        self.sheet_id = sheet_id
        self._service = service
        self._titles: set[str] | None = None

    @property
    def service(self):
        """Lazily build the API client so construction stays offline."""
        if self._service is None:
            self._service = build_service()
        return self._service

    def _sheets(self):
        return self.service.spreadsheets()

    def titles(self) -> set[str]:
        """Return the spreadsheet's tab titles, cached after first read."""
        if self._titles is None:
            meta = self._sheets().get(spreadsheetId=self.sheet_id).execute()
            self._titles = {
                s["properties"]["title"] for s in meta.get("sheets", [])
            }
        return self._titles

    def read_tab(self, title: str) -> list[list[str]]:
        """Return a tab's cell values (header row first), or [] if absent."""
        if title not in self.titles():
            return []
        resp = (
            self._sheets()
            .values()
            .get(spreadsheetId=self.sheet_id, range=f"'{title}'")
            .execute()
        )
        return resp.get("values", [])

    def ensure_tab(self, title: str) -> None:
        """Create a tab if it is not already present."""
        if title in self.titles():
            return
        self._sheets().batchUpdate(
            spreadsheetId=self.sheet_id,
            body={"requests": [{"addSheet": {"properties": {"title": title}}}]},
        ).execute()
        self.titles().add(title)

    def write_tab(self, title: str, values: list[list[str]]) -> None:
        """Overwrite a tab with `values` (header row first)."""
        self.ensure_tab(title)
        self._sheets().values().clear(
            spreadsheetId=self.sheet_id, range=f"'{title}'"
        ).execute()
        self._sheets().values().update(
            spreadsheetId=self.sheet_id,
            range=f"'{title}'!A1",
            valueInputOption="RAW",
            body={"values": values},
        ).execute()
