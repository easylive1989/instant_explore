"""Tests for the manual daily-story publish → IG review hand-off."""
from __future__ import annotations

import dataclasses
import subprocess
from datetime import date
from unittest.mock import MagicMock, patch

from manual_daily_story import _send_for_ig_review, _trigger_landing_deploy

_DATE = date(2026, 6, 18)


def _supabase_returning(message_id):
    """A supabase double whose zh-TW row carries this discord_message_id."""
    supabase = MagicMock()
    execute = supabase.table.return_value.select.return_value.eq.return_value
    execute = execute.eq.return_value.limit.return_value.execute
    execute.return_value.data = [{"discord_message_id": message_id}]
    return supabase


def test_skips_hand_off_when_review_not_configured(fake_config, capsys):
    config = dataclasses.replace(fake_config, discord_bot_token=None)
    supabase = MagicMock()

    with patch("manual_daily_story.job.send_today_for_review") as send:
        _send_for_ig_review(config, supabase, _DATE)

    send.assert_not_called()
    assert "won't auto-post to Instagram" in capsys.readouterr().out


def test_posts_card_and_reports_message_id(fake_config, capsys):
    supabase = _supabase_returning("msg-123")

    with patch("manual_daily_story.job.send_today_for_review") as send:
        _send_for_ig_review(fake_config, supabase, _DATE)

    send.assert_called_once_with(fake_config, _DATE)
    out = capsys.readouterr().out
    assert "message_id=msg-123" in out
    assert "21:00 publish job" in out


def test_warns_when_no_card_posted(fake_config, capsys):
    supabase = _supabase_returning(None)

    with patch("manual_daily_story.job.send_today_for_review"):
        _send_for_ig_review(fake_config, supabase, _DATE)

    assert "posted nothing" in capsys.readouterr().out


def test_best_effort_on_send_failure(fake_config, capsys):
    supabase = MagicMock()

    with patch(
        "manual_daily_story.job.send_today_for_review",
        side_effect=RuntimeError("discord down"),
    ):
        _send_for_ig_review(fake_config, supabase, _DATE)

    out = capsys.readouterr().out
    assert "IG review hand-off failed" in out
    assert "discord down" in out


def test_trigger_landing_deploy_runs_gh_workflow(capsys):
    with patch("manual_daily_story.subprocess.run") as run:
        _trigger_landing_deploy()

    run.assert_called_once_with(
        ["gh", "workflow", "run", "deploy-landing.yml", "--ref", "master"],
        check=True,
        capture_output=True,
        text=True,
    )
    assert "Triggered landing deploy" in capsys.readouterr().out


def test_trigger_landing_deploy_skips_when_gh_missing(capsys):
    with patch("manual_daily_story.subprocess.run", side_effect=FileNotFoundError):
        _trigger_landing_deploy()  # must not raise

    assert "gh CLI not found" in capsys.readouterr().out


def test_trigger_landing_deploy_warns_on_failure(capsys):
    error = subprocess.CalledProcessError(1, "gh", stderr="boom")
    with patch("manual_daily_story.subprocess.run", side_effect=error):
        _trigger_landing_deploy()  # must not raise

    out = capsys.readouterr().out
    assert "landing deploy trigger failed" in out
    assert "boom" in out
