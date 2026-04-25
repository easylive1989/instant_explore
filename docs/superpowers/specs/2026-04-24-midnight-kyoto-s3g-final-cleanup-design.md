# Midnight Kyoto S3-g — 最終清理設計文件

- 日期：2026-04-24
- Sprint：S3-g（S3 最終 mini-sprint，總 11 個 sub-sprint 之最後）
- 範圍：
  - `frontend/lib/features/trip/presentation/widgets/trip_card.dart`（2 處 amber）
  - `frontend/lib/features/ads/presentation/widgets/watch_ad_dialog.dart`（2 處 amber + 1 處 textSecondaryDark）
  - `frontend/lib/common/config/app_colors.dart`（刪除 13 個 `@Deprecated` 常數）

## 背景與目標

S3 各 feature 翻新已完成；剩 2 個邊緣 feature（trip、ads）內 5 個 hardcoded ref。S3-g 把這 5 處清掉，然後**真正刪除** `AppColors` 內所有 deprecated 常數。

完成後：
- `fvm flutter analyze --fatal-infos` 預期 0 issues
- `AppColors` 只剩 MK 設計系統的 named tokens
- 整個 S3 sprint 結束

## 已決策事項

| 議題 | 決定 |
|---|---|
| `AppColors.amber` 替換語意 | `cs.tertiary`——MK 暖橘是 amber 的 token 對應，已在 settings 與 onboarding 採用，繼續一致 |
| `AppColors.textSecondaryDark` | `cs.onSurfaceVariant` |
| `app_colors.dart` 內 13 個 `@Deprecated` 常數 | **全部刪除**——S3 後沒有任何 caller |
| 是否同步處理 watch_ad_dialog 的其他非 deprecated 但 hardcoded color（`AppColors.primary`、`Colors.white`）| **不在範圍**——只清 deprecated；其他 token 散落需要更大規模重做 |

## 影響檔案

| 檔案 | 修改點 | 動作 |
|---|---|---|
| `trip_card.dart` | 2 處 `AppColors.amber` | 換 `cs.tertiary` |
| `watch_ad_dialog.dart` | 2 處 `AppColors.amber` + 1 處 `AppColors.textSecondaryDark` | 換 `cs.tertiary` / `cs.onSurfaceVariant` |
| `app_colors.dart` | 13 個 `@Deprecated` 常數 | 刪除 |

對應 tests：
- `trip_card_test.dart`（如有）
- `watch_ad_dialog_test.dart`（如有）

## 不在 S3-g 範圍

- ❌ 全 app 內非 deprecated 的 `Colors.white` / hardcoded `Color(0x...)` 整理
- ❌ trip 或 ads feature 的其他 widget 重塑
- ❌ AppBar 改 `MidnightAppBar` 之類的元件升級
- ❌ light theme 的最終決策（架構保留中）

## 設計細節

### 1. `trip_card.dart`

兩處皆是 "current trip" 的視覺強調——border 與 badge bg。改用 `cs.tertiary`：

**Border**（line 47）：
```dart
border: isCurrent
    ? Border.all(color: cs.tertiary, width: 2)
    : null,
```

**Badge**（line 65 區塊）：
```dart
decoration: BoxDecoration(
  color: cs.tertiary,
  borderRadius: BorderRadius.circular(8),
),
```

⚠️ 需在 build method 取得 `cs`（如還沒 declared）。

### 2. `watch_ad_dialog.dart`

**Icon container & icon**（lines 102, 108）：
```dart
Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
    color: cs.tertiary.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Icon(
    Icons.play_circle_outline,
    size: 28,
    color: cs.tertiary,
  ),
),
```

⚠️ 移除 `child: const Icon(...)` 的 `const`（含 `cs.tertiary`）。

**Cancel text**（line 192）：
```dart
Text(
  'settings.cancel'.tr(),
  style: TextStyle(
    fontSize: 14,
    color: cs.onSurfaceVariant,
  ),
),
```

⚠️ 移除 `style: const TextStyle(...)` 的 `const`。

### 3. `app_colors.dart` 刪除

刪除以下 13 個 `@Deprecated` 常數整個區塊：

```dart
// --- Legacy (S3 will remove these) ---
@Deprecated(...)
static const Color surfaceDark = ...;

@Deprecated(...)
static const Color surfaceDarkPlayer = ...;

@Deprecated(...)
static const Color surfaceDarkConfig = ...;

@Deprecated(...)
static const Color surfaceDarkCard = ...;

@Deprecated(...)
static const Color amber = ...;

@Deprecated(...)
static const Color errorBg = ...;

// --- Legacy text aliases ---
@Deprecated(...)
static const Color textPrimaryLight = ...;

@Deprecated(...)
static const Color textSecondaryLight = ...;

@Deprecated(...)
static const Color textPrimaryDark = ...;

@Deprecated(...)
static const Color textSecondaryDark = ...;

@Deprecated(...)
static const Color textTertiaryDark = ...;

@Deprecated(...)
static const Color textQuaternaryDark = ...;

@Deprecated(...)
static const Color backgroundLight = ...;
```

包含上方分隔註解 `// --- Legacy (S3 will remove these) ---` 與 `// --- Legacy text aliases ---`。

⚠️ **保留**：`AppColors.primary`、`AppColors.success`、`AppColors.error`、`AppColors.surfaceVariant`、所有 surface 階梯、`outlineVariant`、`backgroundDark`、`white10`、`white20`、`black20`、`glassBorder` 等——這些是 MK 設計系統的有效 token。

## 測試策略

預期所有現有 tests 不需動。pre-commit hook 跑全 suite 一定會抓到任何外部殘留引用。

如果 trip 或 ads 的 widget tests 有斷言 `Container.color == AppColors.amber`，需改用 `cs.tertiary`。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 刪除 deprecated 常數後第三方 code 仍引用 | 高 | grep 確認無殘留；S3 各 sprint 已逐個清掉 |
| `cs.tertiary` (#FFB68C) 比 amber (#F59E0B) 更柔和 | 低 | 已在 onboarding/settings/save_success 採用，視覺一致 |
| Trip / ads widget tests 斷言 amber 顏色 | 低 | 預期 finder 不依賴特定色 |

## 成功指標

1. `fvm flutter analyze --fatal-infos` 報告 **0 issues**。
2. `app_colors.dart` 內 `@Deprecated` 為 0。
3. 全 suite 維持 390+ pass。
4. **跑起來看**：trip "current" 標記從鮮亮 amber 變柔和暖橘；watch ad dialog 的 play icon 同樣。
