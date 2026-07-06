# Midnight Kyoto S3-e — Subscription Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the paywall (`subscription_screen.dart` + `subscription_plan_card.dart`) to drop deprecated `AppColors` tokens, simplify `_SubscribeButton` so it inherits S1's `filledButtonTheme`, remove the redundant local `Theme(midnightKyotoTheme())` wrap, and delete the now-orphan `midnightKyotoTheme()` helper.

**Architecture:** Two source files plus the shared backdrop helper. One commit. Existing tests preserved with at most a couple of finder updates.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3e-subscription-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`
- `frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`
- `frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart` (delete `midnightKyotoTheme()` function)
- `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart` (only if assertions break)
- `frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart` (only if assertions break)

---

## Task H1: Refactor subscription paywall

### Step 1: Update imports in `subscription_screen.dart`

Add `import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';` already present (used for `MidnightKyotoBackdrop`). Confirm it stays. The file imports `AppColors` from `app_colors.dart` — keep until you've removed every reference, then evaluate at the end.

### Step 2: Replace `SubscriptionScreen.build`

In `_SubscriptionScreenState.build`, find the existing return statement (begins `return Theme(...)`). Replace the `Theme` wrapper:

Before:
```dart
return Theme(
  data: midnightKyotoTheme(),
  child: Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: MidnightKyotoBackdrop(
      child: SafeArea(
        // ...
      ),
    ),
  ),
);
```

After:
```dart
final cs = Theme.of(context).colorScheme;
return Scaffold(
  backgroundColor: AppColors.backgroundDark,
  body: MidnightKyotoBackdrop(
    child: SafeArea(
      // ...
    ),
  ),
);
```

(`final cs` declared once at the top of `build`.)

### Step 3: Replace inline icon / text colors in build

In the same method, replace:

```dart
icon: const Icon(Icons.close, color: AppColors.textPrimaryDark)
```
with
```dart
icon: Icon(Icons.close, color: cs.onSurface)
```

Replace the category-label `Text(... color: AppColors.textSecondaryDark)`:
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

Replace the headline `Text` style:
```dart
TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
  color: cs.onSurface,
  height: 1.2,
)
```

Replace the subheadline `Text` style:
```dart
TextStyle(
  fontSize: 15,
  height: 1.55,
  color: cs.onSurfaceVariant,
)
```

Replace the restore button:
```dart
AdaptiveButton(
  style: AdaptiveButtonStyle.text,
  foregroundColor: cs.onSurfaceVariant,
  onPressed: _isPurchasing ? null : _restore,
  child: Text(
    'subscription.restore'.tr(),
    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
  ),
),
```

### Step 4: Replace SnackBar `backgroundColor: AppColors.error` (3 places)

Three SnackBar usages in `_purchase`, `_restore`, `_openUrl` use `backgroundColor: AppColors.error`. Each needs to read `Theme.of(context).colorScheme.error`. Since these methods are inside `_SubscriptionScreenState` and have access to `context`, change:

```dart
backgroundColor: AppColors.error,
```

to:

```dart
backgroundColor: Theme.of(context).colorScheme.error,
```

### Step 5: Refactor `_PremiumIcon`

Replace the entire `_PremiumIcon` class with:

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

### Step 6: Refactor `_SubscribeButton`

Replace the entire `_SubscribeButton` class with:

```dart
class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.lock_open_rounded),
        label: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Text('subscription.subscribe'.tr()),
      ),
    );
  }
}
```

(Removed: `backgroundColor`, `foregroundColor`, `disabledBackgroundColor`, `disabledForegroundColor`, `shape: StadiumBorder()` — all inherited from `filledButtonTheme`.)

### Step 7: Refactor `_LegalFooter`

Replace the entire `_LegalFooter` class with:

```dart
class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpen});

  final Future<void> Function(Uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant.withValues(alpha: 0.7);
    final linkStyle = TextStyle(
      fontSize: 12,
      color: muted,
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
            style: TextStyle(fontSize: 12, color: muted),
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

### Step 8: Refactor `subscription_plan_card.dart` external container

In `SubscriptionPlanCard.build`, replace the `Container.decoration` block:

Before:
```dart
decoration: BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceDarkCard, AppColors.surfaceDark],
  ),
  border: Border.all(color: AppColors.glassBorder),
  borderRadius: BorderRadius.circular(24),
  boxShadow: const [
    BoxShadow(
      color: Color(0x14137FEC),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ],
),
```

After:
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Theme.of(context).colorScheme.surfaceContainerHigh,
      Theme.of(context).colorScheme.surfaceContainer,
    ],
  ),
  border: Border.all(
    color: Theme.of(context).colorScheme.outlineVariant,
  ),
  borderRadius: BorderRadius.circular(24),
  boxShadow: const [
    BoxShadow(
      color: Color(0x14137FEC),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ],
),
```

(Brand glow shadow stays as a hardcoded primary @ 8% — intentional design value.)

### Step 9: Refactor `_SkeletonBar`

Replace the entire `_SkeletonBar` class:

```dart
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
```

### Step 10: Refactor `_Error`

Replace `_Error.build` body internals:

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        message,
        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: const ValueKey('planCard.retry'),
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Retry',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );
}
```

### Step 11: Refactor `_Ready`

Replace the entire `_Ready` class with:

```dart
class _Ready extends StatelessWidget {
  const _Ready({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;

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
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceString,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._priceFontSize,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              periodLabel,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._periodFontSize,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 16),
        ...bullets.map((b) => _bulletRow(b, cs)),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 12),
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
            style: TextStyle(fontSize: 14, color: cs.primary, height: 1.4),
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
}
```

### Step 12: Refactor `_Divider`

Replace `_Divider`:

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

### Step 13: Cleanup `subscription_plan_card.dart` imports

After all the steps in `subscription_plan_card.dart`, run:

```
cd /Users/paulwu/Documents/PLRepo/instant_explore && grep -n "AppColors" frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart
```

Should return nothing. Remove `import 'package:context_app/common/config/app_colors.dart';` from the file.

### Step 14: Cleanup `subscription_screen.dart` imports

Same grep on `subscription_screen.dart`. The file likely still uses `AppColors.backgroundDark` for the Scaffold (kept intentionally). If that's the only remaining reference, leave the import.

### Step 15: Delete `midnightKyotoTheme()` helper

In `frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart`, delete the entire `midnightKyotoTheme()` function (lines 32-46 of the original file). Keep the `MidnightKyotoBackdrop` widget class.

After deletion, verify no remaining usage:

```
cd /Users/paulwu/Documents/PLRepo/instant_explore && grep -rn "midnightKyotoTheme" frontend/
```

Expected: zero matches.

### Step 16: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/subscription/presentation/ lib/shared/widgets/midnight_kyoto_backdrop.dart test/features/subscription/
  ```
  Expected: No issues.

- [ ] **Subscription tests:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test test/features/subscription/
  ```
  Expected: all pass. If a test asserts `find.byType(Theme)` or specific styles, fix with minimum-touch finders.

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

### Step 17: Commit

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/features/subscription/presentation/screens/subscription_screen.dart \
    frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart \
    frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart \
    frontend/test/features/subscription/ && \
  git commit -m "$(cat <<'EOF'
feat(subscription): apply Midnight Kyoto polish to paywall

Drops the redundant local Theme(midnightKyotoTheme()) wrap (S1's
global MK theme is now the single source of truth). Replaces
deprecated AppColors text/surfaceDarkCard/glassBorder/white10 tokens
with colorScheme equivalents. Plan card keeps its bespoke gradient
(now sourced from surfaceContainerHigh → surfaceContainer) and brand
glow shadow. _SubscribeButton inherits filledButtonTheme; only the
custom 18px text size remains as a local override.

Removes the now-orphan midnightKyotoTheme() helper; MidnightKyoto-
Backdrop widget is preserved for brand-moment punch-ups.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Theme wrap removed → Step 2
- ✅ Subscribe button simplified → Step 6
- ✅ Premium icon tokens → Step 5
- ✅ Legal footer tokens → Step 7
- ✅ Plan card gradient + border → Step 8
- ✅ Skeleton bar → Step 9
- ✅ Error retry → Step 10
- ✅ Ready typography → Step 11
- ✅ Divider → Step 12
- ✅ midnightKyotoTheme deleted → Step 15

**Placeholder scan:** None.

**Type consistency:** `_bulletRow` signature changed to `(String, ColorScheme)`; verify the call site.
