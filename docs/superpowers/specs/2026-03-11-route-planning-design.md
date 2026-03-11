# 路線規劃功能設計文件

## Context

目前 Contexture 讀景 app 的導覽功能是單景點模式：使用者選一個景點、選一個面向、生成導覽。但實際旅遊場景中，使用者通常會一次走訪多個鄰近景點。路線規劃功能讓使用者到達現場後，可以快速獲得 AI 推薦的 2-3 站輕量路線，提升探索效率。

## 核心需求

- **場景**：到現場即時規劃，2-3 個景點的輕量半日遊
- **路線產生**：AI 先推薦，使用者可增刪景點、拖曳調整順序
- **導覽內容**：建立路線時生成概覽（150-200 字），到現場再生成完整導覽
- **導航**：顯示站間距離和步行時間，實際導航交給 Google Maps
- **儲存**：路線不持久化，個別導覽可各自存通行證

## UI 流程

### Step 1：入口

探索頁底部新增「規劃路線」按鈕，使用已搜尋到的附近景點作為 AI 的候選清單。

**前置條件**：附近景點至少 3 個時才顯示按鈕（少於 3 個時隱藏，因為 AI 需要足夠候選清單來挑選）。

### Step 2：AI 規劃

AI 從附近景點中挑選 2-3 個，排出最佳遊覽順序，為每站生成簡短概覽，並給路線取一個主題名稱。顯示 loading 畫面。

**額度消耗**：AI 呼叫成功後才消耗 1 次額度（與 `CreateNarrationUseCase` 一致）。若 AI 呼叫失敗或使用者在 loading 時按返回取消，不消耗額度。

### Step 3：路線預覽

以時間軸形式展示推薦路線：
- 路線主題名稱（例如「萬華歷史散步」）
- 總站數、預估時間、總距離
- 每站：景點名稱 + 概覽文字
- 站間：步行時間和距離（直線距離估算，非實際路線）
- 底部：「編輯」和「開始導覽」按鈕

#### 編輯模式

- 刪除景點：左滑或點擊刪除（最少保留 2 站）
- 新增景點：從附近景點列表中選擇加入（排除已在路線中的）
- 調整順序：長按拖曳，同時提供上移/下移按鈕（無障礙支援）

編輯後：
- 距離和步行時間即時重新計算
- 新增的景點沒有 AI 概覽（顯示地址和評分代替）
- 不重新呼叫 AI

#### 前往 Google Maps 導航

每站之間顯示「導航至下一站」按鈕，點擊後使用 `url_launcher` 開啟 Google Maps 導航：
```
https://www.google.com/maps/dir/?api=1&destination={lat},{lng}&travelmode=walking
```
iOS 和 Android 皆適用。

### Step 4：逐站導覽

`RouteNavigationScreen` 作為路線導覽的容器頁面：
- 頂部顯示進度指示器（1 → 2 → 3）
- 顯示當站概覽、地址、「導航至此站」按鈕
- 點擊「開始導覽」按鈕後，使用 `Navigator.push` 推入 `SelectNarrationAspectScreen` → `NarrationScreen`（使用 Navigator 而非 GoRouter，避免返回按鈕導回首頁的問題）
- 每站完整導覽各消耗 1 次額度
- 從 NarrationScreen 返回後，回到 RouteNavigationScreen，可選擇「前往下一站」或「結束路線」
- 系統返回鍵：在 RouteNavigationScreen 時彈出確認對話框「確定要離開路線嗎？」

## 資料模型

### TourRoute

使用 `TourRoute` 避免與 Flutter 的 `Route` 衝突。

```dart
class TourRoute extends Equatable {
  final String title;
  final List<RouteStop> stops;

  /// 總距離（公尺），從 stops 計算而得
  double get totalDistance => ...;

  /// 預估總步行時間（分鐘），從 stops 計算而得
  double get estimatedDuration => ...;
}
```

### RouteStop

```dart
class RouteStop extends Equatable {
  final Place place;
  final String? overview;           // AI 概覽，手動新增為 null
  final double? distanceToNext;     // 到下一站距離（公尺）
  final double? walkingTimeToNext;  // 到下一站步行時間（分鐘）
}
```

順序由 `List<RouteStop>` 的 index 決定，不另設 `order` 欄位。
`totalDistance` 和 `estimatedDuration` 為 computed getter，編輯後自動正確。

### AI 回傳格式

要求 Gemini 以 JSON 格式回傳：

```json
{
  "title": "萬華歷史散步",
  "stops": [
    {
      "placeId": "ChIJ...",
      "overview": "萬華最具代表性的百年古廟，融合閩南與日式建築風格..."
    }
  ]
}
```

## 技術設計

### 新增檔案結構

```
features/route/
├── domain/
│   ├── models/
│   │   ├── tour_route.dart
│   │   └── route_stop.dart
│   ├── use_cases/
│   │   └── create_route_use_case.dart   # 額度檢查 + AI 呼叫 + JSON 解析
│   └── errors/
│       └── route_error.dart             # insufficientPlaces, aiParsingFailed 等
├── data/
│   ├── route_prompt_builder.dart        # 路線規劃 Prompt
│   └── route_ai_service.dart            # AI 呼叫（封裝 Gemini JSON 回傳）
├── presentation/
│   ├── screens/
│   │   ├── route_planning_screen.dart   # Step 2：Loading
│   │   ├── route_preview_screen.dart    # Step 3：路線預覽
│   │   └── route_navigation_screen.dart # Step 4：逐站導覽容器
│   ├── widgets/
│   │   ├── route_timeline_widget.dart   # 時間軸元件
│   │   ├── route_stop_card.dart         # 停靠站卡片
│   │   ├── route_edit_sheet.dart        # 編輯底部彈出
│   │   └── route_progress_indicator.dart # 頂部進度指示器
│   └── controllers/
│       └── route_controller.dart        # 路線狀態管理
└── providers.dart
```

### 共用工具提取

將 `SearchNearbyPlacesUseCase._calculateDistance()` 提取到 `core/utils/geo_utils.dart`：

```dart
/// 計算兩點間直線距離（Haversine 公式，回傳公尺）
double calculateDistance(PlaceLocation from, PlaceLocation to);

/// 估算步行時間（回傳分鐘，假設步行速度 1.4 m/s）
double estimateWalkingMinutes(PlaceLocation from, PlaceLocation to);
```

### RouteAiService

獨立的 AI 服務，不修改現有 `GeminiService`：

```dart
abstract class RouteAiService {
  Future<TourRoute> generateRoute({
    required List<Place> candidatePlaces,
    required PlaceLocation userLocation,
    required String language,
  });
}
```

實作類別 `GeminiRouteAiService` 負責：
- 使用 `RoutePromptBuilder` 建構 prompt
- 呼叫 Gemini API
- 解析 JSON 回傳，比對 `placeId` 與候選清單
- 計算站間距離和步行時間

### 錯誤處理

```dart
enum RouteError {
  insufficientPlaces,  // 附近景點不足 3 個
  aiParsingFailed,     // AI 回傳的 JSON 無法解析
  invalidPlaceId,      // AI 回傳的 placeId 不在候選清單中
  networkError,        // 網路錯誤
  quotaExceeded,       // 額度不足
}
```

AI JSON 解析失敗時的 fallback：
- 嘗試從回傳文字中提取 JSON（移除 markdown code fence）
- 若仍失敗，顯示錯誤訊息讓使用者重試（不消耗額度）

### 重用的現有元件

| 元件 | 路徑 | 用途 |
|------|------|------|
| `Place` model | `features/explore/domain/models/place.dart` | 景點資料 |
| `CreateNarrationUseCase` | `features/narration/domain/use_cases/` | 逐站完整導覽 |
| `SelectNarrationAspectScreen` | `features/narration/presentation/screens/` | 選面向畫面（Navigator.push） |
| `NarrationScreen` (Player) | `features/narration/presentation/screens/` | 播放畫面（Navigator.push） |
| `UsageRepository` | `features/usage/` | 額度管理 |
| `url_launcher` | 已安裝 | 開啟 Google Maps |

### Prompt 設計

`RoutePromptBuilder` 負責建構路線規劃 prompt：

**輸入**：
- 使用者位置座標
- 附近景點列表（名稱、類別、地址、評分、距離、types）
- 語言偏好

**Prompt 重點**：
- 角色：專業導遊，為旅客規劃步行路線
- 從景點列表中挑選 2-3 個最值得去的
- 考慮地理動線（不走回頭路）
- 考慮主題連貫性（例如同一歷史脈絡的景點）
- 每站概覽 150-200 字，精簡有吸引力
- 嚴格以 JSON 格式回傳，提供 schema 範例
- `placeId` 必須使用候選清單中的 id

### 額度消耗

| 操作 | 額度消耗 | 時機 |
|------|---------|------|
| 規劃路線（含概覽） | 1 次 | AI 成功回傳後 |
| 每站完整導覽 | 各 1 次 | 走現有 CreateNarrationUseCase 流程 |
| 編輯路線（增刪調整） | 0 次 | — |

### 路由配置

新增路由：

| 路由 | 畫面 | 參數（extra） |
|------|------|------|
| `/route/planning` | RoutePlanningScreen | `List<Place>` 附近景點 |
| `/route/preview` | RoutePreviewScreen | `TourRoute` 物件 + `List<Place>` 全部附近景點 |
| `/route/navigate` | RouteNavigationScreen | `TourRoute` 物件 |

每個路由加上 redirect guard（參考現有 `/config` 和 `/player` 的做法），若 `extra` 為 null 則導回首頁。

逐站導覽中的 `SelectNarrationAspectScreen` 和 `NarrationScreen` 使用 `Navigator.push`（不使用 GoRouter），確保返回按鈕回到 RouteNavigationScreen 而非首頁。

### 狀態管理

```dart
// 不使用 autoDispose，因為使用者會在路線畫面和導覽畫面間來回切換
final routeControllerProvider =
    StateNotifierProvider<RouteController, RouteState>(...);

class RouteState {
  final TourRoute? route;
  final List<Place> candidatePlaces;  // 全部附近景點（編輯時使用）
  final int currentStopIndex;
  final bool isLoading;
  final String? error;
}
```

## Feature Toggle

此功能先不上線，使用 feature toggle 隱藏：

```dart
// core/config/feature_flags.dart
class FeatureFlags {
  /// 路線規劃功能開關，設為 true 時才顯示「規劃路線」按鈕
  static const bool enableRoutePlanning = false;
}
```

探索頁的「規劃路線」按鈕根據 `FeatureFlags.enableRoutePlanning` 決定是否顯示。路由不需要保護，因為入口已隱藏。上線時只需改為 `true`。

## 不做的事

- 不儲存路線到資料庫
- 不在 app 內顯示地圖路線
- 不支援跨城市路線（僅附近 1000m 內）
- 不在編輯後重新呼叫 AI
- 不為手動新增的景點生成概覽

## 驗證方式

1. **單元測試**：
   - `TourRoute` / `RouteStop` 模型（computed getter 計算正確性）
   - `geo_utils.dart`（距離計算、步行時間估算）
   - `RoutePromptBuilder` 產出格式
   - `GeminiRouteAiService` JSON 解析（正常、malformed、missing placeId）
   - `CreateRouteUseCase` 額度消耗時機
2. **整合測試**：
   - `RouteController` 的狀態流轉（loading → preview → navigate）
   - 編輯操作（刪除、新增、排序）後 state 正確性
3. **手動測試**：
   - 附近景點 < 3 個時，「規劃路線」按鈕隱藏
   - AI 回傳的 JSON 正確解析為 TourRoute
   - 編輯路線：刪除（最少 2 站）、新增、拖曳，距離重新計算
   - 逐站導覽：Navigator.push 到導覽流程，返回後回到路線頁
   - 額度消耗：規劃消耗 1 次（失敗不消耗），每站導覽各消耗 1 次
   - Google Maps 導航連結正常開啟
   - 系統返回鍵在路線模式中的行為
