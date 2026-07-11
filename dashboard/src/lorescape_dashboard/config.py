"""路徑與環境設定：repo 內各資料來源的位置與 .env 載入。"""
from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

# dashboard/src/lorescape_dashboard/config.py → repo root
REPO_ROOT = Path(__file__).resolve().parents[3]
DASHBOARD_DIR = REPO_ROOT / "dashboard"
OUT_DATA_DIR = DASHBOARD_DIR / "out" / "data"

BACKLOG_PATH = REPO_ROOT / "BACKLOG.md"
FRONTEND_DIR = REPO_ROOT / "frontend"
BACKEND_DIR = REPO_ROOT / "backend"
PUBLISHER_DIR = REPO_ROOT / "publisher"

SETUP_DOC = "docs/init/dashboard-notion-setup.md"


def load_env() -> None:
    """載入 dashboard/.env，並沿用 scripts/.env（metrics Sheet 憑證）與
    publisher/.env（Supabase 憑證）。已存在的環境變數不覆寫。"""
    for env_path in (
        DASHBOARD_DIR / ".env",
        REPO_ROOT / "scripts" / ".env",
        PUBLISHER_DIR / ".env",
    ):
        if env_path.exists():
            load_dotenv(env_path, override=False)


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"缺少環境變數 {name}；設置步驟見 {SETUP_DOC}")
    return value
