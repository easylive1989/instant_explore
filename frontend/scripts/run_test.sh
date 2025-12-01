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

# 載入環境變數
if [ -f .env.test ]; then
    echo "📝 Loading test environment variables..."
    export $(cat .env.test | grep -v '^#' | xargs)
else
    echo "❌ .env.test file not found!"
    echo "   Please create .env.test with the following content:"
    echo ""
    echo "   SUPABASE_URL=https://kypcxxjqsinamcqrjeog.supabase.co"
    echo "   SUPABASE_ANON_KEY=<your-remote-anon-key>"
    echo "   SUPABASE_SERVICE_ROLE_KEY=<your-remote-service-role-key>"
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

# 檢查遠端 Supabase 連線
echo "📡 Checking remote Supabase connection..."
HEALTH_URL="${SUPABASE_URL}/rest/v1/"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL")
if ! echo "$HTTP_CODE" | grep -q "200\|401"; then
    echo "❌ Cannot connect to remote Supabase at $SUPABASE_URL"
    echo "   Received HTTP code: $HTTP_CODE"
    echo "   Please check your network connection and SUPABASE_URL"
    exit 1
fi
echo "✅ Connected to remote Supabase"

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

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully!"
else
    echo "❌ Test failed with exit code $TEST_EXIT_CODE"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Check your network connection to remote Supabase"
    echo "2. Verify that email registration is enabled in Supabase Dashboard"
    echo "3. Check if test user was properly cleaned up"
    echo "4. Review test logs for specific error messages"
fi

exit $TEST_EXIT_CODE
