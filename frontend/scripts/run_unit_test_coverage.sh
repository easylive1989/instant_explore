#!/bin/bash

# 單元測試與 Coverage 腳本
# 產生整個專案的 coverage 報告

set -e  # 遇到錯誤立即退出

echo "🧪 Running Unit Tests with Coverage"
echo "===================================="

# 檢查是否在 frontend 目錄中
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in frontend directory!"
    echo "   Please run this script from the frontend directory:"
    echo "   cd frontend && ./scripts/run_unit_test_coverage.sh"
    exit 1
fi

# 清理舊的 coverage 資料
echo "🧹 Cleaning old coverage data..."
rm -rf coverage
mkdir -p coverage

# 偵測使用 fvm 或直接使用 flutter
if command -v fvm &> /dev/null; then
    FLUTTER_CMD="fvm flutter"
else
    FLUTTER_CMD="flutter"
fi

# 執行單元測試並產生 coverage
echo ""
echo "🔬 Running unit tests with coverage..."
$FLUTTER_CMD test --coverage

# 檢查 coverage 檔案是否存在
if [ ! -f "coverage/lcov.info" ]; then
    echo "❌ Coverage file not found!"
    exit 1
fi

echo "✅ Tests completed, coverage generated"

# 顯示包含的檔案
echo ""
echo "📁 Files included in coverage:"
grep "^SF:" coverage/lcov.info | sed 's/SF:/  /' | sort

# 計算 coverage 統計（如果有 lcov）
echo ""
if command -v lcov &> /dev/null; then
    echo "📊 Coverage Summary:"
    lcov --summary coverage/lcov.info 2>&1 | grep -E "(lines|functions|branches)"
fi

# 產生 HTML 報告（如果有 genhtml）
if command -v genhtml &> /dev/null; then
    echo ""
    echo "📄 Generating HTML report..."
    genhtml coverage/lcov.info -o coverage/html --quiet
    echo "✅ HTML report generated at coverage/html/index.html"
    echo ""
    echo "💡 Open the report with:"
    echo "   open coverage/html/index.html"
else
    echo ""
    echo "💡 Install lcov to generate HTML reports:"
    echo "   brew install lcov"
fi

echo ""
echo "✅ Done!"
