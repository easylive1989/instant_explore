# Midnight Kyoto S3-c — Onboarding Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up onboarding to match the rest of S3: drop the redundant local `Theme(midnightKyotoTheme())` wrap, swap deprecated `AppColors` token references for `colorScheme.X` equivalents, replace `FilledButton.icon` sample CTA with `PillButton`, and rename the ghost serial colour to its `AppColors.surfaceVariant` token. Keep the editorial art and the stacked `MidnightKyotoBackdrop`.

**Architecture:** Two-file edit — `onboarding_welcome_screen.dart` (main refactor) and `onboarding_page_art.dart` (single token rename). One commit. Existing 2-test suite expected to pass unchanged.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, S2 Midnight Kyoto components, `introduction_screen` package.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3c-onboarding-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`
- `frontend/lib/features/onboarding/presentation/widgets/onboarding_page_art.dart`

### Untouched (out of scope)
- `frontend/lib/shared/widgets/pulsing_glow.dart`
- `frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart` (still exports `midnightKyotoTheme()` used by subscription_screen — to be cleaned up in S3-e)
- `frontend/lib/features/onboarding/domain/`, `data/`, `controllers/`

---

## Task F1: Refactor onboarding files

### Step 1: Edit `onboarding_welcome_screen.dart`

- [ ] **a) Imports**: Add `import 'package:context_app/shared/widgets/midnight/midnight.dart';`. Keep the existing `import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';` because we still use `MidnightKyotoBackdrop`.

- [ ] **b) Remove the `Theme(...)` wrap.** In `build`, replace:

  ```dart
  return Theme(
    data: midnightKyotoTheme(),
    child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: MidnightKyotoBackdrop(
        child: IntroductionScreen(
          // ...
        ),
      ),
    ),
  );
  ```

  With:

  ```dart
  final cs = Theme.of(context).colorScheme;
  return Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: MidnightKyotoBackdrop(
      child: IntroductionScreen(
        // ...
      ),
    ),
  );
  ```

  Note: `final cs = ...` declared at the top of `build` so all subsequent style refs reuse it.

- [ ] **c) Update `skip` Text style**:
  ```dart
  skip: Text(
    'onboarding.skip'.tr(),
    style: TextStyle(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
  ),
  ```

- [ ] **d) Update `next` Icon**:
  ```dart
  next: Icon(Icons.arrow_forward, color: cs.primary),
  ```

- [ ] **e) Update `done` Text**:
  ```dart
  done: Text(
    'onboarding.get_started'.tr(),
    style: TextStyle(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    ),
  ),
  ```

- [ ] **f) Update `dotsDecorator`**:
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

- [ ] **g) Update the four `_page(...)` calls** so each `accent` flows from `cs`:
  - Page 1: `accent: cs.primary`
  - Page 2: `accent: cs.primary`
  - Page 3: `accent: cs.primary`
  - Page 4: `accent: cs.tertiary` (replaces `AppColors.amber`)

- [ ] **h) Update the `_page` helper signature & body** so it reads `Theme.of(context)` itself (because `_page` is called from `build`, the `BuildContext` is already in scope via `this.context` for `State` subclasses):

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

    return PageViewModel(
      titleWidget: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
        child: Text(
          titleKey.tr(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bodyKey.tr(), style: bodyStyle, textAlign: TextAlign.center),
            if (footer != null) ...[const SizedBox(height: 28), footer],
          ],
        ),
      ),
      image: OnboardingPageArt(
        icon: icon,
        serialLabel: serialLabel,
        chipLabel: chipKey.tr(),
        accent: accent,
      ),
      decoration: const PageDecoration(
        pageColor: Colors.transparent,
        imagePadding: EdgeInsets.only(top: 24),
        contentMargin: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
      ),
    );
  }
  ```

  (Removed: `const titleStyle` and `const bodyStyle` declarations.)

- [ ] **i) Replace the `_SampleCtaFooter` widget** with the PillButton version:

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

### Step 2: Edit `onboarding_page_art.dart`

- [ ] In `_GhostSerial.build`, change:

  ```dart
  color: Color(0x14FFFFFF),
  ```

  To:

  ```dart
  color: AppColors.surfaceVariant,
  ```

  No other edits needed in this file — `_ChipLabel` keeps its bespoke design.

### Step 3: Verify

- [ ] **Run analyzer:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart lib/features/onboarding/presentation/widgets/onboarding_page_art.dart test/features/onboarding/presentation/screens/onboarding_welcome_screen_test.dart
  ```
  Expected: No issues.

- [ ] **Run onboarding tests:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test test/features/onboarding/
  ```
  Expected: 2/2 PASS (or whatever the current count is — all should pass).

- [ ] **Run full suite:**
  ```
  cd /Users/paulwu/Documents/PLRepo/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

### Step 4: Commit

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart \
    frontend/lib/features/onboarding/presentation/widgets/onboarding_page_art.dart && \
  git commit -m "$(cat <<'EOF'
feat(onboarding): apply Midnight Kyoto cleanup pass

Drops the redundant local Theme(midnightKyotoTheme()) wrap (S1's
global MK theme is now sufficient). Replaces AppColors text/amber/
white20 tokens with colorScheme equivalents (page-4 accent uses
cs.tertiary). Sample CTA becomes a PillButton. _GhostSerial colour
named via AppColors.surfaceVariant. Editorial layout, MidnightKyoto-
Backdrop punch-up and PulsingGlow are preserved.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Theme wrap removed → Step 1b
- ✅ Skip/next/done text → Steps 1c/d/e
- ✅ Dots decorator → Step 1f
- ✅ Page accents (incl. cs.tertiary for page 4) → Step 1g
- ✅ `_page` helper → Step 1h
- ✅ `_SampleCtaFooter` → Step 1i
- ✅ `_GhostSerial` colour token → Step 2

**Placeholder scan:** None.

**Type consistency:** `_page` accesses `this.context` from State; `_SampleCtaFooter` is a `StatelessWidget` so uses its build context.
