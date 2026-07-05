"""Standalone social publisher daemon (runs as its own container).

Decouples Instagram publishing from the API server: the `publisher`
service in backend/docker-compose.yml runs this module as its main
process, while the api container keeps only the generate and reconcile
jobs. Daily jobs (Asia/Taipei):

    21:00 — carousel: read Discord reactions, publish the approved story
    21:10 — reel: read the reel review message's reactions (independent
            of the carousel review) and publish the day's video from
            DAILY_VIDEO_DIR; an unreacted review stays pending
    23:10 — reel final pass: publishes a late ✅ (or a late upload) and
            marks a still-unreacted review as skipped; idempotent via
            the social_posts table

`DAILY_STORY_PUBLISH_ENABLED=0` pauses all three jobs (the process stays
up so the container doesn't restart-loop).

Manual CLIs for back-fill / debugging:
- `python -m lorescape_backend.social.publisher [YYYY-MM-DD]`
- `python -m lorescape_backend.social.reel_publisher [YYYY-MM-DD] [--dry-run]`
"""
from __future__ import annotations

import logging
from datetime import date

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger

from lorescape_backend.config import Config
from lorescape_backend.social.publisher import run_publish_job
from lorescape_backend.social.reel_publisher import run_reel_publish_job

logger = logging.getLogger(__name__)

CAROUSEL_JOB_ID = "social_publish_carousel"
REEL_JOB_ID = "social_publish_reel"
REEL_RETRY_JOB_ID = "social_publish_reel_retry"
SCHEDULER_TIMEZONE = "Asia/Taipei"
CAROUSEL_HOUR = 21
CAROUSEL_MINUTE = 0
REEL_HOUR = 21
REEL_MINUTE = 10
REEL_RETRY_HOUR = 23
REEL_RETRY_MINUTE = 10


def _register_jobs(scheduler, config: Config) -> None:
    """Register the carousel and reel publish jobs on the scheduler."""
    if not config.daily_story_publish_enabled:
        logger.warning(
            "social publish paused — no jobs scheduled "
            "(DAILY_STORY_PUBLISH_ENABLED is off)"
        )
        return

    def _carousel() -> None:
        run_publish_job(config, date.today())

    def _reel() -> None:
        run_reel_publish_job(config, date.today())

    def _reel_final() -> None:
        run_reel_publish_job(config, date.today(), final_pass=True)

    scheduler.add_job(
        _carousel,
        trigger=CronTrigger(hour=CAROUSEL_HOUR, minute=CAROUSEL_MINUTE),
        id=CAROUSEL_JOB_ID,
        replace_existing=True,
    )
    scheduler.add_job(
        _reel,
        trigger=CronTrigger(hour=REEL_HOUR, minute=REEL_MINUTE),
        id=REEL_JOB_ID,
        replace_existing=True,
    )
    scheduler.add_job(
        _reel_final,
        trigger=CronTrigger(hour=REEL_RETRY_HOUR, minute=REEL_RETRY_MINUTE),
        id=REEL_RETRY_JOB_ID,
        replace_existing=True,
    )
    if not config.daily_video_dir:
        logger.warning(
            "DAILY_VIDEO_DIR not set — reel jobs will no-op until it is "
            "configured"
        )


def main() -> None:
    """Entrypoint: block forever running the publish schedule."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    config = Config.from_env()
    scheduler = BlockingScheduler(timezone=SCHEDULER_TIMEZONE)
    _register_jobs(scheduler, config)
    logger.info(
        "publisher daemon up — %d job(s) scheduled", len(scheduler.get_jobs())
    )
    scheduler.start()


if __name__ == "__main__":
    main()
