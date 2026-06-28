#!/usr/bin/env python3
"""Upload files to Google Drive.

Supports authentication via:
1. Google Application Default Credentials (ADC) - default fallback.
2. A default 'service-account.json' file in the project root or backend root.
3. A specific Google Service Account JSON file path.

Usage:
    python scripts/upload_to_drive.py <file_path> [--credentials <credentials_path>]

Requires Google Drive API enabled in your Google Cloud Project.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Any


def get_credentials(credentials_path: str | None = None) -> Any:
    """Obtain credentials for Google Drive API.

    Supports:
    1. Explicit service account JSON file path.
    2. Default service-account.json in the project root or backend root.
    3. Fallback to GOOGLE_APPLICATION_CREDENTIALS environment variable.
    4. Standard Application Default Credentials (ADC).
    """
    import google.auth
    from google.oauth2 import service_account

    # Google Drive scopes:
    # - https://www.googleapis.com/auth/drive (Full control)
    # - https://www.googleapis.com/auth/drive.file (Access to files created/opened by this app)
    scopes = [
        "https://www.googleapis.com/auth/drive",
        "https://www.googleapis.com/auth/drive.file",
    ]

    # 1. Explicit credentials path
    if credentials_path:
        path = Path(credentials_path)
        if not path.exists():
            print(
                f"ERROR: Credentials file not found at: {credentials_path}",
                file=sys.stderr,
            )
            sys.exit(1)
        print(f"Loading credentials from: {path}", file=sys.stderr)
        return service_account.Credentials.from_service_account_file(
            str(path), scopes=scopes
        )

    # 2. Default service-account.json in project root or backend root
    project_root = Path(__file__).resolve().parents[1]

    project_root_creds = project_root / "service-account.json"
    if project_root_creds.exists():
        print(
            f"Loading default credentials from project root: {project_root_creds}",
            file=sys.stderr,
        )
        return service_account.Credentials.from_service_account_file(
            str(project_root_creds), scopes=scopes
        )

    backend_root_creds = project_root / "backend" / "service-account.json"
    if backend_root_creds.exists():
        print(
            f"Loading default credentials from backend root: {backend_root_creds}",
            file=sys.stderr,
        )
        return service_account.Credentials.from_service_account_file(
            str(backend_root_creds), scopes=scopes
        )

    # 3. Fallback to GOOGLE_APPLICATION_CREDENTIALS env var
    env_creds_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if env_creds_path:
        path = Path(env_creds_path)
        if path.exists():
            print(
                f"Loading credentials from GOOGLE_APPLICATION_CREDENTIALS: {path}",
                file=sys.stderr,
            )
            return service_account.Credentials.from_service_account_file(
                str(path), scopes=scopes
            )
        else:
            print(
                f"WARNING: GOOGLE_APPLICATION_CREDENTIALS is set but file not found: {env_creds_path}",
                file=sys.stderr,
            )

    # 4. Fallback to Application Default Credentials
    print("Using Application Default Credentials (ADC)...", file=sys.stderr)
    try:
        creds, _ = google.auth.default(scopes=scopes)
        return creds
    except google.auth.exceptions.DefaultCredentialsError as exc:
        print(
            f"ERROR: Failed to resolve default credentials.\n"
            f"Detail: {exc}\n\n"
            f"Please configure credentials by doing one of the following:\n"
            f"1. Run: gcloud auth application-default login\n"
            f"2. Set the GOOGLE_APPLICATION_CREDENTIALS environment variable to a service account JSON file.\n"
            f"3. Pass the JSON file using the --credentials parameter.",
            file=sys.stderr,
        )
        sys.exit(1)


def upload_file_to_drive(
    file_path: Path,
    creds: Any,
    folder_id: str | None = None,
    name: str | None = None,
    mime_type: str | None = None,
) -> dict[str, Any]:
    """Uploads a file to Google Drive.

    Returns the response dictionary containing 'id', 'name', and 'webViewLink'.
    """
    import mimetypes
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    # Guess MIME type if not specified
    if not mime_type:
        mime_type, _ = mimetypes.guess_type(str(file_path))
        if not mime_type:
            mime_type = "application/octet-stream"

    # Construct file metadata
    file_metadata: dict[str, Any] = {
        "name": name or file_path.name,
    }
    if folder_id:
        file_metadata["parents"] = [folder_id]

    print(f"Uploading file to Google Drive: {file_path}", file=sys.stderr)
    print(f"Detected MIME type: {mime_type}", file=sys.stderr)
    if folder_id:
        print(f"Target Folder ID: {folder_id}", file=sys.stderr)

    # Initialize Drive service
    service = build("drive", "v3", credentials=creds, cache_discovery=False)

    # Prepare media upload
    media = MediaFileUpload(
        str(file_path),
        mimetype=mime_type,
        resumable=True,
    )

    # Execute upload
    file = (
        service.files()
        .create(
            body=file_metadata,
            media_body=media,
            fields="id, name, webViewLink",
        )
        .execute()
    )

    return file


def main() -> None:
    parser = argparse.ArgumentParser(description="Upload files to Google Drive.")
    parser.add_argument(
        "file_path",
        help="Path to the local file to upload.",
    )
    parser.add_argument(
        "--folder-id",
        help="Google Drive target folder ID.",
    )
    parser.add_argument(
        "--name",
        help="Custom name for the uploaded file on Google Drive.",
    )
    parser.add_argument(
        "--mime-type",
        help="Explicitly specify the MIME type of the file.",
    )
    parser.add_argument(
        "--credentials",
        help="Path to Google service account credentials JSON file.",
    )
    args = parser.parse_args()

    # Verify local file exists
    local_file = Path(args.file_path)
    if not local_file.exists() or not local_file.is_file():
        print(
            f"ERROR: Local file does not exist or is not a file: {args.file_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    # Initialize credentials
    print("Initializing credentials...", file=sys.stderr)
    creds = get_credentials(args.credentials)

    try:
        file = upload_file_to_drive(
            local_file,
            creds,
            folder_id=args.folder_id,
            name=args.name,
            mime_type=args.mime_type,
        )
        print("\n=== Upload Successful ===")
        print(f"File Name: {file.get('name')}")
        print(f"File ID: {file.get('id')}")
        print(f"Web View Link: {file.get('webViewLink')}")
    except Exception as exc:
        print(f"ERROR: Failed to upload file: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
