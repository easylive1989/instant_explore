# iOS Share Extension 設定指南

本文件說明如何在 Xcode 中為 Contexture 讀景 App 設定 iOS Share Extension，讓使用者可以從 Google Maps 分享地點到 App。

> **前置條件**：已完成 `receive_sharing_intent` 套件的 Flutter 端整合（`pubspec.yaml`、`providers.dart`、`app.dart`）。

---

## 1. 建立 App Group

主 App 與 Share Extension 是獨立的 process，需透過 **App Group** 共享資料。

### 1.1 在 Apple Developer Portal 建立 App Group

1. 前往 [Apple Developer — Identifiers](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
2. 點擊 **+** → 選擇 **App Groups**
3. 輸入 Group ID：

   ```
   group.com.paulchwu.instantexplore
   ```

4. 點擊 **Continue** → **Register**

### 1.2 更新主 App 的 App ID

1. 在 Identifiers 中找到 `com.paulchwu.instantexplore`
2. 編輯 → 勾選 **App Groups**
3. 選擇剛建立的 `group.com.paulchwu.instantexplore`
4. 儲存

---

## 2. 在 Xcode 中新增 Share Extension Target

1. 在 Xcode 中開啟 `ios/Runner.xcworkspace`
2. 點擊左側 Project Navigator 中的 **Runner** 專案（藍色圖示）
3. 在左下角點擊 **+** 按鈕（或選單 File → New → Target…）
4. 選擇 **iOS → Share Extension**
5. 填入：
   - **Product Name**：`ShareExtension`
   - **Language**：Swift
   - **Bundle Identifier**：`com.paulchwu.instantexplore.ShareExtension`
6. 點擊 **Finish**
7. 如果出現 "Activate scheme?" 對話框，選擇 **Cancel**（保持使用 Runner scheme）

完成後，專案中會出現 `ShareExtension/` 資料夾，包含：

```
ios/
├── ShareExtension/
│   ├── ShareViewController.swift
│   └── Info.plist
```

---

## 3. 設定 App Groups Capability

### 3.1 主 App（Runner）

1. 選擇 **Runner** target
2. 切到 **Signing & Capabilities** 分頁
3. 點擊 **+ Capability** → 搜尋並加入 **App Groups**
4. 勾選 `group.com.paulchwu.instantexplore`

此操作會自動更新 `Runner/Runner.entitlements`，加入：

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.paulchwu.instantexplore</string>
</array>
```

### 3.2 Share Extension

1. 選擇 **ShareExtension** target
2. 切到 **Signing & Capabilities** 分頁
3. 設定正確的 **Team** 和 **Signing Certificate**（與主 App 相同）
4. 點擊 **+ Capability** → 加入 **App Groups**
5. 勾選同一個 `group.com.paulchwu.instantexplore`

---

## 4. 設定 Share Extension 的 Info.plist

開啟 `ios/ShareExtension/Info.plist`，將內容替換為：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AppGroupId</key>
    <string>group.com.paulchwu.instantexplore</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>NSExtensionActivationRule</key>
            <dict>
                <key>NSExtensionActivationSupportsText</key>
                <true/>
                <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
                <integer>1</integer>
            </dict>
        </dict>
        <key>NSExtensionMainStoryboard</key>
        <string>MainInterface</string>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
    </dict>
</dict>
</plist>
```

**說明**：
- `NSExtensionActivationSupportsText`：允許接收純文字（Google Maps 分享的地點名稱 + URL）
- `NSExtensionActivationSupportsWebURLWithMaxCount`：允許接收網址（1 個）
- `AppGroupId`：供 `receive_sharing_intent` 在 Extension 與主 App 間傳遞資料

---

## 5. 替換 ShareViewController.swift

開啟 `ios/ShareExtension/ShareViewController.swift`，替換為以下內容：

```swift
import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private let appGroupId = "group.com.paulchwu.instantexplore"
    private let sharedKey = "ShareKey"

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        guard let extensionItem = extensionContext?.inputItems.first
                as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(
                UTType.url.identifier
            ) {
                provider.loadItem(
                    forTypeIdentifier: UTType.url.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let url = data as? URL {
                        self?.save(url.absoluteString)
                    }
                    self?.completeRequest()
                }
                return
            }

            if provider.hasItemConformingToTypeIdentifier(
                UTType.plainText.identifier
            ) {
                provider.loadItem(
                    forTypeIdentifier: UTType.plainText.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let text = data as? String {
                        self?.save(text)
                    }
                    self?.completeRequest()
                }
                return
            }
        }

        completeRequest()
    }

    override func configurationItems()
        -> [Any]! {
        return []
    }

    /// 將分享的文字存到 App Group UserDefaults，
    /// 主 App 透過 receive_sharing_intent 讀取。
    private func save(_ text: String) {
        let userDefaults = UserDefaults(
            suiteName: appGroupId
        )
        userDefaults?.set(text, forKey: sharedKey)
        userDefaults?.synchronize()
    }

    private func completeRequest() {
        extensionContext?.completeRequest(
            returningItems: [],
            completionHandler: nil
        )
    }
}
```

---

## 6. 更新 Podfile

在 `ios/Podfile` 中新增 Share Extension target，讓 CocoaPods 為它安裝必要的 pod：

```ruby
target 'Runner' do
  use_frameworks!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end

  target 'RunnerUITests' do
    inherit! :complete
  end
end

# --- 新增以下區塊 ---
target 'ShareExtension' do
  use_frameworks!
end
```

新增後執行：

```bash
cd ios
pod install
```

---

## 7. 設定 Build Settings

### 7.1 Deployment Target

1. 選擇 **ShareExtension** target
2. **Build Settings** → 搜尋 `iOS Deployment Target`
3. 設為 **15.0**（與主 App 一致）

### 7.2 Build 版號同步

確保 Share Extension 的版號與主 App 同步。在 ShareExtension 的 **Build Settings** 中：

1. 搜尋 `MARKETING_VERSION`，設為 `$(FLUTTER_BUILD_NAME)`
2. 搜尋 `CURRENT_PROJECT_VERSION`，設為 `$(FLUTTER_BUILD_NUMBER)`

或者在 Share Extension 的 Info.plist 中使用變數（如步驟 4 所示的 `$(FLUTTER_BUILD_NUMBER)`）。

---

## 8. 驗證設定

### 8.1 確認檔案結構

完成後，`ios/` 目錄結構應如下：

```
ios/
├── Runner/
│   ├── AppDelegate.swift
│   ├── Runner.entitlements        ← 包含 App Groups
│   ├── Info.plist
│   └── ...
├── ShareExtension/
│   ├── ShareViewController.swift  ← 分享邏輯
│   ├── Info.plist                 ← Extension 設定
│   └── ShareExtension.entitlements ← 包含 App Groups
├── Podfile                        ← 包含 ShareExtension target
└── ...
```

### 8.2 在模擬器或真機上測試

1. 用 Xcode 編譯並安裝 App 到裝置
2. 開啟 Safari，瀏覽任意 Google Maps 地點頁面
3. 點擊分享按鈕 → 在分享清單中找到 **Contexture**
4. 點擊 → 確認 App 開啟後顯示「已儲存至地點清單」的 SnackBar

### 8.3 常見問題

| 問題 | 解法 |
|------|------|
| 分享清單中看不到 Contexture | 確認 Info.plist 的 `NSExtensionActivationRule` 設定正確，且 Extension 有正確簽署 |
| App 開啟但沒有接收到資料 | 確認主 App 和 Extension 使用相同的 App Group ID |
| 編譯錯誤：找不到 module | 執行 `cd ios && pod install`，確認 Podfile 包含 ShareExtension target |
| Extension 閃退 | 檢查 `ShareViewController.swift` 的 `appGroupId` 是否與 entitlements 中一致 |

---

## 9. 注意事項

- **Share Extension 有 memory 限制**（約 120 MB），不要在 Extension 中做大量運算
- 每次更新 `receive_sharing_intent` 版本後，確認 `ShareViewController.swift` 與套件版本相容
- 若 App 上架 App Store，Share Extension 需一併提交審核
- 簽署 Extension 時需使用包含 App Groups capability 的 Provisioning Profile
