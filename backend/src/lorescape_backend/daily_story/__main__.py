"""CLI entrypoint: `python -m lorescape_backend.daily_story [YYYY-MM-DD]`.

If a date argument is given, run for that date.
Otherwise default to tomorrow (cron runs at 23:30 to publish for next day).
"""
from __future__ import annotations

import logging
import sys
from datetime import date, timedelta

from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import run_with_retry


def main(argv: list[str]) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    config = Config.from_env()

    if argv:
        target = date.fromisoformat(argv[0])
    else:
        target = date.today() + timedelta(days=1)

    run_with_retry(config, target)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
