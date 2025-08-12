# Instant Explore 隨性探點

[![CI/CD Pipeline](https://github.com/easylive1989/instant_explore/actions/workflows/ci.yml/badge.svg)](https://github.com/easylive1989/instant_explore/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/easylive1989/instant_explore/branch/master/graph/badge.svg)](https://codecov.io/gh/easylive1989/instant_explore)

一款基於即時位置的智慧推薦應用程式，幫助使用者探索周邊的精彩去處。無論是旅遊觀光、朋友聚會，還是日常探索，Instant Explore 都能為您推薦最適合的下一站。

## ✨ 核心功能

- 📍 **即時位置推薦** - 根據當前位置智慧推薦附近景點、餐廳、飲料店
- 🏷️ **智慧篩選** - 支援分類和距離篩選，精準符合需求
- ⭐ **地點評價** - 整合 Google 評價和使用者評論
- 👥 **多人決定** - 群組投票功能，民主決定下一個目的地
- 🗺️ **路線規劃** - 整合 Google Maps 導航，支援多種交通方式
- 📱 **跨平台支援** - iOS、Android 和 Web（Web 版專為手機尺寸最佳化）
- 🔐 **多元登入** - 支援 Google、Apple 和 Email 帳號密碼登入

## 💎 版本方案

### 免費版
- ✅ 完整核心功能
- ✅ 乾淨無廣告體驗
- ⚠️ 每日搜尋次數限制（10 次）

### 訂閱版 
- ✅ 所有功能完全無限制
- ✅ 無搜尋次數限制
- ✅ 進階功能（歷史記錄、收藏地點、進階篩選）
- ✅ 優先客服支援

> **設計理念**：提供乾淨無廣告的使用體驗，透過合理的使用限制鼓勵重度使用者訂閱

## 🛠️ 技術棧

- **前端：** Flutter (iOS / Android / Web)
- **API：** Google Places API, Google Maps API
- **架構：** Feature-First 模組化設計
- **設計理念：** 行動優先（Mobile-First），專注手機使用場景

## 🚀 快速開始

```bash
# 複製專案
git clone https://github.com/[your-username]/instant_explore.git
cd instant_explore/frontend

# 安裝依賴
fvm flutter pub get

# 執行應用程式 (開發環境)
fvm flutter run

# 或使用開發腳本 (需要 .env 檔案)
chmod +x scripts/run_dev.sh
./scripts/run_dev.sh
```

### 🔧 CI/CD 狀態
- **自動化測試**: 每次 push 自動執行單元測試和程式碼檢查
- **多平台建置**: 自動建置 Android APK、iOS 和 Web 版本
- **安全檢查**: 自動掃描硬編碼 API 金鑰
- **自動部署**: main/master 分支自動部署 Web 版本到 GitHub Pages

> 詳細設定請參考 [開發指南](doc/DEVELOPMENT.md)

## 📚 文件導覽

- 📖 [使用者手冊](doc/USER_GUIDE.md) - 詳細功能說明和使用教學
- 🏗️ [架構設計](doc/ARCHITECTURE.md) - 技術架構和專案結構
- 💻 [開發指南](doc/DEVELOPMENT.md) - 開發環境設定和開發規範
- 🔌 [API 整合](doc/API_INTEGRATION.md) - Google APIs 整合說明
- 📊 [技術可行性](doc/TECHNICAL_FEASIBILITY.md) - 技術分析和成本評估

## 📝 授權

本專案採用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 檔案

---

**Instant Explore** - 讓每一次出門都是一場新的探險！ 🗺️✨