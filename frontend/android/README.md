# Android Debug Keystore

這個目錄包含專案專用的 debug keystore，確保所有開發者使用相同的 SHA 指紋。

## 重要資訊

### Keystore 詳細資訊
- **檔案名稱**: `debug.keystore`
- **Store 密碼**: `android`
- **Key 別名**: `androiddebugkey`
- **Key 密碼**: `android`

### SHA 指紋
這些指紋用於 Google Cloud Console 的 OAuth 2.0 設定：

```
SHA1: 65:31:24:6A:5F:23:88:8E:70:96:33:46:35:71:6D:23:02:E8:8B:90
SHA256: 4B:E5:76:ED:3E:4A:D8:8C:DB:7B:BA:3C:90:29:89:4D:73:DF:36:8F:F4:8D:EB:2D:E0:DB:E8:E2:DE:B8:DE:F0
```

## Google Cloud Console 設定

### 設定 Android OAuth Client ID
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 選擇你的專案
3. 前往 "API 和服務" → "憑證"
4. 點擊 "建立憑證" → "OAuth 用戶端 ID"
5. 選擇 "Android"
6. 輸入以下資訊：
   - **套件名稱**: `com.paulchwu.instantexplore`
   - **SHA-1 憑證指紋**: `65:31:24:6A:5F:23:88:8E:70:96:33:46:35:71:6D:23:02:E8:8B:90`

## 檔案說明

### `debug.keystore`
- 專案專用的 debug keystore
- **已提交到 Git**，所有開發者共用
- 僅用於開發和測試，不得用於正式發布

### `keystore.properties`
- 包含 keystore 的路徑和密碼資訊
- **未提交到 Git**（在 .gitignore 中）
- 每個開發者需要自己建立

### 建立 `keystore.properties`
在 `android/` 目錄下建立 `keystore.properties` 檔案：

```properties
storePassword=android
keyPassword=android
keyAlias=androiddebugkey
storeFile=debug.keystore
```

## 使用方式

1. 克隆專案後，確保 `debug.keystore` 存在於 `android/` 目錄
2. 建立 `keystore.properties` 檔案（見上方說明）
3. 正常執行 `flutter run` 即可

## 注意事項

⚠️ **重要安全提醒**：
- 這個 keystore 僅供開發使用
- 正式發布版本必須使用不同的 release keystore
- 永遠不要在正式版本中使用 debug keystore
- release keystore 絕對不可提交到版本控制系統

## 驗證 Keystore

你可以使用以下指令驗證 keystore 的指紋：

```bash
keytool -list -v -keystore debug.keystore -storepass android
```

應該看到與上方相同的 SHA1 和 SHA256 指紋。