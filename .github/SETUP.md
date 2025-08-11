# GitHub Actions CI/CD 設定指南

## 🚀 自動設定完成項目

此專案已包含完整的 CI/CD pipeline，包含：

### ✅ 自動化流程
- **程式碼檢查**: 格式化、靜態分析
- **安全檢查**: 硬編碼 API 金鑰掃描
- **自動測試**: 單元測試執行
- **多平台建置**: Android APK、iOS、Web
- **自動部署**: Web 版本部署到 GitHub Pages

## 🔧 需要手動設定的項目

### 1. 啟用 GitHub Pages
1. 進入專案的 GitHub Repository
2. 點選 **Settings** 頁籤
3. 在左側選單找到 **Pages**
4. 在 **Source** 設定中選擇 **GitHub Actions**
5. 點選 **Save**

### 2. 更新 README 中的徽章連結
將 README.md 中的 `YOUR_USERNAME` 替換為實際的 GitHub 用戶名：
```markdown
[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/instant_explore/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/instant_explore/actions/workflows/ci.yml)
```

### 3. （可選）設定 Codecov
如果要使用測試覆蓋率報告：
1. 註冊 [Codecov](https://codecov.io/)
2. 連接此 GitHub Repository
3. 更新 README 中的 codecov 徽章連結

## 📋 工作流程說明

### 觸發條件
- Push 到 `main`, `master`, `develop` 分支
- 建立 Pull Request 到 `main`, `master` 分支

### 執行階段
1. **Test & Security Check** - 測試和安全檢查
2. **Build Android APK** - Android 建置
3. **Build iOS App** - iOS 建置
4. **Build & Deploy Web** - Web 建置和部署
5. **Build Status Report** - 狀態報告

### 建置產物
- **Android APK**: 驗證建置成功（不上傳 artifacts）
- **iOS Build**: 驗證建置成功（不上傳 artifacts）
- **Web 版本**: 自動部署到 GitHub Pages

## 🛠️ 本地開發

### 環境變數設定
1. 複製 `.env.example` 為 `.env`
2. 填入實際的 Google API 金鑰
3. 使用開發腳本執行：
```bash
chmod +x scripts/run_dev.sh
./scripts/run_dev.sh
```

### 測試和檢查
```bash
# 執行測試
fvm flutter test --coverage

# 程式碼格式化
fvm dart format .

# 靜態分析
fvm flutter analyze

# 安全檢查
grep -r "AIza[A-Za-z0-9_-]\{35\}" lib/ && echo "發現硬編碼 API 金鑰" || echo "安全檢查通過"
```

## 🔒 安全注意事項

- ✅ 所有 API 金鑰都使用環境變數
- ✅ `.env` 檔案已加入 `.gitignore`
- ✅ CI/CD 使用測試用的占位符金鑰
- ✅ 自動掃描硬編碼金鑰

## 📊 監控和維護

- 查看建置狀態：點選 README 中的徽章
- 查看 Web 版本：`https://YOUR_USERNAME.github.io/instant_explore/`
- 監控測試覆蓋率：Codecov 儀表板
- 建置驗證：Android 和 iOS 建置成功代表程式碼可正常編譯

## 🐛 故障排除

### 常見問題
1. **建置失敗**: 檢查 Flutter 版本和依賴是否正確
2. **GitHub Pages 無法訪問**: 確認 Pages 設定已啟用
3. **測試失敗**: 檢查測試程式碼和環境變數設定

### 支援資源
- [GitHub Actions 文件](https://docs.github.com/en/actions)
- [Flutter CI/CD 指南](https://docs.flutter.dev/deployment/ci)
- [GitHub Pages 設定](https://docs.github.com/en/pages)