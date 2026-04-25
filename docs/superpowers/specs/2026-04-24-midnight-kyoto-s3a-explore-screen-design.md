# Midnight Kyoto S3-a — Explore Screen 設計文件

- 日期：2026-04-24
- Sprint：S3-a（共 7 個 mini-sprint，這是第一個）
- 範圍：`frontend/lib/features/explore/presentation/screens/explore_screen.dart` + 對應 widget test

## 背景與目標

S2 把元件詞彙建好（`GlassCard`、`PillButton`、`PillIconButton`、`StatusChip`、`AmbientBackdrop` 等）。S3-a 是第一個把這套詞彙套到實際 feature screen 的試金石——把 explore 主頁從「Material 預設外觀 + hard-coded 顏色」翻新成 Midnight Kyoto 編輯風格。

成功的 S3-a 會證明 S2 元件 API 設計合理；同時定義出 S3-b 之後的範本流程。

## 已決策事項

| 議題 | 決定 | 說明 |
|---|---|---|
| Q1：PlaceCard 類別 chip 色彩 | **保留動態色**（依 `place.category.color`） | category 是有功能性的識別，不為純設計犧牲可用性；只改外觀 |
| Q2：BookmarkButton 互動 | **加 `PressScale` wrapper、不加背景** | 保留簡潔感獲得 MK 按下回饋 |
| Q3：既有 widget tests 處理 | **最小修改** | 改 query 路徑保留行為驗證，不重寫測試本意 |
| Scope：SavedLocationsFab | **不動** | 留給 S3-f（saved_locations + journey）|
| Scope：`place_category_extension.dart` | **不動** | category 顏色 / icon 是獨立關注點 |

## 不在 S3-a 範圍

- ❌ `SavedLocationsFab`（→ S3-f）
- ❌ `place_category_extension.dart`（顏色 / icon 來源不變）
- ❌ `AppColors` 內已 deprecated token 的最終刪除（→ S3-g）
- ❌ saved_locations 對話框、journey 等其他 feature

## 設計

### 1. ExploreScreen 主體

**標題行**：
- "Explore" 字串字級從 `fontSize: 40, FontWeight.bold` 改用 `Theme.of(context).textTheme.displayLarge`（36px / w900 / letterSpacing -0.5），符合 MK 編輯排版。
- Refresh 按鈕：原 `IconButton(ElevatedButton.styleFrom(... AppColors.primary))` 改 `PillIconButton(icon: Icons.refresh, onPressed: ..., variant: PillIconButtonVariant.filled, size: 40)`。
- 兩個 icon button 之間 padding 維持 `SizedBox(width: 8)`。

**搜尋框**：
- 維持 `AdaptiveTextField`（這是 cross-platform 抽象，動到 S3-g 再評估），僅確認其外觀已透過 ThemeData 的 `inputDecorationTheme`（S1 設定）正確繼承新外觀。

**列表 / 空狀態 / 錯誤**：
- "No places found" 字串可考慮改 `textTheme.headlineMedium` + 較大 padding，但低優先；先維持。
- `error` 顯示維持，僅替換成 `colorScheme.error` 文字色。

### 2. `_FilterButton`

```dart
PillIconButton(
  icon: Icons.tune,
  onPressed: onPressed,
  variant: isActive
      ? PillIconButtonVariant.filled  // active 仍用 primary 強調
      : PillIconButtonVariant.ghost,  // inactive 用 surfaceContainerHigh
  size: 40,
)
```

⚠️ 失去既有的 amber 色作為「filter active」的視覺差異（先前是用 amber 與 primary 區分 active）。新設計用 `filled` vs `ghost` 兩個 variant 區分 active/inactive，依然能視覺辨識，但顏色更收斂於品牌。

`Badge(isLabelVisible: isActive, smallSize: 8)` 因為 `PillIconButton` 不支援 child wrapping，會在 widget tree 拆解成：

```dart
Stack(
  children: [
    PillIconButton(icon: Icons.tune, onPressed: onPressed, variant: ...),
    if (isActive) Positioned(top: 0, right: 0, child: _ActiveDot()),
  ],
)
```

`_ActiveDot` 是 8x8 的 `primary` 圓點，視覺通知有 filter 啟動中。

### 3. `_FilterPanel`（底部 sheet）

- 標題 `'explore.filter.title'.tr()` 從 `fontSize: 20, FontWeight.bold` 改 `textTheme.headlineMedium`。
- "min reviews" 標籤改 `textTheme.bodyMedium` 配 `colorScheme.onSurfaceVariant`（這個本來就是了，只是用 textTheme 標準化）。
- 數值 display（`$currentValue`）改 `textTheme.titleLarge` + `colorScheme.primary`。
- "0" 與 "1000" 邊界字 → `textTheme.labelSmall`（10px / w700 / uppercase tracking——但因為是數字看起來不會醜，且符合 MK 規範）。
- description 字 → `textTheme.bodySmall`。
- Reset 按鈕：原 `AdaptiveButton(expanded: true)` → `PillButton(label: ..., variant: PillButtonVariant.ghost, fullWidth: true)`。
- Sheet 內 Padding / drag handle 容器維持。

### 4. `PlaceCard`

從 `Card + InkWell` 改成 `GlassCard(onTap: ...)`：

```dart
GlassCard(
  onTap: () => context.pushNamed('config', extra: place),
  padding: const EdgeInsets.all(12),
  child: Row(
    children: [
      ClipRRect(...image),  // 維持
      const SizedBox(width: 16),
      Expanded(
        child: Column(...title + categoryChip + address),
      ),
      _BookmarkButton(...),
    ],
  ),
)
```

外層 `Padding(EdgeInsets.symmetric(vertical: 8))` 改放在 ListView 的 itemBuilder 那層（用 `Padding` 包 `GlassCard`），因為 GlassCard 不接受 margin。

**類別 chip**（保持動態色）：

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: place.category.color.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(4),  // ← MK chip radius 4，不再用 12
    // 移除 border（"No-Line" 規則）
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(place.category.icon, size: 12, color: place.category.color),  // 12 統一 MK chip icon size
      const SizedBox(width: 4),
      Text(
        place.category.translationKey.tr().toUpperCase(),
        style: TextStyle(
          color: place.category.color,
          fontSize: 10,                     // ← MK label small
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ],
  ),
)
```

文字標題 / 地址使用 textTheme：
- name → `textTheme.headlineMedium` (18 / w700)
- formattedAddress → `textTheme.bodyMedium` 但 size 改 12（已是 textTheme.bodyMedium 預設）

### 5. `_BookmarkButton`

```dart
PressScale(
  onTap: onTap,
  child: AnimatedSwitcher(
    duration: Duration(milliseconds: 300),
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child: Icon(
      isSaved ? Icons.bookmark : Icons.bookmark_border,
      key: ValueKey(isSaved),
      color: isSaved ? AppColors.primary : colorScheme.onSurfaceVariant,
      size: 28,
    ),
  ),
)
```

⚠️ `PressScale` 在 `lib/shared/widgets/midnight/_press_scale.dart`，公開 class 名是 `PressScale`，需直接 `import` 而非透過 barrel（barrel 故意不 export internal helper）。S3-a 將為這個 case 開啟例外：要嘛把 `_press_scale.dart` 加進 barrel、要嘛把 `_press_scale.dart` 重命名成 `press_scale.dart`（移除 underscore 前綴）並加進 barrel。

**決策：本 spec 不在這層做變更**。`_BookmarkButton` 直接 `import 'package:context_app/shared/widgets/midnight/_press_scale.dart';` 從具體檔案載入。如果 S3 後續有更多 feature 需要直接用 `PressScale`（不透過 PillButton/GlassCard），再 promote 到 barrel。

### 6. AppColors 替換

- `AppColors.primary`（line 99, 472）：保留——本來就是 MK 主色。
- `AppColors.amber`（line 181）：刪除——隨 `_FilterButton` 改用 PillIconButton 後不再需要。

S3-a 結束後 `explore_screen.dart` 應該完全沒有 `AppColors.amber` 引用。

## 測試策略

`explore_screen_test.dart`（294 行）的最小修改原則（Q3=B）：

- **保留行為斷言**：tap refresh 觸發 controller、search submit 觸發 search、tap place card 觸發 push、tap bookmark 觸發 toggle ——這些行為的測試原則不變。
- **更新 widget query**：`find.byType(Card)` → `find.byType(GlassCard)`；`find.byType(IconButton)`（refresh 那個）→ `find.byType(PillIconButton)`。
- **`_FilterButton` 測試的 `isActive` 視覺判斷**：原本可能斷言 `backgroundColor: AppColors.amber`；改為斷言「`PillIconButton` 的 `variant` 屬性等於 `PillIconButtonVariant.filled`」或檢查 `_ActiveDot` 是否存在。
- **保留搜尋框、空狀態、錯誤狀態的測試**——這些跟 widget 替換無關。

如果發現某個測試不能用最小修改達成驗證目的，當下停下並彙報「需要重寫」的具體 case，我會在繼續前評估。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `GlassCard` 在 ListView 裡 N 個 BackdropFilter 疊加效能差 | 中 | S3-a 結束後在裝置上跑、若卡再考慮把 `GlassCard.blurSigma` 或退到非 blur 的 `surfaceVariant` 純色變體 |
| 既有測試的視覺斷言過多、最小修改達不到 | 中 | 真的無法的，採 Q3 fallback：刪舊測試寫新測試；先讓這次驗證成立 |
| Refresh / Filter 兩個 PillIconButton 並排——MK 規定 size 48 但畫面緊張 | 低 | 兩個都用 `size: 40`（比預設 48 小）；spec 已寫 |
| 失去 amber 作為 filter-active 視覺差異 | 低 | 用 filled/ghost variant + `_ActiveDot` 補足；接受視覺收斂 |

## 成功指標

1. `explore_screen.dart` 內 `AppColors.amber` 引用為 0；其他 deprecated tokens 引用為 0。
2. 既有 `explore_screen_test.dart` 全 pass（minimal-touch 修改後）。
3. `fvm flutter analyze --fatal-infos lib/features/explore/presentation/screens/explore_screen.dart test/features/explore/presentation/screens/explore_screen_test.dart` clean。
4. 整體 test suite 維持 390+ passing。
5. **跑起來看**：探索頁標題編輯感更強（顯眼大標題）、PlaceCard 玻璃化、Refresh/Filter 改用品牌風格 pill icon、整體與 AmbientBackdrop 視覺一致。
