"""FastAPI app for the Lorescape backend.

Hosts:
- `/health` endpoint (placeholder for monitoring)
- An APScheduler with a daily job at Asia/Taipei:
    03:00 — reconcile subscriptions against RevenueCat

Daily-story generation/publishing and the Instagram publish flow (review
reactions + on-demand publish) live in the standalone publisher project
(`python -m lorescape_publisher.daily_story`, `lorescape_publisher.bot`),
not here.
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from fastapi import FastAPI

from lorescape_backend.config import Config
from lorescape_backend.logging_config import setup_logging
from lorescape_backend.narration.routes import router as narration_router
from lorescape_backend.subscriptions.reconcile import run_reconcile_job
from lorescape_backend.subscriptions.routes import router as subscriptions_router

logger = logging.getLogger(__name__)

RECONCILE_JOB_ID = "subscription_reconcile"
SCHEDULER_TIMEZONE = "Asia/Taipei"
RECONCILE_HOUR = 3


def _register_jobs(scheduler: BackgroundScheduler, config: Config) -> None:
    """Register the subscription reconcile job on the scheduler.

    Daily-story generation/publishing lives in the standalone publisher
    project (publisher/, `python -m lorescape_publisher.daily_story` /
    `python -m lorescape_publisher.bot`).
    """

    def _reconcile() -> None:
        run_reconcile_job(config)

    if config.revenuecat_reconcile_enabled:
        scheduler.add_job(
            _reconcile,
            trigger=CronTrigger(hour=RECONCILE_HOUR, minute=0),
            id=RECONCILE_JOB_ID,
            replace_existing=True,
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
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
