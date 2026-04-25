# Midnight Kyoto S1 — Theme Foundation 設計文件

- 日期：2026-04-24
- Sprint：S1（共 3 個 sprint：S1 token、S2 元件庫、S3 feature 翻新）
- 範圍：`frontend/lib/common/config/`、`frontend/lib/features/settings/` 的主題切換 UI、`frontend/lib/main.dart` / `app.dart` 的 MaterialApp 設定

## 背景與目標

`docs/design/component/DESIGN.md` 定義了 Midnight Kyoto 設計系統（"Neon Nocturne"）。它是 dark-first 的編輯風格，靠玻璃擬態、深底、霓虹電光藍營造氣氛。目前 Flutter 端的 dark theme 是淺薄的 `ColorScheme.fromSeed`，且維持 light/dark/system 切換。

S1 的目標：**建立 Midnight Kyoto 的色彩 token、字型、單一深色 ThemeData**，讓後續的元件庫（S2）與螢幕翻新（S3）有完整的詞彙可用。S1 結束後 app 應該已經呈現「全黑底 + 電光藍主色 + 玻璃 surface 階梯」的基礎面貌，只是元件還沒重塑。

## 已決策事項（與用戶確認）

| 議題 | 決定 |
|---|---|
| Light theme 命運 | **廢除**——`ThemeMode.dark` 鎖定，settings 移除切換 UI |
| 未來想加回 light | **架構保留**——`ThemeConfig.lightTheme` getter 留住、`ThemeModeNotifier` 結構不動，僅 MaterialApp 鎖定 dark |
| M3 ColorScheme 策略 | **完整 override**——不用 `ColorScheme.fromSeed`，所有 token 手挑成 MK 值 |
| Atmospheric backdrop | **全 app 都套**（決定後移至 S2 落地，S1 只把 scaffold 顏色準備好） |
| Settings UI | **完全移除主題切換 section**（連選項都不顯示） |

## 不在 S1 範圍

明確排除避免 scope creep：
- ❌ `AmbientBackdrop` 帶圖片紋理 + 漸層 + 動畫（→ S2）
- ❌ `GlassCard` / `PillButton` / `StatusChip` / `MidnightAppBar` / `MidnightBottomNav` 等共用元件（→ S2）
- ❌ 各 feature screen 的視覺翻新（→ S3）
- ❌ 任何 hard-coded `Color(0x...)` 在 widget 內的清理（→ S3）
- ❌ 既有 widget tests 的視覺斷言調整（→ S3，視需要修）

## 目前狀態

- `app_colors.dart`：13 個 const，已有 `primary = #137FEC`、`backgroundDark = #101922`、`surfaceDark = #1C2630`、`white10`、`white20`，但缺 surface 階梯、`outlineVariant`、`secondary`、`tertiary`、`primaryContainer` 等。
- `theme_config.dart`：dark theme 是 `ColorScheme.fromSeed(seedColor: primary, brightness: dark)` + 少量元件 override。Light theme 完整存在。
- `MaterialApp`：`theme` + `darkTheme` 都傳，`themeMode` 由 `themeModeNotifierProvider` 提供（dark/light/system）。
- `ThemeModeNotifier`：用 `SharedPreferences` 讀寫 `'theme_mode'` key，預設 `dark`。
- `settings_screen.dart`：有 ThemeMode 切換 UI（line 205-242）。
- `MidnightKyotoBackdrop`：已存在但只用於 onboarding 與 paywall。

## 設計

### 1. Token 表（`app_colors.dart` 完整改寫）

採用 Material 3 命名 + MK 自訂值。所有顏色直接從 `docs/design/component/code.html` 的 `tailwind.config` 抓出來：

```
// Surface 階梯（黑→灰漸層）
backgroundDark            = #101922  // surface
surfaceDim                = #0D141B
surfaceContainerLowest    = #0B1117
surfaceContainerLow       = #151E27
surfaceContainer          = #1C2630
surfaceContainerHigh      = #27313C
surfaceContainerHighest   = #323C48
surfaceBright             = #222D39
surfaceVariant            = rgba(255,255,255,0.08)  // glass card 主色
inverseSurface            = #E0E2EC
onSurface                 = #FFFFFF
onSurfaceVariant          = #C1C6D5
onBackground              = #FFFFFF
inverseOnSurface          = #2D3038

// Primary（電光藍 + container 是低不透明度）
primary                   = #137FEC
onPrimary                 = #FFFFFF
primaryContainer          = rgba(19,127,236,0.2)
onPrimaryContainer        = #A8C8FF
primaryFixed              = #D5E3FF
primaryFixedDim           = #A8C8FF
onPrimaryFixed            = #001B3C
onPrimaryFixedVariant     = #004689
inversePrimary            = #005EB4
surfaceTint               = #137FEC

// Secondary
secondary                 = #ADC8F7
onSecondary               = #123158
secondaryContainer        = #2C4770
onSecondaryContainer      = #9BB6E5
secondaryFixed            = #D5E3FF
secondaryFixedDim         = #ADC8F7
onSecondaryFixed          = #001B3C
onSecondaryFixedVariant   = #2C4770

// Tertiary（暖橘色）
tertiary                  = #FFB68C
onTertiary                = #532200
tertiaryContainer         = #E47019
onTertiaryContainer       = #481D00
tertiaryFixed             = #FFDBC9
tertiaryFixedDim          = #FFB68C
onTertiaryFixed           = #321200
onTertiaryFixedVariant    = #753400

// Error
error                     = #FFB4AB
onError                   = #690005
errorContainer            = #93000A
onErrorContainer          = #FFDAD6

// Outline（"ghost border" 用）
outline                   = #8B919F
outlineVariant            = rgba(255,255,255,0.1)
```

舊的 `surfaceDarkPlayer` / `surfaceDarkConfig` / `surfaceDarkCard` / `errorBg` / `success` / `amber` 暫時保留（避免破壞 31 個 call sites），加上 `@Deprecated` 註解告知 S3 會清掉。

### 2. ThemeConfig 重寫

**`darkTheme`**：捨棄 `ColorScheme.fromSeed`，改用全 override：

```dart
final colorScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.backgroundDark,
  onSurface: AppColors.onSurface,
  surfaceDim: AppColors.surfaceDim,
  surfaceBright: AppColors.surfaceBright,
  surfaceContainerLowest: AppColors.surfaceContainerLowest,
  surfaceContainerLow: AppColors.surfaceContainerLow,
  surfaceContainer: AppColors.surfaceContainer,
  surfaceContainerHigh: AppColors.surfaceContainerHigh,
  surfaceContainerHighest: AppColors.surfaceContainerHighest,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
  inverseSurface: AppColors.inverseSurface,
  onInverseSurface: AppColors.inverseOnSurface,
  inversePrimary: AppColors.inversePrimary,
  surfaceTint: AppColors.surfaceTint,
);
```

**`scaffoldBackgroundColor`**：保持 `AppColors.backgroundDark`（S2 加 backdrop 後改 transparent）。

**`textTheme`**：改成 MK 編輯排版節奏（在 Inter 字型上 — 字型載入由現有 `google_fonts` 負責；S2 才正式換）：
- `displayLarge` 36px / FontWeight.w900 / letterSpacing -0.5（"Explore"、"KYOTO" 級標題）
- `displaySmall` 24px / w700
- `headlineMedium` 18px / w700
- `bodyLarge` 14px / w400 / height 1.5
- `bodyMedium` 12px / w400 / height 1.6（MK 主要內文尺寸）
- `bodySmall` 10px / w400
- `labelMedium` 12px / w700
- `labelSmall` 10px / w700 / letterSpacing 1.5（uppercase metadata 用）

**Component themes**（核心方向，細節到 S2 才實際打磨）：
- `appBarTheme`：transparent 背景、`foregroundColor: onSurface`、`titleTextStyle`: 18px bold uppercase tracking-tight
- `cardTheme`：移除 `BorderSide`（"No-Line" 規則）、`color: surfaceVariant`、`shape: RoundedRectangleBorder(BorderRadius.circular(12))`
- `elevatedButtonTheme` / `filledButtonTheme`：圓 pill 形 (`StadiumBorder()`)、`primary` 背景、`onPrimary` 文字、無 elevation
- `outlinedButtonTheme`：`StadiumBorder()` + `outlineVariant` 邊
- `textButtonTheme`：`primary` 文字、無背景
- `inputDecorationTheme`：`filled: true`、`fillColor: surfaceContainerLow`、邊框圓角 8px、focus 時 `primary` 邊
- `chipTheme`：`backgroundColor: surfaceContainerHigh`、`shape: StadiumBorder()`、selected: `primaryContainer`
- `dividerTheme`：`color: outlineVariant`、`thickness: 0.5`
- `bottomNavigationBarTheme`：`backgroundColor: Colors.transparent`、`type: fixed`、selected: `primary`、unselected: `onSurface.withOpacity(0.4)`
- `progressIndicatorTheme`、`switchTheme` 等其他 M3 元件由 `ColorScheme` 自動套，無需單獨 theme

**`lightTheme`**：getter 保留但實作改為「return darkTheme」 + 加 `@Deprecated('Light theme not yet implemented. Returns darkTheme as placeholder.')` 註解。這保住未來增加時 API 是現成的，呼叫端不會崩。

### 3. MaterialApp 設定變更

`app.dart`（找到 MaterialApp.router 的位置）：

```dart
return MaterialApp.router(
  // ...
  theme: ThemeConfig.darkTheme,         // 同 darkTheme，避免 themeMode bug 時崩
  darkTheme: ThemeConfig.darkTheme,
  themeMode: ThemeMode.dark,            // ← 鎖定，不再讀 notifier
  // ...
);
```

**移除**：`ref.watch(themeModeNotifierProvider)` 那行（如果有的話）。

### 4. ThemeModeNotifier 命運

**保留 class 與 SharedPreferences key**——架構不動，僅以下調整：
- `build()` 仍讀 prefs，但回傳值固定 `ThemeMode.dark`（忽略 saved 值）
- `setThemeMode` 仍寫 prefs（保留歷史，未來可讀）
- 加入 class-level 註解：

```dart
/// 主題模式管理。
///
/// 目前 app 鎖定 [ThemeMode.dark]（Midnight Kyoto），但保留此 notifier
/// 與 SharedPreferences 結構，方便未來重啟 light theme 時：
/// 1. 在 [ThemeConfig.lightTheme] 實作 light 變體；
/// 2. 將 MaterialApp 的 `themeMode` 改回 `ref.watch(themeModeNotifierProvider)`；
/// 3. 在設定頁恢復切換 UI。
```

### 5. Settings UI 變更

`settings_screen.dart` 移除：
- 整個「主題」section（包含 ThemeMode toggle）
- 對 `themeModeNotifierProvider` 的 read/watch
- 對應的翻譯 key `settings.theme_dark`、`settings.theme_light`、`settings.theme_system` 從 widget 移除呼叫，但**翻譯檔本身保留 key**（未來重啟時不用重新翻）

### 6. 未來重新啟用 light theme 的步驟（架構保留證明）

當未來決定重做 light：
1. 在 `ThemeConfig.lightTheme` 寫實際實作。
2. 在 `app.dart` 把 `themeMode: ThemeMode.dark` 改回 `themeMode: ref.watch(themeModeNotifierProvider)`。
3. 在 `settings_screen.dart` 恢復切換 widget 並 import 對應 provider。
4. （可選）`ThemeModeNotifier.build()` 移除「忽略 saved 值」邏輯。

無 schema 變更、無資料遷移。

## 測試策略

- **既有 widget tests**：54 個必須維持 pass。預期影響面 = 設定頁的 `ThemeMode` 切換相關測試（如有）會被刪除，其他 widget tests 不直接斷言顏色，應該無影響。
- **新增 unit test**：`ThemeConfigTest`
  - `darkTheme` 之 `colorScheme.primary == AppColors.primary`
  - `darkTheme.scaffoldBackgroundColor == AppColors.backgroundDark`
  - `darkTheme.cardTheme.shape` 是 `RoundedRectangleBorder` 且無 `side`（"No-Line" 規則）
  - `lightTheme` 暫時等於 `darkTheme`
- **既有 settings_screen_test**：移除主題切換相關 case。
- **`fvm flutter analyze --fatal-infos`**：必須 clean。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 31 個既有 `AppColors.X` call sites 無視覺變化（仍用舊 surfaceDarkPlayer 等）| App 在 S2/S3 之前看起來「半舊半新」| 接受——S1 是基礎，視覺收斂在 S3 |
| 移除 settings 主題切換可能讓既有用戶疑惑 | 中 | 文案不主動提；releaseNotes 提一下 |
| `ColorScheme` 全 override 後某些 Material widgets 顏色突兀 | 中 | 全套 component themes 把外觀拉回 |
| 翻譯 key 保留但 unused 觸發 i18n linter | 低 | 不啟用未使用 key 的 lint，或用 `// ignore: unused_l10n_key` 註解 |
| 既有 `MidnightKyotoBackdrop` 與新 token 命名重疊 | 低 | S1 不動它，S2 替換時一起整理 |

## 成功指標

1. App 啟動後 Scaffold 背景為 `#101922`，按鈕、focus state 為電光藍 `#137FEC`。
2. Settings 看不到主題切換選項。
3. `themeMode` 永遠是 `ThemeMode.dark`，不論 SharedPreferences saved 值。
4. 既有 54 個 widget tests + 新增的 `ThemeConfigTest` 全 pass。
5. `fvm flutter analyze --fatal-infos` 0 issues。
6. 未來重啟 light 只需修改 4 處（spec section 6 列舉）。
