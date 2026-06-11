"""Tests for the FastAPI app + in-container scheduler wiring."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

from apscheduler.triggers.cron import CronTrigger

import dataclasses

from lorescape_backend.api import (
    GENERATE_HOUR,
    GENERATE_JOB_ID,
    PUBLISH_HOUR,
    PUBLISH_JOB_ID,
    RECONCILE_HOUR,
    RECONCILE_JOB_ID,
    _register_jobs,
    health,
)


def test_health_returns_ok():
    assert health() == {"status": "ok"}


def test_register_jobs_schedules_generate_and_publish(fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    calls_by_id = {
        call.kwargs["id"]: call for call in scheduler.add_job.call_args_list
    }

    gen_call = calls_by_id[GENERATE_JOB_ID]
    gen_trigger = gen_call.kwargs["trigger"]
    assert isinstance(gen_trigger, CronTrigger)
    gen_fields = {field.name: str(field) for field in gen_trigger.fields}
    assert gen_fields["hour"] == str(GENERATE_HOUR)
    assert gen_fields["minute"] == "0"
    assert gen_call.kwargs["replace_existing"] is True

    pub_call = calls_by_id[PUBLISH_JOB_ID]
    pub_trigger = pub_call.kwargs["trigger"]
    assert isinstance(pub_trigger, CronTrigger)
    pub_fields = {field.name: str(field) for field in pub_trigger.fields}
    assert pub_fields["hour"] == str(PUBLISH_HOUR)
    assert pub_fields["minute"] == "0"
    assert pub_call.kwargs["replace_existing"] is True


def test_register_jobs_schedules_reconcile_when_revenuecat_enabled(fake_config):
    # fake_config carries a REVENUECAT_API_KEY, so reconcile is scheduled.
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    calls_by_id = {
        call.kwargs["id"]: call for call in scheduler.add_job.call_args_list
    }
    assert RECONCILE_JOB_ID in calls_by_id
    trigger = calls_by_id[RECONCILE_JOB_ID].kwargs["trigger"]
    fields = {field.name: str(field) for field in trigger.fields}
    assert fields["hour"] == str(RECONCILE_HOUR)


def test_register_jobs_skips_reconcile_when_revenuecat_disabled(fake_config):
    config = dataclasses.replace(fake_config, revenuecat_api_key=None)
    scheduler = MagicMock()
    _register_jobs(scheduler, config)

    ids = {call.kwargs["id"] for call in scheduler.add_job.call_args_list}
    assert ids == {GENERATE_JOB_ID, PUBLISH_JOB_ID}


@patch("lorescape_backend.api.run_generate_and_review")
def test_generate_job_runs_for_today(mock_run, fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    gen_call = next(
        call for call in scheduler.add_job.call_args_list
        if call.kwargs["id"] == GENERATE_JOB_ID
    )
    gen_call.args[0]()

    mock_run.assert_called_once()
    args = mock_run.call_args.args
    assert args[0] is fake_config
    assert args[1] == date.today()


@patch("lorescape_backend.api.run_publish_job")
def test_publish_job_runs_for_today(mock_run, fake_config):
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    pub_call = next(
        call for call in scheduler.add_job.call_args_list
        if call.kwargs["id"] == PUBLISH_JOB_ID
    )
    pub_call.args[0]()

    mock_run.assert_called_once()
    args = mock_run.call_args.args
    assert args[0] is fake_config
    assert args[1] == date.today()


def test_register_jobs_skips_story_jobs_when_daily_story_disabled(fake_config):
    config = dataclasses.replace(fake_config, daily_story_enabled=False)
    scheduler = MagicMock()
    _register_jobs(scheduler, config)

    ids = {call.kwargs["id"] for call in scheduler.add_job.call_args_list}
    assert GENERATE_JOB_ID not in ids
    assert PUBLISH_JOB_ID not in ids
    assert ids == {RECONCILE_JOB_ID}  # reconcile unaffected
