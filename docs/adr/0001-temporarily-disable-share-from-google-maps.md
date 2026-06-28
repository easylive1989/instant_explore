# ADR 0001：暫時關閉「從 Google Maps 分享地點到 App」功能

- 狀態：Accepted（暫時性決定）
- 日期：2026-05-13
- 影響範圍：iOS Share Extension、Android `SEND` intent filter、Flutter 端 share intent listener

## 背景

App 原本支援使用者從 Google Maps（與其他可分享純文字的 app）將地點分享進 Lorescape，由 `ShareIntentHandler` 解析、搜尋、自動存入 saved locations。實際使用上回報「很容易找不到」，分析後找出根因：

1. **資料源錯位**：`PlacesRepositoryImpl.searchPlaces` 走的是 Wikipedia / Wikidata，只涵蓋「上 Wikipedia 的知名地標」。但使用者從 Google Maps 分享的 90% 以上是餐廳、咖啡廳、小店、私房景點，這些幾乎不會有 Wikipedia 條目，因此命中率極低。
2. **座標資訊未被利用**：`GoogleMapsUrlParser` 已解析出 `latitude` / `longitude`，但 `ShareIntentHandler.resolveSharedText` 只用名稱做文字搜尋，從未 fallback 到「以座標找最近的 Wikipedia 地標」或「以座標 reverse geocode」。
3. **架構限制**：`Place.id` 統一是 `wikidata:XXX`，下游（saved locations、narration、trip）都假設這個來源。即使我們手上已有名稱 + 座標，也無法不經 Wikipedia 就直接建立可用的 `Place`。

詳細分析請參考相關 systematic debugging session（2026-05-13）。

短期內無法把資料源整個換掉（牽涉 narration prompt、photo、category mapper 等）。讓使用者持續看到「找不到」的失敗體驗，比暫時下架功能更傷信任。

## 決策

暫時關閉分享入口，但**保留所有程式碼**，方便日後接上更高涵蓋率的資料源（OpenStreetMap / Nominatim、Google Places API 等）後快速回復。

具體在三個入口下開關：

| 平台 / 層 | 檔案 | 變更 |
|---|---|---|
| iOS Share Extension | `frontend/ios/ShareExtension/Info.plist` | `NSExtensionActivationRule` 改為 `<string>FALSEPREDICATE</string>`；原 dict 形式以註解保留於上方 |
| Android intent filter | `frontend/android/app/src/main/AndroidManifest.xml` | `SEND` + `text/plain` 的 `<intent-filter>` 整段以 XML 註解包起來 |
| Flutter 端 listener | `frontend/lib/app.dart` | `ref.watch(shareIntentInitProvider);` 改為註解，並標註理由與回復方法 |

未變動：

- `frontend/lib/features/share/` 底下所有 domain、data、provider、test 程式碼
- `receive_sharing_intent` 套件依賴（`pubspec.yaml`）
- iOS `ShareExtension` target 本身、`ShareViewController.swift`、App Group 設定
- `docs/init/ios-share-extension-setup.md` 設定文件

## 影響

### 對使用者
- 從 Google Maps、其他 app 的「分享 → Lorescape」入口在分享選單中不再出現
- 不會再看到「shared_place.not_found」這個誤導性的失敗訊息
- 原本想用分享流程把地點存進 saved locations 的使用者，需改走 app 內搜尋（局限於 Wikipedia 地標）

### 對開發
- 既有 share 相關單元測試（`google_maps_url_parser_test.dart`、`share_intent_handler_test.dart`）仍會跑、會通過，不會因為這次調整而失效。**刻意保留**：用以維持解析邏輯的正確性，方便日後再啟用
- `pendingSharedPlaceProvider` 等 provider 仍存在但不會被任何 listener 觸發，等同 dead code，但保留可讓回復成本最低
- `shareIntentInitProvider` 的 import 暫時保留（位於 `app.dart`），分析器不會報錯，因為 `share/providers.dart` 同檔仍提供 `pendingSharedPlaceProvider` 給 listener 區塊使用

### 對未來重新啟用
回復步驟（按順序）：

1. **資料源就緒**：先把更高涵蓋率的 places 來源（建議 OSM Nominatim 反向地理編碼）接上，並讓 `Place` 模型支援多來源 ID（例如 `osm:way/123`）
2. **回復三個入口**：
   - `ios/ShareExtension/Info.plist`：把 `NSExtensionActivationRule` 改回原本的 dict 形式（檔內已留註解可直接還原）
   - `android/app/src/main/AndroidManifest.xml`：移除包住 `<intent-filter>` 的 XML 註解
   - `lib/app.dart`：取消註解 `ref.watch(shareIntentInitProvider);`
3. **End-to-end 驗證**：iOS（須重新 archive、TestFlight）與 Android（adb shell `am start -a android.intent.action.SEND ...`）各驗一次
4. **刪除本 ADR 對應的 status 欄位改為 Superseded**，並新增一份描述新資料源的 ADR

## 替代方案（與否決理由）

| 方案 | 為何不採用 |
|---|---|
| 直接接 OSM / Google Places 修好命中率，不下架 | 下游（narration、photo、category）改動較大，沒辦法「一晚做完」。讓失敗體驗繼續存在於 production 不可接受 |
| 完全刪除 share 相關程式碼 | 解析邏輯（短連結展開、ZIP-prefix fallback、`?q=` 解析）日後仍會用到，刪掉等於重做 |
| 僅關閉 Dart listener，平台入口照舊 | 使用者仍會在分享選單看到 Lorescape，點下去毫無反應，比目前更糟 |
| 在分享流程顯示「功能暫時停用」的訊息 | 仍會出現在分享選單，使用者每次都要點才知道沒用，UX 比直接從選單拿掉差 |

## 後續追蹤

- 命中率改善方案的設計 → 另開新 ADR / spec
- 若一個月內未推進，需重新評估：是否乾脆移除 share extension target 與 plugin 依賴（會省一些 build 時間與 binary size）
