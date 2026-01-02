#!/bin/bash

# 單元測試與 Coverage 腳本
# 只產生 domain 資料夾的 coverage 報告

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

# 過濾 coverage，只保留 domain 資料夾的檔案
echo ""
echo "🔧 Filtering coverage to domain folders only..."

# 使用 lcov 過濾 coverage（如果已安裝）
if command -v lcov &> /dev/null; then
    lcov --extract coverage/lcov.info \
         'lib/features/*/domain/*' \
         -o coverage/lcov_domain.info \
         --ignore-errors unused
    
    # 備份原始檔案並替換
    mv coverage/lcov.info coverage/lcov_full.info
    mv coverage/lcov_domain.info coverage/lcov.info
    
    echo "✅ Coverage filtered using lcov"
else
    # 如果沒有 lcov，使用 grep 過濾
    echo "⚠️  lcov not found, using grep to filter..."
    
    # 建立臨時檔案
    TEMP_FILE=$(mktemp)
    
    # 使用 awk 來正確解析 lcov 格式並過濾 domain 資料夾
    awk '
    BEGIN { in_domain = 0 }
    /^SF:/ {
        # 檢查檔案路徑是否包含 /domain/
        if ($0 ~ /features\/[^\/]+\/domain\//) {
            in_domain = 1
            print
        } else {
            in_domain = 0
        }
        next
    }
    /^end_of_record/ {
        if (in_domain) {
            print
        }
        next
    }
    {
        if (in_domain) {
            print
        }
    }
    ' coverage/lcov.info > "$TEMP_FILE"
    
    # 備份原始檔案並替換
    mv coverage/lcov.info coverage/lcov_full.info
    mv "$TEMP_FILE" coverage/lcov.info
    
    echo "✅ Coverage filtered using awk"
fi

# 顯示過濾後包含的檔案
echo ""
echo "📁 Domain files included in coverage:"
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
