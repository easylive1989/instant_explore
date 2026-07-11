FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Taipei

WORKDIR /app

# tzdata is required for the API's APScheduler jobs (subscription reconcile)
# to resolve local time; the slim base image ships without
# /usr/share/zoneinfo, so without this it would silently fall back to UTC.
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip && \
    pip install -e .

EXPOSE 8000

# Default command runs the FastAPI app.
# Social publishing / daily story now live in the separate publisher
# project; this image only serves the narration + subscriptions API.
CMD ["uvicorn", "lorescape_backend.api:app", "--host", "0.0.0.0", "--port", "8000"]
