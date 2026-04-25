# Midnight Kyoto S3-f — Saved Locations 設計文件

- 日期：2026-04-24
- Sprint：S3-f（S3 第七個 mini-sprint）
- 範圍：`frontend/lib/features/saved_locations/presentation/widgets/saved_locations_fab.dart` (197 行) + `saved_locations_dialog.dart` (219 行)

## 背景與目標

Saved locations 已經大量使用 `colorScheme.X` token——只剩 4 處 hardcoded `AppColors.primary` / `Colors.white`。最小範圍 cleanup：把這幾個 token 化、保留 FAB→dialog 的 morph 動畫。

Journey feature 因為太大（5 個檔 2000+ 行），延後到 S3-ff。

## 影響範圍

| Widget | 角色 | 動作 |
|---|---|---|
| `SavedLocationsFab` | 圓形 FAB（書籤 icon + 計數 badge）+ morph route | 小（移除多餘 backgroundColor + token 化）|
| `_SavedLocationsRoute` | morph 動畫（FAB → 對話框）| 小（colorTween begin token 化）|
| `SavedLocationsDialog` | 對話框內容 + list | 已經 token 化 |
| `_DialogHeader` | 標題 + 關閉按鈕 | 小（icon color token） |
| `_EmptyState` / `_SavedLocationsList` / `_SavedLocationTile` | list 內容 | 已經 token 化 |

對應測試：`saved_locations_fab_test.dart`（111 行）、`saved_locations_dialog_test.dart`（150 行）。

## 已決策事項

| 議題 | 決定 |
|---|---|
| FAB 是否改 `PillIconButton` | **不改**——FAB 有 hero animation、container morph 邏輯、`heroTag`，與 `PillIconButton` API 不相容；保留 Material `FloatingActionButton`，僅 token 替換 |
| FAB `backgroundColor: AppColors.primary` | **刪除**——S1 `floatingActionButtonTheme.backgroundColor` 已是 `AppColors.primary`，重複設定 |
| Badge 計數 typography | 保留 hardcoded（`fontSize: 10`）|
| `Material(elevation: 8)` 在 morph route | **保留**——對話框需要從背景脫離，elevation 是必要的 |
| Morph route colorTween begin | `AppColors.primary` → `Theme.of(context).colorScheme.primary` |
| FAB icon color `Colors.white` 與 morph icon `Colors.white` | 改 `cs.onPrimary` |
| Dialog header bookmark icon `AppColors.primary` | 改 `colorScheme.primary` |
| Dialog header title (20/bold) | 保留 hardcoded 20px——對話框標題比 MK textTheme 預設值大，是設計刻意值 |

## 不在 S3-f 範圍

- ❌ Journey feature（→ S3-ff）
- ❌ saved_location_entry / repository / providers（純邏輯）
- ❌ Morph 動畫的 timing 與 curve（保留現有設計）
- ❌ FloatingActionButton → PillIconButton 重構（API 不相容）

## 設計細節

### 1. `SavedLocationsFab.build`

```dart
return Visibility(
  visible: !isRouteActive,
  maintainState: true,
  maintainSize: true,
  maintainAnimation: true,
  child: FloatingActionButton(
    heroTag: 'saved_locations_fab',
    shape: const CircleBorder(),
    onPressed: () { /* unchanged */ },
    // 移除 backgroundColor: AppColors.primary（theme 已設定）
    child: Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      child: Icon(
        Icons.bookmark,
        color: Theme.of(context).colorScheme.onPrimary,  // ← was Colors.white
      ),
    ),
  ),
);
```

⚠️ FAB 預設 `foregroundColor` 已從 theme 取得 `AppColors.onPrimary`——其實 child Icon 的 color 也可以省去，讓 FAB 自動 propagate iconColor。但這需要驗證 Badge 與 Icon 的繼承鏈。簡單做法：明確設 `cs.onPrimary` 確保跟 morph route 中的 icon 顏色一致。

### 2. `_SavedLocationsRoute.transitionsBuilder`

```dart
final colorTween = ColorTween(
  begin: Theme.of(context).colorScheme.primary,  // ← was AppColors.primary
  end: colorScheme.surface,
);
```

```dart
// FAB icon 顯示在 morph 早期
IgnorePointer(
  child: Center(
    child: Opacity(
      opacity: iconOpacity.value,
      child: Icon(
        Icons.bookmark,
        color: Theme.of(context).colorScheme.onPrimary,  // ← was Colors.white
        size: 24,
      ),
    ),
  ),
),
```

⚠️ `transitionsBuilder` 的 `context` 已可使用 `Theme.of`。

### 3. `_DialogHeader.build`

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
  child: Row(
    children: [
      Icon(Icons.bookmark, color: colorScheme.primary, size: 24),  // ← was AppColors.primary
      // ... rest unchanged
    ],
  ),
);
```

### 4. Imports

`saved_locations_fab.dart`：
- 移除 `import 'package:context_app/common/config/app_colors.dart';`（grep 確認無殘留 `AppColors`）

`saved_locations_dialog.dart`：
- 移除 `import 'package:context_app/common/config/app_colors.dart';`

## 測試策略

`saved_locations_fab_test.dart`（111 行）：
- 主要驗證 FAB 顯示 + 計數 badge + tap 觸發 morph route——預期不需動
- 若有測試斷言 `find.byWidgetPredicate((w) => w is FloatingActionButton && w.backgroundColor == AppColors.primary)`，則需動

`saved_locations_dialog_test.dart`（150 行）：
- 驗證 dialog 內容、empty state、tile interactions——預期不需動

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 移除 FAB `backgroundColor` 後若 theme 未正確 propagate primary | 低 | S1 `floatingActionButtonTheme.backgroundColor: AppColors.primary` 已驗證；視覺與原本一致 |
| morph route 中 `AppColors.primary` → `cs.primary` 視覺改變 | 低 | 兩者實際相同顏色 |
| FAB icon `Colors.white` → `cs.onPrimary` 視覺改變 | 低 | `cs.onPrimary` 在 MK theme 中即 `Colors.white` |

## 成功指標

1. `saved_locations_fab.dart` 與 `saved_locations_dialog.dart` 內 `AppColors.X` 引用為 0。
2. `Colors.white` hardcoded 引用為 0（由 `cs.onPrimary` 取代）。
3. 既有 saved_locations test 全 pass（最小修改後）。
4. analyzer clean。
5. 全 suite 維持 390+ pass。
6. **跑起來看**：FAB 仍是電光藍書籤、計數 badge 顯示正常、tap 觸發 morph 動畫對話框。
