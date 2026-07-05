"""publisher_daemon scheduler-wiring tests."""
from __future__ import annotations

import dataclasses
from datetime import date
from unittest.mock import MagicMock, patch

from apscheduler.triggers.cron import CronTrigger

from lorescape_backend.social.publisher_daemon import (
    CAROUSEL_HOUR,
    CAROUSEL_JOB_ID,
    CAROUSEL_MINUTE,
    REEL_HOUR,
    REEL_JOB_ID,
    REEL_MINUTE,
    REEL_RETRY_HOUR,
    REEL_RETRY_JOB_ID,
    REEL_RETRY_MINUTE,
    _register_jobs,
)


def _trigger_fields(call):
    trigger = call.kwargs["trigger"]
    assert isinstance(trigger, CronTrigger)
    return {field.name: str(field) for field in trigger.fields}


def test_register_jobs_schedules_carousel_and_reels(fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    calls_by_id = {
        call.kwargs["id"]: call for call in scheduler.add_job.call_args_list
    }
    assert set(calls_by_id) == {
        CAROUSEL_JOB_ID, REEL_JOB_ID, REEL_RETRY_JOB_ID,
    }

    carousel = _trigger_fields(calls_by_id[CAROUSEL_JOB_ID])
    assert carousel["hour"] == str(CAROUSEL_HOUR)
    assert carousel["minute"] == str(CAROUSEL_MINUTE)

    reel = _trigger_fields(calls_by_id[REEL_JOB_ID])
    assert reel["hour"] == str(REEL_HOUR)
    assert reel["minute"] == str(REEL_MINUTE)

    retry = _trigger_fields(calls_by_id[REEL_RETRY_JOB_ID])
    assert retry["hour"] == str(REEL_RETRY_HOUR)
    assert retry["minute"] == str(REEL_RETRY_MINUTE)


def test_register_jobs_skips_all_when_publish_disabled(fake_config):
    config = dataclasses.replace(
        fake_config, daily_story_publish_enabled=False
    )
    scheduler = MagicMock()
    _register_jobs(scheduler, config)

    scheduler.add_job.assert_not_called()


@patch("lorescape_backend.social.publisher_daemon.run_publish_job")
def test_carousel_job_runs_for_today(mock_run, fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    call = next(
        c for c in scheduler.add_job.call_args_list
        if c.kwargs["id"] == CAROUSEL_JOB_ID
    )
    call.args[0]()

    mock_run.assert_called_once()
    args = mock_run.call_args.args
    assert args[0] is fake_config
    assert args[1] == date.today()


@patch("lorescape_backend.social.publisher_daemon.run_reel_publish_job")
def test_reel_jobs_run_for_today(mock_run, fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    for job_id in (REEL_JOB_ID, REEL_RETRY_JOB_ID):
        call = next(
            c for c in scheduler.add_job.call_args_list
            if c.kwargs["id"] == job_id
        )
        call.args[0]()

    assert mock_run.call_count == 2
    for run_call in mock_run.call_args_list:
        assert run_call.args[0] is fake_config
        assert run_call.args[1] == date.today()
