#!/usr/bin/env bash
# 快速啟動產品面板 serve 模式（免打長 uv 指令）。
# 預設 --skip-tests 秒開；可再加參數，如：./scripts/dashboard.sh --port 9000
set -euo pipefail
cd "$(dirname "$0")/.."
exec uv run --project dashboard lorescape-dashboard --serve --skip-tests "$@"
