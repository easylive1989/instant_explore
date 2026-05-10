# Midnight Kyoto S3-ff-2 — Journey Timeline Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Token-cleanup pass on three journey files (~1357 lines): route every `AppColors.primary` / `AppColors.error` / `Colors.white` (where `Colors.white` is being used as a primary-on contrast) through `colorScheme`, switch the main journey title to `textTheme.displayLarge`, preserve `_FilterChips`/`_ViewModeToggle`/`_CurrentTripBanner` custom designs, keep the quick-guide camera node's distinctive `Color(0xFF2A7AE4)` as design intent.

**Architecture:** Three source files in one commit (they're tightly coupled — `journey_screen` instantiates both timeline entries). Existing tests preserved.

**Tech Stack:** Dart, Flutter, Material 3.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3ff2-journey-timeline-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/journey/presentation/screens/journey_screen.dart`
- `frontend/lib/features/journey/presentation/widgets/timeline_entry.dart`
- `frontend/lib/features/journey/presentation/widgets/quick_guide_timeline_entry.dart`

### Untouched (out of scope)
- `frontend/lib/features/journey/presentation/widgets/journey_sharing_card.dart` (S3-ff-3)
- `frontend/lib/features/journey/presentation/screens/save_success_screen.dart` (done in S3-ff-1)
- All trip / move_to_trip widgets

---

## Task K1: Refactor journey timeline ecosystem

### Step 1: Edit `journey_screen.dart`

- [ ] **a) Title typography**: In `JourneyScreen.build`, find the title `Text` and replace its style:

  Before:
  ```dart
  Text(
    'journey.title'.tr(),
    style: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ),
  ),
  ```

  After:
  ```dart
  Text(
    'journey.title'.tr(),
    style: Theme.of(context).textTheme.displayLarge,
  ),
  ```

- [ ] **b) `_CurrentTripBanner` gradient**: Replace `AppColors.primary` × 2 with `colorScheme.primary`:
  ```dart
  gradient: LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      colorScheme.primary.withValues(alpha: 0.85),
      colorScheme.primary.withValues(alpha: 0.65),
    ],
  ),
  ```

- [ ] **c) `_CurrentTripBanner` flag icon and trip name**:

  Replace `const Icon(Icons.flag_outlined, color: Colors.white, size: 18)` with:
  ```dart
  Icon(Icons.flag_outlined, color: colorScheme.onPrimary, size: 18),
  ```

  Replace `Colors.white` in the trip-name `Text(...)` with `colorScheme.onPrimary`.

  Replace `AdaptiveButton(... foregroundColor: Colors.white ...)` with `colorScheme.onPrimary`.

- [ ] **d) `_FilterChips._buildChip`**: Replace selected colors:

  Before:
  ```dart
  decoration: BoxDecoration(
    color: selected
        ? AppColors.primary
        : colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    label,
    style: TextStyle(
      color: selected ? Colors.white : colorScheme.onSurfaceVariant,
      // ...
    ),
  ),
  ```

  After:
  ```dart
  decoration: BoxDecoration(
    color: selected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    label,
    style: TextStyle(
      color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      // ...
    ),
  ),
  ```

- [ ] **e) `_TripGridView` error**:

  Before:
  ```dart
  error: (error, _) => Center(
    child: Text(
      '${'trip.load_error'.tr()}: $error',
      style: const TextStyle(color: AppColors.error),
    ),
  ),
  ```

  After (note: removes `const` because `Theme.of(context)` isn't const):
  ```dart
  error: (error, _) => Center(
    child: Text(
      '${'trip.load_error'.tr()}: $error',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  ),
  ```

- [ ] **f) `_JourneyList` error** — same change as Step e for the `journey.load_error` Text.

- [ ] **g) Cleanup imports**: After all the edits above, run:
  ```
  cd /Users/paulwu/Documents/Github/instant_explore && grep -n "AppColors" frontend/lib/features/journey/presentation/screens/journey_screen.dart
  ```
  Expected: zero matches. Remove `import 'package:context_app/common/config/app_colors.dart';`.

### Step 2: Edit `timeline_entry.dart`

- [ ] **a) Timeline node**: Replace the 24x24 circle decoration:

  Before:
  ```dart
  Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: colorScheme.surface, width: 3),
      // ... boxShadow unchanged
    ),
    child: Center(
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    ),
  ),
  ```

  After:
  ```dart
  Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: colorScheme.primary,
      shape: BoxShape.circle,
      border: Border.all(color: colorScheme.surface, width: 3),
      // ... boxShadow unchanged
    ),
    child: Center(
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  ),
  ```

  (Inner Container's `BoxDecoration` no longer `const`.)

- [ ] **b) Date label**: Replace `color: AppColors.primary` with `color: colorScheme.primary` and remove `const` from the `TextStyle`:
  ```dart
  Text(
    _formatDateLabel(widget.entry.createdAt).toUpperCase(),
    style: TextStyle(
      color: colorScheme.primary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
  ```

- [ ] **c) SnackBar errors** (× 2 — `_showMoveToTripSheet` and `_showDeleteConfirmDialog`):
  Replace each `backgroundColor: AppColors.error` with `backgroundColor: Theme.of(context).colorScheme.error`.

- [ ] **d) Sharing/deleting spinners** (× 2):
  Replace each `color: AppColors.primary` with `color: colorScheme.primary` (note: `colorScheme` is in scope inside `build`).

- [ ] **e) Cleanup import**: Verify zero `AppColors` matches in this file, then remove the import.

### Step 3: Edit `quick_guide_timeline_entry.dart`

- [ ] **a) SnackBar errors** (× 2 in `_showMoveToTripSheet` and `_showDeleteConfirmDialog`):
  Replace each `backgroundColor: AppColors.error` with `backgroundColor: Theme.of(context).colorScheme.error`.

- [ ] **b) Spinners** (× 2): Replace each `color: AppColors.primary` with `color: colorScheme.primary`. (Verify `colorScheme` is in scope in `build`.)

- [ ] **c) PRESERVE** `Color(0xFF2A7AE4)` (the quick-guide-distinctive node color) and `Colors.white` (camera icon on the solid blue node) — these are intentional design values. Do NOT replace them.

- [ ] **d) Cleanup import**: Verify zero `AppColors` matches, then remove the import.

### Step 4: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/journey/presentation/screens/journey_screen.dart lib/features/journey/presentation/widgets/timeline_entry.dart lib/features/journey/presentation/widgets/quick_guide_timeline_entry.dart
  ```
  Expected: No issues.

- [ ] **Journey tests:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/
  ```
  Expected: all pass.

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test
  ```

### Step 5: Commit

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/features/journey/presentation/screens/journey_screen.dart \
    frontend/lib/features/journey/presentation/widgets/timeline_entry.dart \
    frontend/lib/features/journey/presentation/widgets/quick_guide_timeline_entry.dart && \
  git commit -m "$(cat <<'EOF'
feat(journey): apply Midnight Kyoto polish to timeline ecosystem

Routes every AppColors.primary / AppColors.error / Colors.white-on-
primary through colorScheme across journey_screen, timeline_entry,
and quick_guide_timeline_entry. Title becomes textTheme.displayLarge
to align with explore. _FilterChips and _CurrentTripBanner keep their
custom designs but source colors from theme. Quick-guide camera node's
distinctive Color(0xFF2A7AE4) is preserved as design intent.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Title typography → Step 1a
- ✅ Current trip banner gradient + icons → Steps 1b-c
- ✅ Filter chips → Step 1d
- ✅ Error texts → Steps 1e-f
- ✅ Timeline node → Step 2a
- ✅ Date label → Step 2b
- ✅ SnackBar errors → Steps 2c, 3a
- ✅ Spinners → Steps 2d, 3b
- ✅ Quick-guide design preservation → Step 3c
- ✅ Imports → Steps 1g, 2e, 3d

**Placeholder scan:** None.

**Type consistency:** All `colorScheme` references use the local var declared in each `build` method.
