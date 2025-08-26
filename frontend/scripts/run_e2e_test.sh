#!/bin/bash

# E2E 測試執行腳本
# 使用 Patrol 執行 E2E 測試，並啟用測試模式

echo "🧪 準備執行 Instant Explore E2E 測試..."

# 檢查是否已安裝 patrol_cli
if [ ! -f "/tmp/patrol_fvm" ]; then
    echo "⚙️ 設定 patrol 命令..."
    sed 's|dart |fvm dart |g' ~/.pub-cache/bin/patrol > /tmp/patrol_fvm
    chmod +x /tmp/patrol_fvm
fi

if ! /tmp/patrol_fvm --version &> /dev/null; then
    echo "❌ patrol_cli 未安裝或無法執行"
    echo "請執行: fvm dart pub global activate patrol_cli"
    exit 1
fi

# 檢查 integration_test 資料夾是否存在
if [ ! -d "integration_test" ]; then
    echo "❌ integration_test 資料夾不存在"
    echo "請確認目前在正確的專案根目錄"
    exit 1
fi

# 檢查測試檔案是否存在
if [ ! -f "integration_test/app_e2e_test.dart" ]; then
    echo "❌ E2E 測試檔案不存在"
    echo "請確認 integration_test/app_e2e_test.dart 檔案存在"
    exit 1
fi

echo "✅ 環境檢查通過"
echo ""

# 顯示測試資訊
echo "📋 測試資訊:"
echo "- 測試檔案: integration_test/app_e2e_test.dart"
echo "- 使用 Riverpod Overrides 注入 Fake Services"
echo "- 無需真實 API 金鑰"
echo ""

echo "🚀 開始執行 E2E 測試..."
echo ""

# 執行 patrol 測試
/tmp/patrol_fvm test \
    --target=integration_test/app_e2e_test.dart \
    --verbose