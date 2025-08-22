#!/bin/bash

# 開發環境執行腳本
# 用於加載環境變數並執行 Flutter 應用程式

# 檢查 .env 檔案是否存在
if [ -f .env ]; then
    echo "✅ 找到 .env 檔案，正在載入環境變數..."
    
    # 載入環境變數
    export $(cat .env | grep -v '^#' | xargs)
    
    # 執行 Flutter 應用程式
    echo "🚀 啟動 Instant Explore..."
    fvm flutter run \
        --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
        --dart-define=SUPABASE_URL=$SUPABASE_URL \
        --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
        --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
        --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID
else
    echo "⚠️  未找到 .env 檔案"
    echo "請複製 .env.example 並重新命名為 .env"
    echo "然後填入您的 API 金鑰"
    echo ""
    echo "執行以下命令："
    echo "cp .env.example .env"
    echo "然後編輯 .env 檔案填入您的 API 金鑰"
fi