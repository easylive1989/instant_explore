#!/bin/bash

# E2E 測試執行腳本
# 用於執行 Patrol E2E 測試
# 自動啟動 local Supabase 與 Android 模擬器，測試後自動關閉

set -e  # 遇到錯誤立即退出

echo "🚀 Starting E2E Test"
echo "===================="

# 檢查是否在 frontend 目錄中
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in frontend directory!"
    echo "   Please run this script from the frontend directory:"
    echo "   cd frontend && ./scripts/run_test.sh"
    exit 1
fi

# 載入環境變數
if [ -f .env.test ]; then
    echo "📝 Loading test environment variables..."
    export $(cat .env.test | grep -v '^#' | xargs)
else
    echo "❌ .env.test file not found!"
    echo "   Please create .env.test with required environment variables."
    exit 1
fi

# 驗證必要的環境變數
echo "🔍 Validating environment variables..."
if [ -z "$SUPABASE_URL" ]; then
    echo "❌ SUPABASE_URL is not set!"
    exit 1
fi
if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ SUPABASE_ANON_KEY is not set!"
    exit 1
fi
if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "❌ SUPABASE_SERVICE_ROLE_KEY is not set!"
    exit 1
fi
echo "✅ Environment variables validated"

# ==========================================
# 啟動 Local Supabase
# ==========================================
echo ""
echo "🗄️  Starting local Supabase..."
cd ..  # 移動到專案根目錄 (supabase 目錄所在地)

# 檢查 Supabase 是否已在運行
if npx supabase status 2>/dev/null | grep -q "API URL"; then
    echo "✅ Local Supabase is already running"
else
    npx supabase start
    echo "✅ Local Supabase started"
fi

cd frontend  # 回到 frontend 目錄

# ==========================================
# 啟動 Android 模擬器
# ==========================================
echo ""
echo "📱 Starting Android emulator (sdk_gphone64_arm64)..."

EMULATOR_NAME="Medium_Phone_API_35"
EMULATOR_SERIAL="emulator-5554"

# 檢查模擬器是否已在運行
if adb devices | grep -q "$EMULATOR_SERIAL"; then
    echo "✅ Android emulator is already running"
else
    # 在背景啟動模擬器
    $ANDROID_HOME/emulator/emulator -avd "$EMULATOR_NAME" -no-snapshot-load &
    EMULATOR_PID=$!
    
    echo "⏳ Waiting for emulator to boot..."
    # 等待模擬器啟動 (最多等待 120 秒)
    WAIT_TIME=0
    MAX_WAIT=120
    while [ $WAIT_TIME -lt $MAX_WAIT ]; do
        if adb shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; then
            echo "✅ Android emulator booted successfully"
            break
        fi
        sleep 2
        WAIT_TIME=$((WAIT_TIME + 2))
        echo "   Waiting... ($WAIT_TIME/$MAX_WAIT seconds)"
    done
    
    if [ $WAIT_TIME -ge $MAX_WAIT ]; then
        echo "❌ Emulator boot timeout!"
        exit 1
    fi
fi

# ==========================================
# 執行測試
# ==========================================
echo ""
echo "🧪 Running E2E test on Android emulator..."
echo ""

# 使用 Android 模擬器執行測試
set +e  # 暫時關閉 errexit，讓測試失敗不會直接退出
patrol test \
  --target integration_test/app_test.dart \
  --device "$EMULATOR_SERIAL" \
  --show-flutter-logs \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-""} \
  --dart-define=GOOGLE_IOS_CLIENT_ID=${GOOGLE_IOS_CLIENT_ID:-""} \
  --dart-define=GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-""} \
  --dart-define=GOOGLE_DIRECTIONS_API_KEY=${GOOGLE_DIRECTIONS_API_KEY:-""}

TEST_EXIT_CODE=$?
set -e  # 重新啟用 errexit

# ==========================================
# 清理：關閉模擬器與 Supabase
# ==========================================
echo ""
echo "🧹 Cleaning up..."

# 關閉 Android 模擬器
echo "📱 Stopping Android emulator..."
adb -s "$EMULATOR_SERIAL" emu kill 2>/dev/null || true
echo "✅ Android emulator stopped"

# 關閉 Local Supabase
echo "🗄️  Stopping local Supabase..."
cd ..  # 移動到專案根目錄
npx supabase stop
cd frontend
echo "✅ Local Supabase stopped"

# ==========================================
# 結果報告
# ==========================================
echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully!"
else
    echo "❌ Test failed with exit code $TEST_EXIT_CODE"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Check if local Supabase migrations are applied"
    echo "2. Verify that test user was properly cleaned up"
    echo "3. Review test logs for specific error messages"
fi

exit $TEST_EXIT_CODE
