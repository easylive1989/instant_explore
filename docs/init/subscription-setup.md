# 訂閱功能設定教學

本文說明如何在 App Store Connect、Google Play Console、RevenueCat Dashboard 完成訂閱商品設定，以及如何在本地開發環境中設定 API Key。本教學涵蓋了「每週」、「每月」、「每年」三種訂閱方案的設定。

---

## 命名規範（建議）

為了保持各平台與 RevenueCat 之間商品 ID 的一致性，建議採用以下命名規範：

| 方案 | iOS Product ID | Android Product ID | Android Base Plan ID | RC Package 預設 ID |
|------|----------------|--------------------|----------------------|---------------------|
| 每週 | `com.paulchwu.instantexplore.premium_weekly` | `instantexplore.premium_weekly` | `weekly` | `$rc_weekly` |
| 每月 | `com.paulchwu.instantexplore.premium_monthly` | `instantexplore.premium_monthly` | `monthly` | `$rc_monthly` |
| 每年 | `com.paulchwu.instantexplore.premium_yearly` | `instantexplore.premium_yearly` | `yearly` | `$rc_annual` |

> ⚠️ Bundle / Package ID 請改成你 App 實際使用的值。商品 ID 一旦建立**不能修改**，請先確認再送出。
> `$rc_weekly`、`$rc_monthly`、`$rc_annual` 是 RevenueCat 預設的 Package Identifier，App 內 `PackageType.weekly` / `monthly` / `annual` 對應這三個。程式會從 SDK 動態讀取這三個 package，**不需要**在程式裡 hard-code 商品 ID。

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

> ⚠️ 必須先在 App Store Connect / Google Play Console 建立好訂閱商品，再回到 RevenueCat 建立 Product。

#### Android 自動匯入（建議）

RevenueCat 支援直接從 Google Play Console 匯入：
1. 進入 **Products** → 點選頁面頂端的 **Import Products** 按鈕。
2. 授權後勾選尚未匯入的 base plans：例如 `instantexplore.premium_weekly:weekly`、`instantexplore.premium_monthly:monthly`、`instantexplore.premium_yearly:yearly`。
3. 點選 **Import** 即可自動帶入已建立的訂閱商品。

#### iOS 手動建立

iOS 端無法自動拉取，需點選 **Products** → **+ New** 手動建立三筆：

| 欄位 | 每週方案填法 | 每月方案填法 | 每年方案填法 |
|------|--------------|--------------|--------------|
| **Identifier** | `com.paulchwu.instantexplore.premium_weekly` | `com.paulchwu.instantexplore.premium_monthly` | `com.paulchwu.instantexplore.premium_yearly` |
| **Display name** | `premium_weekly` | `premium_monthly` | `premium_yearly` |
| **Product type** | Subscription | Subscription | Subscription |

*Identifier 必須與 App Store Connect 的 Product ID 完全一致。*

---

### 2-5. 建立 Offering 與 Package

Offering 是展示給用戶的「方案組合」，App 動態從 RevenueCat 拉取。

#### 建立 Offering
1. 進入 **Offerings** → **+ New**
2. 填入：
   - **Identifier**：`default`（SDK 透過此名稱取得 Offering，建立後無法修改）
   - **Display Name**：`Premium Plans`

#### 新增 Package
點進剛建立的 `default` Offering → **+ New Package**，建立三個 Package：

1. **每週 Package**
   - **Package Identifier**：下拉選擇 **Weekly**（會自動儲存為 `$rc_weekly`）
   - **Description**：`週訂閱方案，享有無廣告、無限次數導覽與路線規劃`
   - **Products → App Store**：選擇 `premium_weekly`
   - **Products → Play Store**：選擇 `premium_weekly`

2. **每月 Package**
   - **Package Identifier**：下拉選擇 **Monthly**（會自動儲存為 `$rc_monthly`）
   - **Description**：`月訂閱方案，享有無廣告、無限次數導覽與路線規劃`
   - **Products → App Store**：選擇 `premium_monthly`
   - **Products → Play Store**：選擇 `premium_monthly`

3. **每年 Package**
   - **Package Identifier**：下拉選擇 **Annual**（會自動儲存為 `$rc_annual`）
   - **Description**：`年訂閱方案，享有無廣告、無限次數導覽與路線規劃，最劃算`
   - **Products → App Store**：選擇 `premium_yearly`
   - **Products → Play Store**：選擇 `premium_yearly`

> ⚠️ Package Identifier **必須**用下拉預設值，不要用 Custom。
> 程式碼依賴 `PackageType.weekly | monthly | annual` 區分週期，自訂 identifier 會被視為 `PackageType.unknown` 而過濾掉。

#### 確認 current Offering
確認 `default` Offering 是預設的 Offering（列表左邊有星號 ★ 標記）。如果不是，點選並點擊「Make current」。

### 2-6. 將 Product 附加到 Entitlement

1. 進入 **Entitlements** → 點選 `premium`
2. **Attach** → 選擇剛建立的所有 6 個 Products（3 個 iOS Products + 3 個 Android Products）。

> 這一步是程式判斷 `entitlements.active['premium']` 是否存在的關鍵；漏掉的話購買成功但 App 端不會解鎖 Premium。

---

## 3. App Store Connect 設定（iOS）

> ⚠️ 訂閱商品在「**訂閱**」頁面建立，不是「App 內購買項目」。兩者是不同的入口：
> - **App 內購買項目**：消耗性、非消耗性商品（一次性購買）
> - **訂閱**：自動續訂訂閱（本專案使用此項）

### 3-1. 建立訂閱群組

1. 登入 [App Store Connect](https://appstoreconnect.apple.com/)
2. 進入你的 App → 左側「**營利**」區塊 → **訂閱**
3. 在「**自動續訂型訂閱**」區塊點選「**建立**」
4. 輸入訂閱群組名稱：`Premium`，按「建立」

> ⚠️ 「每週」、「每月」與「每年」必須**放在同一個訂閱群組**，使用者才能在三個方案間進行升級／降級。

### 3-2. 在群組內新增訂閱項目

在剛建立的 `Premium` 群組內點選「**+**」，依序建立以下三個項目：

1. **每週方案**
   - **參考名稱**：`Premium Weekly`（內部名稱）
   - **產品 ID**：`com.paulchwu.instantexplore.premium_weekly`

2. **每月方案**
   - **參考名稱**：`Premium Monthly`（內部名稱）
   - **產品 ID**：`com.paulchwu.instantexplore.premium_monthly`

3. **每年方案**
   - **參考名稱**：`Premium Yearly`（內部名稱）
   - **產品 ID**：`com.paulchwu.instantexplore.premium_yearly`

### 3-3. 設定訂閱詳情

進入各個訂閱項目頁面，完成以下設定：

#### 基本資訊與期限

| 方案 | 參考名稱 | 訂閱期限 |
|------|---------|---------|
| 每週 | `Premium Weekly` | **1 週** |
| 每月 | `Premium Monthly` | **1 個月** |
| 每年 | `Premium Yearly` | **1 年** |

#### 供應狀況（必填）
點選「**設定供應狀況**」→ 選擇要銷售的國家或地區（通常選「所有國家和地區」）。

#### 訂閱價格（必填）
點選「**新增訂閱價格**」設定基準幣別與價格（例如：每週 $1.49、每月 $2.99、每年 $19.99）。App Store 會自動換算其他地區的建議售價。

#### App Store 本地化資訊（必填）
為每個方案設定至少一個語系（中、英）的顯示名稱與描述：
- **每週方案**
  - **顯示名稱**：`Premium 週訂閱`
  - **說明**：`享有無廣告、無限次數導覽和路線規劃。每週自動續訂。`
- **每月方案**
  - **顯示名稱**：`Premium 月訂閱`
  - **說明**：`享有無廣告、無限次數導覽和路線規劃。每月自動續訂。`
- **每年方案**
  - **顯示名稱**：`Premium 年訂閱`
  - **說明**：`享有無廣告、無限次數導覽和路線規劃。每年自動續訂。`

### 3-4. 設定 App Store Server Notifications（可選但建議）

1. 進入 **App Store Connect** → **App 資訊** → **App Store 伺服器通知**
2. 填入 RevenueCat 提供的 Webhook URL（可至 RevenueCat Dashboard 的 iOS App 設定中取得）。

### 3-5. 上傳 Subscription Key（RevenueCat 需要）

1. App Store Connect → **用戶和存取** → **金鑰** → **App Store Connect API**
2. 建立新金鑰，角色選 **App Manager**
3. 下載 `.p8` 金鑰檔
4. 進入 RevenueCat → iOS App 設定 → 上傳此金鑰

### 3-6. 建立 Sandbox 測試帳號

1. App Store Connect → **用戶和存取** → **Sandbox 測試員**
2. 新增測試帳號（使用未註冊為 Apple ID 的 email）

---

## 4. Google Play Console 設定（Android）

本專案採用 **「每個訂閱 Product 包含單一 Base Plan」** 的模式（即 Weekly / Monthly / Yearly 各自是獨立的 Subscription Product，各自底下只有一個對應的 Base Plan）。

### 4-1. 建立訂閱商品

依序為三個方案建立訂閱商品：
1. 登入 [Google Play Console](https://play.google.com/console/)
2. 選擇你的 App → **營利** → **商品** → **訂閱** → 點選 **建立訂閱**
3. 填入資訊：

| 欄位 | 每週方案填法 | 每月方案填法 | 每年方案填法 |
|------|--------------|--------------|--------------|
| **產品 ID** | `instantexplore.premium_weekly` | `instantexplore.premium_monthly` | `instantexplore.premium_yearly` |
| **名稱** | `Premium Weekly` | `Premium Monthly` | `Premium Yearly` |
| **說明** | 享有無廣告、無限次數導覽，每週自動續訂 | 享有無廣告、無限次數導覽，每月自動續訂 | 享有無廣告、無限次數導覽，每年自動續訂 |

*產品 ID 最多 40 字元，建立後無法修改。*

### 4-2. 建立基本方案 (Base Plan)

進入各個訂閱商品的詳情頁面，點選 **新增基本方案**：

1. **每週方案 Base Plan**
   - **基本方案 ID**：`weekly`
   - **基本方案類型**：自動續訂
   - **續訂週期**：每週
   - **定價**：依市場設定

2. **每月方案 Base Plan**
   - **基本方案 ID**：`monthly`
   - **基本方案類型**：自動續訂
   - **續訂週期**：每月
   - **定價**：依市場設定

3. **每年方案 Base Plan**
   - **基本方案 ID**：`yearly`
   - **基本方案類型**：自動續訂
   - **續訂週期**：每年
   - **定價**：依市場設定

> ⚠️ 設定完成後，必須將每個基本方案的狀態設為 **「啟用」**，RevenueCat 才能順利讀取。

### 4-3. 設定 Google Real-Time Developer Notifications（可選但建議）

沒有此設定，RevenueCat 無法即時得知訂閱狀態變更（例如用戶取消、續訂失敗）。

#### 步驟一：在 Google Cloud Console 建立 Pub/Sub Topic
1. 登入 [Google Cloud Console](https://console.cloud.google.com/)
2. 選擇與 Google Play 連結的專案，前往 **Pub/Sub** → **Topics** → **Create Topic**。
3. **Topic ID**：填入 `play-billing`。建立後複製完整 Topic 名稱。

#### 步驟二：在 RevenueCat 連接 Topic
1. 前往 RevenueCat Dashboard → 你的 Android App → **Google developer notifications**。
2. 選擇剛建立的 Topic，並點選 **Connect to Google**。

#### 步驟三：授予 Google Play 發布到 Topic 的權限
1. 前往 Google Cloud Console → **Pub/Sub** → **Topics** → 點選 `play-billing`。
2. 點選右側「**權限**」分頁 → **新增主體**：
   - **新增主體**：`google-play-developer-notifications@system.gserviceaccount.com`
   - **角色**：`Pub/Sub 發布者`（Pub/Sub Publisher）
3. 儲存。

#### 步驟四：在 Google Play Console 填入 Topic
1. 登入 Google Play Console → 選擇 App → **營利 → 設定 → 開發人員通知**。
2. 勾選「**啟用即時通知**」。
3. **主題名稱**填入你的 Pub/Sub Topic 完整名稱。
4. 點選「傳送測試通知」確認成功後儲存。

### 4-4. 設定 Service Account（RevenueCat 需要）

1. Google Cloud Console → **IAM 與管理** → **服務帳戶** → 建立新服務帳戶。
2. 賦予權限：`Cloud Pub/Sub Subscriber`。
3. 建立 JSON 金鑰並下載。
4. Google Play Console → **設定** → **API 存取權** → 授權服務帳戶。
5. RevenueCat Dashboard → Android App → 上傳 JSON 金鑰。

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
# 讀取 .env 並執行
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

---

## 6. Sandbox 測試

### iOS Sandbox 測試

1. 在實體 iPhone 上執行 App（模擬器不支援訂閱）。
2. 設定 → App Store → 使用 Sandbox 測試員帳號登入。
3. 在 App 中開啟付費牆，確認顯示 **三張卡片**（順序：Weekly → Monthly → Yearly），確認 Yearly 預設被選取且有標章。
4. 測試購買流程。在 Sandbox 下：
   - 1 週 = 3 分鐘
   - 1 個月 = 5 分鐘
   - 1 年 = 1 小時

### Android 測試

1. 將 App 上傳至 Google Play Console **內部測試** 軌道。
2. 使用測試帳號在實機上安裝。
3. 開啟付費牆並測試三個方案的購買。

---

## 7. 上架前檢查清單

### RevenueCat
- [ ] iOS App 已連接 App Store Connect API 金鑰。
- [ ] Android App 已連接 Google Play Service Account。
- [ ] Entitlement `premium` 已建立。
- [ ] 週、月、年共 6 個 Products 均已附加至 `premium` Entitlement。
- [ ] Offering `default` 已建立，含 `$rc_weekly`、`$rc_monthly`、`$rc_annual` 三個 Packages。
- [ ] Real-Time Server Notifications 已設定（iOS + Android）。

### App Store Connect
- [ ] `Premium Weekly`, `Premium Monthly`, `Premium Yearly` 均已建立且在**同一個訂閱群組**下。
- [ ] 訂閱項目均已完成定價、銷售地區與本地化名稱文字設定。

### Google Play Console
- [ ] 三個訂閱商品及對應的 `weekly`、`monthly`、`yearly` 基本方案均已啟用。

---

## 相關檔案與文件

| 檔案 | 說明 |
|------|------|
| `lib/features/subscription/` | 訂閱功能模組 |
| `lib/features/subscription/providers.dart` | Riverpod providers（`subscriptionStatusProvider`、`isPremiumProvider`） |
| `lib/features/subscription/presentation/screens/subscription_screen.dart` | 付費牆畫面（展示三張卡片） |
| `lib/features/subscription/data/revenuecat_subscription_service.dart` | RevenueCat SDK 實作 |
| `docs/superpowers/specs/2026-05-11-weekly-subscription-design.md` | 新增每週與每年訂閱的程式設計文件 |
| `docs/superpowers/specs/2026-03-12-subscription-design.md` | 訂閱功能初始設計規格文件 |
