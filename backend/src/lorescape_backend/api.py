"""FastAPI app for the Lorescape backend.

Hosts:
- `/health` endpoint (placeholder for monitoring)
- An APScheduler that runs the daily story job at 23:30 Asia/Taipei
  inside the container — no host-side cron required.

The CLI entrypoint (`python -m lorescape_backend.daily_story [YYYY-MM-DD]`)
is preserved for manual triggering / back-filling specific dates.
"""
from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import date, timedelta

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from fastapi import FastAPI

from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import run_with_retry

DAILY_STORY_JOB_ID = "daily_story"
SCHEDULER_TIMEZONE = "Asia/Taipei"
JOB_HOUR = 23
JOB_MINUTE = 30


def _register_daily_job(scheduler: BackgroundScheduler, config: Config) -> None:
    """Schedule `run_with_retry` to fire daily at 23:30 Asia/Taipei.

    Each invocation generates the story for *tomorrow* so it is visible at
    the next 00:00 to users.
    """

    def _run() -> None:
        target = date.today() + timedelta(days=1)
        run_with_retry(config, target)

    scheduler.add_job(
        _run,
        trigger=CronTrigger(hour=JOB_HOUR, minute=JOB_MINUTE),
        id=DAILY_STORY_JOB_ID,
        replace_existing=True,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    config = Config.from_env()
    scheduler = BackgroundScheduler(timezone=SCHEDULER_TIMEZONE)
    _register_daily_job(scheduler, config)
    scheduler.start()
    try:
        yield
    finally:
        scheduler.shutdown()


app = FastAPI(title="Lorescape Backend", version="0.1.0", lifespan=lifespan)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
