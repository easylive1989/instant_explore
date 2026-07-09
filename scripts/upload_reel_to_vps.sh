#!/usr/bin/env bash
#
# 把後製完成的 Reel（final.mp4 + narration.txt）rsync 到 VPS 的
# /opt/lorescape-media/daily_video/<date>/，並寫一筆 pending row（Discord
# bot 會輪詢到並貼審核訊息；按 🚀 立即發布，或核准後到排程時間才發
# 到 IG Reels）。
#
# 用法：
#   scripts/upload_reel_to_vps.sh            # 日期用今天
#   scripts/upload_reel_to_vps.sh 2026-07-05 # 指定日期
#
# 前置：~/.ssh/config 需有 VPS 的 host alias（預設 lorescape-vps，
# 可用環境變數 LORESCAPE_VPS_HOST 覆寫）。

set -euo pipefail

VPS_HOST="${LORESCAPE_VPS_HOST:-lorescape-vps}"
VPS_MEDIA_DIR="/opt/lorescape-media/daily_video"

# repo root = 此腳本所在資料夾的上一層
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DATE="${1:-$(date +%F)}"
SRC_DIR="${REPO_ROOT}/marketing/outputs/daily_video/${DATE}"

if [[ ! -f "${SRC_DIR}/final.mp4" ]]; then
  echo "❌ 找不到 ${SRC_DIR}/final.mp4 — 先跑 daily_video_post 產出 IG cut。"
  exit 1
fi
if [[ ! -f "${SRC_DIR}/narration.txt" ]]; then
  echo "❌ 找不到 ${SRC_DIR}/narration.txt — caption 的 hook 需要它。"
  exit 1
fi

echo "上傳 ${DATE} 的 Reel 到 ${VPS_HOST}:${VPS_MEDIA_DIR}/${DATE}/ ..."
ssh "${VPS_HOST}" "mkdir -p '${VPS_MEDIA_DIR}/${DATE}'"
rsync -av --progress \
  "${SRC_DIR}/final.mp4" \
  "${SRC_DIR}/narration.txt" \
  "${VPS_HOST}:${VPS_MEDIA_DIR}/${DATE}/"

echo ""
echo "寫入 pending row..."
(cd "${SCRIPT_DIR}" && uv run python -m send_reel_for_review "${DATE}")

echo ""
echo "✅ 發布 bot 會在 Discord 貼審核訊息；按 🚀 立即發布，或核准後到排程時間才發。"
