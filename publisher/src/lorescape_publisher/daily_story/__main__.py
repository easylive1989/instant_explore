"""CLI entrypoint: `python -m lorescape_publisher.daily_story [YYYY-MM-DD]`.

If a date argument is given, run for that date.
Otherwise default to today (cron runs at 09:00 to generate today's story).

Always runs generation + Discord review post (when configured). Review /
publish now happens via the bot: `python -m lorescape_publisher.bot`.
"""
from __future__ import annotations

import logging
import sys
from datetime import date

from lorescape_publisher.config import Config
from lorescape_publisher.daily_story.job import run_generate_and_review


def main(argv: list[str]) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    config = Config.from_env()

    target = date.fromisoformat(argv[0]) if argv else date.today()

    run_generate_and_review(config, target)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
