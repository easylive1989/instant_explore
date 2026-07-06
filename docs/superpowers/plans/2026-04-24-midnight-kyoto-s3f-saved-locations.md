# Midnight Kyoto S3-f — Saved Locations Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Minimal token-cleanup pass on saved_locations: drop the redundant `FloatingActionButton.backgroundColor` override, route 4 hardcoded color references through `colorScheme`, remove `AppColors` imports.

**Architecture:** Two source files + their existing tests. One commit. Morph animation preserved.

**Tech Stack:** Dart, Flutter, Material 3.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3f-saved-locations-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/saved_locations/presentation/widgets/saved_locations_fab.dart`
- `frontend/lib/features/saved_locations/presentation/widgets/saved_locations_dialog.dart`

### Untouched (out of scope)
- `frontend/lib/features/journey/` (S3-ff)

---

## Task I1: Refactor saved_locations widgets

### Step 1: Edit `saved_locations_fab.dart`

- [ ] **a) FAB build** — remove `backgroundColor: AppColors.primary` line and route the icon color through `colorScheme.onPrimary`:

  Find:
  ```dart
  child: FloatingActionButton(
    heroTag: 'saved_locations_fab',
    shape: const CircleBorder(),
    onPressed: () { /* ... */ },
    backgroundColor: AppColors.primary,
    child: Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      child: const Icon(Icons.bookmark, color: Colors.white),
    ),
  ),
  ```

  Replace with:
  ```dart
  child: FloatingActionButton(
    heroTag: 'saved_locations_fab',
    shape: const CircleBorder(),
    onPressed: () { /* ... */ },
    child: Badge(
      isLabelVisible: count > 0,
      label: const Text('$count', style: TextStyle(fontSize: 10)),
      child: Icon(
        Icons.bookmark,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  ),
  ```

  Wait — `count` interpolation means the `Text(...)` cannot be `const`. Keep the existing `Text('$count', ...)`. Just change the inner Icon. Final form:
  ```dart
  child: FloatingActionButton(
    heroTag: 'saved_locations_fab',
    shape: const CircleBorder(),
    onPressed: () { /* unchanged inner body */ },
    child: Badge(
      isLabelVisible: count > 0,
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      child: Icon(
        Icons.bookmark,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  ),
  ```

- [ ] **b) `_SavedLocationsRoute.transitionsBuilder`** — replace two color references:

  Find:
  ```dart
  final colorTween = ColorTween(
    begin: AppColors.primary,
    end: colorScheme.surface,
  );
  ```

  Replace with:
  ```dart
  final colorTween = ColorTween(
    begin: Theme.of(context).colorScheme.primary,
    end: colorScheme.surface,
  );
  ```

  And find the FAB icon inside the morph:
  ```dart
  child: const Icon(
    Icons.bookmark,
    color: Colors.white,
    size: 24,
  ),
  ```

  Replace with:
  ```dart
  child: Icon(
    Icons.bookmark,
    color: Theme.of(context).colorScheme.onPrimary,
    size: 24,
  ),
  ```

- [ ] **c) Remove import** — after the edits, run:
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore && grep -n "AppColors" frontend/lib/features/saved_locations/presentation/widgets/saved_locations_fab.dart
  ```
  Expected: zero matches. Then remove `import 'package:context_app/common/config/app_colors.dart';`.

### Step 2: Edit `saved_locations_dialog.dart`

- [ ] **a) `_DialogHeader.build`** — replace bookmark icon color:

  Find:
  ```dart
  const Icon(Icons.bookmark, color: AppColors.primary, size: 24),
  ```

  Replace with:
  ```dart
  Icon(Icons.bookmark, color: colorScheme.primary, size: 24),
  ```

  (`colorScheme` is already in scope via the constructor parameter.)

- [ ] **b) Remove import** — after the edit, run:
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore && grep -n "AppColors" frontend/lib/features/saved_locations/presentation/widgets/saved_locations_dialog.dart
  ```
  Expected: zero matches. Then remove `import 'package:context_app/common/config/app_colors.dart';`.

### Step 3: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/saved_locations/presentation/widgets/ test/features/saved_locations/presentation/widgets/
  ```
  Expected: No issues.

- [ ] **Saved locations tests:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test test/features/saved_locations/
  ```
  Expected: all pass.

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

### Step 4: Commit

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/features/saved_locations/presentation/widgets/ && \
  git commit -m "$(cat <<'EOF'
feat(saved-locations): route hardcoded colors through colorScheme

Drops the redundant FloatingActionButton.backgroundColor override (S1's
floatingActionButtonTheme already provides AppColors.primary). Routes
the FAB icon, the morph route's color tween, the morph FAB-icon overlay,
and the dialog header's bookmark icon through colorScheme. Removes
AppColors imports from both widgets.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ FAB backgroundColor override removed → Step 1a
- ✅ FAB child Icon color → Step 1a
- ✅ Morph route ColorTween begin → Step 1b
- ✅ Morph FAB icon → Step 1b
- ✅ Dialog header bookmark icon → Step 2a
- ✅ AppColors imports removed → Steps 1c, 2b

**Placeholder scan:** None.

**Type consistency:** All `Theme.of(context)` calls have valid `BuildContext` in scope (transitionsBuilder receives `context`, build methods receive `context`).
