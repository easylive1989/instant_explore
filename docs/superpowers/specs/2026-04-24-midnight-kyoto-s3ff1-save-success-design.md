# Midnight Kyoto S3-ff-1 — Save Success Screen 設計文件

- 日期：2026-04-24
- Sprint：S3-ff-1（journey 的第一個 sub-sprint，總 S3 第八個 mini-sprint）
- 範圍：`frontend/lib/features/journey/presentation/screens/save_success_screen.dart`（243 行）

## 背景與目標

把資訊保存到 journey 後出現的成功畫面。視覺上是「儀式感成功 confirmation」hero——三層成功圓 + 大標題 + 預覽卡片 + 兩個 CTA 按鈕。已大量使用 `colorScheme.X`，剩 3 處 hardcoded 需要清掉。

順便處理 S1 時對 `AppColors.success` 的過度棄用：success green 是有語意的設計 token，不該被改掉。**這次取消 deprecation**。

## 影響檔案

| 檔案 | 行數 | 動作 |
|---|---|---|
| `save_success_screen.dart` | 243 | 中（PillButton 替換 + token 化）|
| `frontend/lib/common/config/app_colors.dart` | — | 取消 `AppColors.success` 的 `@Deprecated` 標記 |

對應 test：本 feature 沒有獨立的 widget test（只有 domain 層）。

## 已決策事項

| 議題 | 決定 |
|---|---|
| `AppColors.success` 棄用 | **取消棄用**——success green 是 MK 之外有語意的設計 token；移除 `@Deprecated` 標記 |
| 三層成功圓圈設計 | **保留**——120 / 100 / 80 同心圓是儀式感設計 |
| Success shadow `Color(0x4D10b981)` | **保留**——success green 30% 的 brand glow，與 subscription brand glow `Color(0x14137FEC)` 同 pattern |
| `Icons.bookmark_added` icon `Colors.white` | 改 `Colors.white`——這是 success green 上的對比色，不是 MK token；維持 hardcoded |
| Primary CTA 按鈕 | 改 `PillButton(label, icon: arrow_forward, fullWidth)` |
| Secondary "Continue tour" 按鈕 | 改 `PillButton(secondary, fullWidth)` |
| AppBar 標題 typography | 維持自訂 12px uppercase tracking 1.0（很 MK 的 metadata 樣式）|
| Hero "Item saved" 標題 | 維持 24/bold（介於 MK headlineMedium 與 displaySmall）|
| Preview card | 維持 surfaceContainer + outlineVariant 邊框（已 token 化）|

## 不在 S3-ff-1 範圍

- ❌ `journey_screen.dart`（→ S3-ff-2）
- ❌ `timeline_entry.dart` / `quick_guide_timeline_entry.dart`（→ S3-ff-2）
- ❌ `journey_sharing_card.dart`（→ S3-ff-3）

## 設計細節

### 1. 取消 `AppColors.success` 的 deprecation

`frontend/lib/common/config/app_colors.dart` 約 line 90：

刪除：
```dart
@Deprecated('Use a tertiary or new token; will be removed in S3.')
static const Color success = Color(0xFF10B981);
```

替換為：
```dart
/// Success green for confirmation states.
///
/// Distinct from MK's primary blue and tertiary orange — semantic
/// "success" colour for save / completion confirmations.
static const Color success = Color(0xFF10B981);
```

`AppColors.amber` 與 `AppColors.errorBg` 的 deprecation 維持不變（這兩個是 S3 仍要清掉的）。

### 2. `save_success_screen.dart` build

**移除 `const successColor` 別名**，直接使用 `AppColors.success`（因為已不再 deprecated）。

**Primary CTA "View journey"**——改 PillButton：

```dart
PillButton(
  label: 'journey.view_button'.tr(),
  icon: Icons.arrow_forward,
  fullWidth: true,
  onPressed: onViewJourney,
),
```

⚠️ 失去原本「label 在前、icon 在後」的順序；`PillButton` icon 是 leading。設計 trade-off：與全 app 一致 vs. 失去視覺 affordance。**接受**——`PillButton` 預設 icon 在前是設計慣例。

⚠️ 失去 `padding: EdgeInsets.symmetric(vertical: 18)` 的客製高度；`PillButton` 預設 14v 較矮。**接受**——MK 標準高度。

**Secondary "Continue tour"**——改 PillButton：

```dart
PillButton(
  label: 'journey.continue_tour'.tr(),
  variant: PillButtonVariant.secondary,
  fullWidth: true,
  onPressed: onContinueTour ?? () => context.pop(),
),
```

⚠️ 原本是 `AdaptiveButtonStyle.text` 但傳入 `backgroundColor: surfaceContainerHigh + foregroundColor: onSurface`——其實是 secondary button 的視覺。`PillButton.secondary` 一致對齊。

### 3. 取消 `colors` 的 `successColor` 別名

```dart
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  // 移除 const successColor = AppColors.success;
  // 直接用 AppColors.success
  
  return Scaffold(
    // ...
  );
}
```

三層圓圈 / icon background 用 `AppColors.success`、`AppColors.success.withValues(alpha: 0.1)`、`AppColors.success.withValues(alpha: 0.2)` 直接寫。

### 4. Imports

`save_success_screen.dart`：
- 已 import `app_colors.dart` 與 `adaptive_widgets.dart`
- 新增 `import 'package:context_app/shared/widgets/midnight/midnight.dart';`（PillButton）
- `AdaptiveButton` 不再需要 → 移除 `adaptive_widgets.dart` import 若無其他 adaptive 元件。**檢查**：`AdaptiveIconButton`（close button）仍使用 → 保留 import。

## 測試策略

無獨立 widget test。pre-commit hook 全 suite 執行，注意：
- 任何 navigation test 若觸及 `journey_success` 路由，預期不受影響（行為不變）。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 取消 `AppColors.success` deprecation 影響其他 S3 sprint 計畫 | 低 | 沒有其他 sprint 為了清掉它而 spec；改回去是無痛的 |
| `PillButton` 的 14v padding 比舊 18v 矮，視覺差 | 低 | MK 標準化；接受 |
| Primary CTA icon 從尾部移到頭部 | 低 | iOS 標準 affordance（icon 在前）|
| `AdaptiveButton` 改 `PillButton` 可能讓平台適配層失效 | 低 | `PillButton` 內部已是 Material InkWell；iOS/Android 都有 ripple |

## 成功指標

1. `save_success_screen.dart` 內 `AppColors.success` 引用 ≥ 1（無 deprecation warning）。
2. `AppColors.primary` 與其他 deprecated tokens 引用為 0。
3. 兩個 CTA 改用 `PillButton`。
4. 全 suite 維持 390+ pass。
5. analyzer info 數從 7 降到 ≤ 6（移除 deprecation 警告）。
6. **跑起來看**：成功畫面三層綠圓 + 綠 shadow 仍亮眼；兩顆按鈕變圓 stadium、間距與 explore/subscription 一致。
