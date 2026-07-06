"""archive_ig_cards — 下載整月 ig-cards 物件到本機後刪 bucket 端."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

import pytest

import archive_ig_cards as mod


def _entry(name: str) -> dict:
    return {"name": name}


@pytest.fixture
def bucket(tmp_path, monkeypatch):
    monkeypatch.setattr(mod, "ARCHIVE_DIR", tmp_path)
    bucket = MagicMock()

    # bucket.list(prefix)：頂層列日期夾與 wander 夾；夾內列檔案
    def list_side_effect(prefix=""):
        listing = {
            "": [_entry("2026-06-05"), _entry("2026-07-01"),
                 _entry("wander")],
            "wander": [_entry("2026-06-06")],
            "2026-06-05": [_entry("a-0.png"), _entry("a-1.png")],
            "wander/2026-06-06": [_entry("slide_01.jpg")],
        }
        return listing.get(prefix, [])

    bucket.list.side_effect = list_side_effect
    bucket.download.side_effect = lambda path: b"data:" + path.encode()

    supabase = MagicMock()
    supabase.storage.from_.return_value = bucket
    with (
        patch.object(mod, "load_dotenv"),
        patch.object(mod.Config, "from_env", return_value=MagicMock()),
        patch.object(mod, "create_client", return_value=supabase),
    ):
        yield bucket


def test_archives_and_deletes_only_target_month(bucket, tmp_path):
    assert mod.main(["2026-06"]) == 0

    downloaded = sorted(
        p.relative_to(tmp_path).as_posix()
        for p in tmp_path.rglob("*") if p.is_file()
    )
    assert downloaded == [
        "2026-06/2026-06-05/a-0.png",
        "2026-06/2026-06-05/a-1.png",
        "2026-06/wander/2026-06-06/slide_01.jpg",
    ]
    removed = bucket.remove.call_args.args[0]
    assert sorted(removed) == [
        "2026-06-05/a-0.png",
        "2026-06-05/a-1.png",
        "wander/2026-06-06/slide_01.jpg",
    ]


def test_download_failure_aborts_without_deleting(bucket):
    bucket.download.side_effect = RuntimeError("net down")
    assert mod.main(["2026-06"]) == 1
    bucket.remove.assert_not_called()


def test_month_with_no_objects_is_a_noop(bucket):
    assert mod.main(["2026-01"]) == 0
    bucket.remove.assert_not_called()


def test_last_month_mid_year():
    assert mod._last_month(date(2026, 7, 6)) == "2026-06"


def test_last_month_january_rolls_to_previous_december():
    assert mod._last_month(date(2026, 1, 15)) == "2025-12"
