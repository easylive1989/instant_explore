FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

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
