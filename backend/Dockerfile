FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Taipei

WORKDIR /app

# tzdata is required for the API's APScheduler jobs and the publisher bot's
# `zoneinfo.ZoneInfo("Asia/Taipei")` (schedule-modal time parsing) to resolve
# local time; the slim base image ships without /usr/share/zoneinfo, so
# without this those would silently fall back to UTC. ffmpeg is required by
# the publisher bot to render the 720p reel preview before publishing.
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata ffmpeg && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip && \
    pip install -e .

# Playwright Chromium + its required system libs (for IG card rendering).
# --with-deps lets Playwright apt-install whatever Chromium needs (libnss,
# libatk, fonts, etc.) on top of the python:3.11-slim base.
RUN playwright install --with-deps chromium

EXPOSE 8000

# Default command runs the FastAPI app.
# The cron job is invoked separately (see docker-compose / system cron).
CMD ["uvicorn", "lorescape_backend.api:app", "--host", "0.0.0.0", "--port", "8000"]
