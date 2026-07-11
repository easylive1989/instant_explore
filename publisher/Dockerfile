FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Taipei

WORKDIR /app

# tzdata: bot 的 zoneinfo.ZoneInfo("Asia/Taipei")（排程 modal 的時間解析）
# 需要 /usr/share/zoneinfo，slim base 沒帶。ffmpeg: bot 產 720p reel 預覽。
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata ffmpeg && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip && \
    pip install -e .

# Playwright Chromium + 系統依賴（IG card / reel 封面渲染）。
RUN playwright install --with-deps chromium

# Discord Gateway 常駐 bot：審核訊息、按鈕互動、排程發布。
CMD ["python", "-m", "lorescape_publisher.bot"]
