# Plan Tab 設計文件

**日期：** 2026-03-21
**狀態：** 已核准

---

## 概述

新增獨立的 **Plan** 頁面至 Bottom Navigation Bar（第二個位置），讓使用者可以管理已儲存的路線規劃。使用者可透過右上角的 `+` 按鈕根據當前位置自動產生新路線，並以 Hive 持久化儲存。同時移除 Explore 畫面原有的「規劃路線」按鈕，將入口統一至 Plan tab。

---

## 架構

採用現有的 **Feature-First + Clean Architecture** 分層，新增 `features/plan` module。

### 目錄結構

```
features/plan/
├── domain/
│   ├── models/
│   │   └── plan.dart                  # 持久化 Plan 模型
│   └── repositories/
│       └── plan_repository.dart       # 介面定義
├── data/
│   └── hive_plan_repository.dart      # Hive 實作（JSON 序列化，與現有 codebase 一致）
├── presentation/
│   ├── controllers/
│   │   └── plan_list_controller.dart  # 列表狀態管理（Riverpod）
│   ├── screens/
│   │   └── plan_screen.dart           # Plan Tab 主畫面
│   └── widgets/
│       └── plan_card.dart             # Plan 卡片（含左滑刪除）
└── providers.dart                     # Riverpod providers
```

---

## 資料模型

### 儲存策略

現有 codebase 中 Hive 全部採用 **JSON 字串存入 `Box<dynamic>`** 的方式（無 TypeAdapter），本功能遵循相同風格，以 `Map<String, dynamic>` 序列化後存入 `Box<Map>`，避免引入 build_runner 產生程式碼。

### Plan

```dart
class Plan {
  final String id;                 // UUID（使用 uuid 套件）
  final String title;              // AI 生成的路線名稱
  final DateTime createdAt;
  final List<PlanStop> stops;
  final double totalDistance;      // 總距離（公尺）
  final double estimatedDuration;  // 預估時間（分鐘）

  factory Plan.fromTourRoute(TourRoute route) => Plan(
    id: const Uuid().v4(),
    title: route.title,
    createdAt: DateTime.now(),
    stops: route.stops.map(PlanStop.fromRouteStop).toList(),
    totalDistance: route.totalDistance,
    estimatedDuration: route.estimatedDuration,
  );

  TourRoute toTourRoute() => TourRoute(
    title: title,
    stops: stops.map((s) => s.toRouteStop()).toList(),
  );

  Map<String, dynamic> toJson() { ... }
  factory Plan.fromJson(Map<String, dynamic> json) { ... }
}
```

### PlanStop

儲存足夠還原 `RouteStop`（含完整 `Place`）所需的欄位：

```dart
class PlanStop {
  final String placeId;
  final String placeName;
  final String placeAddress;
  final double latitude;
  final double longitude;
  final double? placeRating;
  final String placeCategory;      // PlaceCategory.name
  final String? overview;
  final double? distanceToNext;
  final double? walkingTimeToNext;

  factory PlanStop.fromRouteStop(RouteStop stop) { ... }

  RouteStop toRouteStop() => RouteStop(
    place: Place(
      id: placeId,
      name: placeName,
      formattedAddress: placeAddress,
      location: PlaceLocation(latitude: latitude, longitude: longitude),
      rating: placeRating,
      category: PlaceCategory.values.byName(placeCategory),
      types: const [],    // 不儲存，導覽功能不需要
      photos: const [],   // 不儲存，導覽畫面不顯示照片
    ),
    overview: overview,
    distanceToNext: distanceToNext,
    walkingTimeToNext: walkingTimeToNext,
  );

  Map<String, dynamic> toJson() { ... }
  factory PlanStop.fromJson(Map<String, dynamic> json) { ... }
}
```

> `photos` 和 `types` 不持久化：RoutePreviewScreen 和 RouteNavigationScreen 不顯示地點照片，`types` 僅用於分類標籤（用 `placeCategory` 取代）。

---

## 資料流

### 產生新 Plan

```
Plan Tab "+" 按鈕
  → ref.read(searchNearbyPlacesUseCaseProvider).execute()
      （複用現有 ExploreService，自動取得 GPS 並搜尋附近景點）
  → 若景點數 < 3，顯示 SnackBar 提示並停止
  → context.push('/route/planning', extra: places)
      （複用現有 RoutePlanningScreen）
  → CreateRouteUseCase 成功取得 TourRoute
  → PlanRepository.save(Plan.fromTourRoute(route))  ← 新增
  → PlanListController 重新載入列表
  → context.go('/route/preview')
      （與現有流程一致，清除 planning 頁面堆疊）
```

### 開啟已儲存的 Plan

```
PlanCard onTap
  → plan.toTourRoute() 還原 TourRoute
  → routeControllerProvider.notifier.setRoute(tourRoute)
      （candidatePlaces 設為空列表，見下方說明）
  → context.push('/route/preview')
      （保留返回 Plan Tab 的堆疊）
```

**candidatePlaces 行為說明：** 從已儲存 Plan 開啟時，`candidatePlaces` 為空列表，RoutePreviewScreen 的「新增站點」按鈕將顯示空的 RouteEditSheet。此為預期行為，不做額外處理（新增站點功能的完整支援列為 future scope）。

### 刪除 Plan

```
PlanCard Dismissible（左滑）
  → PlanRepository.delete(plan.id)
  → PlanListController 更新列表（移除該項目）
  → 若失敗：SnackBar 顯示錯誤，列表還原
```

---

## UI 設計

### Bottom Navigation Bar

| 位置 | Tab | Icon | 翻譯 Key |
|------|-----|------|---------|
| 1 | Explore | `Icons.home` | `bottom_nav.home` |
| 2 | **Plans**（新增） | `Icons.map_outlined` | `bottom_nav.plan` |
| 3 | Journey | `Icons.book` | `bottom_nav.passport` |
| 4 | Settings | `Icons.settings` | `bottom_nav.settings` |

### Plan Screen

- **AppBar：** 標題 "Plans"，右上角 `+` IconButton
- **空白狀態：** `Icons.map_outlined` 大圖示 + 提示文字
- **列表：** `ListView.builder`，每個 item 為 `PlanCard`，包裝在 `Dismissible`，左滑顯示紅色刪除背景

### PlanCard

顯示內容：
- **標題**（路線名稱，粗體）
- **資訊列：** 站點數、預估時間、總距離（小字，icon 輔助）
- **建立日期**（右下角，淡色）

---

## Repository 介面

```dart
abstract class PlanRepository {
  Future<List<Plan>> getAll();
  Future<void> save(Plan plan);
  Future<void> delete(String id);
}
```

Hive 實作：使用 `Hive.box<Map>('plans')`，key 為 `plan.id`，value 為 `plan.toJson()`。

---

## RouteController 異動

新增 `setRoute()` 方法，供從 Plan 還原路線時使用：

```dart
void setRoute(TourRoute route) {
  state = state.copyWith(
    route: route,
    candidatePlaces: const [],
  );
}
```

---

## 現有程式碼異動

1. **`main_screen.dart`** — 新增 Plan tab（第二個位置）
2. **`explore_screen.dart`** — 移除 `FeatureFlags.enableRoutePlanning` 按鈕區塊
3. **`feature_flags.dart`** — 移除 `enableRoutePlanning`（功能正式上線）
4. **`route_controller.dart`** — 新增 `setRoute(TourRoute)` 方法
5. **翻譯檔** — 新增 `bottom_nav.plan` 及 `plan.*` 相關 key

---

## 錯誤處理

| 情境 | 處理方式 |
|------|---------|
| 取得位置失敗 | SnackBar 顯示錯誤訊息，停留在 Plan 畫面 |
| 附近景點不足 3 個 | SnackBar 提示「附近景點不足，無法規劃路線」 |
| Hive 讀取失敗 | log 錯誤，顯示空白狀態，不崩潰 |
| Hive 寫入失敗 | log 錯誤，導覽仍繼續，SnackBar 提示「儲存失敗」 |
| Hive 刪除失敗 | SnackBar 提示，列表還原被刪項目 |

---

## 翻譯 Key（需新增）

```json
"bottom_nav": {
  "plan": "Plans"
},
"plan": {
  "title": "Plans",
  "empty_title": "No Plans Yet",
  "empty_subtitle": "Tap + to plan a route near you",
  "stops": "{count} stops",
  "duration": "~{minutes} min",
  "distance": "{distance}m",
  "delete_failed": "Failed to delete plan",
  "save_failed": "Failed to save plan",
  "location_failed": "Unable to get current location",
  "not_enough_places": "Not enough nearby places to plan a route"
}
```

## 依賴套件

- `uuid`：產生 Plan 的唯一 ID（需確認 pubspec.yaml 是否已有，若無則新增）

---

## 不在本次範圍內

- 從已儲存 Plan 新增/刪除站點（candidatePlaces 為空）
- Plan 的分享功能
- Plan 的排序或篩選
- 雲端同步
