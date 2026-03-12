# 訂閱功能設定教學

本文說明如何在 App Store Connect、Google Play Console、RevenueCat Dashboard 完成訂閱商品設定，以及如何在本地開發環境中設定 API Key。

---

## 目錄

1. [前置準備](#1-前置準備)
2. [RevenueCat Dashboard 設定](#2-revenuecat-dashboard-設定)
3. [App Store Connect 設定（iOS）](#3-app-store-connect-設定ios)
4. [Google Play Console 設定（Android）](#4-google-play-console-設定android)
5. [環境變數設定](#5-環境變數設定)
6. [Sandbox 測試](#6-sandbox-測試)
7. [上架前檢查清單](#7-上架前檢查清單)

---

## 1. 前置準備

### 需要的帳號

- [RevenueCat](https://app.revenuecat.com/) 帳號
- Apple Developer Program 帳號（App Store Connect 存取權限）
- Google Play Developer 帳號

### 訂閱功能架構摘要

```
App (purchases_flutter SDK)
    ↕
RevenueCat Dashboard
    ↕            ↕
App Store     Google Play
(StoreKit)    (Billing)
```

RevenueCat 作為中介層，統一管理兩平台的訂閱狀態，App 只需接收 RevenueCat 的 Entitlement 結果。

---

## 2. RevenueCat Dashboard 設定

### 2-1. 建立 App

1. 登入 [RevenueCat Console](https://app.revenuecat.com/)
2. 點選 **Projects** → **Create new project**
3. 輸入專案名稱（例如：`TravelDiary`）
4. 分別新增 iOS 和 Android App：
   - **iOS App**：輸入 Bundle ID（例如：`com.paulchwu.instantexplore`）
   - **Android App**：輸入 Package Name（例如：`com.paulchwu.instantexplore`）

### 2-2. 取得 API Key

1. 進入 **Project Settings** → **API Keys**
2. 找到：
   - **iOS App** 的 Public API Key（格式：`appl_xxxx...`）→ 這是 `REVENUECAT_API_KEY_IOS`
   - **Android App** 的 Public API Key（格式：`goog_xxxx...`）→ 這是 `REVENUECAT_API_KEY_ANDROID`

> ⚠️ 使用 **Public** (App) API Key，不是 Secret Key。

### 2-3. 建立 Entitlement

Entitlement 是 RevenueCat 的「權益定義」，App 程式碼依賴此名稱判斷用戶是否訂閱。

1. 進入 **Entitlements** → **+ New**
2. **Identifier**：`premium`（必須完全一致，程式碼中寫死此名稱）
3. **Display Name**：Premium

### 2-4. 建立 Product（需先完成平台商品設定，見第 3、4 節）

1. 進入 **Products** → **+ New**
2. 填入：
   - **Product Identifier**：與 App Store / Google Play 一致（例如：`com.paulchwu.instantexplore.premium_monthly`）
   - **App**：選擇對應平台的 App
3. 重複為 iOS 和 Android 各建一個

### 2-5. 建立 Offering

Offering 是展示給用戶的「方案組合」，App 動態從 RevenueCat 拉取。

1. 進入 **Offerings** → **+ New**
2. **Identifier**：`default`（使用預設即可）
3. **Display Name**：Premium Monthly
4. 點進 Offering → **+ Add Package**：
   - **Identifier**：`$rc_monthly`（RevenueCat 內建的每月方案代號）
   - 分別為 iOS 和 Android 綁定對應的 Product

### 2-6. 將 Product 附加到 Entitlement

1. 進入 **Entitlements** → 點選 `premium`
2. **Attach** → 選擇剛建立的 iOS 和 Android Products

---

## 3. App Store Connect 設定（iOS）

### 3-1. 建立 App 內購買項目

1. 登入 [App Store Connect](https://appstoreconnect.apple.com/)
2. 進入你的 App → **功能** → **App 內購買項目**
3. 點選 **+** → 選擇 **自動續訂訂閱**
4. **參考名稱**：Premium Monthly
5. **產品 ID**：`com.paulchwu.instantexplore.premium_monthly`（與 RevenueCat 一致）

### 3-2. 建立訂閱群組

第一次建立自動續訂訂閱時，App Store 會要求建立一個「訂閱群組」：
- **群組名稱**：Premium（對外顯示的名稱）

### 3-3. 設定訂閱詳情

| 欄位 | 填寫內容 |
|------|---------|
| 訂閱期間 | 1 個月 |
| 價格 | 依市場決定（例如 NT$90/月） |
| App Store 本地化 | 填寫名稱（Premium 訂閱）和說明文字 |

### 3-4. 設定 App Store Server Notifications（可選但建議）

1. 進入 **App Store Connect** → **App 資訊** → **App Store 伺服器通知**
2. 填入 RevenueCat 提供的 Webhook URL：
   - 進入 RevenueCat Dashboard → 你的 iOS App → **App Store Server Notifications**
   - 複製提供的 URL

### 3-5. 上傳 Subscription Key（RevenueCat 需要）

1. App Store Connect → **用戶和存取** → **金鑰** → **App Store Connect API**
2. 建立新金鑰，角色選 **App Manager**
3. 下載 `.p8` 金鑰檔
4. 進入 RevenueCat → iOS App 設定 → 上傳此金鑰

### 3-6. 建立 Sandbox 測試帳號

1. App Store Connect → **用戶和存取** → **Sandbox 測試員**
2. 新增測試帳號（使用未在 Apple 帳號系統中的 email）
3. 此帳號可在實機上測試訂閱流程（沙盒環境不會實際收費）

---

## 4. Google Play Console 設定（Android）

### 4-1. 建立訂閱商品

1. 登入 [Google Play Console](https://play.google.com/console/)
2. 選擇你的 App → **營利** → **商品** → **訂閱**
3. 點選 **建立訂閱**
4. 填入：
   - **產品 ID**：`com.paulchwu.instantexplore.premium_monthly`
   - **名稱**：Premium Monthly
   - **說明**：享有無廣告、無限次數導覽和路線規劃

### 4-2. 建立基本方案

1. 點選 **新增基本方案**
2. **基本方案 ID**：`monthly`
3. **續訂週期**：每月
4. **定價**：依市場設定

### 4-3. 設定 Google Real-Time Developer Notifications（可選但建議）

RevenueCat 需要此設定才能即時接收 Google Play 的訂閱狀態更新。

1. Google Cloud Console → 建立 Pub/Sub Topic
2. RevenueCat Dashboard → Android App → **Google Real-Time Developer Notifications**
3. 將 Pub/Sub Topic 名稱填入

### 4-4. 設定 Service Account（RevenueCat 需要）

1. Google Cloud Console → **IAM 與管理** → **服務帳戶**
2. 建立新服務帳戶
3. 賦予權限：`Cloud Pub/Sub Subscriber`
4. 建立 JSON 金鑰並下載
5. Google Play Console → **設定** → **API 存取權** → 授權服務帳戶
6. RevenueCat Dashboard → Android App → 上傳 JSON 金鑰

---

## 5. 環境變數設定

在本地開發時，通過 `--dart-define` 傳入 API Key。

### 5-1. .env 設定（本地）

在 `frontend/` 目錄下建立 `.env`（已在 `.gitignore` 中，不會提交）：

```
REVENUECAT_API_KEY_IOS=appl_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
REVENUECAT_API_KEY_ANDROID=goog_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 5-2. 執行 App

```bash
# 讀取 .env 並執行（iOS）
cd frontend
source ../.env 2>/dev/null || true
fvm flutter run \
  --dart-define=REVENUECAT_API_KEY_IOS=$REVENUECAT_API_KEY_IOS \
  --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID \
  --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

### 5-3. CI/CD（GitHub Actions）

在 GitHub Secrets 中新增：
- `REVENUECAT_API_KEY_IOS`
- `REVENUECAT_API_KEY_ANDROID`

在 workflow YAML 中加入：
```yaml
- name: Build
  run: |
    fvm flutter build ios --no-codesign \
      --dart-define=REVENUECAT_API_KEY_IOS=${{ secrets.REVENUECAT_API_KEY_IOS }} \
      --dart-define=REVENUECAT_API_KEY_ANDROID=${{ secrets.REVENUECAT_API_KEY_ANDROID }}
```

---

## 6. Sandbox 測試

### iOS Sandbox 測試

1. 在實體 iPhone 上執行 App（模擬器不支援訂閱）
2. 設定 → App Store → 使用 Sandbox 帳號登入（第 3-6 節建立的帳號）
3. 在 App 中觸發訂閱流程
4. 沙盒環境特性：
   - 訂閱立即生效
   - 月訂閱的計費週期縮短（5 分鐘 = 1 個月）
   - 不實際收費

### Android 測試

1. 在 Google Play Console → **內部測試** 中上傳 APK
2. 將測試帳號加入內部測試人員
3. 使用測試帳號在裝置上安裝
4. 可用 Google Play 的 License Testing 設定測試不同購買結果

### 驗證 RevenueCat 是否收到購買資訊

1. RevenueCat Dashboard → **Customers**
2. 搜尋測試帳號的 User ID（即 Supabase User ID）
3. 確認 **Active Subscriptions** 顯示 `premium`

---

## 7. 上架前檢查清單

### RevenueCat
- [ ] iOS App 已連接 App Store Connect API 金鑰
- [ ] Android App 已連接 Google Play Service Account
- [ ] Entitlement `premium` 已建立
- [ ] iOS Product 和 Android Product 均已建立並附加至 `premium` Entitlement
- [ ] Offering `default` 已建立，含 `$rc_monthly` Package
- [ ] Real-Time Server Notifications 已設定（iOS + Android）

### App Store Connect
- [ ] 訂閱商品已建立並提交審核
- [ ] 訂閱群組本地化文字已填寫
- [ ] 審核資訊中提供測試帳號

### Google Play Console
- [ ] 訂閱商品已啟用
- [ ] 基本方案定價已設定

### App 程式碼
- [ ] `REVENUECAT_API_KEY_IOS` 環境變數已設定
- [ ] `REVENUECAT_API_KEY_ANDROID` 環境變數已設定
- [ ] `subscription_screen.dart` 中的服務條款 URL 已更新（目前為 `https://paulchwu.com/terms`）
- [ ] `subscription_screen.dart` 中的隱私權政策 URL 已更新（目前為 `https://paulchwu.com/privacy`）

### iOS 審核必要項目
- [ ] 付費牆有「恢復購買」按鈕
- [ ] 付費牆有服務條款連結
- [ ] 付費牆有隱私權政策連結
- [ ] 訂閱說明文字清楚描述費用與週期

---

## 相關檔案

| 檔案 | 說明 |
|------|------|
| `lib/features/subscription/` | 訂閱功能模組 |
| `lib/features/subscription/providers.dart` | Riverpod providers（`subscriptionStatusProvider`、`isPremiumProvider`） |
| `lib/features/subscription/presentation/screens/subscription_screen.dart` | 付費牆畫面 |
| `lib/features/subscription/data/revenuecat_subscription_service.dart` | RevenueCat SDK 實作 |
| `lib/features/usage/data/unlimited_usage_repository.dart` | Premium 用戶的無限額度實作 |
| `docs/superpowers/specs/2026-03-12-subscription-design.md` | 設計規格文件 |
| `docs/superpowers/plans/2026-03-12-subscription.md` | 實作計畫 |
