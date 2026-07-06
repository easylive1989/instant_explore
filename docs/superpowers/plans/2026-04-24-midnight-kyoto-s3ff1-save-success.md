# Midnight Kyoto S3-ff-1 — Save Success Screen Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up `save_success_screen.dart`: route both CTAs through `PillButton`, drop the `successColor` const alias, and un-deprecate `AppColors.success` (which carries genuine semantic meaning vs the MK brand palette).

**Architecture:** Two file edits + one targeted token un-deprecation. One commit. No tests for this screen, but pre-commit hook runs full suite.

**Tech Stack:** Dart, Flutter, Material 3, S2 PillButton.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3ff1-save-success-design.md`

---

## File Structure

### Modified
- `frontend/lib/common/config/app_colors.dart` (un-deprecate `success`)
- `frontend/lib/features/journey/presentation/screens/save_success_screen.dart`

### Untouched (out of scope)
- All other journey/ files (S3-ff-2, S3-ff-3)

---

## Task J1: Save success cleanup

### Step 1: Un-deprecate `AppColors.success`

In `frontend/lib/common/config/app_colors.dart`, find:

```dart
@Deprecated('Use a tertiary or new token; will be removed in S3.')
static const Color success = Color(0xFF10B981);
```

Replace with:

```dart
/// Success green for confirmation states.
///
/// Distinct from MK's primary blue and tertiary orange — semantic
/// "success" colour for save / completion confirmations.
static const Color success = Color(0xFF10B981);
```

⚠️ Leave `AppColors.amber` and `AppColors.errorBg` deprecation markers in place.

### Step 2: Refactor `save_success_screen.dart`

- [ ] **a) Imports**: Add `import 'package:context_app/shared/widgets/midnight/midnight.dart';`. Verify `AdaptiveIconButton` (used by close button) still requires `adaptive_widgets.dart` — it does — so keep that import.

- [ ] **b) Remove `const successColor` alias**: In `build`, remove the line `const successColor = AppColors.success;`. Inline `AppColors.success` directly in the three Container decorations and the icon shadow.

- [ ] **c) Replace primary CTA**:

  Find:
  ```dart
  AdaptiveButton(
    expanded: true,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 18),
    onPressed: onViewJourney,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'journey.view_button'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward, size: 20),
      ],
    ),
  ),
  ```

  Replace with:
  ```dart
  PillButton(
    label: 'journey.view_button'.tr(),
    icon: Icons.arrow_forward,
    fullWidth: true,
    onPressed: onViewJourney,
  ),
  ```

- [ ] **d) Replace secondary CTA**:

  Find:
  ```dart
  AdaptiveButton(
    expanded: true,
    style: AdaptiveButtonStyle.text,
    backgroundColor: colorScheme.surfaceContainerHigh,
    foregroundColor: colorScheme.onSurface,
    padding: const EdgeInsets.symmetric(vertical: 18),
    onPressed: onContinueTour ?? () => context.pop(),
    child: Text(
      'journey.continue_tour'.tr(),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  ```

  Replace with:
  ```dart
  PillButton(
    label: 'journey.continue_tour'.tr(),
    variant: PillButtonVariant.secondary,
    fullWidth: true,
    onPressed: onContinueTour ?? () => context.pop(),
  ),
  ```

- [ ] **e) Verify `colorScheme` is still used**: After the CTA replacements, `colorScheme` is still referenced by AppBar, the preview card, and the placeholder icon. Don't remove the local var.

### Step 3: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/journey/presentation/screens/save_success_screen.dart lib/common/config/app_colors.dart
  ```
  Expected: No issues.

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

- [ ] **Total deprecation count:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze 2>&1 | grep "issues found"
  ```
  Expected: 6 issues (down from 7 — un-deprecating `success` removed the warning at this call site).

### Step 4: Commit

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/common/config/app_colors.dart \
    frontend/lib/features/journey/presentation/screens/save_success_screen.dart && \
  git commit -m "$(cat <<'EOF'
feat(journey): apply Midnight Kyoto polish to save success screen

Routes both CTAs through PillButton (primary + secondary), drops the
successColor alias, and un-deprecates AppColors.success — the
confirmation green carries genuine semantic meaning that doesn't map
cleanly to MK's brand palette (primary blue / tertiary orange).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ AppColors.success un-deprecated → Step 1
- ✅ successColor alias removed → Step 2b
- ✅ Primary CTA via PillButton → Step 2c
- ✅ Secondary CTA via PillButton.secondary → Step 2d

**Placeholder scan:** None.

**Type consistency:** `PillButton.fullWidth` parameter is `bool`; both call sites pass `true`.
