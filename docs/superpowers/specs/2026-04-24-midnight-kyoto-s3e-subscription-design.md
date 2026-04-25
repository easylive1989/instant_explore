# Midnight Kyoto S3-e — Subscription / Paywall 設計文件

- 日期：2026-04-24
- Sprint：S3-e（S3 第六個 mini-sprint）
- 範圍：
  - `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`（415 行）
  - `frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`（311 行）
  - `frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart`（清理 `midnightKyotoTheme()` helper）

## 背景與目標

Subscription/paywall 是 brand-moment 的另一個 hero——跟 onboarding 並列為 MK 編輯感最該到位的螢幕之一。它已經有部分 MK 化（自畫 glass card、`MidnightKyotoBackdrop`、`midnightKyotoTheme()` helper），但充滿 deprecated `AppColors.text*Dark` / `AppColors.surfaceDarkCard` 等舊 token。

S3-e 做三件事：
1. **清理 deprecated tokens**：把所有 `AppColors.X` 換成 `colorScheme.X`
2. **簡化結構**：移除多餘的 `Theme(midnightKyotoTheme())` wrap、原生繼承 S1 的 filled-button theme 把局部 override 變成可自動繼承
3. **連帶清理** `midnightKyotoTheme()` helper——subscription 是最後一個 consumer，可以正式刪除

## 影響範圍

| Widget | 角色 | 動作 |
|---|---|---|
| `SubscriptionScreen` | 主 Scaffold + 進場動畫 + 購買流程 | 中（drop Theme wrap、token 替換）|
| `_PremiumIcon` | 120x120 hero icon | 小（token） |
| `_SubscribeButton` | CTA 按鈕（loading 狀態）| 中（簡化 style 繼承 theme）|
| `_LegalFooter` | terms / privacy 連結 | 小（token） |
| `SubscriptionPlanCard` | 容器（loading/error/ready）| 中（gradient token）|
| `_Loading` / `_SkeletonBar` | skeleton 占位 | 小（token） |
| `_Error` | 錯誤狀態 + retry | 小（token） |
| `_Ready` | 價格 + 福利清單 + 法律提示 | 中（typography token） |
| `_Divider` | 分隔線 | 小（token） |
| `midnightKyotoTheme()` helper | 已過時 | **刪除** |

測試：
- `subscription_screen_test.dart`（220 行）
- `subscription_plan_card_test.dart`（119 行）

## 已決策事項

| 議題 | 決定 |
|---|---|
| `Theme(midnightKyotoTheme())` wrap | **刪除** |
| `MidnightKyotoBackdrop` | **保留**（brand-moment punch-up）|
| `Scaffold(backgroundColor: AppColors.backgroundDark)` | **保留**（讓 brand-moment backdrop 有底色）|
| `_SubscribeButton` 改 `PillButton`? | **不改**——loading state（spinner ↔ icon 切換）`PillButton` API 不支援；保留 `FilledButton.icon` 但**移除局部 style override**，讓 S1 的 `filledButtonTheme` 自動套上 StadiumBorder + primary 色 |
| `SubscriptionPlanCard` 改 `GlassCard`? | **不改**——卡片 gradient + 藍色 glow shadow 是品牌設計，跟 `GlassCard` 的 BackdropFilter 玻璃感不同。保留 custom container 但用 token 重塗 |
| `surfaceDarkCard → surfaceDark` 漸層 | 改 `surfaceContainerHigh → surfaceContainer`（從 deprecated 別名換到正式 M3 token）|
| `glassBorder` / `white10` | 改 `colorScheme.outlineVariant` |
| `AppColors.text*Dark` | 全替換成 `colorScheme.onSurface` / `cs.onSurfaceVariant`（依語意）|
| `_PremiumIcon` 設計 | 保留 RadialGradient + 圓角方塊 icon——很 MK，僅 token 化 |
| `_LegalFooter` 連結樣式 | 保留 GestureDetector + underline Text（簡單可讀）|
| `midnightKyotoTheme()` helper | **刪除**——subscription 是最後 consumer，全 app 已自動是 MK 主題 |

## 不在 S3-e 範圍

- ❌ Subscription controllers / providers / service 邏輯
- ❌ RevenueCat 整合
- ❌ Watch ad dialog（在 ads feature）
- ❌ 翻譯字串

## 設計細節

### 1. `SubscriptionScreen.build`

**移除 `Theme(midnightKyotoTheme())` wrap**：

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: MidnightKyotoBackdrop(
      child: SafeArea(
        child: Column(
          // ...
        ),
      ),
    ),
  );
}
```

**Close button icon**：

```dart
AdaptiveIconButton(
  icon: Icon(Icons.close, color: cs.onSurface),
  onPressed: () => Navigator.of(context).pop(),
),
```

**Category label**（11px uppercase tracking）：

```dart
Text(
  'subscription.category_label'.tr(),
  style: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    color: cs.onSurfaceVariant,
  ),
  textAlign: TextAlign.center,
),
```

**Headline / subheadline**：

```dart
// Headline (30/w800/-0.5)
Text(
  'subscription.headline'.tr(),
  style: TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: cs.onSurface,
    height: 1.2,
  ),
  textAlign: TextAlign.center,
),

// Subheadline (15/h1.55)
Text(
  'subscription.subheadline'.tr(),
  style: TextStyle(
    fontSize: 15,
    height: 1.55,
    color: cs.onSurfaceVariant,
  ),
  textAlign: TextAlign.center,
),
```

⚠️ Headline 30/w800 跟 MK 的 `displayMedium`(28/w800) 接近但 size 是設計值；維持 hardcoded。同樣 15/h1.55 的 subheadline 是設計值。

**Restore button**：

```dart
AdaptiveButton(
  style: AdaptiveButtonStyle.text,
  foregroundColor: cs.onSurfaceVariant,
  onPressed: _isPurchasing ? null : _restore,
  child: Text(
    'subscription.restore'.tr(),
    style: TextStyle(
      fontSize: 14,
      color: cs.onSurfaceVariant,
    ),
  ),
),
```

**SnackBar `backgroundColor: AppColors.error`** → `cs.error`（3 處）。

### 2. `_PremiumIcon`

```dart
class _PremiumIcon extends StatelessWidget {
  const _PremiumIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.25),
                  cs.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 40,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

⚠️ 改成 `Container(width: 120, height: 120)` 改 `DecoratedBox` 因為 SizedBox 已限定大小，`DecoratedBox` 更輕。

### 3. `_SubscribeButton`

**簡化**——刪除多餘的 styleFrom override（已被 S1 `filledButtonTheme` 覆蓋）：

```dart
class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.lock_open_rounded),
        label: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(strokeWidth: 2),
              )
            : Text('subscription.subscribe'.tr()),
      ),
    );
  }
}
```

⚠️ 移除：
- `backgroundColor: AppColors.primary` ← S1 theme 已設
- `foregroundColor: Colors.white` ← S1 theme 已設
- `disabledBackgroundColor` / `disabledForegroundColor` ← FilledButton 自動處理
- `shape: StadiumBorder()` ← S1 `filledButtonTheme` 已設
- spinner 的 `color: Colors.white` ← `AdaptiveProgressIndicator` 預設用 primary，但因為按鈕是 primary 底，spinner 用白色才對比清楚——**這個保留**讓 progress indicator 可見

修正：保留 spinner 的 `color`（但用 `Theme.of(context).colorScheme.onPrimary` 取代 `Colors.white`）。

### 4. `_LegalFooter`

```dart
class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpen});

  final Future<void> Function(Uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final linkStyle = TextStyle(
      fontSize: 12,
      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      decoration: TextDecoration.underline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.termsOfUse)),
          child: Text('subscription.terms'.tr(), style: linkStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '·',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.privacyPolicy)),
          child: Text('subscription.privacy'.tr(), style: linkStyle),
        ),
      ],
    );
  }
}
```

⚠️ `linkStyle` 不再 `const`（含 `cs.onSurfaceVariant`）。Padding 內 Text 也改非 `const`。

### 5. `SubscriptionPlanCard`

**外層 Container 重塗**：

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Theme.of(context).colorScheme.surfaceContainerHigh,
        Theme.of(context).colorScheme.surfaceContainer,
      ],
    ),
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14137FEC),  // primary @ 8% — brand glow shadow，保留
        blurRadius: 40,
        offset: Offset(0, 12),
      ),
    ],
  ),
  // ...
)
```

⚠️ 漸層從 `surfaceDarkCard` (#1C2732) → `surfaceDark` (#1C2630) 改為 `surfaceContainerHigh` (#27313C) → `surfaceContainer` (#1C2630)——稍微更亮的卡頂、和原本一致的卡底。視覺效果接近，token 化乾淨。

⚠️ Brand glow shadow `Color(0x14137FEC)` 保留（這是 primary @ 8%，是設計刻意值，跟 token 沒有 1:1 mapping）。

### 6. `_Loading` / `_SkeletonBar`

```dart
class _SkeletonBar extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,  // ← was AppColors.white10
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
```

⚠️ Container → DecoratedBox + SizedBox（perf 微優）。

### 7. `_Error`

```dart
Text(
  message,
  style: TextStyle(
    fontSize: 14,
    color: Theme.of(context).colorScheme.onSurfaceVariant,  // ← was AppColors.textSecondaryDark
  ),
),
// ...
TextButton(
  // ...
  style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.primary,  // ← was AppColors.primary
    padding: EdgeInsets.zero,
    minimumSize: const Size(0, 32),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
  // ...
),
```

### 8. `_Ready`

每個 Text style 從 `AppColors.X` 改 `colorScheme.X`：

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        planLabel,
        style: TextStyle(
          fontSize: SubscriptionPlanCard._planLabelFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant,  // ← was textTertiaryDark
        ),
      ),
      // ...
      Text(
        priceString,
        style: TextStyle(
          fontSize: SubscriptionPlanCard._priceFontSize,
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
          height: 1,
        ),
      ),
      // ...
      Text(
        periodLabel,
        style: TextStyle(
          fontSize: SubscriptionPlanCard._periodFontSize,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
      // ...
      Text(
        autoRenewNotice,
        style: TextStyle(
          fontSize: SubscriptionPlanCard._noticeFontSize,
          color: cs.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    ],
  );
}

Widget _bulletRow(String text, ColorScheme cs) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✦',
          style: TextStyle(
            fontSize: 14,
            color: cs.primary,
            height: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: SubscriptionPlanCard._bulletFontSize,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
```

⚠️ `_bulletRow` 簽名改成 `(String text, ColorScheme cs)`。

### 9. `_Divider`

```dart
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: const SizedBox(height: 1),
    );
  }
}
```

### 10. `midnightKyotoTheme()` 刪除

`frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart`：

刪除 `midnightKyotoTheme()` function（line 32-46）。**保留** `MidnightKyotoBackdrop` widget 與其 doc。檔案結尾的 trailing function 移除。

驗證沒有 consumer：

```
cd /Users/paulwu/Documents/Github/instant_explore && grep -rn "midnightKyotoTheme" frontend/
```

預期僅出現在 `midnight_kyoto_backdrop.dart` 自身（被刪除前）。S3-e 此次 commit 後應該為 0。

## 測試策略

`subscription_screen_test.dart`（220 行）：
- 主要驗證購買流程、loading state、SnackBar 出現等行為——應大部分通過
- 若有測試斷言 `Theme.of(context).colorScheme.primary` 是特定值或 `find.byType(Theme)` 之類，可能需動

`subscription_plan_card_test.dart`（119 行）：
- 驗證 loading skeleton、error retry、ready 內容
- 預期不需動（用 ValueKey 找元素）

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| 移除 `Theme(midnightKyotoTheme())` 後與 onboarding 不對等（onboarding 已移除） | 低 | 兩個 brand moment 對等了 |
| `surfaceContainerHigh` 卡頂顏色 (#27313C) 比原本 `surfaceDarkCard` (#1C2732) 亮 ~10pp | 中 | 視覺微亮但仍是深色；如果 designer 不滿可改 `surfaceBright` |
| `_SubscribeButton` 失去 `disabledBackgroundColor` 自訂 | 低 | FilledButton 預設 disabled 邏輯（自動降透明度）通常更標準 |
| brand glow shadow `Color(0x14137FEC)` 看似 hardcoded | 低 | 跟其他 hardcoded brand glow 一致；token 化會讓設計失去精準度 |
| Test 對 spinner color 等做斷言 | 中 | 跑測試確認；最小修改 |

## 成功指標

1. `subscription_screen.dart` 與 `subscription_plan_card.dart` 內 `AppColors.text*Dark` / `surfaceDarkCard` / `glassBorder` / `white10` 引用為 0。
2. `Theme(midnightKyotoTheme())` 不再使用，helper 已從 `midnight_kyoto_backdrop.dart` 刪除。
3. `MidnightKyotoBackdrop` 仍存在（brand-moment punch-up）。
4. 全 `flutter analyze --fatal-infos` 顯示之前 33 個 deprecation infos 應降至 ~25 以下（這個 PR 把 subscription_plan_card 的 7 個 textPrimaryDark/textSecondaryDark/textTertiaryDark 引用清光）。
5. 全 suite 維持 390+ pass。
6. **跑起來看**：paywall 視覺與 onboarding 一致（brand-moment）；plan card 仍有玻璃感與藍色 glow shadow；subscribe 按鈕變圓 stadium、保留 56px 高度與 loading 狀態。
