# Midnight Kyoto S3-ff-2 — Journey Timeline 設計文件

- 日期：2026-04-24
- Sprint：S3-ff-2（journey 第二個 sub-sprint，總 S3 第九個 mini-sprint）
- 範圍：3 個檔，~1357 行：
  - `frontend/lib/features/journey/presentation/screens/journey_screen.dart`（525 行）
  - `frontend/lib/features/journey/presentation/widgets/timeline_entry.dart`（434 行）
  - `frontend/lib/features/journey/presentation/widgets/quick_guide_timeline_entry.dart`（398 行）

## 背景與目標

Journey 主螢幕是「Knowledge Passport」——時間軸 / trip 兩種瀏覽模式 + 搜尋 + 篩選。視覺上以**列表內容為主**，已大量使用 `colorScheme.X`，剩下少量 hardcoded `AppColors.primary` / `AppColors.error` / `Colors.white` 需 token 化。

不是 hero refactor——主要是 token cleanup + 標題 typography 對齊。

## 影響範圍

| 檔案 | hardcoded refs | 動作 |
|---|---|---|
| `journey_screen.dart` | 5 | 中（標題 typography + filter chip + current trip banner + error 訊息）|
| `timeline_entry.dart` | 6 | 中（timeline node + date label + error + spinner）|
| `quick_guide_timeline_entry.dart` | 6 | 中（同 timeline_entry，加 quick_guide-specific node color）|

對應測試：
- `journey_screen_test.dart`（388 行）
- `save_success_screen_test.dart` 已穩定（S3-ff-1 後）
- `journey_sharing_card_test.dart` 不在本次範圍

## 已決策事項

| 議題 | 決定 |
|---|---|
| Journey 主標題（"passport.title"，40/bold）| 改 `Theme.of(context).textTheme.displayLarge`（與 explore 相同）|
| `_FilterChips`（all / narration / quick_guide）| **保留自畫**——不改 `StatusChip`，原因：StatusChip 是純展示、filter 是互動；自畫圓角 20 + 全色 primary 視覺更強烈，符合 filter 篩選感 |
| Filter 選中時 bg `AppColors.primary` | `cs.primary` |
| Filter 選中時文字 `Colors.white` | `cs.onPrimary` |
| `_ViewModeToggle`（segmented 切換）| **保留自畫**——MK 沒有 segmented control 元件 |
| `_CurrentTripBanner` gradient | `cs.primary @ 0.85` + `cs.primary @ 0.65`（替換 hardcoded `AppColors.primary`）|
| Banner 旗幟 icon `Colors.white` 與 trip name `Colors.white` | `cs.onPrimary` |
| `_TripGridView` / `_JourneyList` error text `AppColors.error` | `cs.error` |
| Timeline node 圓圈 (24x24, primary bg + white inner dot) | 設計保留；`AppColors.primary` → `cs.primary`、`Colors.white` inner dot → `cs.onPrimary` |
| Quick-guide timeline node 用的特殊藍 `Color(0xFF2A7AE4)` | **保留 hardcoded**——這個 blue 是 camera-based 條目的識別色，與 primary 刻意不同 |
| Quick-guide camera icon `Colors.white` | 保留 `Colors.white`——它是該特殊藍 node 上的對比色，不是 MK token |
| Date label "TODAY" / "YESTERDAY" `AppColors.primary` | `cs.primary` |
| `_isSharing` / `_isDeleting` spinner color `AppColors.primary` | `cs.primary` |
| 其他既有 `colorScheme.X` 用法 | 保留不動（已 token 化）|
| `_ActionButton` 設計 | 保留——既有 `cs.onSurfaceVariant` 已正確 |
| Content card box shadow `Colors.black.withValues(alpha: 0.05)` | 保留——subtle shadow 是設計刻意值 |

## 不在 S3-ff-2 範圍

- ❌ `journey_sharing_card.dart`（→ S3-ff-3）
- ❌ Move-to-trip sheet（trip feature）
- ❌ Trip-related widgets（`trip_grid.dart` 等）
- ❌ AppBar 改 `MidnightAppBar`——journey screen 沒有 AppBar，標題在 body 內

## 設計細節

### 1. `journey_screen.dart`

**主標題**：

```dart
Expanded(
  child: Text(
    'passport.title'.tr(),
    style: Theme.of(context).textTheme.displayLarge,
  ),
),
```

⚠️ 失去 hardcoded 40px——`displayLarge` 是 36/w900；視覺微小化但編輯感更強（與 explore 一致）。

**`_CurrentTripBanner` gradient**：

```dart
gradient: LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    colorScheme.primary.withValues(alpha: 0.85),
    colorScheme.primary.withValues(alpha: 0.65),
  ],
),
```

**Banner icon、text、按鈕色**：

```dart
const Icon(
  Icons.flag_outlined,
  // ...
)
// → 改為
Icon(
  Icons.flag_outlined,
  color: colorScheme.onPrimary,
  size: 18,
),
```

```dart
'trip.current_badge' label color: colorScheme.onPrimary.withValues(alpha: 0.85)  // 已是 cs.onPrimary
trip.name color: Colors.white → colorScheme.onPrimary
'trip.end_current' AdaptiveButton.foregroundColor: Colors.white → colorScheme.onPrimary
```

**`_FilterChips._buildChip`**：

```dart
decoration: BoxDecoration(
  color: selected
      ? colorScheme.primary
      : colorScheme.surfaceContainerHighest,
  borderRadius: BorderRadius.circular(20),
),
child: Text(
  label,
  style: TextStyle(
    color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
    fontSize: 13,
    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
  ),
),
```

⚠️ `_buildChip` 簽名增加 `BuildContext context` 已存在；用 `colorScheme` 取代 `AppColors.primary` / `Colors.white`。

**`_TripGridView` 與 `_JourneyList` error Text**：

```dart
// _TripGridView
error: (error, _) => Center(
  child: Text(
    '${'trip.load_error'.tr()}: $error',
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  ),
),

// _JourneyList
error: (error, stack) => Center(
  child: Text(
    '${'passport.load_error'.tr()}: $error',
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  ),
),
```

⚠️ 兩個 Text 不再 `const`（含 Theme.of）。

### 2. `timeline_entry.dart`

**Timeline node**：

```dart
Container(
  width: 24,
  height: 24,
  decoration: BoxDecoration(
    color: colorScheme.primary,  // ← was AppColors.primary
    shape: BoxShape.circle,
    border: Border.all(color: colorScheme.surface, width: 3),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 4,
      ),
    ],
  ),
  child: Center(
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,  // ← was Colors.white
        shape: BoxShape.circle,
      ),
    ),
  ),
),
```

⚠️ 內 inner dot Container 不再 `const`（含 colorScheme）。

**Date label**：

```dart
Text(
  _formatDateLabel(widget.entry.createdAt).toUpperCase(),
  style: TextStyle(
    color: colorScheme.primary,  // ← was AppColors.primary
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
),
```

**SnackBar `backgroundColor: AppColors.error`** × 2（在 `_showMoveToTripSheet` 與 `_showDeleteConfirmDialog`）：

```dart
backgroundColor: Theme.of(context).colorScheme.error,
```

**Sharing/deleting spinner**：

```dart
AdaptiveProgressIndicator(
  strokeWidth: 2,
  color: colorScheme.primary,  // ← was AppColors.primary
)
```

### 3. `quick_guide_timeline_entry.dart`

跟 `timeline_entry.dart` 同步更新：
- `AppColors.error` × 2 → `cs.error`（SnackBar）
- `AppColors.primary` × 2 → `cs.primary`（spinner）

**保留** `Color(0xFF2A7AE4)` （camera node 識別色）+ `Colors.white` camera icon——這是設計值。

### 4. Imports

3 個檔的 `import 'package:context_app/common/config/app_colors.dart';`：
- `journey_screen.dart`：移除（無殘留 AppColors）
- `timeline_entry.dart`：移除
- `quick_guide_timeline_entry.dart`：移除

⚠️ Grep 確認後再移除。

## 測試策略

- `journey_screen_test.dart`（388 行）：主要驗證 view mode、filter、search、navigation——預期不需動，因為 widget 結構不變、用 `find.text` / `find.byType` 找元素
- 整 suite 預期 stable

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 標題 40 → 36 size 視覺差 | 低 | 與 explore 一致，編輯感保留 |
| Filter chip 用 `cs.primary` 取代 `AppColors.primary`，值相同無視覺差 | 無 | — |
| `_CurrentTripBanner` gradient 從 hardcoded primary 改 cs.primary，值相同 | 無 | — |
| Quick-guide node `Color(0xFF2A7AE4)` 跟 MK primary 不一致 | 設計刻意 | 文件記錄為「camera entry 識別色」 |

## 成功指標

1. 3 個檔內 `AppColors.X` 引用為 0（除 quick_guide_timeline_entry 的 `Color(0xFF2A7AE4)` 設計值）。
2. 既有 journey 測試全 pass。
3. analyzer 發現的 deprecation infos 從 5 不變或減少。
4. 全 suite 維持 390+ pass。
5. **跑起來看**：journey 主標題與 explore 同 typography；filter chips 仍清晰可選；timeline 節點仍是電光藍 + 白點；quick guide 節點用獨特藍區隔。
