# 設計系統 (Design System)

整理自 `@docs/design/` 中的 HTML 原型檔案。

## 色彩系統 (Color System)

### 核心顏色 (Core Colors)
- **Primary Blue**: `#137fec` (主要品牌色，用於按鈕、圖示高亮)
- **Success Green**: `#10b981` (用於成功狀態頁面)
- **Amber**: `text-amber-500` (用於收藏/書籤圖示)
- **Red**: `text-red-500` / `text-red-600` (用於錯誤提示、刪除帳號)

### 背景顏色 (Background Colors)
- **Background Light**: `#f6f7f8` (淺色模式背景)
- **Background Dark**: `#101922` (深色模式背景 - 接近黑色)

### 表面與卡片顏色 (Surface Colors)
用於卡片、對話框、底部導航欄等。
- **Surface Dark (Default)**: `#1c2630` (通用卡片背景 - 用於 Home, Passport, Settings 等)
- **Surface Dark (Player)**: `#182430` (沈浸式播放器面板)
- **Surface Dark (Config)**: `#192633` (導覽設定頁面)
- **Glass Effect**: `rgba(255, 255, 255, 0.08)` + `backdrop-filter: blur(12px)` (首頁卡片)
- **Glass Panel**: `rgba(16, 25, 34, 0.85)` (播放器底部面板)

### 文字顏色 (Text Colors)
- **Text Primary (Dark)**: `#FFFFFF` (White)
- **Text Secondary (Dark)**: `text-slate-400` / `text-gray-400`
- **Text Primary (Light)**: `text-slate-900`
- **Text Secondary (Light)**: `text-slate-500` / `text-gray-500`

## 字型系統 (Typography)

- **Font Family**:
  - `Inter` (主要用於標題與介面元素)
  - `Noto Sans` (部分內文使用)
  - Fallback: `sans-serif`

## 圓角系統 (Border Radius)

- **Default**: `0.25rem` (4px)
- **lg**: `0.5rem` (8px)
- **xl**: `0.75rem` (12px) - 常用於輸入框、主要按鈕 (Primary Button)
- **2xl**: `1rem` (16px) - 常用於列表卡片 (Cards)
- **Full**: `9999px` - 用於圓形按鈕 (Icon Buttons)、標籤 (Chips)

## 陰影與特效 (Effects)

- **Pulse Slow**: `pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite` (首頁背景光暈動畫)
- **Shadows**: 常見 `shadow-lg`, `shadow-xl`, `shadow-primary/30` (主要按鈕發光效果)

---

## 畫面列表 (Screen List)

### 1. Home Screen (首頁)
- **路徑**: `docs/design/home_screen/`
- **描述**: 應用程式的主入口。
- **關鍵元素**:
  - 頂部 "Explore" 標題與 "Refresh" 按鈕。
  - 列表式景點卡片 (玻璃擬態 Glassmorphism)。
  - 底部導航欄 (Home, Map, Passport, Profile)。
  - 背景有地圖紋理與呼吸燈動畫。

### 2. Immersive Player (沈浸式播放器)
- **路徑**: `docs/design/immersive_player/`
- **描述**: 語音導覽的主要播放介面。
- **關鍵元素**:
  - 全螢幕沈浸式體驗。
  - 滾動的逐字稿 (Transcript)。
  - 底部控制面板 (播放/暫停、進度條、儲存按鈕)。
  - 頂部透明導航列。

### 3. Knowledge Passport (知識護照)
- **路徑**: `docs/design/knowledge_passport/`
- **描述**: 使用者學習歷程與收藏的知識庫。
- **關鍵元素**:
  - 頂部篩選 Chips (Chronological, Location, Saved)。
  - 時間軸 (Timeline) 設計，連接各個知識點。
  - Q&A 手風琴 (Accordion) 展開效果。

### 4. Narration Configuration (導覽設定)
- **路徑**: `docs/design/narration_configuration/`
- **描述**: 開始導覽前的設定頁面。
- **關鍵元素**:
  - 大圖背景。
  - 導覽深度選擇卡片 (Brief vs Deep Dive)。
  - 選中狀態的高亮樣式 (Primary Border + Icon)。

### 5. Login (登入)
- **路徑**: `docs/design/login/`
- **描述**: 使用者登入頁面。
- **關鍵元素**:
  - Email/Password 表單。
  - 第三方登入按鈕 (Google, Apple)。
  - 簡潔的置中佈局。

### 6. Register (註冊)
- **路徑**: `docs/design/register/`
- **描述**: 新用戶註冊頁面。
- **關鍵元素**:
  - 類似登入頁面的表單設計。
  - 漸層 Icon 背景裝飾。

### 7. Settings (設定)
- **路徑**: `docs/design/setting/`
- **描述**: 應用程式設定。
- **關鍵元素**:
  - 分組列表 (Preferences, Account)。
  - 列表項目包含圖示與文字說明。
  - 危險操作 (Delete Account) 使用紅色標示。

### 8. Save to Knowledge Passport (儲存成功)
- **路徑**: `docs/design/save_to_knowledge_passport/`
- **描述**: 將內容加入護照後的成功回饋。
- **關鍵元素**:
  - 大型成功動畫圖示 (Pulse effect)。
  - 預覽卡片。
  - 兩個主要行動按鈕 (View Passport, Continue Tour)。

### 9. AI Over Limit (使用限制提示)
- **路徑**: `docs/design/ai_over_limit/`
- **描述**: 當 AI 使用量耗盡時的彈出視窗。
- **關鍵元素**:
  - 模態對話框 (Modal)。
  - 背景模糊遮罩。
  - 警告圖示與說明文字。
