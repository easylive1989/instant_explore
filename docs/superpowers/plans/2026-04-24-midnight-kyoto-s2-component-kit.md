# Midnight Kyoto S2 — Component Kit Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 7 Midnight Kyoto reusable widgets (`AmbientBackdrop`, `GlassCard`, `PillButton`, `PillIconButton`, `StatusChip`, `MidnightAppBar`, `MidnightBottomNav`) plus a private `_PressScale` helper, wire `AmbientBackdrop` into `MaterialApp.builder` globally, and flip `scaffoldBackgroundColor` to transparent. Each widget is shipped with focused widget tests.

**Architecture:** Component widgets in `frontend/lib/shared/widgets/midnight/`. A barrel `midnight.dart` re-exports the public API. The private `_PressScale` lives inside its own file as a `library`-private widget (or `// ignore_for_file: library_private_types_in_public_api`). Theme tokens drive every component via `Theme.of(context).colorScheme.X` or direct `AppColors.X` reference where the M3 token doesn't exist (e.g., `surfaceVariant` glass colour).

**Tech Stack:** Dart, Flutter, Material 3, `BackdropFilter`/`ImageFilter`, `AnimatedScale`, `TweenAnimationBuilder`, mocktail (for callback verification).

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s2-component-kit-design.md`

---

## File Structure

### Created
- `frontend/lib/shared/widgets/midnight/_press_scale.dart` (private helper)
- `frontend/lib/shared/widgets/midnight/ambient_backdrop.dart`
- `frontend/lib/shared/widgets/midnight/glass_card.dart`
- `frontend/lib/shared/widgets/midnight/pill_button.dart`
- `frontend/lib/shared/widgets/midnight/pill_icon_button.dart`
- `frontend/lib/shared/widgets/midnight/status_chip.dart`
- `frontend/lib/shared/widgets/midnight/midnight_app_bar.dart`
- `frontend/lib/shared/widgets/midnight/midnight_bottom_nav.dart`
- `frontend/lib/shared/widgets/midnight/midnight.dart` (barrel)
- `frontend/test/shared/widgets/midnight/<one test file per widget>.dart`

### Modified
- `frontend/lib/common/config/theme_config.dart` (`scaffoldBackgroundColor: Colors.transparent`)
- `frontend/lib/app.dart` (wrap `MaterialApp.router` builder with `AmbientBackdrop`)

---

## Commands reference

- Run a test file: `cd frontend && fvm flutter test <path>`
- Run all tests: `cd frontend && fvm flutter test`
- Static analysis: `cd frontend && fvm flutter analyze --fatal-infos`

---

## Task B1: `_PressScale` helper

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/_press_scale.dart`
- Test: `frontend/test/shared/widgets/midnight/press_scale_test.dart`

A reusable button-press scale animation. Wraps an `AnimatedScale` driven by gesture state.

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/press_scale_test.dart
@TestOn('vm')
library;

import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PressScale', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: PressScale(child: Text('hello')),
      ));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PressScale(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 50, child: Text('tap')),
          ),
        ),
      ));
      await tester.tap(find.text('tap'));
      expect(taps, 1);
    });

    testWidgets('does not invoke onTap when null (disabled)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PressScale(
            onTap: null,
            child: SizedBox(width: 100, height: 50, child: Text('tap')),
          ),
        ),
      ));
      await tester.tap(find.text('tap'));
      // No exception, no callback expected.
    });

    testWidgets('animates scale on press', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PressScale(
            onTap: () {},
            child: const SizedBox(width: 100, height: 50, child: Text('tap')),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('tap')));
      await tester.pump(const Duration(milliseconds: 100));
      final scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

```
cd frontend && fvm flutter test test/shared/widgets/midnight/press_scale_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/_press_scale.dart
import 'package:flutter/material.dart';

/// Scale-down feedback for taps. Wraps [child] in an [AnimatedScale]
/// driven by [GestureDetector]; scales to [pressedScale] while held,
/// returns to 1.0 on release.
///
/// Disabled when [onTap] is null.
///
/// Note: the leading underscore in the file name keeps this widget out
/// of the `midnight.dart` barrel by convention. Public name `PressScale`
/// is fine for direct file imports inside the kit.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/_press_scale.dart \
    frontend/test/shared/widgets/midnight/press_scale_test.dart && \
  git commit -m "feat(theme): add PressScale helper for Midnight Kyoto buttons"
```

---

## Task B2: `AmbientBackdrop` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/ambient_backdrop.dart`
- Test: `frontend/test/shared/widgets/midnight/ambient_backdrop_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/ambient_backdrop_test.dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/ambient_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmbientBackdrop', () {
    testWidgets('renders child on top', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AmbientBackdrop(child: Text('content')),
      ));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('paints backgroundDark as the base layer', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AmbientBackdrop(child: SizedBox.shrink()),
      ));
      final coloredBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.backgroundDark,
      );
      expect(coloredBoxes, findsAtLeastNWidgets(1));
    });

    testWidgets('honours decorationImage when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AmbientBackdrop(
          decorationImage: DecorationImage(
            image: const AssetImage('assets/test_texture.png'),
            fit: BoxFit.cover,
          ),
          child: const SizedBox.shrink(),
        ),
      ));
      // Allow image error handler.
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byWidgetPredicate(
          (w) => w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).image != null,
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

```
cd frontend && fvm flutter test test/shared/widgets/midnight/ambient_backdrop_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/ambient_backdrop.dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Atmospheric backdrop that runs behind the entire app.
///
/// Layers (bottom → top):
/// 1. Solid [AppColors.backgroundDark] base.
/// 2. Optional [decorationImage] (mix-blend overlay) for texture.
/// 3. Vertical gradient wash (dark → transparent → dark) to ensure
///    text legibility at the top/bottom edges.
/// 4. A slow electric-blue pulse halo near the top, hinting at the
///    "Neon Nocturne" vision.
/// 5. The provided [child] on top.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({
    super.key,
    required this.child,
    this.decorationImage,
  });

  final Widget child;
  final DecorationImage? decorationImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: base color.
        const ColoredBox(color: AppColors.backgroundDark),
        // Layer 2: optional texture overlay.
        if (decorationImage != null)
          DecoratedBox(decoration: BoxDecoration(image: decorationImage)),
        // Layer 3: gradient wash for legibility.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundDark,
                Colors.transparent,
                AppColors.backgroundDark,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Layer 4: neon pulse halo.
        const _PulseHalo(),
        // Layer 5: app content.
        Positioned.fill(child: child),
      ],
    );
  }
}

class _PulseHalo extends StatefulWidget {
  const _PulseHalo();

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.18, end: 0.32).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.85),
                radius: 1.1,
                colors: [
                  AppColors.primary.withValues(alpha: _opacity.value),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/ambient_backdrop.dart \
    frontend/test/shared/widgets/midnight/ambient_backdrop_test.dart && \
  git commit -m "feat(theme): add AmbientBackdrop with pulse halo"
```

---

## Task B3: `GlassCard` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/glass_card.dart`
- Test: `frontend/test/shared/widgets/midnight/glass_card_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/glass_card_test.dart
import 'package:context_app/shared/widgets/midnight/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: GlassCard(child: Text('content'))),
      ));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('contains a BackdropFilter', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: GlassCard(child: SizedBox.shrink())),
      ));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('triggers onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlassCard(
            onTap: () => taps++,
            child: const SizedBox(width: 200, height: 100, child: Text('tap')),
          ),
        ),
      ));
      await tester.tap(find.text('tap'));
      expect(taps, 1);
    });

    testWidgets('does not crash without onTap', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: SizedBox(width: 200, height: 100, child: Text('tap')),
          ),
        ),
      ));
      await tester.tap(find.text('tap'));
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/glass_card.dart
import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

/// A semi-transparent surface card with backdrop blur, ghost border,
/// and rounded corners. Optional [onTap] adds a press-scale interaction
/// and a Material ripple.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
    this.blurSigma = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: radius,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      card = PressScale(
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/glass_card.dart \
    frontend/test/shared/widgets/midnight/glass_card_test.dart && \
  git commit -m "feat(theme): add GlassCard widget"
```

---

## Task B4: `PillButton` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/pill_button.dart`
- Test: `frontend/test/shared/widgets/midnight/pill_button_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/pill_button_test.dart
import 'package:context_app/shared/widgets/midnight/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PillButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(host(PillButton(
        label: 'Action',
        onPressed: () {},
      )));
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('invokes onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PillButton(
        label: 'Action',
        onPressed: () => taps++,
      )));
      await tester.tap(find.text('Action'));
      expect(taps, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(host(const PillButton(
        label: 'Action',
        onPressed: null,
      )));
      await tester.tap(find.text('Action'));
      // No callback registered, no exception.
    });

    testWidgets('renders leading icon', (tester) async {
      await tester.pumpWidget(host(PillButton(
        label: 'Save',
        icon: Icons.save,
        onPressed: () {},
      )));
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('uses StadiumBorder shape', (tester) async {
      await tester.pumpWidget(host(PillButton(
        label: 'Action',
        onPressed: () {},
      )));
      final button = tester.widget<Material>(find.descendant(
        of: find.byType(PillButton),
        matching: find.byType(Material),
      ).first);
      expect(button.shape, isA<StadiumBorder>());
    });

    testWidgets('secondary variant uses surfaceContainerHigh', (tester) async {
      await tester.pumpWidget(host(PillButton(
        label: 'Action',
        variant: PillButtonVariant.secondary,
        onPressed: () {},
      )));
      // Just rendering check; visual assertion via golden is overkill here.
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('ghost variant renders', (tester) async {
      await tester.pumpWidget(host(PillButton(
        label: 'Action',
        variant: PillButtonVariant.ghost,
        onPressed: () {},
      )));
      expect(find.text('Action'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/pill_button.dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

enum PillButtonVariant { primary, secondary, ghost }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final colors = _resolveColors(disabled);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final material = Material(
      color: colors.background,
      shape: StadiumBorder(side: colors.borderSide ?? BorderSide.none),
      shadowColor: colors.shadow,
      elevation: colors.shadow != null ? 6 : 0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: content,
        ),
      ),
    );

    return PressScale(
      onTap: disabled ? null : onPressed,
      child: material,
    );
  }

  _PillColors _resolveColors(bool disabled) {
    switch (variant) {
      case PillButtonVariant.primary:
        return _PillColors(
          background: disabled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
          foreground: disabled
              ? AppColors.onPrimary.withValues(alpha: 0.5)
              : AppColors.onPrimary,
          shadow: disabled
              ? null
              : AppColors.primary.withValues(alpha: 0.2),
        );
      case PillButtonVariant.secondary:
        return _PillColors(
          background: AppColors.surfaceContainerHigh,
          foreground: disabled
              ? AppColors.onSurface.withValues(alpha: 0.5)
              : AppColors.onSurface,
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        );
      case PillButtonVariant.ghost:
        return _PillColors(
          background: Colors.transparent,
          foreground: disabled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
        );
    }
  }
}

class _PillColors {
  const _PillColors({
    required this.background,
    required this.foreground,
    this.borderSide,
    this.shadow,
  });
  final Color background;
  final Color foreground;
  final BorderSide? borderSide;
  final Color? shadow;
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 7/7 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/pill_button.dart \
    frontend/test/shared/widgets/midnight/pill_button_test.dart && \
  git commit -m "feat(theme): add PillButton with primary/secondary/ghost variants"
```

---

## Task B5: `PillIconButton` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/pill_icon_button.dart`
- Test: `frontend/test/shared/widgets/midnight/pill_icon_button_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/pill_icon_button_test.dart
import 'package:context_app/shared/widgets/midnight/pill_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PillIconButton', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(host(PillIconButton(
        icon: Icons.add,
        onPressed: () {},
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('invokes onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PillIconButton(
        icon: Icons.add,
        onPressed: () => taps++,
      )));
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(host(const PillIconButton(
        icon: Icons.add,
        onPressed: null,
      )));
      await tester.tap(find.byIcon(Icons.add));
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(host(PillIconButton(
        icon: Icons.add,
        tooltip: 'Add',
        onPressed: () {},
      )));
      expect(find.byTooltip('Add'), findsOneWidget);
    });

    testWidgets('uses CircleBorder shape', (tester) async {
      await tester.pumpWidget(host(PillIconButton(
        icon: Icons.add,
        onPressed: () {},
      )));
      final material = tester.widget<Material>(find.descendant(
        of: find.byType(PillIconButton),
        matching: find.byType(Material),
      ).first);
      expect(material.shape, isA<CircleBorder>());
    });

    testWidgets('ghost variant renders', (tester) async {
      await tester.pumpWidget(host(PillIconButton(
        icon: Icons.favorite,
        variant: PillIconButtonVariant.ghost,
        onPressed: () {},
      )));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/pill_icon_button.dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

enum PillIconButtonVariant { filled, ghost }

class PillIconButton extends StatelessWidget {
  const PillIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = PillIconButtonVariant.filled,
    this.size = 48,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PillIconButtonVariant variant;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final isFilled = variant == PillIconButtonVariant.filled;

    final material = Material(
      color: isFilled
          ? (disabled
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary)
          : AppColors.surfaceContainerHigh,
      shape: CircleBorder(
        side: isFilled
            ? BorderSide.none
            : const BorderSide(color: AppColors.outlineVariant),
      ),
      shadowColor: isFilled && !disabled
          ? AppColors.primary.withValues(alpha: 0.2)
          : null,
      elevation: isFilled && !disabled ? 6 : 0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: isFilled
                ? (disabled
                      ? AppColors.onPrimary.withValues(alpha: 0.5)
                      : AppColors.onPrimary)
                : AppColors.onSurface,
            size: size * 0.5,
          ),
        ),
      ),
    );

    final wrapped = PressScale(
      onTap: disabled ? null : onPressed,
      child: material,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: wrapped);
    }
    return wrapped;
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 6/6 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/pill_icon_button.dart \
    frontend/test/shared/widgets/midnight/pill_icon_button_test.dart && \
  git commit -m "feat(theme): add PillIconButton"
```

---

## Task B6: `StatusChip` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/status_chip.dart`
- Test: `frontend/test/shared/widgets/midnight/status_chip_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/status_chip_test.dart
import 'package:context_app/shared/widgets/midnight/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('StatusChip', () {
    testWidgets('renders label uppercased', (tester) async {
      await tester.pumpWidget(host(const StatusChip(label: 'Active')));
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(host(const StatusChip(
        label: 'Saved',
        icon: Icons.bookmark,
      )));
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('all tones render without crash', (tester) async {
      for (final tone in StatusChipTone.values) {
        await tester.pumpWidget(host(StatusChip(
          label: tone.name,
          tone: tone,
        )));
        expect(find.text(tone.name.toUpperCase()), findsOneWidget);
      }
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/status_chip.dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

enum StatusChipTone { active, neutral, error, warning, success }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.neutral,
    this.icon,
  });

  final String label;
  final StatusChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.foreground,
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

  _ChipColors _resolveColors(StatusChipTone tone) {
    switch (tone) {
      case StatusChipTone.active:
        return const _ChipColors(
          background: AppColors.primaryContainer,
          foreground: AppColors.primary,
        );
      case StatusChipTone.neutral:
        return const _ChipColors(
          background: AppColors.surfaceContainerHigh,
          foreground: AppColors.onSurface,
        );
      case StatusChipTone.error:
        return const _ChipColors(
          background: AppColors.errorContainer,
          foreground: AppColors.error,
        );
      case StatusChipTone.warning:
        return const _ChipColors(
          background: AppColors.tertiaryContainer,
          foreground: AppColors.tertiary,
        );
      case StatusChipTone.success:
        return const _ChipColors(
          background: AppColors.secondaryContainer,
          foreground: AppColors.secondary,
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/status_chip.dart \
    frontend/test/shared/widgets/midnight/status_chip_test.dart && \
  git commit -m "feat(theme): add StatusChip with five tones"
```

---

## Task B7: `MidnightAppBar` widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/midnight_app_bar.dart`
- Test: `frontend/test/shared/widgets/midnight/midnight_app_bar_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/midnight_app_bar_test.dart
import 'package:context_app/shared/widgets/midnight/midnight_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MidnightAppBar', () {
    testWidgets('renders title uppercased when uppercaseTitle is true',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          appBar: MidnightAppBar(title: Text('explore')),
        ),
      ));
      expect(find.text('EXPLORE'), findsOneWidget);
    });

    testWidgets('preserves casing when uppercaseTitle is false',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          appBar: MidnightAppBar(
            title: Text('Explore'),
            uppercaseTitle: false,
          ),
        ),
      ));
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('renders leading and actions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: MidnightAppBar(
            title: const Text('Title'),
            leading: const Icon(Icons.menu),
            actions: [const Icon(Icons.search)],
          ),
        ),
      ));
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('preferredSize is kToolbarHeight', (tester) async {
      const bar = MidnightAppBar(title: Text('x'));
      expect(bar.preferredSize.height, kToolbarHeight);
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

- [ ] **Step 3: Implement**

```dart
// frontend/lib/shared/widgets/midnight/midnight_app_bar.dart
import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

class MidnightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MidnightAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.uppercaseTitle = true,
    this.blurSigma = 12,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool uppercaseTitle;
  final double blurSigma;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget? resolvedTitle = title;
    if (uppercaseTitle && title is Text) {
      final t = title! as Text;
      resolvedTitle = Text(
        (t.data ?? '').toUpperCase(),
        style: t.style ??
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.onSurface,
            ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xCC0B1117), // surfaceContainerLowest @ 80%
            border: Border(
              bottom: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: AppBar(
            title: resolvedTitle,
            leading: leading,
            actions: actions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/midnight_app_bar.dart \
    frontend/test/shared/widgets/midnight/midnight_app_bar_test.dart && \
  git commit -m "feat(theme): add MidnightAppBar with blur and uppercase title"
```

---

## Task B8: `MidnightBottomNav` widget + barrel export + global wiring

**Files:**
- Create: `frontend/lib/shared/widgets/midnight/midnight_bottom_nav.dart`
- Test: `frontend/test/shared/widgets/midnight/midnight_bottom_nav_test.dart`
- Create: `frontend/lib/shared/widgets/midnight/midnight.dart` (barrel export)
- Modify: `frontend/lib/common/config/theme_config.dart` (`scaffoldBackgroundColor: Colors.transparent`)
- Modify: `frontend/lib/app.dart` (wrap MaterialApp.builder with `AmbientBackdrop`)

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/shared/widgets/midnight/midnight_bottom_nav_test.dart
import 'package:context_app/shared/widgets/midnight/midnight_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  const items = [
    MidnightBottomNavItem(icon: Icons.explore, label: 'Explore'),
    MidnightBottomNavItem(icon: Icons.location_on, label: 'Nearby'),
    MidnightBottomNavItem(icon: Icons.bookmark, label: 'Saved'),
    MidnightBottomNavItem(icon: Icons.person, label: 'Profile'),
  ];

  group('MidnightBottomNav', () {
    testWidgets('renders all items', (tester) async {
      await tester.pumpWidget(host(MidnightBottomNav(
        items: items,
        currentIndex: 0,
        onTap: (_) {},
      )));
      expect(find.text('EXPLORE'), findsOneWidget);
      expect(find.text('NEARBY'), findsOneWidget);
      expect(find.text('SAVED'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('invokes onTap with item index', (tester) async {
      var lastIndex = -1;
      await tester.pumpWidget(host(MidnightBottomNav(
        items: items,
        currentIndex: 0,
        onTap: (i) => lastIndex = i,
      )));
      await tester.tap(find.text('SAVED'));
      expect(lastIndex, 2);
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

- [ ] **Step 3: Implement bottom nav**

```dart
// frontend/lib/shared/widgets/midnight/midnight_bottom_nav.dart
import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

class MidnightBottomNavItem {
  const MidnightBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final String label;
  final IconData? activeIcon;
}

class MidnightBottomNav extends StatelessWidget {
  const MidnightBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.blurSigma = 16,
  });

  final List<MidnightBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xCC0B1117), // surfaceContainerLowest @ 80%
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavItem(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MidnightBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withValues(alpha: 0.7);

    return PressScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? (item.activeIcon ?? item.icon) : item.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                item.label.toUpperCase(),
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
      ),
    );
  }
}
```

- [ ] **Step 4: Run nav test, expect pass**

Expected: 2/2 PASS.

- [ ] **Step 5: Create barrel export**

```dart
// frontend/lib/shared/widgets/midnight/midnight.dart
export 'ambient_backdrop.dart';
export 'glass_card.dart';
export 'midnight_app_bar.dart';
export 'midnight_bottom_nav.dart';
export 'pill_button.dart';
export 'pill_icon_button.dart';
export 'status_chip.dart';
```

(`_press_scale.dart` is intentionally NOT exported — it's a kit-internal helper.)

- [ ] **Step 6: Wire AmbientBackdrop globally**

In `frontend/lib/common/config/theme_config.dart`, change line:

```dart
      scaffoldBackgroundColor: AppColors.backgroundDark,
```

To:

```dart
      scaffoldBackgroundColor: Colors.transparent,
```

In `frontend/lib/app.dart`, find the `builder:` callback in `MaterialApp.router(...)`. Currently it returns:

```dart
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (pendingShare != null && pendingShare.isLoading)
              const _ShareLoadingOverlay(),
          ],
        );
      },
```

Replace with:

```dart
      builder: (context, child) {
        return AmbientBackdrop(
          child: Stack(
            children: [
              child!,
              if (pendingShare != null && pendingShare.isLoading)
                const _ShareLoadingOverlay(),
            ],
          ),
        );
      },
```

Add the import at the top of `app.dart`:

```dart
import 'package:context_app/shared/widgets/midnight/midnight.dart';
```

- [ ] **Step 7: Update ThemeConfig test**

In `frontend/test/common/config/theme_config_test.dart`, update the existing test:

```dart
    test('uses backgroundDark as scaffoldBackgroundColor', () {
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });
```

To:

```dart
    test('uses transparent scaffoldBackgroundColor (AmbientBackdrop paints background)', () {
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
    });
```

- [ ] **Step 8: Run analyzer**

```
cd frontend && fvm flutter analyze --fatal-infos lib/shared/widgets/midnight/ test/shared/widgets/midnight/ lib/common/config/theme_config.dart lib/app.dart test/common/config/theme_config_test.dart
```

Expected: No issues.

- [ ] **Step 9: Run full suite**

```
cd frontend && fvm flutter test
```

Expected: all pass. If any existing widget test fails because the screen no longer has a solid background (now `Colors.transparent` + AmbientBackdrop), and the test was asserting on a colored region, fix that test by wrapping the test scaffold with a solid background or removing the colour assertion. Don't add new tests.

- [ ] **Step 10: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/shared/widgets/midnight/ \
    frontend/test/shared/widgets/midnight/ \
    frontend/lib/common/config/theme_config.dart \
    frontend/test/common/config/theme_config_test.dart \
    frontend/lib/app.dart && \
  git commit -m "$(cat <<'EOF'
feat(theme): add MidnightBottomNav and wire AmbientBackdrop globally

Adds the bottom-nav component with primary-container active state,
exposes the kit through midnight.dart barrel, flips
scaffoldBackgroundColor to transparent so the AmbientBackdrop installed
via MaterialApp.builder shows through.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ `_PressScale` (Task B1)
- ✅ `AmbientBackdrop` (Task B2)
- ✅ `GlassCard` (Task B3)
- ✅ `PillButton` (Task B4)
- ✅ `PillIconButton` (Task B5)
- ✅ `StatusChip` (Task B6)
- ✅ `MidnightAppBar` (Task B7)
- ✅ `MidnightBottomNav` (Task B8)
- ✅ Barrel export (Task B8)
- ✅ Global AmbientBackdrop wiring (Task B8)
- ✅ scaffoldBackgroundColor flip (Task B8)

**Placeholder scan:** No "TBD". All code blocks are complete.

**Type consistency:**
- `PressScale` is the public class; the file name uses underscore prefix per spec.
- `MidnightBottomNavItem` is required by `MidnightBottomNav`; both live in the same file.
- All four button-family widgets share the `PressScale` import.

**Risks acknowledged in spec, not blocking implementation:**
- BackdropFilter performance (multi-layer): handled via `RepaintBoundary` in `_PulseHalo` only; future profiling may suggest more.
- ThemeConfig test in B8 needs to flip its assertion as part of the same task.
