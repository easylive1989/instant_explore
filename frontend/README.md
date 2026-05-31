# Lorescape — Frontend (Flutter)

Lorescape 的 Flutter 應用程式：為眼前的每個景點生成「以史實為本的真實小故事」，
再以純淨人聲逐句朗讀。支援 iOS / Android / Web。

> 產品定位、完整功能與技術棧請見 [專案根目錄 README](../README.md)。

## 核心使用流程

1. **探索 (explore)** — 定位當前位置，發現身邊的景點。
2. **選角度 (narration hooks)** — 後端先回傳 2～3 個故事切角預告，挑一個感興趣的。
3. **聽故事 (narration + TTS)** — 展開成三段式真實故事，語音逐句朗讀並同步高亮。
4. **留足跡 (journey)** — 聽過的故事自動存成文化足跡日誌，可分旅程、匯出 PDF。

每日另有「每日故事 (daily_story)」推送一則全球同步的新景點故事。

## 專案架構

採 **Feature-First + Clean Architecture**，目錄結構：

```
lib/
├── main.dart        # 應用程式入口
├── app.dart         # 根 MaterialApp、路由與主題接線
├── app/             # App 層級設定 (路由、主題、環境設定)
├── core/            # 框架無關的基礎設施 (錯誤、服務、純工具)
├── shared/          # 跨功能共用的 UI 元件與擴充
└── features/        # 功能模組 (每個模組內含 data / domain / presentation)
    ├── explore/         # 地圖探索附近景點
    ├── narration/       # AI 故事生成 + TTS 語音朗讀 (核心)
    ├── daily_story/     # 每日一景故事
    ├── journey/         # 文化足跡日誌
    ├── trip/            # 旅程分組
    ├── export/          # 旅程故事匯出 PDF
    ├── saved_locations/ # 收藏景點
    ├── auth/ subscription/ settings/ ...
```

詳細架構規範（資料夾職責、依賴方向、各層位置）請見 [`../CLAUDE.md`](../CLAUDE.md)。

## 快速開始

本專案使用 [fvm](https://fvm.app/) 管理 Flutter 版本。

```bash
# 安裝依賴
fvm flutter pub get

# 產生程式碼 (json_serializable 等)
dart run build_runner build --delete-conflicting-outputs

# 執行 (需透過 --dart-define 傳入環境變數)
fvm flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key
```

完整環境變數清單請參考根目錄 README 與 `.env.example`。

## 開發指令

```bash
# 靜態分析 (提交前必跑，須零錯誤/警告/提示)
fvm flutter analyze --fatal-infos

# 格式化
dart format .

# 單元 / Widget 測試
fvm flutter test

# E2E 測試 (Patrol)
patrol test
```
