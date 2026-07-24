"""Tests for JSON logging setup."""
from __future__ import annotations

import json
import logging

from lorescape_backend.logging_config import JsonFormatter, setup_logging


def _format(record: logging.LogRecord) -> dict:
    return json.loads(JsonFormatter().format(record))


def test_extra_fields_are_rendered():
    record = logging.LogRecord(
        name="narration.cache",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="narration.hooks_cache.hit",
        args=(),
        exc_info=None,
    )
    record.place_key = "abc123"

    out = _format(record)

    assert out["level"] == "INFO"
    assert out["logger"] == "narration.cache"
    assert out["msg"] == "narration.hooks_cache.hit"
    assert out["place_key"] == "abc123"


def test_exception_info_is_included():
    try:
        raise ValueError("boom")
    except ValueError:
        record = logging.LogRecord(
            name="subscriptions",
            level=logging.ERROR,
            pathname=__file__,
            lineno=1,
            msg="failed",
            args=(),
            exc_info=logging.sys.exc_info(),
        )

    out = _format(record)

    assert "ValueError: boom" in out["exc"]


def test_setup_logging_installs_single_stdout_handler():
    setup_logging(level="INFO")
    root = logging.getLogger()

    assert root.level == logging.INFO
    assert len(root.handlers) == 1
    assert isinstance(root.handlers[0].formatter, JsonFormatter)
