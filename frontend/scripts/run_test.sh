#!/bin/bash

# Email 註冊測試執行腳本
# 用於執行 Patrol E2E 測試

set -e  # 遇到錯誤立即退出

echo "🚀 Starting E2E Test: Email Registration"
echo "=========================================="

# 檢查是否在 frontend 目錄中
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in frontend directory!"
    echo "   Please run this script from the frontend directory:"
    echo "   cd frontend && ./scripts/run_test.sh"
    exit 1
fi

# 檢查 Supabase 是否運行
echo "📡 Checking Supabase status..."
if ! curl -s http://127.0.0.1:54321/health > /dev/null 2>&1; then
    echo "❌ Local Supabase is not running!"
    echo "   Please start it first: supabase start"
    exit 1
fi
echo "✅ Supabase is running"

# 載入環境變數
if [ -f .env.test ]; then
    echo "📝 Loading test environment variables..."
    export $(cat .env.test | grep -v '^#' | xargs)
else
    echo "❌ .env.test file not found!"
    echo "   Please create .env.test with the following content:"
    echo ""
    echo "   SUPABASE_URL=http://10.0.2.2:54321"
    echo "   SUPABASE_ANON_KEY=<your-anon-key>"
    echo "   SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>"
    echo "   GOOGLE_WEB_CLIENT_ID="
    echo "   GOOGLE_IOS_CLIENT_ID="
    echo "   GOOGLE_MAPS_API_KEY="
    echo "   GOOGLE_DIRECTIONS_API_KEY="
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

# 執行測試
echo "🧪 Running email registration test..."
echo ""

patrol test \
  --show-flutter-logs \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-""} \
  --dart-define=GOOGLE_IOS_CLIENT_ID=${GOOGLE_IOS_CLIENT_ID:-""} \
  --dart-define=GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-""} \
  --dart-define=GOOGLE_DIRECTIONS_API_KEY=${GOOGLE_DIRECTIONS_API_KEY:-""} \
  --target integration_test/email_register_test.dart

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully!"
else
    echo "❌ Test failed with exit code $TEST_EXIT_CODE"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Check Supabase logs for errors"
    echo "2. Verify that email registration is enabled in Supabase"
    echo "3. Ensure the emulator can connect to host (use 10.0.2.2 for Android)"
    echo "4. Check the test report at: build/app/reports/androidTests/connected/index.html"
fi

exit $TEST_EXIT_CODE
