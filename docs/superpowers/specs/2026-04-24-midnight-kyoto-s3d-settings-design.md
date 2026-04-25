# Midnight Kyoto S3-d — Settings 設計文件

- 日期：2026-04-24
- Sprint：S3-d（S3 第五個 mini-sprint）
- 範圍：`frontend/lib/features/settings/presentation/screens/settings_screen.dart`（398 行）

## 背景與目標

Settings 是 functional UI（不是 hero screen），設計取捨偏「資訊清晰度 > 編輯感」。在 S1 已做過 theme 切換 UI 的清理；現在做 token 統一 + AppBar 替換 + deprecated `AppColors` 收尾。

## 影響範圍

| Widget | 角色 | 動作 |
|---|---|---|
| `SettingsScreen` | 主 Scaffold + AppBar | 中（換 MidnightAppBar）|
| `_SectionHeader` | 區塊大標 | 小（typography） |
| `_SectionContainer` | 帶邊框的卡片容器 | 不動（與 GlassCard 故意不同：`surfaceContainer` 不透明，是 list section）|
| `_LanguageTile` | 語言列 | 小（token） |
| `_OnboardingSection` | 重看 onboarding 入口 | 小（token） |
| `_SubscriptionSection` | premium / upgrade 兩變體 | 中（amber → tertiary） |
| `_UsageSection` | 每日使用量 | 小（token） |
| `_SettingsTile` | 基底列 | 小（保留 32x32 icon-in-circle 設計）|

測試：`settings_screen_test.dart`（124 行 / 3 testWidgets），預期不需動。

## 已決策事項

| 議題 | 決定 |
|---|---|
| AppBar | 改用 `MidnightAppBar(title, uppercaseTitle: true)`——統一品牌 |
| `_SectionContainer` 設計 | **保留不動**——`surfaceContainer` 不透明區塊容器是刻意設計（與 GlassCard 的 `surfaceVariant` 玻璃卡片區分用途） |
| 所有 `AppColors.primary` icon 用法 | 改 `cs.primary`（4 處） |
| `_SubscriptionSection` premium icon `AppColors.amber` | 改 `cs.tertiary`（暖橘，保有「金幣感」）|
| `_SettingsTile` 32x32 icon circle | 保留設計，只 token-化 |
| `_SectionHeader` typography (12/w600/tracking 1.0) | 改 `textTheme.labelMedium.copyWith(letterSpacing: 1.0)`（labelMedium 是 12/w700——對齊 MK 規範）|
| `_SettingsTile` 標題 (16/w500) | 維持 hardcoded——settings 列需要比 MK textTheme 預設大一點以利可讀性 |
| AlertDialog (`_confirmReplay`) | 維持，會繼承 MK dialogTheme |

## 不在 S3-d 範圍

- ❌ Subscription 螢幕本身（→ S3-e）
- ❌ Settings controller / language provider 邏輯
- ❌ `_LanguageTile.controller` 的 `dynamic` 型別清理（與 MK 無關）

## 設計細節

### 1. `SettingsScreen.build`

```dart
return Scaffold(
  appBar: MidnightAppBar(title: Text('settings.title'.tr())),
  body: ListView(
    padding: const EdgeInsets.all(16.0),
    // ...
  ),
);
```

⚠️ `MidnightAppBar` 預設 `uppercaseTitle: true`——`Settings` 變 `SETTINGS`，中文 "設定" 不變。可接受。

⚠️ 移除原本自畫的 `Container(color: cs.onSurface @ 10%)` 1px divider——`MidnightAppBar` 內建 `BorderSide(color: cs.outlineVariant)` 底邊。

### 2. `_SectionHeader`

```dart
@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 1.0,
      ),
    ),
  );
}
```

`labelMedium` 已是 12/w700/`onSurfaceVariant`——只需加 `letterSpacing: 1.0`。

### 3. `_LanguageTile` icon 色

```dart
return _SettingsTile(
  icon: Icons.language,
  iconColor: cs.primary,
  iconBgColor: cs.primary.withValues(alpha: 0.2),
  // ...
);
```

⚠️ 需要 `cs` 變數——目前 `_LanguageTile` 沒有 `Theme.of(context)` 因為它把 controller 傳進來、不直接用 colorScheme。要在 build method 開頭加 `final cs = Theme.of(context).colorScheme;`。

### 4. `_OnboardingSection` icon 色

同樣：`cs.primary` 取代 `AppColors.primary`。已有 `colorScheme` 變數。

### 5. `_SubscriptionSection`

Premium 變體：

```dart
_SettingsTile(
  icon: Icons.workspace_premium,
  iconColor: cs.tertiary,                          // ← was AppColors.amber
  iconBgColor: cs.tertiary.withValues(alpha: 0.2),
  title: 'subscription.premium_active'.tr(),
  // ...
),
```

Upgrade 變體：`AppColors.primary` → `cs.primary`。

### 6. `_UsageSection`

3 處 `AppColors.primary` → `cs.primary`（data / error 路徑都有 `_SettingsTile` 用 primary icon）。

### 7. `_SettingsTile`

不變設計——僅依賴外部傳入的 `iconColor` 與 `iconBgColor`。當所有 caller 改成 `cs.X` 後這個 widget 就 token 化了。

### 8. Imports

新增：`import 'package:context_app/shared/widgets/midnight/midnight.dart';`（為了 `MidnightAppBar`）

移除：`import 'package:context_app/common/config/app_colors.dart';`（如所有 `AppColors.X` 都已替換）

⚠️ 若有殘留 `AppColors.X` 引用就保留 import；grep 確認後再刪。

## 測試策略

`settings_screen_test.dart`（3 個 testWidgets）：
- `find.text('settings.title')` → 注意 MidnightAppBar 會 uppercase——測試需改成 `find.text('SETTINGS.TITLE')` 或更穩的 `find.byType(MidnightAppBar)`
- 其他斷言應不受影響（focus 在功能行為：tap onboarding tile → 看到 dialog 等）

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `MidnightAppBar` 把 `'settings.title'.tr()` 改大寫導致測試 fail | 中 | 預期會 fail；改 finder（最小修改）|
| Premium tile 從 amber → tertiary 視覺變化（橘色不那麼鮮亮）| 低 | 暖色感保留，跟 onboarding page-4 一致 |
| `_SectionContainer` 仍是 1px outline border 與 MK 「no-line」規則衝突 | 低 | 接受——settings list 需要清晰邊界區隔；no-line 規則的目的是 layout sectioning，這裡是 list grouping |

## 成功指標

1. `settings_screen.dart` 內 `AppColors.X` 引用為 0；`AppColors.amber` 引用為 0。
2. AppBar 是 `MidnightAppBar`。
3. 既有 settings test 全 pass（最小修改後）。
4. analyzer clean。
5. 全 suite 維持 390+ pass。
6. **跑起來看**：標題大寫"SETTINGS"、所有 icon 圓點是電光藍 / premium 是暖橘、`_SectionContainer` 邊框依然清晰。
