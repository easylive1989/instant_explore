#!/usr/bin/env bash
#
# 把 ~/Downloads 裡下載好的 mp4 改名成 source.mp4，
# 放到 marketing/outputs/daily_video/<today>/ 資料夾。
#
# 用法：
#   scripts/import_source_video.sh            # 日期用今天
#   scripts/import_source_video.sh 2026-06-25 # 指定日期
#
# 若 ~/Downloads 有多個 mp4，會列出讓你選一個。

set -euo pipefail

DOWNLOADS="${HOME}/Downloads"

# repo root = 此腳本所在資料夾的上一層
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DATE="${1:-$(date +%F)}"
DEST_DIR="${REPO_ROOT}/marketing/outputs/daily_video/${DATE}"
DEST="${DEST_DIR}/source.mp4"

# 收集 Downloads 裡的 mp4（只看第一層，不遞迴）
mp4s=()
while IFS= read -r -d '' f; do
  mp4s+=("$f")
done < <(find "${DOWNLOADS}" -maxdepth 1 -type f -iname '*.mp4' -print0)

count=${#mp4s[@]}

if (( count == 0 )); then
  echo "❌ ${DOWNLOADS} 裡沒有任何 mp4 檔。"
  exit 1
fi

if (( count == 1 )); then
  chosen="${mp4s[0]}"
  echo "找到 1 個 mp4：$(basename "${chosen}")"
else
  echo "在 ${DOWNLOADS} 找到 ${count} 個 mp4，請選擇要使用的："
  i=1
  for f in "${mp4s[@]}"; do
    # 依修改時間順序顯示，並附上人類可讀的時間
    mtime="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f")"
    printf "  %2d) %-50s  %s\n" "$i" "$(basename "$f")" "${mtime}"
    ((i++))
  done

  read -r -p "輸入編號 (1-${count})，或按 Enter 取消：" idx
  if [[ -z "${idx}" ]]; then
    echo "已取消。"
    exit 0
  fi
  if ! [[ "${idx}" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > count )); then
    echo "❌ 無效的編號：${idx}"
    exit 1
  fi
  chosen="${mp4s[idx-1]}"
fi

mkdir -p "${DEST_DIR}"

# 若目標已存在，先確認是否覆蓋
if [[ -e "${DEST}" ]]; then
  read -r -p "⚠️  ${DEST} 已存在，覆蓋？(y/N) " yn
  if [[ ! "${yn}" =~ ^[Yy]$ ]]; then
    echo "已取消。"
    exit 0
  fi
fi

mv -f "${chosen}" "${DEST}"

echo "✅ 已搬移："
echo "   來源：${chosen}"
echo "   目標：${DEST}"
