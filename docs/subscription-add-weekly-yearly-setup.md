# 新增每週 / 每年訂閱方案 — 後台設定指引

本文是 [`subscription-setup.md`](./subscription-setup.md) 的**增量指引**，假設你已完成既有的「每月訂閱」設定，目標是在不影響月訂閱使用者的前提下：

- 在 App Store Connect 與 Google Play Console 各加入「每週」、「每年」兩個訂閱商品
- 在 RevenueCat 將兩個新商品建立為 Products、加入 `default` Offering、附加到 `premium` Entitlement
- 在 Sandbox 上驗證三個方案都可購買

> 程式碼設計請見 [`docs/superpowers/specs/2026-05-11-weekly-subscription-design.md`](./superpowers/specs/2026-05-11-weekly-subscription-design.md)。
> 程式碼會在你完成 RevenueCat Offering 設定後從 SDK 動態讀取三個 package，**不需要**在程式裡 hard-code 商品 ID。

---

## 命名規範（建議）

為了與既有 `premium_monthly` 一致，新增商品建議命名：

| 角色 | iOS Product ID | Android Product ID | Android Base Plan ID | RC Package 預設 ID |
|------|----------------|--------------------|----------------------|---------------------|
| 每週 | `com.paulchwu.instantexplore.premium_weekly` | `instantexplore.premium_weekly` | `weekly` | `$rc_weekly` |
| 每年 | `com.paulchwu.instantexplore.premium_yearly` | `instantexplore.premium_yearly` | `yearly` | `$rc_annual` |

> ⚠️ Bundle / Package ID 請改成你 App 實際使用的值。商品 ID 一旦建立**不能修改**，請先確認再送出。
> `$rc_weekly` / `$rc_annual` 是 RevenueCat 預設的 Package Identifier，App 內 `PackageType.weekly` / `PackageType.annual` 對應這兩個。

---

## 目錄

1. [App Store Connect — iOS 設定](#1-app-store-connect--ios-設定)
2. [Google Play Console — Android 設定](#2-google-play-console--android-設定)
3. [RevenueCat Dashboard — 匯入並加入 Offering](#3-revenuecat-dashboard--匯入並加入-offering)
4. [Sandbox 驗證](#4-sandbox-驗證)
5. [完成檢查清單](#5-完成檢查清單)

---

## 1. App Store Connect — iOS 設定

### 1-1. 進入既有訂閱群組

1. 登入 [App Store Connect](https://appstoreconnect.apple.com/)
2. 進入 App → 左側「**營利**」→「**訂閱**」
3. 點進你既有的「**Premium**」訂閱群組（與 `Premium Monthly` 同一個群組）

> ⚠️ 「每週」與「每年」必須與既有 `Premium Monthly` **放在同一訂閱群組**，使用者才能在三個方案間升級／降級。

### 1-2. 新增「每週」訂閱項目

1. 在群組頁面點「**+**」
2. 填入：
   - **參考名稱**：`Premium Weekly`
   - **產品 ID**：`com.paulchwu.instantexplore.premium_weekly`
3. 進入訂閱項目頁面，完成下列設定：

#### 基本資訊

| 欄位 | 填寫內容 |
|------|---------|
| 訂閱期限 | **1 週** |
| 家人共享 | 視需求開啟 |

#### 供應狀況

點「**設定供應狀況**」→ 選擇要銷售的地區（通常「**所有國家或地區**」）。

#### 訂閱價格

點「**新增訂閱價格**」→ 選擇基準幣別與價格（例如 USD $1.49）。

#### App Store 本地化資訊

- **顯示名稱**：`Premium 週訂閱`
- **說明**：`享有無廣告、無限次數導覽和路線規劃。每週自動續訂。`
- 至少填寫一個語系（中、英）；提交審核時所有銷售地區語言都需有對應字段，建議與既有月訂閱同步。

### 1-3. 新增「每年」訂閱項目

重複 1-2，差異欄位：

| 欄位 | 填寫內容 |
|------|---------|
| 參考名稱 | `Premium Yearly` |
| 產品 ID | `com.paulchwu.instantexplore.premium_yearly` |
| 訂閱期限 | **1 年** |
| 訂閱價格 | 依市場策略（例如 USD $19.99） |
| 顯示名稱 | `Premium 年訂閱` |
| 說明 | `享有無廣告、無限次數導覽和路線規劃。每年自動續訂。` |

### 1-4. 提交審核

- 兩個新訂閱商品都必須狀態為「**準備提交**」→「**等待審核**」→「**已核准**」才能在 Sandbox 與 Production 使用。
- 第一次新增訂閱商品時，App Store 會要求你在 App 提交審核時一起送，但**只新增訂閱商品**通常可以單獨提交審核。
- 審核時記得：付費牆截圖、審核備註提供 Sandbox 測試帳號。

---

## 2. Google Play Console — Android 設定

Google Play 有兩種做法，本文採 **「同一訂閱多個 base plan」** 模式，與你既有 `instantexplore.premium_monthly` 結構保持一致：每個訂閱 product 下只有一個 base plan。也就是說 weekly / monthly / yearly 各自是獨立的 subscription product。

### 2-1. 建立「每週」訂閱

1. 登入 [Google Play Console](https://play.google.com/console/)
2. 進入 App → **營利** → **商品** → **訂閱** → 點「**建立訂閱**」
3. 填入：
   - **產品 ID**：`instantexplore.premium_weekly`（**40 字元上限**、建立後不可改）
   - **名稱**：`Premium Weekly`
   - **說明**：享有無廣告、無限次數導覽和路線規劃，每週自動續訂
4. 進入訂閱詳情頁，點「**新增基本方案**」：
   - **基本方案 ID**：`weekly`
   - **基本方案類型**：自動續訂
   - **續訂週期**：每週
   - **定價**：依市場設定（建議匯率與 iOS 相當）
   - **方案地區**：所有支援地區
5. 完成後將基本方案狀態設為「**啟用**」

### 2-2. 建立「每年」訂閱

重複 2-1，差異：

| 欄位 | 填寫內容 |
|------|---------|
| 產品 ID | `instantexplore.premium_yearly` |
| 名稱 | `Premium Yearly` |
| 基本方案 ID | `yearly` |
| 續訂週期 | **每年** |
| 定價 | 依市場策略 |

### 2-3. 確認 Service Account 權限

新增的 subscription products 會自動繼承既有的 Service Account 權限（在 `subscription-setup.md` § 4-4 設定）。如果你之後手動建立過新的 Service Account，需到 **設定 → API 存取權** 確認新訂閱仍可被存取。

---

## 3. RevenueCat Dashboard — 匯入並加入 Offering

進入 [RevenueCat Dashboard](https://app.revenuecat.com/) → 你的專案。

### 3-1. 匯入或建立 Products

#### Android（建議自動匯入）

1. **Products** → 頁面頂端「**Import Products**」
2. 授權 Google Play 後，會列出尚未匯入的 base plans：勾選 `instantexplore.premium_weekly:weekly` 與 `instantexplore.premium_yearly:yearly`，點「**Import**」
3. 匯入完成後 Products 列表會多出兩筆

> 如果你偏好手動建立，欄位填法請參考 `subscription-setup.md` § 2-4 的「Android 手動建立」表，把 `monthly` 對應位置換成 `weekly` / `yearly`。

#### iOS（手動建立）

iOS 端無法從 App Store Connect 自動拉取，需手動建立兩筆：

| 欄位（每週） | 填寫 |
|--------------|------|
| Identifier | `com.paulchwu.instantexplore.premium_weekly` |
| Display name | `premium_weekly` |
| Product type | Subscription |

| 欄位（每年） | 填寫 |
|--------------|------|
| Identifier | `com.paulchwu.instantexplore.premium_yearly` |
| Display name | `premium_yearly` |
| Product type | Subscription |

### 3-2. Attach 到既有 `premium` Entitlement

**Entitlements** → 點 `premium` → 「**Attach**」→ 把剛建立的 4 個 Products（iOS weekly、iOS yearly、Android weekly、Android yearly）都加進去。

> 這一步是程式判斷 `entitlements.active['premium']` 是否存在的關鍵；漏掉的話購買成功但 App 端不會解鎖 Premium。

### 3-3. 在 `default` Offering 加入 Weekly / Annual Package

**Offerings** → 點既有的 `default` offering → 「**+ New Package**」加入兩個 Package：

#### 加 Weekly Package

| 欄位 | 填寫 |
|------|------|
| Package Identifier | 下拉選 **Weekly** （會儲存為 `$rc_weekly`） |
| Description | `週訂閱方案，享有無廣告、無限次數導覽與路線規劃` |
| Products → App Store | `premium_weekly` |
| Products → Play Store | `premium_weekly` |

#### 加 Annual Package

| 欄位 | 填寫 |
|------|------|
| Package Identifier | 下拉選 **Annual** （會儲存為 `$rc_annual`） |
| Description | `年訂閱方案，享有無廣告、無限次數導覽與路線規劃，最划算` |
| Products → App Store | `premium_yearly` |
| Products → Play Store | `premium_yearly` |

完成後 `default` offering 應該有三個 Packages：`$rc_monthly`、`$rc_weekly`、`$rc_annual`。

> ⚠️ Package Identifier **必須**用下拉預設值（Weekly / Monthly / Annual），不要用 Custom。
> 程式碼依賴 `PackageType.weekly | monthly | annual` 區分週期，自訂 identifier 會被視為 `PackageType.unknown` 而過濾掉。

### 3-4. 確認 `current` Offering 仍是 `default`

**Offerings** 列表 → 左邊有星號 ★ 的就是 `current`。確認 `default` 是 current；如果你建過多個 offering，點 default 的「**Make current**」。

---

## 4. Sandbox 驗證

### 4-1. iOS

1. 在實體 iPhone 上用 Sandbox 帳號登入（設定 → App Store）
2. 安裝 dev build：
   ```bash
   cd frontend
   source ../.env
   fvm flutter run \
     --dart-define=REVENUECAT_API_KEY_IOS=$REVENUECAT_API_KEY_IOS \
     --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID \
     # ...其他 dart-define 同既有 setup
   ```
3. 開啟付費牆，確認顯示 **三張卡片**（順序：Weekly → Monthly → Yearly）
4. 確認 Yearly 卡片預設選取，且有「Best value」徽章
5. 分別測試三個方案的購買流程
6. Sandbox 月訂閱續訂週期被加速（5 分鐘 = 1 個月、3 分鐘 = 1 週、1 小時 = 1 年）

### 4-2. Android

1. 把 dev build 上傳到 **內部測試** 軌道
2. 用內部測試人員帳號在裝置上安裝（**不要**用 `flutter run` 安裝，Google Play Billing 需從 Play 安裝才能驗證）
3. 確認三張卡片顯示與選取行為
4. 測試三個方案的購買流程
5. Google Play 的測試訂閱續訂週期被加速（與 iOS 規則類似）

### 4-3. RevenueCat Customers 驗證

每次測試購買後：

1. RevenueCat Dashboard → **Customers**
2. 用 Supabase User ID 搜尋
3. **Active Subscriptions** 應顯示 `premium`，**Product** 欄會標出剛購買的方案

---

## 5. 完成檢查清單

### App Store Connect
- [ ] `Premium Weekly` 訂閱已建立、提交審核並通過
- [ ] `Premium Yearly` 訂閱已建立、提交審核並通過
- [ ] 兩者與 `Premium Monthly` 在**同一個訂閱群組**
- [ ] 兩者的本地化資訊、供應地區、訂閱價格都已設定

### Google Play Console
- [ ] `instantexplore.premium_weekly` 訂閱與 `weekly` 基本方案已啟用
- [ ] `instantexplore.premium_yearly` 訂閱與 `yearly` 基本方案已啟用
- [ ] 兩者皆有定價並開放給目標地區
- [ ] Service Account 仍能存取新訂閱

### RevenueCat
- [ ] iOS / Android weekly Products 已建立
- [ ] iOS / Android yearly Products 已建立
- [ ] 四個 Products 都已 attach 到 `premium` Entitlement
- [ ] `default` Offering 內有 `$rc_weekly`、`$rc_monthly`、`$rc_annual` 三個 Packages
- [ ] `default` 仍是 `current` Offering

### Sandbox / Internal Testing
- [ ] iOS Sandbox 可購買 weekly / monthly / yearly
- [ ] Android Internal Testing 可購買 weekly / monthly / yearly
- [ ] 購買後 RevenueCat Customers 頁面顯示 `premium` Active
- [ ] App 內 `subscriptionStatusProvider` 反映為 premium，所有 Premium 功能解鎖

---

## 相關文件

| 檔案 | 角色 |
|------|------|
| `docs/subscription-setup.md` | 既有訂閱（月）完整設定 |
| `docs/superpowers/specs/2026-05-11-weekly-subscription-design.md` | 本次新增每週訂閱的程式設計文件 |
