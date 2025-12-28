# Contexture 讀景 — 你的 AI 口袋歷史學家

[![CI/CD Pipeline](https://github.com/easylive1989/instant_explore/actions/workflows/ci.yml/badge.svg)](https://github.com/easylive1989/instant_explore/actions/workflows/ci.yml)

別只是看風景，要讀懂風景。隨身攜帶的 AI 歷史學家，即時解說、隨時提問，為你的旅程注入深度靈魂。

## 詳細說明

🌍 當你站在宏偉的古蹟前，你看見的是一堆冰冷的石頭，還是千年前的輝煌與脈絡？

親愛的旅人，我們知道你不滿足於走馬看花。 你渴望了解這座城市的靈魂，你想要看穿表象，閱讀磚瓦背後的故事。

歡迎使用 Contexture 讀景 — 專為深度知性旅人打造的 AI 語音導遊。在這裡，旅行不再只是拍照打卡，而是一場深度的閱讀體驗。這不是傳統單向輸出的語音導覽機，而是一位博學、優雅，且隨時準備好回答你任何問題的私人歷史學家。

把手機放口袋，戴上耳機，讓風景開口說話。

✨ 為什麼 Contexture 讀景 是你的最佳旅伴？
🎙️ 不只是聽，還可以「問」！ 聽完解說還有疑問？不用去 Google。 只要按下麥克風問：「這座塔後來是被誰燒掉的？」、「這幅畫背後的含義是什麼？」，AI 歷史學家會立刻針對你的好奇心，提供最詳盡的解答。這是真正的雙向對話，就像身邊跟著一位真人導遊。

⏱️ 你的時間，由你做主 趕行程還是想發呆？在播放前，你可以自由選擇：

☕ 30秒摘要版：喝杯咖啡的時間，快速掌握景點脈絡。

📖 10分鐘深度版：沉浸在歷史長河中，享受如有聲書般的深度故事。

👀 把視線留給真實世界 我們相信，最好的介面就是沒有介面。 Contexture 讀景 設計極簡，採用純淨人聲導覽，沒有多餘的干擾。我們不希望你低頭盯著螢幕，請抬起頭，用眼睛欣賞實景，用耳朵閱讀歷史。

📝 自動生成的「文化足跡日誌」 擔心聽過就忘？別費心做筆記了。 旅程結束後，App 會自動將你聽過的景點故事、問過的精彩問題，整理成一份精美的知識護照。無論是回家回味，或是撰寫遊記，你的文化足跡都已被完美保存。

📍 自由探索，隨遇而安 不需要跟著死板的路線走。打開 App，看看身邊有哪些隱藏的歷史寶藏，想去哪就點哪，享受真正的自由行樂趣。

準備好閱讀這個世界了嗎？ 現在就下載 Contexture 讀景，讓每一次的駐足，都充滿意義。

## ✨ 核心功能
- 📝 **AI 語音導覽** - 隨身攜帶的 AI 歷史學家，即時解說、隨時提問。
- 🎙️ **雙向對話** - 不只是聽，還可以「問」！AI 會針對你的好奇心提供詳盡解答。
- ⏱️ **彈性時間選擇** - 30秒摘要版或10分鐘深度版，你的時間由你做主。
- 👀 **沉浸式體驗** - 純淨人聲導覽，極簡介面，讓你專注於真實世界。
- 📝 **文化足跡日誌** - 自動生成精美知識護照，保存你的文化足跡。
- 📍 **自由探索** - 打開 App，探索身邊隱藏的歷史寶藏，隨遇而安。
- 📱 **跨平台支援** - iOS、Android 和 Web (Web 版專為手機尺寸最佳化)
- 🔐 **安全登入** - 支援 Google 帳號登入,資料安全有保障

## 💡 使用場景

- 🌍 **深度知性旅行** - 適合不滿足於走馬看花，渴望了解城市靈魂的深度知性旅人。
- 📚 **歷史文化學習** - 透過 AI 解說與互動問答，深入學習景點背後的歷史與故事。
- 🧭 **自由行探索** - 擺脫傳統導覽路線束縛，隨心所欲探索周邊景點。
- 📝 **個人回憶記錄** - 自動生成文化足跡日誌，完美保存旅行中的知識與感動。

> **設計理念**:簡單、快速、直覺,讓記錄成為習慣而非負擔

## 🛠️ 技術棧

- **前端:** Flutter (iOS / Android / Web)
- **後端:** Supabase (Authentication, Database, Storage)
- **地圖服務:** Google Maps API
- **AI 服務:** Firebase AI (Gemini)
- **訂閱管理:** RevenueCat
- **架構:** Feature-First 模組化設計
- **狀態管理:** Riverpod
- **設計理念:** 行動優先 (Mobile-First)

## 🚀 快速開始

```bash
# 複製專案
git clone https://github.com/easylive1989/instant_explore.git
cd instant_explore/frontend

# 安裝依賴
fvm flutter pub get

# 執行應用程式 (開發環境，需透過 --dart-define 傳入環境變數)
fvm flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key
```

### 環境變數設定

透過 `--dart-define` 傳入以下變數:

| 變數名稱 | 說明 |
|---------|------|
| `GOOGLE_MAPS_API_KEY` | Google Maps API 金鑰 |
| `SUPABASE_URL` | Supabase 專案 URL |
| `SUPABASE_ANON_KEY` | Supabase Anon Key |
| `GEMINI_API_KEY` | Google Gemini API 金鑰 |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth Web Client ID |
| `GOOGLE_IOS_CLIENT_ID` | Google OAuth iOS Client ID |
| `REVENUECAT_API_KEY_ANDROID` | RevenueCat Android API 金鑰 |
| `REVENUECAT_API_KEY_IOS` | RevenueCat iOS API 金鑰 |

> 詳細設定請參考 `frontend/.env.example`

### 🔧 CI/CD 狀態
- **程式碼檢查**: 每次 push 自動執行格式檢查與靜態分析
- **單元測試**: 自動執行單元測試
- **資料庫同步**: master 分支自動推送 Supabase DB Schema
- **自動部署**:
  - Android: 自動建置 AAB 並部署至 Google Play Internal Testing
  - iOS: 自動建置 IPA 並上傳至 TestFlight

## 📚 專案架構

### 目錄結構

```
instant_explore/
├── frontend/                 # Flutter 應用程式
│   ├── lib/
│   │   ├── main.dart         # 應用程式入口
│   │   ├── app.dart          # App 設定 (路由、主題)
│   │   ├── common/           # 共用功能
│   │   │   ├── config/       # 應用程式設定
│   │   │   ├── constraints/  # UI 約束
│   │   │   └── utils/        # 工具函式
│   │   ├── core/             # 核心功能
│   │   └── features/         # 功能模組
│   │       ├── auth/         # 登入與認證
│   │       ├── camera/       # 相機功能
│   │       ├── explore/      # 地點探索
│   │       ├── journey/      # 旅程足跡
│   │       ├── narration/    # AI 語音導覽
│   │       ├── settings/     # 設定頁面
│   │       └── subscription/ # 訂閱管理
│   ├── test/                 # 測試檔案
│   └── assets/               # 靜態資源
├── supabase/                 # Supabase 設定與 Schema
└── docs/                     # 專案文件
```

## 🧪 測試

```bash
cd frontend
# 執行單元測試
fvm flutter test
```

## 📝 授權

本專案採用 Apache 2.0 授權條款 - 詳見 [LICENSE](LICENSE) 檔案

---

**Contexture 讀景** - 讓每一次的駐足，都充滿意義 📖✨