# Midnight Kyoto S3-a — Explore Screen Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `explore_screen.dart` (479 lines, 4 widgets) to use Midnight Kyoto components from S2 (`GlassCard`, `PillButton`, `PillIconButton`, `PressScale`) while keeping per-category dynamic chip colors and minimal-touch updates to the existing 11 widget tests.

**Architecture:** Single source file refactor + same-file test updates committed together. No new files created. `_ActiveDot` is a small private widget local to `_FilterButton` for the filter-active indicator (replaces the previous `Badge`).

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, S2 Midnight Kyoto components, mocktail-style fakes (existing).

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3a-explore-screen-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/explore/presentation/screens/explore_screen.dart`
- `frontend/test/features/explore/presentation/screens/explore_screen_test.dart`

### Untouched (out of scope)
- `frontend/lib/features/saved_locations/presentation/widgets/saved_locations_fab.dart`
- `frontend/lib/shared/extensions/place_category_extension.dart`

---

## Task C1: Refactor `explore_screen.dart` + update tests

**Files:**
- Modify: `frontend/lib/features/explore/presentation/screens/explore_screen.dart`
- Modify: `frontend/test/features/explore/presentation/screens/explore_screen_test.dart`

This task ships the entire screen refactor in one commit. The structure is:
1. Update imports (add midnight barrel + direct PressScale import; remove AppColors if no longer used by widget code).
2. Apply changes to each of the 5 widgets in the file (`ExploreScreen`, `_FilterButton`, `_FilterPanel`, `PlaceCard`, `_BookmarkButton`).
3. Update the 2 filter-badge tests in `explore_screen_test.dart` to read the new `_ActiveDot` indicator.
4. Run analyzer + tests. Commit.

### Step-by-step changes to `explore_screen.dart`

- [ ] **Step 1: Update imports**

Replace the existing imports with:

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_fab.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
```

(Imports sorted; the two new midnight imports — barrel + direct PressScale — added.)

- [ ] **Step 2: Update `ExploreScreen.build`**

In the title row (around lines 71-108):

Replace:
```dart
Text(
  'explore.title'.tr(),
  style: TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
  ),
),
```

With:
```dart
Text(
  'explore.title'.tr(),
  style: Theme.of(context).textTheme.displayLarge,
),
```

Replace the refresh `IconButton` (lines 89-104):
```dart
IconButton(
  onPressed: () {
    _searchController.clear();
    ref.read(placesControllerProvider.notifier).refresh();
  },
  icon: const Icon(Icons.refresh),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),
```

With:
```dart
PillIconButton(
  icon: Icons.refresh,
  size: 40,
  onPressed: () {
    _searchController.clear();
    ref.read(placesControllerProvider.notifier).refresh();
  },
),
```

Empty state copy stays unchanged for now.

- [ ] **Step 3: Rewrite `_FilterButton`**

Replace the entire `_FilterButton` widget (lines 164-186) with:

```dart
class _FilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _FilterButton({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PillIconButton(
          icon: Icons.tune,
          size: 40,
          variant: isActive
              ? PillIconButtonVariant.filled
              : PillIconButtonVariant.ghost,
          onPressed: onPressed,
        ),
        if (isActive)
          const Positioned(
            top: 2,
            right: 2,
            child: _ActiveDot(),
          ),
      ],
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
```

- [ ] **Step 4: Update `_FilterPanel.build`**

Replace the typography expressions inside the Column children (lines 254-322).

Replace:
```dart
Text(
  'explore.filter.title'.tr(),
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
  ),
),
```

With:
```dart
Text(
  'explore.filter.title'.tr(),
  style: Theme.of(context).textTheme.headlineMedium,
),
```

Replace:
```dart
Text(
  'explore.filter.min_reviews'.tr(),
  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
),
```

With:
```dart
Text(
  'explore.filter.min_reviews'.tr(),
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
),
```

Replace the value-display Text (around line 286-294):
```dart
Text(
  '$currentValue',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: colorScheme.primary,
  ),
),
```

With:
```dart
Text(
  '$currentValue',
  textAlign: TextAlign.center,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colorScheme.primary,
      ),
),
```

Replace the "0" / "1000" boundary labels (around line 304-316):
```dart
Text(
  '0',
  style: TextStyle(
    fontSize: 11,
    color: colorScheme.onSurfaceVariant,
  ),
),
// ...
Text(
  '1000',
  style: TextStyle(
    fontSize: 11,
    color: colorScheme.onSurfaceVariant,
  ),
),
```

With (using textTheme.labelSmall = 10 / w700 / letterSpacing 1.5 — but that's tracked. Acceptable for these labels):
```dart
Text(
  '0',
  style: Theme.of(context).textTheme.labelSmall,
),
// ...
Text(
  '1000',
  style: Theme.of(context).textTheme.labelSmall,
),
```

Replace the description Text (around line 321-323):
```dart
Text(
  'explore.filter.description'.tr(),
  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
),
```

With:
```dart
Text(
  'explore.filter.description'.tr(),
  style: Theme.of(context).textTheme.bodyMedium,
),
```

Replace the reset button (lines 326-335):
```dart
AdaptiveButton(
  expanded: true,
  onPressed: () {
    ref.read(minReviewCountProvider.notifier).state = 100;
    setState(() {
      _sliderValue = _valueToSlider(100);
    });
  },
  child: Text('explore.filter.reset'.tr()),
),
```

With:
```dart
PillButton(
  label: 'explore.filter.reset'.tr(),
  variant: PillButtonVariant.ghost,
  fullWidth: true,
  onPressed: () {
    ref.read(minReviewCountProvider.notifier).state = 100;
    setState(() {
      _sliderValue = _valueToSlider(100);
    });
  },
),
```

- [ ] **Step 5: Rewrite `PlaceCard`**

Replace the entire `PlaceCard` widget (lines 342-451) with:

```dart
class PlaceCard extends ConsumerWidget {
  final Place place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final savedLocations = ref.watch(savedLocationsProvider);
    final isSaved =
        savedLocations.valueOrNull?.any((e) => e.placeId == place.id) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassCard(
        onTap: () => context.pushNamed('config', extra: place),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                place.category.getImageAssetPath(context),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _CategoryChip(category: place.category),
                  const SizedBox(height: 8),
                  Text(
                    place.formattedAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _BookmarkButton(
              isSaved: isSaved,
              onTap: () {
                ref.read(savedLocationsProvider.notifier).togglePlace(place);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              category.translationKey.tr().toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

(Note: this introduces a new `PlaceCategory` import — `place_category_extension.dart` re-exports it via `place.category`. Verify by reading the extension file before editing; if `PlaceCategory` is not directly importable, accept the inline `place.category` accessor and pass `category` to `_CategoryChip` as the same type.)

- [ ] **Step 6: Rewrite `_BookmarkButton`**

Replace the existing `_BookmarkButton` widget (lines 453-479) with:

```dart
class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isSaved),
          color: isSaved ? AppColors.primary : colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
```

### Step-by-step changes to `explore_screen_test.dart`

- [ ] **Step 7: Replace the two Badge-based filter tests**

Find the test block "given the filter is at its default value" (lines 135-144). Replace with:

```dart
    testWidgets(
      'given the filter is at its default value, when the screen renders, '
      'then no active dot is shown',
      (tester) async {
        await _givenExploreScreen(tester, minReviewCount: 100);

        // The active dot is an 8x8 BoxDecoration in the filter-button stack.
        // When inactive, it is not present.
        expect(_activeDotFinder(), findsNothing);
      },
    );
```

Find the test block "given a non-default minReviewCount" (lines 146-155). Replace with:

```dart
    testWidgets(
      'given a non-default minReviewCount, when the screen renders, '
      'then the active dot is shown',
      (tester) async {
        await _givenExploreScreen(tester, minReviewCount: 500);

        expect(_activeDotFinder(), findsOneWidget);
      },
    );
```

Add this finder helper at the bottom of the test file (after `_thenPlaceNamesAreHidden`):

```dart
Finder _activeDotFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
        (widget.decoration! as BoxDecoration).color != null,
    description: 'filter active dot',
  );
}
```

The other 9 tests (refresh, search, place rendering, bookmark, navigation, filter panel) **continue to use the same finders** (`find.byIcon(Icons.refresh)`, `find.byIcon(Icons.tune)`, `find.byType(TextField)`, `find.byIcon(Icons.bookmark)`, `find.text(...)`) which remain accurate against the new widget tree.

### Verify and commit

- [ ] **Step 8: Run targeted analyzer**

```
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/explore/presentation/screens/explore_screen.dart test/features/explore/presentation/screens/explore_screen_test.dart
```

Expected: No issues. Old `AppColors.amber` reference at line 181 should be gone.

- [ ] **Step 9: Run explore tests**

```
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/explore/presentation/screens/explore_screen_test.dart
```

Expected: 11/11 PASS.

If a test fails not because of a behaviour change but because the widget tree assertion was too strict, fix the finder (still using minimal-touch principle). If a test fails because the visual contract genuinely changed, **stop and report** for review before continuing.

- [ ] **Step 10: Run full test suite**

```
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test
```

Expected: 390+ tests pass. The widget tree change should not affect tests outside `explore_screen_test.dart`.

- [ ] **Step 11: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/features/explore/presentation/screens/explore_screen.dart \
    frontend/test/features/explore/presentation/screens/explore_screen_test.dart && \
  git commit -m "$(cat <<'EOF'
feat(explore): apply Midnight Kyoto components to ExploreScreen

Refactors explore_screen.dart to use GlassCard, PillIconButton, PillButton,
and PressScale from S2. Title uses textTheme.displayLarge. _FilterButton
swaps Badge for a Stack-positioned _ActiveDot. PlaceCard becomes a
GlassCard with the same per-category dynamic chip color.

The two existing filter-badge tests are rewritten to detect the
_ActiveDot widget; the other 9 widget tests pass unchanged because they
search by icon/text/TextField rather than by widget type.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

The pre-commit hook runs the full suite — must pass.

---

## Self-Review

**Spec coverage:**
- ✅ Title typography → Step 2
- ✅ Refresh button → Step 2
- ✅ `_FilterButton` swap to PillIconButton + ActiveDot → Step 3
- ✅ `_FilterPanel` typography + reset PillButton → Step 4
- ✅ `PlaceCard` GlassCard + extracted `_CategoryChip` → Step 5
- ✅ `_BookmarkButton` PressScale wrapper → Step 6
- ✅ Filter-badge tests adapted → Step 7
- ✅ AppColors.amber removed (was at line 181, now part of PillIconButton variant) → Step 3

**Placeholder scan:** None.

**Type consistency:**
- `PressScale` imported directly from `_press_scale.dart` (per spec, intentional).
- `PillIconButton(size: 40)` chosen for both refresh & filter — spec consistent.
- `_ActiveDot` is a private widget local to this file; not exported.

**Risk:** if `_categoryChip` cannot reference `PlaceCategory` directly, the implementer should pass the chip's color/icon/translationKey rather than the whole category. Verify when reading `place_category_extension.dart` first.
