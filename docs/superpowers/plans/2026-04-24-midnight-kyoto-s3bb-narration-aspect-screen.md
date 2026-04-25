# Midnight Kyoto S3-bb — Narration Aspect Screen Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `select_narration_aspect_screen.dart` (484 lines, 6 widgets) end-to-end to use Midnight Kyoto components. Drops all hard-coded `Color(0x...)` values except the photo-darken filter. Preserves per-category dynamic chip colour.

**Architecture:** Single source-of-truth refactor. Each widget reads colours and typography from `Theme.of(context)`. `AspectOption` becomes a Container-styled selectable card (not a `GlassCard`, because selection needs conditional decoration). Start button becomes a `PillButton`.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, S2 Midnight Kyoto components.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3bb-narration-aspect-screen-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/narration/presentation/screens/select_narration_aspect_screen.dart`
- `frontend/test/features/narration/presentation/screens/select_narration_aspect_screen_test.dart` (only if test assertions break)

### Untouched (out of scope)
- All controllers / state / domain
- `place_image_cache_manager.dart`
- `narration_aspect.dart` and its extension

---

## Task E1: Refactor aspect screen

**Files:** `select_narration_aspect_screen.dart` + test as needed.

This is a single-commit task. The 6 widgets within the file change together; the test file is only touched if assertions break.

### Step 1: Update imports

Replace the existing imports at the top of `select_narration_aspect_screen.dart` with:

```dart
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/controllers/extensions/narration_aspect_extension.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
```

Removed: `import 'package:context_app/common/config/app_colors.dart';`

(Verify with grep that `AppColors` is no longer referenced anywhere in the file before removing the import. If any usage remains in a step you haven't gotten to yet, keep the import until those are cleaned.)

### Step 2: Replace top-bar back button

Find the `AdaptiveIconButton` for back navigation in the top app bar (currently around line 148-154). Replace its icon's `color: Colors.white` with `color: Theme.of(context).colorScheme.onSurface`.

### Step 3: Replace bottom-area gradient

Find the `Container.decoration.gradient.colors` list (currently around lines 173-178). Replace the static color list with theme-derived values. The whole `BoxDecoration` becomes:

```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
      Colors.transparent,
    ],
  ),
),
```

⚠️ Because the colors now depend on `Theme.of`, the enclosing `Container.decoration` constant cannot be `const`. The compiler will already enforce this — confirm it builds.

### Step 4: Replace place-name typography

Find the `Text(widget.place.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))` (around lines 185-192). Replace with:

```dart
Text(
  widget.place.name,
  style: Theme.of(context).textTheme.displayMedium,
),
```

### Step 5: Replace aspect-title typography

Find the `Text('config_screen.select_aspect_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))` (around lines 208-215). Replace with:

```dart
Text(
  'config_screen.select_aspect_title'.tr(),
  style: Theme.of(context).textTheme.headlineMedium,
),
```

### Step 6: Replace Start button

Find the `AdaptiveButton(...)` block (around lines 251-268). Replace with:

```dart
PillButton(
  label: 'config_screen.start_button'.tr(),
  icon: Icons.play_arrow,
  fullWidth: true,
  onPressed: selectedAspects.isEmpty ? null : _onStartPressed,
),
```

### Step 7: Refactor `_GeneratingIndicator`

Replace the entire `_GeneratingIndicator` class (around lines 282-301) with:

```dart
class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdaptiveProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'config_screen.generating'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

⚠️ Constructor changed from no-arg to `const`. Update the call site (`_GeneratingIndicator()`) to `const _GeneratingIndicator()`.

### Step 8: Refactor `_BackgroundImage`

Make these surgical changes inside the `_BackgroundImage` build method:

- The `placeholder` `Container(color: Colors.black, ...)` → `ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerLowest, child: ...)`.
- The `errorWidget` `Container(color: Colors.black, ...)` → same as above.
- The fallback `Container(color: Colors.black)` (the very last branch) → `ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerLowest)`.

Keep `Color(0x66000000)` as the `colorFilter`/`color` darken — that's an image processing filter, not a theme value.

### Step 9: Replace `_CategoryBadge`

Replace the entire `_CategoryBadge` class (around lines 352-383) with:

```dart
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
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
            Icon(place.category.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              place.category.translationKey.tr().toUpperCase(),
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

### Step 10: Replace `_AddressRow`

Replace the entire `_AddressRow` class (around lines 385-407) with:

```dart
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.location_on, color: cs.onSurfaceVariant, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            place.formattedAddress,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
```

### Step 11: Replace `AspectOption`

Replace the entire `AspectOption` class (around lines 409-484) with:

```dart
class AspectOption extends StatelessWidget {
  final NarrationAspect aspect;
  final bool isSelected;
  final VoidCallback onTap;

  const AspectOption({
    super.key,
    required this.aspect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      aspect.icon,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspect.translationKey.tr(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aspect.descriptionKey.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: isSelected
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Step 12: Verify

- [ ] Run targeted analyzer:
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/narration/presentation/screens/select_narration_aspect_screen.dart test/features/narration/presentation/screens/select_narration_aspect_screen_test.dart
  ```
  Expected: No issues.

- [ ] Run aspect-screen test:
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/narration/presentation/screens/select_narration_aspect_screen_test.dart
  ```
  Expected: 9/9 PASS.
  
  If any assertion fails because of the widget tree changes (e.g., a finder that targeted a `Container` colour now finds different content), fix that finder using minimum-touch principle. If more than 3 tests need rewriting, **stop and report**.

- [ ] Run full suite:
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

### Step 13: Commit

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/features/narration/presentation/screens/select_narration_aspect_screen.dart \
    frontend/test/features/narration/presentation/screens/select_narration_aspect_screen_test.dart && \
  git commit -m "$(cat <<'EOF'
feat(narration): apply Midnight Kyoto components to aspect screen

Refactors select_narration_aspect_screen.dart end-to-end. Place name
becomes textTheme.displayMedium; bottom gradient sources from
colorScheme.surface; AspectOption gains a PressScale wrap and
conditional primary border on selection; Start button becomes a
PillButton with leading play icon. Per-category badge unifies with
PlaceCard's chip styling. Photo-darken filter (Color(0x66000000)) is
preserved as an image-processing intent.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Top-bar back button → Step 2
- ✅ Bottom gradient → Step 3
- ✅ Place name → Step 4
- ✅ Aspect title → Step 5
- ✅ Start button → Step 6
- ✅ `_GeneratingIndicator` → Step 7
- ✅ `_BackgroundImage` placeholders → Step 8
- ✅ `_CategoryBadge` → Step 9
- ✅ `_AddressRow` → Step 10
- ✅ `AspectOption` → Step 11

**Placeholder scan:** None.

**Type consistency:**
- `_GeneratingIndicator` constructor changed from non-const to `const` → call site `_GeneratingIndicator()` must add `const`.
- `AspectOption` is public (used by tests via `find.byType`); class shape unchanged → tests should keep passing.
