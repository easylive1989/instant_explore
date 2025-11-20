# 旅食日記 - 設定指南

本指南將協助你完成「旅食日記」App 的初始設定，讓應用程式能夠正常運作。

## 目錄

1. [前置需求](#前置需求)
2. [Supabase 設定](#supabase-設定)
3. [Google Maps API 設定](#google-maps-api-設定)
4. [環境變數設定](#環境變數設定)
5. [專案初始化](#專案初始化)
6. [執行應用程式](#執行應用程式)
7. [常見問題](#常見問題)

---

## 前置需求

在開始之前，請確保已安裝以下工具：

- **Flutter SDK** (3.0.0 或更高版本)
- **Dart SDK** (3.0.0 或更高版本)
- **FVM** (Flutter Version Management)
- **Android Studio** 或 **Xcode** (依據目標平台)
- **Supabase 帳號** (https://supabase.com)
- **Google Cloud Platform 帳號** (用於 Google Maps API)

檢查 Flutter 安裝：

```bash
fvm flutter --version
fvm flutter doctor
```

---

## Supabase 設定

### 1. 建立 Supabase 專案

1. 登入 [Supabase Dashboard](https://app.supabase.com)
2. 點擊「New Project」建立新專案
3. 填寫專案資訊：
   - **Name**: Travel Diary (或你喜歡的名稱)
   - **Database Password**: 設定強密碼並記下來
   - **Region**: 選擇最接近你的區域
4. 等待專案建立完成 (約 2-3 分鐘)

### 2. 執行資料庫 Migration

1. 在 Supabase Dashboard 中，進入你的專案
2. 點擊左側選單的「SQL Editor」
3. 點擊「New query」
4. 複製 `supabase/migrations/20250118_create_diary_tables.sql` 的內容
5. 貼上到 SQL Editor 並執行 (點擊「Run」)
6. 確認執行成功，應該會看到 4 個資料表被建立

### 3. 設定 Storage

1. 在 Supabase Dashboard 中，點擊左側選單的「Storage」
2. 點擊「Create a new bucket」
3. 填寫資訊：
   - **Name**: `diary-images`
   - **Public bucket**: ✅ 勾選 (允許公開存取)
4. 點擊「Create bucket」

#### 設定 Storage 政策

1. 點擊剛建立的 `diary-images` bucket
2. 點擊「Policies」標籤
3. 點擊「New policy」，建立以下政策：

**政策 1: 允許認證用戶上傳**
```sql
-- Policy name: Enable insert for authenticated users
-- Allowed operation: INSERT
-- Target roles: authenticated

(bucket_id = 'diary-images' AND (storage.foldername(name))[1] = auth.uid()::text)
```

**政策 2: 允許認證用戶讀取自己的圖片**
```sql
-- Policy name: Enable read for authenticated users
-- Allowed operation: SELECT
-- Target roles: authenticated

(bucket_id = 'diary-images' AND (storage.foldername(name))[1] = auth.uid()::text)
```

**政策 3: 允許認證用戶刪除自己的圖片**
```sql
-- Policy name: Enable delete for authenticated users
-- Allowed operation: DELETE
-- Target roles: authenticated

(bucket_id = 'diary-images' AND (storage.foldername(name))[1] = auth.uid()::text)
```

### 4. 取得 Supabase 連線資訊

1. 在 Supabase Dashboard 中，點擊左側選單的「Settings」
2. 點擊「API」
3. 記下以下資訊：
   - **Project URL** (例如: `https://xxxxx.supabase.co`)
   - **anon public** API key

---

## Google Maps API 設定

### 1. 建立 Google Cloud Project

1. 前往 [Google Cloud Console](https://console.cloud.google.com)
2. 建立新專案或選擇現有專案
3. 記下專案 ID

### 2. 啟用必要的 API

在 Google Cloud Console 中啟用以下 API：

1. 前往「APIs & Services」>「Library」
2. 搜尋並啟用：
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Places API (New)**
   - **Geocoding API**

### 3. 建立 API 金鑰

1. 前往「APIs & Services」>「Credentials」
2. 點擊「Create Credentials」>「API key」
3. 複製產生的 API 金鑰

### 4. 限制 API 金鑰 (建議)

為了安全性，建議限制 API 金鑰的使用範圍：

**Android 金鑰限制：**
1. 點擊剛建立的 API 金鑰
2. 在「Application restrictions」選擇「Android apps」
3. 新增 Package name 和 SHA-1 憑證指紋
4. 在「API restrictions」選擇「Restrict key」
5. 勾選: Maps SDK for Android, Places API

**iOS 金鑰限制：**
1. 建立另一個 API 金鑰
2. 在「Application restrictions」選擇「iOS apps」
3. 新增 Bundle identifier
4. 在「API restrictions」選擇「Restrict key」
5. 勾選: Maps SDK for iOS, Places API

---

## 環境變數設定

### 1. 建立環境設定檔

在專案根目錄建立 `.env` 檔案：

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend
touch .env
```

### 2. 填寫環境變數

編輯 `.env` 檔案，填入以下資訊：

```env
# Supabase 設定
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Google Maps API Keys
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GOOGLE_PLACES_API_KEY=your-google-places-api-key
```

**重要**: 確認 `.env` 已被加入 `.gitignore`，避免洩漏機密資訊！

### 3. 設定 Android API 金鑰

編輯 `android/app/src/main/AndroidManifest.xml`：

```xml
<application>
    <!-- 在 application 標籤內加入 -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="${GOOGLE_MAPS_API_KEY}"/>
</application>
```

### 4. 設定 iOS API 金鑰

編輯 `ios/Runner/AppDelegate.swift`：

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 專案初始化

### 1. 安裝相依套件

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend
fvm flutter pub get
```

### 2. 清理專案

```bash
fvm flutter clean
```

### 3. 重新建置

```bash
fvm flutter pub get
```

### 4. 程式碼生成 (如有需要)

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

---

## 執行應用程式

### 開發模式執行

```bash
# Android
fvm flutter run --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY

# iOS
fvm flutter run --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
```

### 使用方便的執行腳本

建立 `scripts/run_dev.sh`:

```bash
#!/bin/bash

# 載入環境變數
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# 執行應用程式
fvm flutter run \
    --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
    --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

給予執行權限：

```bash
chmod +x scripts/run_dev.sh
```

執行：

```bash
./scripts/run_dev.sh
```

---

## 常見問題

### Q1: Flutter Doctor 顯示錯誤

**A**: 執行以下命令並依照提示修正：

```bash
fvm flutter doctor -v
```

### Q2: Google Maps 無法顯示

**A**: 檢查以下項目：
1. API 金鑰是否正確設定
2. API 是否已啟用 (Maps SDK, Places API)
3. API 金鑰是否有正確的限制設定
4. 帳單是否已啟用 (Google Maps 需要綁定信用卡)

### Q3: Supabase 連線失敗

**A**: 檢查以下項目：
1. SUPABASE_URL 和 SUPABASE_ANON_KEY 是否正確
2. 網路連線是否正常
3. Supabase 專案是否處於啟用狀態

### Q4: 圖片上傳失敗

**A**: 檢查以下項目：
1. Storage bucket 是否已建立
2. Storage 政策是否正確設定
3. 使用者是否已登入
4. 檔案大小是否超過限制

### Q5: 無法取得當前位置

**A**: 檢查以下項目：
1. 裝置是否已授予位置權限
2. GPS 是否已開啟
3. AndroidManifest.xml 或 Info.plist 是否有設定位置權限

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要存取您的位置以顯示附近的餐廳</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>需要存取您的位置以提供更好的服務</string>
```

---

## 下一步

設定完成後，你可以：

1. 執行應用程式並測試各項功能
2. 建立第一筆日記測試資料
3. 查看 [README.md](README.md) 了解更多功能說明
4. 查看 [CLAUDE.md](CLAUDE.md) 了解專案架構

如有任何問題，請參考專案文件或提出 Issue。

祝你使用愉快！ 🎉

---

## Google 認證設定

### Android 設定

1. **取得 SHA-1 憑證指紋**

開發環境:
```bash
cd android
./gradlew signingReport
```

在輸出中找到 `SHA1` 行，複製該值。

2. **在 Google Cloud Console 設定**

- 前往「APIs & Services」>「Credentials」
- 選擇你的 OAuth 2.0 Client ID (Android)
- 新增 Package name: `com.example.travel_diary`
- 新增 SHA-1 憑證指紋

3. **下載 google-services.json**

- 在 Firebase Console 下載 `google-services.json`
- 放到 `android/app/` 目錄

### iOS 設定

1. **在 Google Cloud Console 建立 iOS Client ID**

- 前往「APIs & Services」>「Credentials」
- 建立 OAuth 2.0 Client ID (iOS)
- 設定 Bundle ID: `com.example.travelDiary`

2. **設定 URL Schemes**

編輯 `ios/Runner/Info.plist`，加入:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

將 `YOUR-CLIENT-ID` 替換為你的實際 Client ID。

3. **下載 GoogleService-Info.plist**

- 在 Firebase Console 下載 `GoogleService-Info.plist`
- 放到 `ios/Runner/` 目錄

### 環境變數更新

在 `.env` 檔案中加入:

```env
# Google OAuth (可選，已使用 google-services.json)
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
```

---

## 認證測試

### 1. 測試登入流程

```bash
./scripts/run_dev.sh
```

應該會看到:
1. 啟動畫面 → 載入中
2. 登入畫面 → 顯示「使用 Google 帳號登入」按鈕
3. 點擊登入 → 開啟 Google 登入流程
4. 登入成功 → 自動導向主畫面

### 2. 測試登出流程

1. 進入「設定」頁面
2. 點擊「登出」
3. 確認對話框點擊「登出」
4. 應該自動返回登入畫面

### 3. 測試認證持久性

1. 登入後關閉 App
2. 重新開啟 App
3. 應該自動登入，直接進入主畫面（不需要重新登入）

---

## 認證流程說明

### 登入流程

```
使用者點擊登入
    ↓
開啟 Google 登入
    ↓
取得 Google ID Token
    ↓
使用 ID Token 登入 Supabase
    ↓
Supabase 建立 Session
    ↓
AuthStateListener 偵測到登入
    ↓
自動導向主畫面
```

### 登出流程

```
使用者點擊登出
    ↓
確認對話框
    ↓
登出 Supabase
    ↓
登出 Google
    ↓
AuthStateListener 偵測到登出
    ↓
自動導向登入畫面
```

### 自動登入

```
App 啟動
    ↓
初始化 Supabase
    ↓
檢查 Session
    ↓
Session 有效？
  是 → 主畫面
  否 → 登入畫面
```

---

## 常見認證問題

### Q: 點擊登入沒有反應

**A**: 檢查以下項目:
1. Google OAuth Client ID 是否正確設定
2. SHA-1 憑證是否已加入 Google Cloud Console
3. `google-services.json` 是否在正確位置
4. 查看 console 是否有錯誤訊息

### Q: 登入後顯示錯誤

**A**: 可能原因:
1. Supabase Auth 未啟用 Google Provider
2. API Config 未正確設定
3. 網路連線問題

檢查 Supabase Dashboard:
- 前往 Authentication > Providers
- 確認 Google 已啟用
- 檢查 Client ID 和 Client Secret

### Q: 無法登出

**A**: 檢查:
1. AuthService 的 signOut 方法是否正常執行
2. 是否有錯誤訊息
3. Supabase 連線是否正常

### Q: 重新開啟 App 需要重新登入

**A**: 這表示 Session 沒有正確保存:
1. 檢查 Supabase 初始化是否正確
2. 確認沒有在登出後清除過多的資料
3. 檢查 Supabase Storage 權限

---
