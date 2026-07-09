"""FastAPI app for the Lorescape backend.

Hosts:
- `/health` endpoint (placeholder for monitoring)
- An APScheduler with daily jobs at Asia/Taipei:
    08:00 — generate today's story and post it to Discord for review
    03:00 — reconcile subscriptions against RevenueCat

The Instagram publish flow (review reactions + on-demand publish) lives
in the separate `publisher` container (`lorescape_backend.social.publisher_bot`,
a Discord Gateway bot), not here.

Manual CLI (preserved for back-fill / debugging):
- `python -m lorescape_backend.daily_story [YYYY-MM-DD]`
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from datetime import date

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from fastapi import FastAPI

from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import run_generate_and_review
from lorescape_backend.narration.routes import router as narration_router
from lorescape_backend.subscriptions.reconcile import run_reconcile_job
from lorescape_backend.subscriptions.routes import router as subscriptions_router

logger = logging.getLogger(__name__)

GENERATE_JOB_ID = "daily_story_generate"
RECONCILE_JOB_ID = "subscription_reconcile"
SCHEDULER_TIMEZONE = "Asia/Taipei"
GENERATE_HOUR = 8
RECONCILE_HOUR = 3


def _register_jobs(scheduler: BackgroundScheduler, config: Config) -> None:
    """Register the generate and reconcile jobs on the scheduler."""

    def _generate() -> None:
        run_generate_and_review(config, date.today())

    def _reconcile() -> None:
        run_reconcile_job(config)

    if config.daily_story_generate_enabled:
        scheduler.add_job(
            _generate,
            trigger=CronTrigger(hour=GENERATE_HOUR, minute=0),
            id=GENERATE_JOB_ID,
            replace_existing=True,
        )
    else:
        logger.warning(
            "daily_story.generate paused — 09:00 generate job not scheduled "
            "(DAILY_STORY_GENERATE_ENABLED is off)"
        )
    if config.revenuecat_reconcile_enabled:
        scheduler.add_job(
            _reconcile,
            trigger=CronTrigger(hour=RECONCILE_HOUR, minute=0),
            id=RECONCILE_JOB_ID,
            replace_existing=True,
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config.from_env()
    scheduler = BackgroundScheduler(timezone=SCHEDULER_TIMEZONE)
    _register_jobs(scheduler, config)
    scheduler.start()
    try:
        yield
    finally:
        scheduler.shutdown()


app = FastAPI(title="Lorescape Backend", version="0.1.0", lifespan=lifespan)
app.include_router(narration_router)
app.include_router(subscriptions_router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
