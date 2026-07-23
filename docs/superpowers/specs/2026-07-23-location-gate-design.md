# 定位不可用時的浮層引導卡（Location Gate）設計

日期：2026-07-23
範圍：`frontend/`（Flutter）探索頁定位錯誤處理

## 背景與問題

`GeolocatorService.getCurrentLocation()`（`lib/features/explore/data/services/geolocator_service.dart`）
在三種情況下 throw **純英文字串**：

- 定位服務關閉 → `'Location services are disabled.'`
- 權限被拒（denied）→ `'Location permissions are denied'`
- 永久拒絕（deniedForever）→ `'Location permissions are permanently denied, ...'`

錯誤經 `PlacesController`（AsyncNotifier，`AsyncValue.guard`）→ `filteredPlacesProvider`
→ 探索頁底部 `_MapCardsRail` 的 `_RailNotice`，使用者只看到
「錯誤: Location permissions are denied」這種半中半英、無引導的小字（116px 高卡片列）。

缺點：訊息未 i18n、不分狀態、沒有「前往設定 / 允許定位」的引導動作。

## 目標

1. 錯誤型別化，UI 可依三種狀態顯示不同文案與引導按鈕。
2. 文案 i18n（zh-TW / en）。
3. 定位不可用時，在地圖中央顯示浮層卡片：共用插圖 ＋ 標題 ＋ 說明 ＋ 引導按鈕。
4. 引導按鈕依狀態導向正確的系統設定或重新請求權限。

非目標：不改動非定位類錯誤的既有 `_RailNotice` 行為；不做 onboarding 前置權限畫面。

## 設計

### 1. 型別化錯誤（domain 層）

新增 `lib/features/explore/domain/errors/location_error.dart`：

```dart
import 'package:context_app/core/errors/app_error_type.dart';

enum LocationError implements AppErrorType {
  serviceDisabled,          // 定位服務關閉
  permissionDenied,         // 拒絕（還能再要）
  permissionDeniedForever;  // 永久拒絕

  @override
  String get code => 'LOCATION_${name.toUpperCase()}';
}
```

沿用專案既有 `AppErrorType` 慣例（與 `NarrationError` 一致）。

`GeolocatorService.getCurrentLocation()` 改為 throw 對應的 `LocationError`
（取代三段字串）：

- `!serviceEnabled` → `LocationError.serviceDisabled`
- 請求後仍 `denied` → `LocationError.permissionDenied`
- `deniedForever` → `LocationError.permissionDeniedForever`

錯誤透過既有的 `AsyncValue.guard` 自然傳遞到 `filteredPlacesProvider.error`，
不需改 controller / use case。

### 2. 引導動作（保持分層乾淨）

`LocationService` 介面（`lib/features/explore/domain/services/location_service.dart`）
新增三個方法，讓 presentation **不直接依賴 geolocator 套件**：

```dart
Future<bool> requestPermission();     // 回傳是否已授權
Future<void> openAppSettings();       // 開 App 設定頁
Future<void> openLocationSettings();  // 開系統定位設定
```

`GeolocatorService` 以 `Geolocator.requestPermission()`、
`Geolocator.openAppSettings()`、`Geolocator.openLocationSettings()` 實作。
（geolocator ^14.0.2 已提供這些 API。）

### 3. i18n（zh-TW + en）

在兩個翻譯檔的 `explore` 節下新增 `location_gate`，每種狀態一組
`title / description / action`：

| 狀態 | 標題（zh 範例） | 按鈕（zh 範例） |
|---|---|---|
| `serviceDisabled` | 定位服務已關閉 | 開啟定位服務 |
| `permissionDenied` | 開啟定位以探索附近故事 | 允許定位 |
| `permissionDeniedForever` | 定位權限已關閉 | 前往設定 |

移除 UI 直接吐英文字串（`_RailNotice` 對定位錯誤不再顯示原始 error）。
key 結構：`explore.location_gate.<state>.{title,description,action}`。
state 命名對齊 enum 名稱：`service_disabled` / `permission_denied` /
`permission_denied_forever`（或以 helper 對應）。

### 4. 畫面：地圖中央浮層卡

新增 widget（如 `_LocationGateCard`，置於 `explore_screen.dart` 或獨立檔）。
在 `ExploreScreen` build 的 Stack 中，以置中 `Positioned` / `Align` 疊在地圖上方、
卡片列之上，**僅當** `filteredPlacesProvider` 為 `AsyncError` 且
`error is LocationError` 時顯示。

卡片內容（沿用 `LorescapeTokens` 紙感樣式，與 `_RailNotice` 一致的視覺語彙）：

1. 共用插圖（`Image.asset`）
2. 標題（`explore.location_gate.<state>.title`）
3. 說明（`explore.location_gate.<state>.description`）
4. 引導按鈕（`explore.location_gate.<state>.action`），依狀態：
   - `permissionDenied` → `await requestPermission()`；若授權成功則
     `placesControllerProvider.notifier.refresh()`
   - `permissionDeniedForever` → `openAppSettings()`
   - `serviceDisabled` → `openLocationSettings()`

非定位類錯誤（`error is! LocationError`）維持原本 `_RailNotice`，不變。
地圖底圖照常顯示（不遮全螢幕）。

### 5. 插圖（agy 產一張共用）

用 `agy --prompt "..."` 產一張插圖 PNG，放 `frontend/assets/images/`，
在 `pubspec.yaml` 的 `assets:` 註冊。三狀態共用同一張。

風格要求（對齊品牌與地圖 field-journal 調性）：暖紙感、極簡、知性、
以「地圖與定位」為題（如折疊地圖＋定位圖釘），構圖留白、可自然置於淺／深色卡片上。
輸出去背或淺色透明底，避免與深色主題衝突。

### 6. 測試（依 flutter-widget-tests skill）

以 fake `LocationService` 覆寫 provider，widget test 驗證：

- `AsyncError(LocationError.permissionDenied)` → 浮層顯示對應標題、說明、按鈕；
  點按鈕呼叫 fake 的 `requestPermission()`（且成功後觸發 refresh）。
- `AsyncError(LocationError.permissionDeniedForever)` → 按鈕呼叫 `openAppSettings()`。
- `AsyncError(LocationError.serviceDisabled)` → 按鈕呼叫 `openLocationSettings()`。
- 非定位錯誤（如一般 Exception）→ 仍顯示 `_RailNotice`，不顯示浮層卡。

## 影響檔案

| 檔案 | 動作 |
|---|---|
| `lib/features/explore/domain/errors/location_error.dart` | 新增 |
| `lib/features/explore/domain/services/location_service.dart` | 加三方法 |
| `lib/features/explore/data/services/geolocator_service.dart` | throw 型別化錯誤、實作三方法 |
| `assets/translations/zh-TW.json`、`en.json` | 加 `explore.location_gate` |
| `lib/features/explore/presentation/screens/explore_screen.dart` | 加浮層卡、判定 LocationError |
| `frontend/assets/images/<插圖>.png` | 新增（agy 產） |
| `pubspec.yaml` | 註冊 asset |
| `frontend/test/...` | 新增 widget 測試 |

## 驗收

- 三種定位錯誤各顯示正確中／英文案與正確按鈕動作。
- `fvm flutter analyze --fatal-infos` 全綠。
- `fvm flutter test` 全綠（含新測試）。
