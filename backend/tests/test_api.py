"""Tests for the FastAPI app + in-container scheduler wiring."""
from __future__ import annotations

from datetime import date, timedelta
from unittest.mock import MagicMock, patch

from apscheduler.triggers.cron import CronTrigger

from lorescape_backend.api import (
    DAILY_STORY_JOB_ID,
    JOB_HOUR,
    JOB_MINUTE,
    _register_daily_job,
    health,
)


def test_health_returns_ok():
    assert health() == {"status": "ok"}


def test_register_daily_job_schedules_at_2330(fake_config):
    scheduler = MagicMock()
    _register_daily_job(scheduler, fake_config)

    scheduler.add_job.assert_called_once()
    call = scheduler.add_job.call_args
    trigger = call.kwargs["trigger"]
    assert isinstance(trigger, CronTrigger)
    fields = {field.name: str(field) for field in trigger.fields}
    assert fields["hour"] == str(JOB_HOUR)
    assert fields["minute"] == str(JOB_MINUTE)
    assert call.kwargs["id"] == DAILY_STORY_JOB_ID
    assert call.kwargs["replace_existing"] is True


@patch("lorescape_backend.api.run_with_retry")
def test_register_daily_job_callable_runs_for_tomorrow(mock_run, fake_config):
    scheduler = MagicMock()
    _register_daily_job(scheduler, fake_config)

    # Capture the function passed as the first positional arg to add_job
    job_func = scheduler.add_job.call_args.args[0]
    job_func()

    mock_run.assert_called_once()
    args = mock_run.call_args.args
    assert args[0] is fake_config
    assert args[1] == date.today() + timedelta(days=1)
