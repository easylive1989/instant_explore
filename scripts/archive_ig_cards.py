"""Archive a month of published IG card images out of Supabase Storage.

Downloads every `ig-cards` object for the given month (default: last
month) to marketing/outputs/ig_cards_archive/<YYYY-MM>/, preserving the
bucket-relative path, then deletes the bucket objects. Both layouts are
covered: the default style's top-level `<date>/…` and the wander style's
`wander/<date>/…`. Any download failure aborts BEFORE deleting anything,
so re-running is always safe. Instagram keeps its own copy of published
media — the bucket objects are only needed until publish.

After it finishes, back the archive folder up (e.g. Google Drive) at your
leisure; it is plain files on disk.

Run from scripts/:

    uv run python -m archive_ig_cards             # last month
    uv run python -m archive_ig_cards 2026-06
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config

REPO_ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_DIR = REPO_ROOT / "marketing" / "outputs" / "ig_cards_archive"
BUCKET_NAME = "ig-cards"


def _last_month(today: date | None = None) -> str:
    if today is None:
        today = date.today()
    year, month = (today.year, today.month - 1) if today.month > 1 \
        else (today.year - 1, 12)
    return f"{year:04d}-{month:02d}"


def _month_object_paths(bucket, month: str) -> list[str]:
    """Bucket-relative paths of every object belonging to `month`."""
    paths: list[str] = []
    for entry in bucket.list(""):
        name = entry["name"]
        if name.startswith(month):                      # 2026-06-05/...
            paths.extend(
                f"{name}/{child['name']}" for child in bucket.list(name)
            )
        elif name == "wander":                          # wander/2026-06-06/...
            for day in bucket.list("wander"):
                if day["name"].startswith(month):
                    prefix = f"wander/{day['name']}"
                    paths.extend(
                        f"{prefix}/{child['name']}"
                        for child in bucket.list(prefix)
                    )
    return paths


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "backend" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "month", nargs="?", default=_last_month(),
        help="Month to archive, YYYY-MM (default: last month)",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    bucket = supabase.storage.from_(BUCKET_NAME)

    paths = _month_object_paths(bucket, args.month)
    if not paths:
        print(f"no ig-cards objects for {args.month}; nothing to archive")
        return 0

    month_dir = ARCHIVE_DIR / args.month
    try:
        for path in paths:
            data = bucket.download(path)
            target = month_dir / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            print(f"archived {path} ({len(data)} bytes)")
    except Exception as exc:  # noqa: BLE001 — abort keeps bucket intact
        print(
            f"download failed ({exc}); aborting WITHOUT deleting anything",
            file=sys.stderr,
        )
        return 1

    bucket.remove(paths)
    print(
        f"done: {len(paths)} objects archived to {month_dir} and removed "
        f"from the bucket — back the folder up to Google Drive when ready."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
