# Midnight Kyoto S3-d — Settings Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply Midnight Kyoto polish to `settings_screen.dart`: swap the bespoke AppBar for `MidnightAppBar`, route every `AppColors.primary` icon through `cs.primary`, replace the deprecated `AppColors.amber` premium icon with `cs.tertiary`, and align `_SectionHeader` typography with `textTheme.labelMedium`. Keep `_SectionContainer`'s outlined-card design — it serves a different purpose than `GlassCard`.

**Architecture:** Single source file refactor + minimal test adjustments for the AppBar title casing change.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, S2 Midnight Kyoto components.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3d-settings-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/settings/presentation/screens/settings_screen.dart`
- `frontend/test/features/settings/presentation/screens/settings_screen_test.dart` (only if title-find assertions break)

---

## Task G1: Refactor settings_screen

### Step 1: Update imports

In `frontend/lib/features/settings/presentation/screens/settings_screen.dart`:

- [ ] Add `import 'package:context_app/shared/widgets/midnight/midnight.dart';`
- [ ] Remove `import 'package:context_app/common/config/app_colors.dart';` only if all AppColors usages have been replaced (verify with grep at the end). Initially keep it; remove at the cleanup step.

### Step 2: Replace AppBar in `SettingsScreen.build`

Find:

```dart
return Scaffold(
  appBar: AppBar(
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: colorScheme.onSurface.withValues(alpha: 0.1),
        height: 1.0,
      ),
    ),
    title: Text('settings.title'.tr(), style: textTheme.titleLarge),
  ),
  body: ListView(...),
);
```

Replace with:

```dart
return Scaffold(
  appBar: MidnightAppBar(title: Text('settings.title'.tr())),
  body: ListView(...),
);
```

The `textTheme.titleLarge` variable is no longer used by AppBar; verify no other place in this file still uses it. If `textTheme` becomes unused after the refactor, remove the `final textTheme = Theme.of(context).textTheme;` line. If it's still used (e.g., for `bodySmall` in app version display), keep it.

### Step 3: Update `_LanguageTile`

Find the `_LanguageTile.build` body. Add `final cs = Theme.of(context).colorScheme;` near the top, then change:

```dart
return _SettingsTile(
  icon: Icons.language,
  iconColor: AppColors.primary,
  iconBgColor: AppColors.primary.withValues(alpha: 0.2),
  // ...
);
```

To:

```dart
return _SettingsTile(
  icon: Icons.language,
  iconColor: cs.primary,
  iconBgColor: cs.primary.withValues(alpha: 0.2),
  // ...
);
```

The trailing `Text` and `Icon` already use `Theme.of(context).colorScheme.onSurfaceVariant` — no change needed there.

### Step 4: Update `_OnboardingSection`

Find the `_SettingsTile(...)` call in `_OnboardingSection.build`. Replace `AppColors.primary` with `colorScheme.primary` (the existing `colorScheme` variable already on line 209 of the original file):

```dart
_SettingsTile(
  icon: Icons.school_outlined,
  iconColor: colorScheme.primary,
  iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
  // ...
)
```

### Step 5: Update `_SubscriptionSection`

Two `_SettingsTile` calls — both need `AppColors.X` → `colorScheme.X` replacement.

Premium variant:
```dart
_SettingsTile(
  icon: Icons.workspace_premium,
  iconColor: colorScheme.tertiary,                          // ← was AppColors.amber
  iconBgColor: colorScheme.tertiary.withValues(alpha: 0.2), // ← was AppColors.amber
  // ...
)
```

Upgrade variant:
```dart
_SettingsTile(
  icon: Icons.workspace_premium,
  iconColor: colorScheme.primary,
  iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
  // ...
)
```

### Step 6: Update `_UsageSection`

Three `_SettingsTile` calls (data / error path). Replace `AppColors.primary` with `colorScheme.primary` in all of them.

### Step 7: Update `_SectionHeader` typography

Find:

```dart
return Padding(
  padding: const EdgeInsets.only(left: 4.0),
  child: Text(
    title.toUpperCase(),
    style: TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
  ),
);
```

Replace with:

```dart
return Padding(
  padding: const EdgeInsets.only(left: 4),
  child: Text(
    title.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      letterSpacing: 1.0,
    ),
  ),
);
```

Drop `final colorScheme = Theme.of(context).colorScheme;` from `_SectionHeader.build` if it becomes unused after this change.

### Step 8: Cleanup unused imports

After all the steps above, run:

```
cd /Users/paulwu/Documents/PLRepo/instant_explore && grep -n "AppColors" frontend/lib/features/settings/presentation/screens/settings_screen.dart
```

If the grep returns nothing, remove `import 'package:context_app/common/config/app_colors.dart';` from the import block. If anything remains (it shouldn't), inspect.

### Step 9: Update `settings_screen_test.dart` if needed

Read the test file. The title `'settings.title'.tr()` was previously rendered as raw text (since easy_localization in tests returns the key); under `MidnightAppBar` it gets uppercased before display.

If a test asserts `find.text('settings.title')`, it needs to become:
- Either `find.text('SETTINGS.TITLE')` (matches the rendered uppercase), or
- `find.byType(MidnightAppBar)` (more durable — independent of the casing rule).

Choose the casing approach if a single test breaks; choose `byType` if multiple do.

If the tests don't exercise the title at all, no test edits are needed.

### Step 10: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/screens/settings_screen_test.dart
  ```

- [ ] **Settings tests:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test test/features/settings/
  ```

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test
  ```

### Step 11: Commit

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/features/settings/presentation/screens/settings_screen.dart \
    frontend/test/features/settings/presentation/screens/settings_screen_test.dart && \
  git commit -m "$(cat <<'EOF'
feat(settings): apply Midnight Kyoto polish to SettingsScreen

Switches the AppBar to MidnightAppBar (uppercase title), routes every
AppColors.primary through cs.primary, swaps the deprecated AppColors.amber
premium icon to cs.tertiary, and aligns _SectionHeader typography with
textTheme.labelMedium. _SectionContainer keeps its outlined-card design
to remain visually distinct from GlassCard's translucent variant.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ AppBar → Step 2
- ✅ `_SectionHeader` typography → Step 7
- ✅ `_LanguageTile` tokens → Step 3
- ✅ `_OnboardingSection` tokens → Step 4
- ✅ `_SubscriptionSection` premium amber → tertiary → Step 5
- ✅ `_UsageSection` tokens → Step 6
- ✅ Test minimal-touch → Step 9

**Placeholder scan:** None.

**Type consistency:** `_SectionHeader` no longer uses `colorScheme` after Step 7 — drop the local var if unused.
