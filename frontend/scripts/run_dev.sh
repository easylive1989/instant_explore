#!/bin/bash

# 旅食日記 - 開發環境執行腳本
# 此腳本會載入環境變數並執行應用程式

set -e  # 遇到錯誤立即停止

echo "🚀 啟動旅食日記開發環境..."

# 檢查是否在正確的目錄
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 錯誤: 請在專案根目錄執行此腳本"
    exit 1
fi

# 檢查 .env 檔案是否存在
if [ ! -f ".env" ]; then
    echo "⚠️  警告: 找不到 .env 檔案"
    echo "📝 建議: 複製 .env.example 並填入你的設定"
    echo ""
    read -p "是否繼續執行? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ 載入環境變數..."
    # 載入 .env 檔案
    export $(cat .env | grep -v '^#' | xargs)
fi

# 檢查 fvm 是否安裝
if ! command -v fvm &> /dev/null; then
    echo "❌ 錯誤: 找不到 fvm 命令"
    echo "請先安裝 FVM: https://fvm.app"
    exit 1
fi

# 檢查環境變數
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "⚠️  警告: GOOGLE_MAPS_API_KEY 未設定"
fi

if [ -z "$SUPABASE_URL" ]; then
    echo "⚠️  警告: SUPABASE_URL 未設定"
fi

# 取得相依套件
echo "📦 安裝相依套件..."
fvm flutter pub get

# 執行應用程式
echo "▶️  啟動應用程式..."
echo ""

fvm flutter run \
    --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY}" \
    --dart-define=GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_API_KEY:-$GOOGLE_MAPS_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
    --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID \
    --dart-define=SHARE_BASE_URL="${SHARE_BASE_URL:-https://lorescape.app}"

FLUTTER_PID=$!

# 等待 Flutter 進程結束
wait $FLUTTER_PID
