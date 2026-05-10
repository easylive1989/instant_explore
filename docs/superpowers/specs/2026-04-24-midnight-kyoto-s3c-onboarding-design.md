# Midnight Kyoto S3-c — Onboarding 設計文件

- 日期：2026-04-24
- Sprint：S3-c（S3 第四個 mini-sprint）
- 範圍：`frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`、`onboarding_page_art.dart`

## 背景與目標

Onboarding 是 brand-moment 的先驅實作——`MidnightKyotoBackdrop` 與 `midnightKyotoTheme()` helper 當初就是為這個畫面建的。整體已經有 MK 編輯感（_GhostSerial、PulsingGlow、stadium button）。

S3-c 的工作是「**清理 + 統一**」：移除 S1 後不再需要的 local theme override、把 deprecated `AppColors` token 換成 `colorScheme.X`、把 `FilledButton.icon` 換成 `PillButton`，讓 onboarding 跟其他 S3 feature 用同一套詞彙。**不重新設計**——既有的編輯感保留。

## 影響檔案

| 檔案 | 行數 | 主要動作 |
|---|---|---|
| `onboarding_welcome_screen.dart` | 249 | 重（移除 Theme wrap、改 PillButton、token 替換、typography textTheme）|
| `onboarding_page_art.dart` | 116 | 中（token 替換、`_GhostSerial` 顏色用 `surfaceVariant`）|
| `onboarding_welcome_screen_test.dart` | 94（2 testWidgets）| 預期不需動 |

## 已決策事項

| 議題 | 決定 |
|---|---|
| `Theme(data: midnightKyotoTheme())` wrap | **移除**——S1 後全 app 已是 MK 主題 |
| `MidnightKyotoBackdrop` 保留 | **保留**——brand moment 在全局 AmbientBackdrop 上的 hero punch-up（S2 spec 已定）|
| `midnightKyotoTheme()` helper 函式 | **保留不刪**——subscription_screen 仍使用，留給 S3-e 處理 |
| Sample CTA 按鈕 | 從 `FilledButton.icon(StadiumBorder)` → `PillButton(icon, fullWidth)` |
| Page 4 accent（原 `AppColors.amber`）| `cs.tertiary`（#FFB68C 暖橘，最接近 amber 語意）|
| `AppColors.textSecondaryDark` | `cs.onSurfaceVariant` |
| `AppColors.textPrimaryDark` | `cs.onSurface` |
| `AppColors.textTertiaryDark` | `cs.onSurfaceVariant` |
| `AppColors.white20` | `cs.onSurfaceVariant.withValues(alpha: 0.3)` |
| `Color(0x14FFFFFF)` (ghost serial)| `AppColors.surfaceVariant`（同值的 named token）|
| Title typography (28/w800/-0.5) | 維持 hardcoded（接近 `displayMedium` 但 size 為設計刻意值）|
| Body typography (15/h1.55) | 維持 hardcoded（15 非標準刻度，是 onboarding 專用值）|
| `_ChipLabel` 結構與 size | 維持不動——寬鬆 `radius: 999` pill 是設計刻意 |

## 不在 S3-c 範圍

- ❌ `PulsingGlow` 共用 widget（內部運作正常，不動）
- ❌ `IntroductionScreen` 第三方套件配置邏輯
- ❌ `DemoNarrationFactory` 與 demo 內容
- ❌ Subscription 螢幕的 `MidnightKyotoBackdrop` 用法（→ S3-e）
- ❌ 翻譯字串

## 設計細節

### 1. `onboarding_welcome_screen.dart`

**Build method 簡化**（移除 redundant Theme wrap）：

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  
  return Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: MidnightKyotoBackdrop(
      child: IntroductionScreen(
        globalBackgroundColor: Colors.transparent,
        // ... (rest below)
      ),
    ),
  );
}
```

⚠️ Scaffold 仍保留 `backgroundColor: AppColors.backgroundDark`。雖然全局 ThemeData 已將 `scaffoldBackgroundColor` 設成 `Colors.transparent`，**這個畫面需要明確的不透明底色** 讓 `MidnightKyotoBackdrop` 的 radial wash 不被 AmbientBackdrop 干擾。雙層 backdrop 是刻意安排。

**Skip / Done text**：

```dart
skip: Text(
  'onboarding.skip'.tr(),
  style: TextStyle(
    color: cs.onSurfaceVariant,
    fontWeight: FontWeight.w600,
  ),
),
next: Icon(Icons.arrow_forward, color: cs.primary),
done: Text(
  'onboarding.get_started'.tr(),
  style: TextStyle(
    color: cs.primary,
    fontWeight: FontWeight.w700,
  ),
),
```

**DotsDecorator**：

```dart
dotsDecorator: DotsDecorator(
  activeColor: cs.primary,
  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
  size: const Size(6, 6),
  activeSize: const Size(24, 6),
  activeShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(3),
  ),
),
```

**Page 4 accent 改用 `cs.tertiary`**（不再 hardcoded `AppColors.amber`）：

```dart
_page(
  serialLabel: '04',
  chipKey: 'onboarding.chip.journey',
  titleKey: 'onboarding.journey.title',
  bodyKey: 'onboarding.journey.body',
  icon: Icons.headphones_rounded,
  accent: cs.tertiary,  // ← was AppColors.amber
  footer: _SampleCtaFooter(onTap: _playSample),
),
```

其他 3 頁的 `accent: AppColors.primary` → `accent: cs.primary`。

**`_page` helper styles**（移除 token-based const 限制，改用 cs）：

```dart
PageViewModel _page({
  required String serialLabel,
  required String chipKey,
  required String titleKey,
  required String bodyKey,
  required IconData icon,
  required Color accent,
  Widget? footer,
}) {
  // 注意：因為 colorScheme 不能 const 取得，這些 style 不再 const
  final cs = Theme.of(context).colorScheme;
  final titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: cs.onSurface,
  );
  final bodyStyle = TextStyle(
    fontSize: 15,
    height: 1.55,
    color: cs.onSurfaceVariant,
  );
  // ... (rest unchanged)
}
```

⚠️ `_page` 是 `_OnboardingWelcomeScreenState` 的 method，可以直接 `Theme.of(context)` 因為 method 在 build 時呼叫。

### 2. `_SampleCtaFooter`

整個改寫成 PillButton：

```dart
class _SampleCtaFooter extends StatelessWidget {
  const _SampleCtaFooter({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillButton(
          label: 'onboarding.try_sample'.tr(),
          icon: Icons.play_arrow_rounded,
          fullWidth: true,
          onPressed: onTap,
        ),
        const SizedBox(height: 12),
        Text(
          'onboarding.try_sample_hint'.tr(),
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
```

⚠️ 失去原本 `padding: EdgeInsets.symmetric(vertical: 16)` 的 customization——`PillButton` 預設 14v。試行接受標準高度。

### 3. `onboarding_page_art.dart`

**`_GhostSerial`**：

```dart
class _GhostSerial extends StatelessWidget {
  const _GhostSerial({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -28,
      left: -12,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 220,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -8,
          color: AppColors.surfaceVariant,  // ← was Color(0x14FFFFFF)
        ),
      ),
    );
  }
}
```

值相同（`#14FFFFFF` = white@8% = `AppColors.surfaceVariant`），改用 named token 提高可讀性與未來重構彈性。

**`_ChipLabel`**：維持不動。雖然它跟 `StatusChip` 有概念重疊，但這個的 dynamic accent + radius 999 pill + 6px circle dot 是 onboarding 獨有的編輯設計，不該被 StatusChip 五色 enum 限制。

### 4. Imports

`onboarding_welcome_screen.dart`：
- 新增：`import 'package:context_app/shared/widgets/midnight/midnight.dart';`（取得 `PillButton`）
- 移除：`import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';` 的 `midnightKyotoTheme` import（如有，保留 `MidnightKyotoBackdrop` import）

確認方式：`import` 完成後 grep `midnightKyotoTheme` 在這個檔內應該為 0 引用。

`onboarding_page_art.dart`：imports 不動（`AppColors` 已 import）。

## 測試策略

`onboarding_welcome_screen_test.dart`（94 行 / 2 testWidgets）：
- 不預期需要動。測試多半 driver-style 互動（tap "skip" → expect navigation）。
- 若有測試斷言 `Theme.of(context)` 取得特定值或 `find.byType(FilledButton)` 之類，需改 finder。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `MidnightKyotoBackdrop` + 全局 `AmbientBackdrop` 雙層 → 視覺過暗 | 中 | 跑起來看；如果太暗，調整 `MidnightKyotoBackdrop` 的 alpha 或刪 local backdrop |
| `_page` 的 `titleStyle` / `bodyStyle` 不再是 `const` → 微小性能差 | 低 | 接受（這 styles 每幀重建是 trivial cost）|
| 移除 Theme wrap 後 `IntroductionScreen` 套件內可能假設特定 ThemeData | 低 | 套件文件未指明；測試會抓到回歸 |
| `cs.tertiary` (#FFB68C) 與 amber (#F59E0B) 視覺差大 | 低 | 都是暖橘色，`cs.tertiary` 更柔和；MK 設計選擇 |

## 成功指標

1. `onboarding_welcome_screen.dart` 內無 `Theme(...)` wrap、無 `midnightKyotoTheme()` 引用。
2. 所有 `AppColors.text*Dark` 替換為 `cs.onSurface*`。
3. `AppColors.amber` 與 `AppColors.white20` 引用為 0。
4. `Color(0x14FFFFFF)` 在 `onboarding_page_art.dart` 替換為 `AppColors.surfaceVariant`。
5. Sample CTA 是 `PillButton`。
6. 既有 onboarding test 全 pass。
7. 全 suite 維持 390+ pass。
8. **跑起來看**：4 頁編輯感與 brand moment 視覺保留；CTA 按鈕與其他 feature 一致；page 4 accent 從鮮亮 amber 變柔和暖橘。
