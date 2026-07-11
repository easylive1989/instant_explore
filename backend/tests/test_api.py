"""Tests for the FastAPI app + in-container scheduler wiring.

The daily-story pipeline and Instagram publishing live in the standalone
publisher project (lorescape_publisher); the api scheduler only carries the
subscription reconcile job.
"""
from __future__ import annotations

import dataclasses
from unittest.mock import MagicMock

from apscheduler.triggers.cron import CronTrigger

from lorescape_backend.api import (
    RECONCILE_HOUR,
    RECONCILE_JOB_ID,
    _register_jobs,
    health,
)


def test_health_returns_ok():
    assert health() == {"status": "ok"}


def test_register_jobs_schedules_only_reconcile(fake_config):
    # fake_config carries a REVENUECAT_API_KEY, so reconcile is scheduled.
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    calls_by_id = {
        call.kwargs["id"]: call for call in scheduler.add_job.call_args_list
    }
    assert set(calls_by_id) == {RECONCILE_JOB_ID}
    trigger = calls_by_id[RECONCILE_JOB_ID].kwargs["trigger"]
    assert isinstance(trigger, CronTrigger)
    fields = {field.name: str(field) for field in trigger.fields}
    assert fields["hour"] == str(RECONCILE_HOUR)
    assert fields["minute"] == "0"
    assert calls_by_id[RECONCILE_JOB_ID].kwargs["replace_existing"] is True


def test_register_jobs_skips_reconcile_when_revenuecat_disabled(fake_config):
    config = dataclasses.replace(fake_config, revenuecat_api_key=None)
    scheduler = MagicMock()
    _register_jobs(scheduler, config)

    assert scheduler.add_job.call_args_list == []
