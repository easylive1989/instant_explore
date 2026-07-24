"""Production logging setup for the backend.

FastAPI/uvicorn does not configure the root logger for our own loggers, so by
default every ``logger.info(...)`` in this codebase is dropped (root logger
defaults to WARNING with no handler) and the structured ``extra={...}`` fields
attached throughout narration/sources/subscriptions are never rendered.

``setup_logging()`` installs a single stdout handler with a JSON formatter that
emits those extra fields, and is called once from the app lifespan.
"""
from __future__ import annotations

import json
import logging
import os
from logging.config import dictConfig

# Attributes present on every ``logging.LogRecord``. Anything on a record that
# is not in this set was passed by the caller via ``extra={...}`` and is what we
# want to surface as structured fields.
_RESERVED_RECORD_ATTRS = frozenset(
    logging.makeLogRecord({}).__dict__.keys()
) | {"message", "asctime", "taskName"}


class JsonFormatter(logging.Formatter):
    """Render a log record as a single-line JSON object, including extras."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }
        for key, value in record.__dict__.items():
            if key not in _RESERVED_RECORD_ATTRS and not key.startswith("_"):
                payload[key] = value
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False, default=str)


def setup_logging(level: str | None = None) -> None:
    """Configure the root logger with a JSON stdout handler.

    Level comes from the ``LOG_LEVEL`` env var (default ``INFO``); pass
    ``level`` to override explicitly (used in tests).
    """
    resolved = (level or os.environ.get("LOG_LEVEL") or "INFO").upper()
    dictConfig(
        {
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {"json": {"()": JsonFormatter}},
            "handlers": {
                "stdout": {
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout",
                    "formatter": "json",
                }
            },
            "root": {"level": resolved, "handlers": ["stdout"]},
            # uvicorn ships its own handlers; route them through ours instead
            # of double-logging.
            "loggers": {
                "uvicorn": {"handlers": ["stdout"], "level": resolved, "propagate": False},
                "uvicorn.error": {"handlers": ["stdout"], "level": resolved, "propagate": False},
                "uvicorn.access": {"handlers": ["stdout"], "level": resolved, "propagate": False},
            },
        }
    )
